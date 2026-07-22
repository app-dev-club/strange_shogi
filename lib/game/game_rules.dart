import '../models/game_models.dart';

class MoveResult {
  const MoveResult({
    required this.pieces,
    required this.hands,
    required this.move,
    this.winner,
  });
  final List<Piece> pieces;
  final Map<PlayerId, Hand> hands;
  final Move move;
  final PlayerId? winner;
}

class GameRules {
  const GameRules();

  MoveResult movePiece({
    required Piece piece,
    required Position to,
    required List<Piece> pieces,
    required Map<PlayerId, Hand> hands,
  }) {
    final captured = pieces.where((p) => p.position == to).firstOrNull;
    final nextPieces =
        pieces.where((p) => p.id != piece.id && p.id != captured?.id).toList()
          ..add(piece.copyWith(position: to));
    final nextHands = _copyHands(hands);
    if (captured != null && captured.type != PieceType.king) {
      nextHands[piece.owner] = Hand([
        ...nextHands[piece.owner]!.pieces,
        captured.type,
      ]);
    }
    return MoveResult(
      pieces: nextPieces,
      hands: nextHands,
      winner: captured?.type == PieceType.king ? piece.owner : null,
      move: Move(
        type: captured == null ? MoveType.normalMove : MoveType.capture,
        player: piece.owner,
        pieceType: piece.type,
        from: piece.position,
        to: to,
      ),
    );
  }

  MoveResult dropPiece({
    required PlayerId player,
    required int handIndex,
    required Position to,
    required List<Piece> pieces,
    required Map<PlayerId, Hand> hands,
  }) {
    final nextHands = _copyHands(hands);
    final playerHand = [...nextHands[player]!.pieces];
    if (handIndex < 0 || handIndex >= playerHand.length) {
      throw RangeError.index(handIndex, playerHand, 'handIndex');
    }
    final type = playerHand.removeAt(handIndex);
    nextHands[player] = Hand(playerHand);
    final nextPieces = [
      ...pieces,
      Piece(
        id: 'drop-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        owner: player,
        position: to,
      ),
    ];
    return MoveResult(
      pieces: nextPieces,
      hands: nextHands,
      move: Move(type: MoveType.drop, player: player, pieceType: type, to: to),
    );
  }

  Map<PlayerId, Hand> _copyHands(Map<PlayerId, Hand> hands) => {
    for (final entry in hands.entries) entry.key: Hand([...entry.value.pieces]),
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
