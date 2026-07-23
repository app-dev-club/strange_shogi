import '../data/piece_definitions.dart';
import '../models/game_models.dart';

enum PromotionChoice { none, optional, required }

class PromotionRules {
  const PromotionRules();

  PromotionChoice choice({
    required Piece piece,
    required Position to,
    required int forward,
  }) {
    if (piece.promoted || !canPromote(piece.type)) {
      return PromotionChoice.none;
    }
    if (_mustPromote(piece.type, to, forward)) {
      return PromotionChoice.required;
    }
    if (_inPromotionZone(piece.position, forward) ||
        _inPromotionZone(to, forward)) {
      return PromotionChoice.optional;
    }
    return PromotionChoice.none;
  }

  bool _inPromotionZone(Position position, int forward) =>
      forward > 0 ? position.y >= BoardDefinition.height - 3 : position.y <= 2;

  bool _mustPromote(PieceType type, Position to, int forward) {
    final lastRank = forward > 0 ? BoardDefinition.height - 1 : 0;
    final secondLastRank = forward > 0 ? BoardDefinition.height - 2 : 1;
    return switch (type) {
      PieceType.pawn || PieceType.lance => to.y == lastRank,
      PieceType.knight => to.y == lastRank || to.y == secondLastRank,
      _ => false,
    };
  }
}
