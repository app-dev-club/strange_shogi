import '../models/game_models.dart';
import 'move_generator.dart';

class DropGenerator {
  const DropGenerator({this.moveGenerator = const MoveGenerator()});
  final MoveGenerator moveGenerator;

  Set<Position> legalDrops({
    required BoardDefinition board,
    required PieceType type,
    required PlayerId owner,
    required List<Piece> pieces,
    required int forward,
  }) {
    final occupied = pieces.map((piece) => piece.position).toSet();
    return board.available.where((target) {
      if (occupied.contains(target)) return false;
      if (type == PieceType.pawn &&
          pieces.any(
            (p) =>
                p.owner == owner &&
                p.type == PieceType.pawn &&
                !p.promoted &&
                p.position.x == target.x,
          )) {
        return false;
      }
      final hypothetical = Piece(
        id: 'drop-check',
        type: type,
        owner: owner,
        position: target,
      );
      return moveGenerator
          .legalDestinations(
            board: board,
            piece: hypothetical,
            pieces: const [],
            forward: forward,
          )
          .isNotEmpty;
    }).toSet();
  }
}
