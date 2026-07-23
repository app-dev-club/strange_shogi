import 'package:flutter/material.dart';

import '../data/piece_definitions.dart';
import '../models/game_models.dart';

class ShogiBoard extends StatelessWidget {
  const ShogiBoard({
    super.key,
    required this.board,
    this.pieces = const [],
    this.deploymentPieces = const {},
    this.deploymentSide,
    this.showSideZones = false,
    this.highlighted = const {},
    this.selected,
    this.lastMove,
    this.sides = const {},
    this.onTap,
  });

  final BoardDefinition board;
  final List<Piece> pieces;
  final Map<Position, PieceType> deploymentPieces;
  final ArmySide? deploymentSide;
  final bool showSideZones;
  final Set<Position> highlighted;
  final Position? selected;
  final Move? lastMove;
  final Map<PlayerId, ArmySide> sides;
  final ValueChanged<Position>? onTap;

  @override
  Widget build(BuildContext context) {
    final byPosition = {for (final piece in pieces) piece.position: piece};
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: BoardDefinition.width,
        ),
        itemCount: BoardDefinition.width * BoardDefinition.height,
        itemBuilder: (context, index) {
          final position = Position(
            index % BoardDefinition.width,
            index ~/ BoardDefinition.width,
          );
          final available = board.contains(position);
          final piece = byPosition[position];
          final deploymentType = deploymentPieces[position];
          final isLast = lastMove?.from == position || lastMove?.to == position;
          Color color;
          if (!available) {
            color = const Color(0xff433d38);
          } else if (selected == position) {
            color = const Color(0xffffd45c);
          } else if (highlighted.contains(position)) {
            color = const Color(0xffa8d6a2);
          } else if (isLast) {
            color = const Color(0xffffc48a);
          } else if (deploymentSide == ArmySide.a && position.y <= 1) {
            color = const Color(0xffdcecff);
          } else if (deploymentSide == ArmySide.b && position.y >= 5) {
            color = const Color(0xffffe0dc);
          } else if (showSideZones && position.y <= 1) {
            color = const Color(0xffdcecff);
          } else if (showSideZones && position.y >= 5) {
            color = const Color(0xffffe0dc);
          } else {
            color = const Color(0xffe9bd78);
          }
          return Semantics(
            button: available,
            label: '列${position.x + 1} 行${position.y + 1}',
            child: InkWell(
              onTap: available && onTap != null ? () => onTap!(position) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: available
                        ? const Color(0xff5f4024)
                        : const Color(0xff433d38),
                    width: isLast ? 2.5 : 0.7,
                  ),
                ),
                child: piece != null
                    ? _BattlePiece(piece: piece, side: sides[piece.owner])
                    : deploymentType != null
                    ? _PieceText(type: deploymentType)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BattlePiece extends StatelessWidget {
  const _BattlePiece({required this.piece, required this.side});
  final Piece piece;
  final ArmySide? side;

  @override
  Widget build(BuildContext context) {
    final isTop = side == ArmySide.a;
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xff315b91) : const Color(0xffa43d36),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isTop ? '▼' : '▲',
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
          Text(
            battlePieceLabel(piece),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceText extends StatelessWidget {
  const _PieceText({required this.type});
  final PieceType type;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      pieceLabel(type),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
}
