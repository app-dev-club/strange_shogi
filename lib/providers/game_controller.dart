import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/board_generator.dart';
import '../game/drop_generator.dart';
import '../game/formation_validator.dart';
import '../game/game_rules.dart';
import '../game/move_generator.dart';
import '../models/game_models.dart';

final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

class GameController extends Notifier<GameState> {
  static const _boardGenerator = BoardGenerator();
  static const _formationValidator = FormationValidator();
  static const _moveGenerator = MoveGenerator();
  static const _dropGenerator = DropGenerator();
  static const _rules = GameRules();

  @override
  GameState build() => _newState();

  GameState _newState() {
    final seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final player1First = Random(seed).nextBool();
    final first = player1First ? PlayerId.player1 : PlayerId.player2;
    final second = player1First ? PlayerId.player2 : PlayerId.player1;
    return GameState(
      phase: GamePhase.home,
      board: _boardGenerator.generate(seed),
      firstPlayer: first,
      secondPlayer: second,
      sides: const {},
      formations: const {},
      deployments: const {},
      boardPieces: const [],
      hands: const {PlayerId.player1: Hand([]), PlayerId.player2: Hand([])},
      currentTurn: first,
    );
  }

  void start() => state = state.copyWith(phase: GamePhase.boardPreview);

  void regenerateBoard() {
    if (state.phase != GamePhase.boardPreview) return;
    final seed =
        (state.board.seed + 1 + Random().nextInt(1000000)) & 0x7fffffff;
    state = state.copyWith(board: _boardGenerator.generate(seed));
  }

  void confirmBoard() => state = state.copyWith(phase: GamePhase.turnOrder);

  void continueToSideSelection() =>
      state = state.copyWith(phase: GamePhase.sideSelection);

  void selectSecondSide(ArmySide side) {
    if (state.phase != GamePhase.sideSelection) return;
    final other = side == ArmySide.a ? ArmySide.b : ArmySide.a;
    state = state.copyWith(
      sides: {state.secondPlayer: side, state.firstPlayer: other},
      phase: GamePhase.firstFormation,
      formations: {state.firstPlayer: Formation.initial()},
    );
  }

  PlayerId get setupPlayer => switch (state.phase) {
    GamePhase.firstFormation || GamePhase.firstDeployment => state.firstPlayer,
    GamePhase.secondFormation ||
    GamePhase.secondDeployment => state.secondPlayer,
    _ => state.currentTurn,
  };

  void changeFormation(PieceType type, int delta) {
    if (type == PieceType.king ||
        (state.phase != GamePhase.firstFormation &&
            state.phase != GamePhase.secondFormation)) {
      return;
    }
    final player = setupPlayer;
    final current = state.formations[player] ?? Formation.initial();
    final nextCount = current.count(type) + delta;
    if (nextCount < 0) return;
    final pieces = Map<PieceType, int>.of(current.pieces);
    if (nextCount == 0) {
      pieces.remove(type);
    } else {
      pieces[type] = nextCount;
    }
    final next = Formation(pieces);
    if (_formationValidator.points(next) > FormationValidator.maxPoints) return;
    state = state.copyWith(formations: {...state.formations, player: next});
  }

  void confirmFormation() {
    final player = setupPlayer;
    final formation = state.formations[player];
    if (formation == null || !_formationValidator.isValid(formation)) {
      state = state.copyWith(message: '編成を確認してください。');
      return;
    }
    state = state.copyWith(
      deployments: {
        ...state.deployments,
        player: DeploymentState.fromFormation(formation),
      },
      phase: state.phase == GamePhase.firstFormation
          ? GamePhase.firstDeployment
          : GamePhase.secondDeployment,
      clearMessage: true,
    );
  }

  void deployFromHand(int handIndex, Position position) {
    final player = setupPlayer;
    final deployment = state.deployments[player];
    final side = state.sides[player];
    if (deployment == null ||
        side == null ||
        !ArmySideDefinition.fromBoard(
          state.board,
          side,
        ).deploymentArea.contains(position) ||
        deployment.boardPieces.containsKey(position) ||
        handIndex < 0 ||
        handIndex >= deployment.hand.pieces.length) {
      return;
    }
    final hand = [...deployment.hand.pieces];
    final type = hand.removeAt(handIndex);
    final next = DeploymentState(
      boardPieces: {...deployment.boardPieces, position: type},
      hand: Hand(hand),
    );
    state = state.copyWith(
      deployments: {...state.deployments, player: next},
      clearMessage: true,
    );
  }

  void returnToDeploymentHand(Position position) {
    final player = setupPlayer;
    final deployment = state.deployments[player];
    final type = deployment?.boardPieces[position];
    if (deployment == null || type == null) return;
    final boardPieces = Map<Position, PieceType>.of(deployment.boardPieces)
      ..remove(position);
    state = state.copyWith(
      deployments: {
        ...state.deployments,
        player: DeploymentState(
          boardPieces: boardPieces,
          hand: Hand([...deployment.hand.pieces, type]),
        ),
      },
    );
  }

