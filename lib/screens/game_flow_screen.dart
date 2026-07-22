import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/piece_definitions.dart';
import '../game/formation_validator.dart';
import '../models/game_models.dart';
import '../providers/game_controller.dart';
import '../widgets/shogi_board.dart';

class GameFlowScreen extends ConsumerWidget {
  const GameFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘンな将棋'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _phaseContent(context, state, controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phaseContent(
    BuildContext context,
    GameState state,
    GameController controller,
  ) {
    return switch (state.phase) {
      GamePhase.home => _Home(onStart: controller.start),
      GamePhase.boardPreview => _BoardPreview(
        state: state,
        controller: controller,
      ),
      GamePhase.turnOrder => _TurnOrderView(
        state: state,
        controller: controller,
      ),
      GamePhase.sideSelection => _SideSelection(
        state: state,
        controller: controller,
      ),
      GamePhase.firstFormation || GamePhase.secondFormation => _FormationView(
        state: state,
        controller: controller,
      ),
      GamePhase.firstDeployment || GamePhase.secondDeployment =>
        _DeploymentView(state: state, controller: controller),
      GamePhase.handoff => _Handoff(state: state, controller: controller),
      GamePhase.battleConfirmation => _BattleConfirmation(
        state: state,
        controller: controller,
      ),
      GamePhase.playing => _BattleView(state: state, controller: controller),
      GamePhase.result => _ResultView(state: state, controller: controller),
    };
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('home'),
    title: '見えない編成、ヘンな盤面。',
    children: [
      const Icon(Icons.grid_view_rounded, size: 92),
      const Text(
        'ランダムに欠けた7×7盤で、8ポイント以内の駒を秘密に編成。\n1台の端末を交互に使う、2人用ローカル対戦です。',
        textAlign: TextAlign.center,
      ),
      FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow),
        label: const Text('新しい対局'),
      ),
    ],
  );
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('board'),
    title: '1. 盤面を確認',
    children: [
      Text(
        'シード: ${state.board.seed}  /  使用可能: ${state.board.available.length}マス',
      ),
      ShogiBoard(board: state.board, showSideZones: true),
      const Text('青の候補は上側2行（陣営A）、赤の候補は下側2行（陣営B）です。'),
      Wrap(
        spacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: controller.regenerateBoard,
            icon: const Icon(Icons.refresh),
            label: const Text('盤面を再生成'),
          ),
          FilledButton(
            onPressed: controller.confirmBoard,
            child: const Text('この盤面に決定'),
          ),
        ],
      ),
    ],
  );
}

class _TurnOrderView extends StatelessWidget {
  const _TurnOrderView({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('turn'),
    title: '2. 先手・後手を決定',
    children: [
      const Icon(Icons.casino_outlined, size: 64),
      Text(
        '${_playerName(state.firstPlayer)} が先手',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text('${_playerName(state.secondPlayer)} が後手'),
      FilledButton(
        onPressed: controller.continueToSideSelection,
        child: const Text('次へ'),
      ),
    ],
  );
}

class _SideSelection extends StatelessWidget {
  const _SideSelection({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('side'),
    title: '3. 後手が陣営を選択',
    children: [
      Text('${_playerName(state.secondPlayer)}（後手）が選んでください。'),
      ShogiBoard(board: state.board, showSideZones: true),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => controller.selectSecondSide(ArmySide.a),
              child: const Text('陣営A（上・前方▼）'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => controller.selectSecondSide(ArmySide.b),
              child: const Text('陣営B（下・前方▲）'),
            ),
          ),
        ],
      ),
    ],
  );
}

