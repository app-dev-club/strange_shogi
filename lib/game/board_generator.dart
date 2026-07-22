import 'dart:math';

import '../models/game_models.dart';
import 'board_validator.dart';

class BoardGenerator {
  const BoardGenerator({this.validator = const BoardValidator()});
  final BoardValidator validator;

  BoardDefinition generate(int seed) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final random = Random(seed + attempt * 7919);
      final cells = <Position>{
        for (var y = 0; y < BoardDefinition.height; y++)
          for (var x = 0; x < BoardDefinition.width; x++) Position(x, y),
      };
      final target = 30 + random.nextInt(11);
      final candidates = cells.toList()..shuffle(random);
      for (final candidate in candidates) {
        if (cells.length <= target) break;
        cells.remove(candidate);
        final trial = BoardDefinition(seed: seed, available: Set.of(cells));
        if (!validator.isConnected(trial) ||
            _sideCount(cells, true) < 5 ||
            _sideCount(cells, false) < 5) {
          cells.add(candidate);
        }
      }
      final result = BoardDefinition(seed: seed, available: cells);
      if (validator.isValid(result) && validator.isAsymmetric(result)) {
        return result;
      }
    }
    throw StateError('条件を満たす盤面を生成できませんでした。');
  }

  int _sideCount(Set<Position> cells, bool top) => cells
      .where((p) => top ? p.y <= 1 : p.y >= BoardDefinition.height - 2)
      .length;
}