  void confirmDeployment() {
    final player = setupPlayer;
    final formation = state.formations[player]!;
    final deployment = state.deployments[player]!;
    final side = ArmySideDefinition.fromBoard(
      state.board,
      state.sides[player]!,
    );
    if (!_formationValidator.isDeploymentValid(formation, deployment, side)) {
      state = state.copyWith(message: '王将を自陣へ配置し、駒の重複や不足がないか確認してください。');
      return;
    }
    if (state.phase == GamePhase.firstDeployment) {
      state = state.copyWith(phase: GamePhase.handoff, clearMessage: true);
    } else {
      state = state.copyWith(
        phase: GamePhase.battleConfirmation,
        clearMessage: true,
      );
    }
  }

  void acceptHandoff() => state = state.copyWith(
    phase: GamePhase.secondFormation,
    formations: {...state.formations, state.secondPlayer: Formation.initial()},
  );

  void startBattle() {
    final pieces = <Piece>[];
    final hands = <PlayerId, Hand>{};
    for (final player in PlayerId.values) {
      final deployment = state.deployments[player]!;
      var index = 0;
      for (final entry in deployment.boardPieces.entries) {
        pieces.add(
          Piece(
            id: '${player.name}-${index++}',
            type: entry.value,
            owner: player,
            position: entry.key,
          ),
        );
      }
      hands[player] = Hand([...deployment.hand.pieces]);
    }
    state = state.copyWith(
      phase: GamePhase.playing,
      boardPieces: pieces,
      hands: hands,
      currentTurn: state.firstPlayer,
      clearBoardSelection: true,
      clearHandSelection: true,
    );
  }

  int forwardFor(PlayerId player) =>
      ArmySideDefinition.fromBoard(state.board, state.sides[player]!).forward;

  Set<Position> get legalTargets {
    if (state.phase != GamePhase.playing) return const {};
    final selectedPosition = state.selectedBoardPosition;
    if (selectedPosition != null) {
      final piece = _pieceAt(selectedPosition);
      if (piece == null) return const {};
      return _moveGenerator.legalDestinations(
        board: state.board,
        piece: piece,
        pieces: state.boardPieces,
        forward: forwardFor(piece.owner),
      );
    }
    final handIndex = state.selectedHandIndex;
    final hand = state.hands[state.currentTurn]!.pieces;
    if (handIndex != null && handIndex < hand.length) {
      return _dropGenerator.legalDrops(
        board: state.board,
        type: hand[handIndex],
        owner: state.currentTurn,
        pieces: state.boardPieces,
        forward: forwardFor(state.currentTurn),
      );
    }
    return const {};
  }

  void selectBoardCell(Position position) {
    if (state.phase != GamePhase.playing || state.winner != null) return;
    final legal = legalTargets;
    if (state.selectedHandIndex != null && legal.contains(position)) {
      final result = _rules.dropPiece(
        player: state.currentTurn,
        handIndex: state.selectedHandIndex!,
        to: position,
        pieces: state.boardPieces,
        hands: state.hands,
      );
      _finishTurn(result);
      return;
    }
    if (state.selectedBoardPosition != null && legal.contains(position)) {
      final piece = _pieceAt(state.selectedBoardPosition!)!;
      _finishTurn(
        _rules.movePiece(
          piece: piece,
          to: position,
          pieces: state.boardPieces,
          hands: state.hands,
        ),
      );
      return;
    }
    final piece = _pieceAt(position);
    if (piece?.owner == state.currentTurn) {
      state = state.copyWith(
        selectedBoardPosition: position,
        clearHandSelection: true,
      );
    } else {
      clearSelection();
    }
  }

  void selectHandPiece(int index) {
    if (state.phase != GamePhase.playing || state.winner != null) return;
    state = state.copyWith(selectedHandIndex: index, clearBoardSelection: true);
  }

  void clearSelection() => state = state.copyWith(
    clearBoardSelection: true,
    clearHandSelection: true,
  );

  void _finishTurn(MoveResult result) {
    final next = state.currentTurn == state.firstPlayer
        ? state.secondPlayer
        : state.firstPlayer;
    state = state.copyWith(
      boardPieces: result.pieces,
      hands: result.hands,
      lastMove: result.move,
      winner: result.winner,
      phase: result.winner == null ? GamePhase.playing : GamePhase.result,
      currentTurn: result.winner == null ? next : state.currentTurn,
      clearBoardSelection: true,
      clearHandSelection: true,
    );
  }

  Piece? _pieceAt(Position position) {
    for (final piece in state.boardPieces) {
      if (piece.position == position) return piece;
    }
    return null;
  }

  void resign() {
    if (state.phase != GamePhase.playing) return;
    final winner = state.currentTurn == state.firstPlayer
        ? state.secondPlayer
        : state.firstPlayer;
    state = state.copyWith(phase: GamePhase.result, winner: winner);
  }

  void newGame() => state = _newState();
}