class _FormationView extends StatelessWidget {
  const _FormationView({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final player = controller.setupPlayer;
    final formation = state.formations[player] ?? Formation.initial();
    final points = const FormationValidator().points(formation);
    return _Panel(
      key: ValueKey('formation-${player.name}'),
      title: '${_turnName(state, player)}の秘密編成',
      children: [
        Text('${_playerName(player)} / 陣営${_sideName(state.sides[player]!)}'),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '使用 $points / 8',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '残り ${8 - points} pt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        ...PieceType.values.map((type) {
          final definition = pieceDefinitions[type]!;
          final isKing = type == PieceType.king;
          return ListTile(
            leading: CircleAvatar(child: Text(definition.label)),
            title: Text('${_pieceName(type)}  ${definition.cost}pt'),
            subtitle: isKing ? const Text('必須・自動で1枚') : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: isKing
                      ? null
                      : () => controller.changeFormation(type, -1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${formation.count(type)}',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: isKing
                      ? null
                      : () => controller.changeFormation(type, 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          );
        }),
        if (state.message != null) _ErrorText(state.message!),
        FilledButton(
          onPressed: controller.confirmFormation,
          child: const Text('編成を決定して配置へ'),
        ),
      ],
    );
  }
}

class _DeploymentView extends StatefulWidget {
  const _DeploymentView({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  State<_DeploymentView> createState() => _DeploymentViewState();
}

class _DeploymentViewState extends State<_DeploymentView> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final player = widget.controller.setupPlayer;
    final deployment = widget.state.deployments[player]!;
    final side = widget.state.sides[player]!;
    return _Panel(
      key: ValueKey('deployment-${player.name}'),
      title: '${_turnName(widget.state, player)}の初期配置',
      children: [
        const Text('下の持ち駒を選んで自陣のマスへ置きます。盤上の駒をタップすると持ち駒へ戻せます。'),
        ShogiBoard(
          board: widget.state.board,
          deploymentPieces: deployment.boardPieces,
          deploymentSide: side,
          onTap: (position) {
            if (deployment.boardPieces.containsKey(position)) {
              widget.controller.returnToDeploymentHand(position);
              setState(() => selectedIndex = null);
            } else if (selectedIndex != null) {
              widget.controller.deployFromHand(selectedIndex!, position);
              setState(() => selectedIndex = null);
            }
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('初期持ち駒', style: Theme.of(context).textTheme.titleMedium),
        ),
        _HandChips(
          hand: deployment.hand,
          selectedIndex: selectedIndex,
          onSelected: (index) => setState(
            () => selectedIndex = selectedIndex == index ? null : index,
          ),
        ),
        if (widget.state.message != null) _ErrorText(widget.state.message!),
        FilledButton(
          onPressed: widget.controller.confirmDeployment,
          child: const Text('配置と持ち駒を確定'),
        ),
      ],
    );
  }
}

class _Handoff extends StatelessWidget {
  const _Handoff({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('handoff'),
    title: '端末を渡してください',
    children: [
      const Icon(Icons.phonelink_lock, size: 80),
      Text('${_playerName(state.firstPlayer)}の編成を隠しました。'),
      Text(
        '${_playerName(state.secondPlayer)}だけが画面を見てから進んでください。',
        textAlign: TextAlign.center,
      ),
      FilledButton(
        onPressed: controller.acceptHandoff,
        child: const Text('後手が受け取りました'),
      ),
    ],
  );
}

class _BattleConfirmation extends StatelessWidget {
  const _BattleConfirmation({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('confirmation'),
    title: '対局開始確認',
    children: [
      const Icon(Icons.visibility, size: 72),
      const Text(
        'ここから両者の盤上の駒を公開します。端末を2人で見られる位置へ置いてください。',
        textAlign: TextAlign.center,
      ),
      Text(
        '先手: ${_playerName(state.firstPlayer)} / 後手: ${_playerName(state.secondPlayer)}',
      ),
      FilledButton.icon(
        onPressed: controller.startBattle,
        icon: const Icon(Icons.sports_esports),
        label: const Text('駒を公開して対局開始'),
      ),
    ],
  );
}

class _BattleView extends StatelessWidget {
  const _BattleView({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final current = state.currentTurn;
    return _Panel(
      key: const ValueKey('battle'),
      title: '${_turnName(state, current)}の手番 — ${_playerName(current)}',
      children: [
        Text(
          '陣営A: ${_ownerOfSide(state, ArmySide.a)}（前方▼）  /  陣営B: ${_ownerOfSide(state, ArmySide.b)}（前方▲）',
        ),
        _PlayerHand(
          label: '${_playerName(state.secondPlayer)}（後手）の持ち駒',
          hand: state.hands[state.secondPlayer]!,
          enabled: current == state.secondPlayer,
          selectedIndex: current == state.secondPlayer
              ? state.selectedHandIndex
              : null,
          onSelected: controller.selectHandPiece,
        ),
        ShogiBoard(
          board: state.board,
          pieces: state.boardPieces,
          sides: state.sides,
          highlighted: controller.legalTargets,
          selected: state.selectedBoardPosition,
          lastMove: state.lastMove,
          onTap: controller.selectBoardCell,
        ),
        _PlayerHand(
          label: '${_playerName(state.firstPlayer)}（先手）の持ち駒',
          hand: state.hands[state.firstPlayer]!,
          enabled: current == state.firstPlayer,
          selectedIndex: current == state.firstPlayer
              ? state.selectedHandIndex
              : null,
          onSelected: controller.selectHandPiece,
        ),
        if (state.lastMove != null)
          Text(
            '直前: ${state.lastMove!.type == MoveType.drop ? '持ち駒' : state.lastMove!.from} → ${state.lastMove!.to}（${pieceLabel(state.lastMove!.pieceType)}）',
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: controller.clearSelection,
              child: const Text('選択解除'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('投了しますか？'),
                  content: const Text('相手の勝利になります。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('戻る'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        controller.resign();
                      },
                      child: const Text('投了する'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('投了'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.controller});
  final GameState state;
  final GameController controller;

  @override
  Widget build(BuildContext context) => _Panel(
    key: const ValueKey('result'),
    title: '対局終了',
    children: [
      const Icon(Icons.emoji_events, size: 88, color: Color(0xffc78912)),
      Text(
        '${_playerName(state.winner!)} の勝利！',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      Text(
        '${_turnName(state, state.winner!)}・陣営${_sideName(state.sides[state.winner!]!)}',
      ),
      FilledButton.icon(
        onPressed: controller.newGame,
        icon: const Icon(Icons.refresh),
        label: const Text('新しい対局を開始'),
      ),
    ],
  );
}

class _PlayerHand extends StatelessWidget {
  const _PlayerHand({
    required this.label,
    required this.hand,
    required this.enabled,
    required this.selectedIndex,
    required this.onSelected,
  });
  final String label;
  final Hand hand;
  final bool enabled;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (hand.pieces.isEmpty)
            const Text('なし')
          else
            _HandChips(
              hand: hand,
              selectedIndex: selectedIndex,
              onSelected: enabled ? onSelected : null,
            ),
        ],
      ),
    ),
  );
}

class _HandChips extends StatelessWidget {
  const _HandChips({required this.hand, this.selectedIndex, this.onSelected});
  final Hand hand;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 4,
    children: [
      for (var i = 0; i < hand.pieces.length; i++)
        ChoiceChip(
          label: Text(pieceLabel(hand.pieces[i])),
          selected: selectedIndex == i,
          onSelected: onSelected == null ? null : (_) => onSelected!(i),
        ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    key: key,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 14),
      ...children.map(
        (child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: child,
        ),
      ),
    ],
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Text(
    message,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
    textAlign: TextAlign.center,
  );
}

String _playerName(PlayerId player) =>
    player == PlayerId.player1 ? 'プレイヤー1' : 'プレイヤー2';
String _sideName(ArmySide side) => side == ArmySide.a ? 'A（上）' : 'B（下）';
String _turnName(GameState state, PlayerId player) =>
    player == state.firstPlayer ? '先手' : '後手';
String _ownerOfSide(GameState state, ArmySide side) => _playerName(
  state.sides.entries.firstWhere((entry) => entry.value == side).key,
);

String _pieceName(PieceType type) => switch (type) {
  PieceType.king => '王将',
  PieceType.rook => '飛車',
  PieceType.bishop => '角',
  PieceType.gold => '金',
  PieceType.silver => '銀',
  PieceType.knight => '桂馬',
  PieceType.lance => '香車',
  PieceType.pawn => '歩',
};
