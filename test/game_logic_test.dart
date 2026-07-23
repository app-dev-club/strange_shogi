import 'package:flutter_test/flutter_test.dart';
import 'package:strange_shogi/data/piece_definitions.dart';
import 'package:strange_shogi/game/board_generator.dart';
import 'package:strange_shogi/game/board_validator.dart';
import 'package:strange_shogi/game/drop_generator.dart';
import 'package:strange_shogi/game/formation_validator.dart';
import 'package:strange_shogi/game/game_rules.dart';
import 'package:strange_shogi/game/move_generator.dart';
import 'package:strange_shogi/game/promotion_rules.dart';
import 'package:strange_shogi/models/game_models.dart';

void main() {
  const generator = BoardGenerator();
  const validator = BoardValidator();

  group('盤面生成', () {
    test('同じシードから同じ非対称盤面が生成される', () {
      final first = generator.generate(12345);
      final second = generator.generate(12345);
      expect(first.available, second.available);
      expect(validator.isAsymmetric(first), isTrue);
    });

    test('全マスが接続され、30〜40マスで、両陣営に5マス以上ある', () {
      for (final seed in [1, 2, 77, 999]) {
        final board = generator.generate(seed);
        expect(validator.isConnected(board), isTrue);
        expect(board.available.length, inInclusiveRange(30, 40));
        expect(
          ArmySideDefinition.fromBoard(board, ArmySide.a).deploymentArea.length,
          greaterThanOrEqualTo(5),
        );
        expect(
          ArmySideDefinition.fromBoard(board, ArmySide.b).deploymentArea.length,
          greaterThanOrEqualTo(5),
        );
      }
    });
  });

  group('陣営と編成', () {
    test('後手が選んだ陣営は先手に割り当てられず、前進方向が異なる', () {
      final board = generator.generate(10);
      const second = ArmySide.a;
      final first = second == ArmySide.a ? ArmySide.b : ArmySide.a;
      expect(first, isNot(second));
      expect(ArmySideDefinition.fromBoard(board, ArmySide.a).forward, 1);
      expect(ArmySideDefinition.fromBoard(board, ArmySide.b).forward, -1);
    });

    test('8ポイント超過は無効', () {
      const formation = Formation({PieceType.king: 1, PieceType.rook: 2});
      expect(const FormationValidator().isValid(formation), isFalse);
    });

    test('香車は2ポイント、歩は1ポイントとして計算する', () {
      const formation = Formation({
        PieceType.king: 1,
        PieceType.lance: 1,
        PieceType.pawn: 1,
      });
      expect(const FormationValidator().points(formation), 3);
    });

    test('王を持ち駒にすると無効、王以外はすべて持ち駒にできる', () {
      final board = generator.generate(4);
      final side = ArmySideDefinition.fromBoard(board, ArmySide.a);
      const formation = Formation({PieceType.king: 1, PieceType.pawn: 2});
      final invalid = DeploymentState(
        boardPieces: const {},
        hand: const Hand([PieceType.king, PieceType.pawn, PieceType.pawn]),
      );
      final valid = DeploymentState(
        boardPieces: {side.deploymentArea.first: PieceType.king},
        hand: const Hand([PieceType.pawn, PieceType.pawn]),
      );
      expect(
        const FormationValidator().isDeploymentValid(formation, invalid, side),
        isFalse,
      );
      expect(
        const FormationValidator().isDeploymentValid(formation, valid, side),
        isTrue,
      );
    });

    test('盤上と持ち駒で重複すると無効', () {
      final board = generator.generate(5);
      final side = ArmySideDefinition.fromBoard(board, ArmySide.a);
      const formation = Formation({PieceType.king: 1, PieceType.gold: 1});
      final positions = side.deploymentArea.take(2).toList();
      final deployment = DeploymentState(
        boardPieces: {
          positions[0]: PieceType.king,
          positions[1]: PieceType.gold,
        },
        hand: const Hand([PieceType.gold]),
      );
      expect(
        const FormationValidator().isDeploymentValid(
          formation,
          deployment,
          side,
        ),
        isFalse,
      );
    });
  });

  group('移動と持ち駒', () {
    final board = BoardDefinition(
      seed: 0,
      available: {
        for (var y = 0; y < 7; y++)
          for (var x = 0; x < 7; x++)
            if (!(x == 3 && y == 2)) Position(x, y),
      },
    );
    const moves = MoveGenerator();

    test('飛車は盤外セルを越えられない', () {
      const rook = Piece(
        id: 'r',
        type: PieceType.rook,
        owner: PlayerId.player1,
        position: Position(3, 4),
      );
      final destinations = moves.legalDestinations(
        board: board,
        piece: rook,
        pieces: const [rook],
        forward: -1,
      );
      expect(destinations, contains(const Position(3, 3)));
      expect(destinations, isNot(contains(const Position(3, 1))));
    });

    test('角は駒を飛び越えない', () {
      const bishop = Piece(
        id: 'b',
        type: PieceType.bishop,
        owner: PlayerId.player1,
        position: Position(1, 5),
      );
      const blocker = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player1,
        position: Position(2, 4),
      );
      final destinations = moves.legalDestinations(
        board: board,
        piece: bishop,
        pieces: const [bishop, blocker],
        forward: -1,
      );
      expect(destinations, isNot(contains(const Position(3, 3))));
    });

    test('桂馬は途中の駒を飛び越える', () {
      const knight = Piece(
        id: 'n',
        type: PieceType.knight,
        owner: PlayerId.player1,
        position: Position(3, 5),
      );
      const blocker = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player1,
        position: Position(3, 4),
      );
      final destinations = moves.legalDestinations(
        board: board,
        piece: knight,
        pieces: const [knight, blocker],
        forward: -1,
      );
      expect(
        destinations,
        containsAll([const Position(2, 3), const Position(4, 3)]),
      );
    });

    test('龍は飛車の動きに加えて斜めへ1マス動ける', () {
      const dragon = Piece(
        id: 'r',
        type: PieceType.rook,
        owner: PlayerId.player1,
        position: Position(3, 4),
        promoted: true,
      );
      final destinations = moves.legalDestinations(
        board: board,
        piece: dragon,
        pieces: const [dragon],
        forward: -1,
      );
      expect(destinations, contains(const Position(2, 3)));
      expect(destinations, isNot(contains(const Position(1, 2))));
    });

    test('と金は金と同じ動きをする', () {
      const promotedPawn = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player1,
        position: Position(3, 4),
        promoted: true,
      );
      final destinations = moves.legalDestinations(
        board: board,
        piece: promotedPawn,
        pieces: const [promotedPawn],
        forward: -1,
      );
      expect(destinations, contains(const Position(3, 5)));
      expect(destinations, isNot(contains(const Position(2, 5))));
    });

    test('取得した駒が持ち駒になり、王取得で勝敗が決まる', () {
      const attacker = Piece(
        id: 'r',
        type: PieceType.rook,
        owner: PlayerId.player1,
        position: Position(0, 0),
      );
      const pawn = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player2,
        position: Position(0, 1),
      );
      const king = Piece(
        id: 'k',
        type: PieceType.king,
        owner: PlayerId.player2,
        position: Position(0, 2),
      );
      const rules = GameRules();
      final capture = rules.movePiece(
        piece: attacker,
        to: pawn.position,
        pieces: const [attacker, pawn, king],
        hands: const {PlayerId.player1: Hand([]), PlayerId.player2: Hand([])},
      );
      expect(capture.hands[PlayerId.player1]!.pieces, [PieceType.pawn]);
      final win = rules.movePiece(
        piece: capture.pieces.firstWhere((p) => p.id == 'r'),
        to: king.position,
        pieces: capture.pieces,
        hands: capture.hands,
      );
      expect(win.winner, PlayerId.player1);
    });

    test('初期持ち駒を空きマスへ打てるが、占有マスへは打てない', () {
      const dropper = DropGenerator();
      const occupied = Piece(
        id: 'x',
        type: PieceType.gold,
        owner: PlayerId.player2,
        position: Position(1, 1),
      );
      final legal = dropper.legalDrops(
        board: board,
        type: PieceType.gold,
        owner: PlayerId.player1,
        pieces: const [occupied],
        forward: 1,
      );
      expect(legal, isNot(contains(occupied.position)));
      expect(legal, isNotEmpty);
      final result = const GameRules().dropPiece(
        player: PlayerId.player1,
        handIndex: 0,
        to: legal.first,
        pieces: const [occupied],
        hands: const {
          PlayerId.player1: Hand([PieceType.gold]),
          PlayerId.player2: Hand([]),
        },
      );
      expect(
        result.pieces.any(
          (p) => p.type == PieceType.gold && p.owner == PlayerId.player1,
        ),
        isTrue,
      );
    });

    test('二歩と行き所のない駒打ちを禁止する', () {
      const dropper = DropGenerator();
      const pawn = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player1,
        position: Position(2, 3),
      );
      final legal = dropper.legalDrops(
        board: board,
        type: PieceType.pawn,
        owner: PlayerId.player1,
        pieces: const [pawn],
        forward: -1,
      );
      expect(legal.where((p) => p.x == 2), isEmpty);
      expect(legal.where((p) => p.y == 0), isEmpty);
    });

    test('成った歩は二歩の判定に含めない', () {
      const dropper = DropGenerator();
      const promotedPawn = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player1,
        position: Position(2, 3),
        promoted: true,
      );
      final legal = dropper.legalDrops(
        board: board,
        type: PieceType.pawn,
        owner: PlayerId.player1,
        pieces: const [promotedPawn],
        forward: -1,
      );
      expect(legal.where((p) => p.x == 2), isNotEmpty);
    });
  });

  group('成り', () {
    const rules = PromotionRules();

    test('敵陣3段への侵入または敵陣からの移動で任意に成れる', () {
      const entering = Piece(
        id: 's1',
        type: PieceType.silver,
        owner: PlayerId.player1,
        position: Position(3, 3),
      );
      const leaving = Piece(
        id: 's2',
        type: PieceType.silver,
        owner: PlayerId.player1,
        position: Position(3, 2),
      );
      expect(
        rules.choice(piece: entering, to: const Position(3, 2), forward: -1),
        PromotionChoice.optional,
      );
      expect(
        rules.choice(piece: leaving, to: const Position(3, 3), forward: -1),
        PromotionChoice.optional,
      );
    });

    test('歩と香車は最終段、桂馬は最終2段で強制的に成る', () {
      for (final type in [PieceType.pawn, PieceType.lance]) {
        expect(
          rules.choice(
            piece: Piece(
              id: type.name,
              type: type,
              owner: PlayerId.player1,
              position: const Position(3, 1),
            ),
            to: const Position(3, 0),
            forward: -1,
          ),
          PromotionChoice.required,
        );
      }
      expect(
        rules.choice(
          piece: const Piece(
            id: 'n',
            type: PieceType.knight,
            owner: PlayerId.player1,
            position: Position(3, 3),
          ),
          to: const Position(2, 1),
          forward: -1,
        ),
        PromotionChoice.required,
      );
    });

    test('成駒を取ると生駒として持ち駒に戻る', () {
      const attacker = Piece(
        id: 'r',
        type: PieceType.rook,
        owner: PlayerId.player1,
        position: Position(0, 0),
      );
      const promotedPawn = Piece(
        id: 'p',
        type: PieceType.pawn,
        owner: PlayerId.player2,
        position: Position(0, 1),
        promoted: true,
      );
      final result = const GameRules().movePiece(
        piece: attacker,
        to: promotedPawn.position,
        pieces: const [attacker, promotedPawn],
        hands: const {PlayerId.player1: Hand([]), PlayerId.player2: Hand([])},
      );
      expect(result.hands[PlayerId.player1]!.pieces, [PieceType.pawn]);
    });
  });

  test('駒定義に全8種が存在する', () {
    expect(pieceDefinitions.keys.toSet(), PieceType.values.toSet());
  });
}
