enum GamePhase {
  home,
  boardPreview,
  turnOrder,
  sideSelection,
  firstFormation,
  firstDeployment,
  handoff,
  secondFormation,
  secondDeployment,
  battleConfirmation,
  playing,
  result,
}

enum PlayerId { player1, player2 }

enum TurnOrder { first, second }

enum ArmySide { a, b }

enum MoveType { normalMove, capture, drop }

enum PieceType { king, rook, bishop, gold, silver, knight, lance, pawn }

class Position {
  const Position(this.x, this.y);

  final int x;
  final int y;

  Position translate(int dx, int dy) => Position(x + dx, y + dy);

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

class BoardDefinition {
  const BoardDefinition({required this.seed, required this.available});

  static const int width = 7;
  static const int height = 7;
  final int seed;
  final Set<Position> available;

  bool contains(Position position) => available.contains(position);
}

class ArmySideDefinition {
  const ArmySideDefinition({
    required this.id,
    required this.deploymentArea,
    required this.forward,
  });

  final ArmySide id;
  final Set<Position> deploymentArea;
  final int forward;

  static ArmySideDefinition fromBoard(BoardDefinition board, ArmySide side) {
    final isTop = side == ArmySide.a;
    return ArmySideDefinition(
      id: side,
      deploymentArea: board.available
          .where((p) => isTop ? p.y <= 1 : p.y >= 5)
          .toSet(),
      forward: isTop ? 1 : -1,
    );
  }
}

class Player {
  const Player({
    required this.id,
    required this.turnOrder,
    required this.armySide,
  });

  final PlayerId id;
  final TurnOrder turnOrder;
  final ArmySide armySide;
}

class Piece {
  const Piece({
    required this.id,
    required this.type,
    required this.owner,
    required this.position,
  });

  final String id;
  final PieceType type;
  final PlayerId owner;
  final Position position;

  Piece copyWith({PlayerId? owner, Position? position}) => Piece(
    id: id,
    type: type,
    owner: owner ?? this.owner,
    position: position ?? this.position,
  );
}

class Formation {
  const Formation(this.pieces);

  factory Formation.initial() => const Formation({PieceType.king: 1});
  final Map<PieceType, int> pieces;

  int count(PieceType type) => pieces[type] ?? 0;
}

class Hand {
  const Hand(this.pieces);
  final List<PieceType> pieces;
}

class DeploymentState {
  const DeploymentState({required this.boardPieces, required this.hand});

  factory DeploymentState.fromFormation(Formation formation) {
    final pieces = <PieceType>[];
    for (final entry in formation.pieces.entries) {
      for (var i = 0; i < entry.value; i++) {
        pieces.add(entry.key);
      }
    }
    return DeploymentState(boardPieces: const {}, hand: Hand(pieces));
  }

  final Map<Position, PieceType> boardPieces;
  final Hand hand;
}

class Move {
  const Move({
    required this.type,
    required this.player,
    required this.pieceType,
    this.from,
    required this.to,
  });

  final MoveType type;
  final PlayerId player;
  final PieceType pieceType;
  final Position? from;
  final Position to;
}

class GameState {
  const GameState({
    required this.phase,
    required this.board,
    required this.firstPlayer,
    required this.secondPlayer,
    required this.sides,
    required this.formations,
    required this.deployments,
    required this.boardPieces,
    required this.hands,
    required this.currentTurn,
    this.selectedBoardPosition,
    this.selectedHandIndex,
    this.lastMove,
    this.winner,
    this.message,
  });

  final GamePhase phase;
  final BoardDefinition board;
  final PlayerId firstPlayer;
  final PlayerId secondPlayer;
  final Map<PlayerId, ArmySide> sides;
  final Map<PlayerId, Formation> formations;
  final Map<PlayerId, DeploymentState> deployments;
  final List<Piece> boardPieces;
  final Map<PlayerId, Hand> hands;
  final PlayerId currentTurn;
  final Position? selectedBoardPosition;
  final int? selectedHandIndex;
  final Move? lastMove;
  final PlayerId? winner;
  final String? message;

  GameState copyWith({
    GamePhase? phase,
    BoardDefinition? board,
    PlayerId? firstPlayer,
    PlayerId? secondPlayer,
    Map<PlayerId, ArmySide>? sides,
    Map<PlayerId, Formation>? formations,
    Map<PlayerId, DeploymentState>? deployments,
    List<Piece>? boardPieces,
    Map<PlayerId, Hand>? hands,
    PlayerId? currentTurn,
    Position? selectedBoardPosition,
    bool clearBoardSelection = false,
    int? selectedHandIndex,
    bool clearHandSelection = false,
    Move? lastMove,
    PlayerId? winner,
    String? message,
    bool clearMessage = false,
  }) => GameState(
    phase: phase ?? this.phase,
    board: board ?? this.board,
    firstPlayer: firstPlayer ?? this.firstPlayer,
    secondPlayer: secondPlayer ?? this.secondPlayer,
    sides: sides ?? this.sides,
    formations: formations ?? this.formations,
    deployments: deployments ?? this.deployments,
    boardPieces: boardPieces ?? this.boardPieces,
    hands: hands ?? this.hands,
    currentTurn: currentTurn ?? this.currentTurn,
    selectedBoardPosition: clearBoardSelection
        ? null
        : selectedBoardPosition ?? this.selectedBoardPosition,
    selectedHandIndex: clearHandSelection
        ? null
        : selectedHandIndex ?? this.selectedHandIndex,
    lastMove: lastMove ?? this.lastMove,
    winner: winner ?? this.winner,
    message: clearMessage ? null : message ?? this.message,
  );
}
