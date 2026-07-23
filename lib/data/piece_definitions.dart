import '../models/game_models.dart';

class MovementPattern {
  const MovementPattern(this.dx, this.dy, {this.sliding = false});
  final int dx;
  final int dy;
  final bool sliding;
}

class PieceDefinition {
  const PieceDefinition({
    required this.type,
    required this.label,
    required this.cost,
    required this.patterns,
  });

  final PieceType type;
  final String label;
  final int cost;
  final List<MovementPattern> patterns;
}

const pieceDefinitions = <PieceType, PieceDefinition>{
  PieceType.king: PieceDefinition(
    type: PieceType.king,
    label: '王',
    cost: 0,
    patterns: [
      MovementPattern(-1, -1),
      MovementPattern(0, -1),
      MovementPattern(1, -1),
      MovementPattern(-1, 0),
      MovementPattern(1, 0),
      MovementPattern(-1, 1),
      MovementPattern(0, 1),
      MovementPattern(1, 1),
    ],
  ),
  PieceType.rook: PieceDefinition(
    type: PieceType.rook,
    label: '飛',
    cost: 5,
    patterns: [
      MovementPattern(0, -1, sliding: true),
      MovementPattern(0, 1, sliding: true),
      MovementPattern(-1, 0, sliding: true),
      MovementPattern(1, 0, sliding: true),
    ],
  ),
  PieceType.bishop: PieceDefinition(
    type: PieceType.bishop,
    label: '角',
    cost: 4,
    patterns: [
      MovementPattern(-1, -1, sliding: true),
      MovementPattern(1, -1, sliding: true),
      MovementPattern(-1, 1, sliding: true),
      MovementPattern(1, 1, sliding: true),
    ],
  ),
  PieceType.gold: PieceDefinition(
    type: PieceType.gold,
    label: '金',
    cost: 3,
    patterns: [
      MovementPattern(0, 1),
      MovementPattern(-1, 1),
      MovementPattern(1, 1),
      MovementPattern(-1, 0),
      MovementPattern(1, 0),
      MovementPattern(0, -1),
    ],
  ),
  PieceType.silver: PieceDefinition(
    type: PieceType.silver,
    label: '銀',
    cost: 2,
    patterns: [
      MovementPattern(0, 1),
      MovementPattern(-1, 1),
      MovementPattern(1, 1),
      MovementPattern(-1, -1),
      MovementPattern(1, -1),
    ],
  ),
  PieceType.knight: PieceDefinition(
    type: PieceType.knight,
    label: '桂',
    cost: 2,
    patterns: [MovementPattern(-1, 2), MovementPattern(1, 2)],
  ),
  PieceType.lance: PieceDefinition(
    type: PieceType.lance,
    label: '香',
    cost: 2,
    patterns: [MovementPattern(0, 1, sliding: true)],
  ),
  PieceType.pawn: PieceDefinition(
    type: PieceType.pawn,
    label: '歩',
    cost: 1,
    patterns: [MovementPattern(0, 1)],
  ),
};

String pieceLabel(PieceType type) => pieceDefinitions[type]!.label;

bool canPromote(PieceType type) =>
    type != PieceType.king && type != PieceType.gold;

String battlePieceLabel(Piece piece) {
  if (!piece.promoted) return pieceLabel(piece.type);
  return switch (piece.type) {
    PieceType.rook => '龍',
    PieceType.bishop => '馬',
    PieceType.silver => '全',
    PieceType.knight => '圭',
    PieceType.lance => '杏',
    PieceType.pawn => 'と',
    PieceType.king || PieceType.gold => pieceLabel(piece.type),
  };
}

List<MovementPattern> movementPatterns(Piece piece) {
  if (!piece.promoted) return pieceDefinitions[piece.type]!.patterns;
  return switch (piece.type) {
    PieceType.rook => [
      ...pieceDefinitions[PieceType.rook]!.patterns,
      const MovementPattern(-1, -1),
      const MovementPattern(1, -1),
      const MovementPattern(-1, 1),
      const MovementPattern(1, 1),
    ],
    PieceType.bishop => [
      ...pieceDefinitions[PieceType.bishop]!.patterns,
      const MovementPattern(0, -1),
      const MovementPattern(0, 1),
      const MovementPattern(-1, 0),
      const MovementPattern(1, 0),
    ],
    PieceType.silver ||
    PieceType.knight ||
    PieceType.lance ||
    PieceType.pawn => pieceDefinitions[PieceType.gold]!.patterns,
    PieceType.king || PieceType.gold => pieceDefinitions[piece.type]!.patterns,
  };
}
