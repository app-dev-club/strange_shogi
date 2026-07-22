import '../models/game_models.dart';

class BoardValidator {
  const BoardValidator();

  bool isValid(BoardDefinition board) {
    final count = board.available.length;
    return count >= 30 &&
        count <= 40 &&
        isConnected(board) &&
        _sideCount(board, true) >= 5 &&
        _sideCount(board, false) >= 5 &&
        _hasEnoughOpenSpace(board);
  }

  bool isConnected(BoardDefinition board) {
    if (board.available.isEmpty) return false;
    final visited = <Position>{};
    final queue = <Position>[board.available.first];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) continue;
      for (final next in _orthogonal(current)) {
        if (board.contains(next) && !visited.contains(next)) queue.add(next);
      }
    }
    return visited.length == board.available.length;
  }

  bool isAsymmetric(BoardDefinition board) {
    for (final position in board.available) {
      final mirror = Position(
        BoardDefinition.width - 1 - position.x,
        position.y,
      );
      if (board.contains(mirror) != board.contains(position)) return true;
    }
    return false;
  }

  int _sideCount(BoardDefinition board, bool top) => board.available
      .where((p) => top ? p.y <= 1 : p.y >= BoardDefinition.height - 2)
      .length;

  bool _hasEnoughOpenSpace(BoardDefinition board) {
    final wellConnected = board.available.where((position) {
      return _orthogonal(position).where(board.contains).length >= 2;
    }).length;
    return wellConnected >= (board.available.length * 0.65).ceil();
  }

  Iterable<Position> _orthogonal(Position p) sync* {
    yield p.translate(1, 0);
    yield p.translate(-1, 0);
    yield p.translate(0, 1);
    yield p.translate(0, -1);
  }
}
