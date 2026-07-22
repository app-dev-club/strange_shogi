import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strange_shogi/models/game_models.dart';
import 'package:strange_shogi/providers/game_controller.dart';

void main() {
  test('後手の陣営選択により先手へ反対陣営が割り当てられる', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);

    controller.start();
    controller.confirmBoard();
    controller.continueToSideSelection();
    controller.selectSecondSide(ArmySide.a);

    final state = container.read(gameControllerProvider);
    expect(state.sides[state.secondPlayer], ArmySide.a);
    expect(state.sides[state.firstPlayer], ArmySide.b);
    expect(state.phase, GamePhase.firstFormation);
  });

  test('新しい対局でホームへ戻り対局状態が初期化される', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.start();
    controller.newGame();
    final state = container.read(gameControllerProvider);
    expect(state.phase, GamePhase.home);
    expect(state.boardPieces, isEmpty);
    expect(state.winner, isNull);
  });
}
