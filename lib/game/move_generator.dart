import '../data/piece_definitions.dart';
import '../models/game_models.dart';

class MoveGenerator {
  const MoveGenerator();

  Set<Position> legalDestinations({
    required BoardDefinition board,
    required Piece piece,
    required List<Piece> pieces,
    required int forward,
  }) {
    final result = <Position>{};
    final occupied = {for (final item in pieces) item.position: item};
    for (final pattern in pieceDefinitions[piece.type]!.patterns) {
      final dx = pattern.dx;
      final dy = pattern.dy * forward;
      var distance = 1;
      while (true) {
        final target = piece.position.translate(dx * distance, dy * distance);
        if (!board.contains(target)) break;
        final blocker = occupied[target];
        if (blocker != null) {
          if (blocker.owner != piece.owner) result.add(target);
          break;
        }
        result.add(target);
        if (!pattern.sliding) break;
        distance++;
      }
    }
    return result;
  }
}
