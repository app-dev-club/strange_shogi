import '../data/piece_definitions.dart';
import '../models/game_models.dart';

class FormationValidator {
  const FormationValidator();
  static const maxPoints = 8;

  int points(Formation formation) => formation.pieces.entries.fold(
    0,
    (sum, entry) => sum + pieceDefinitions[entry.key]!.cost * entry.value,
  );

  bool isValid(Formation formation) =>
      formation.count(PieceType.king) == 1 &&
      formation.pieces.values.every((count) => count >= 0) &&
      points(formation) <= maxPoints;

  bool isDeploymentValid(
    Formation formation,
    DeploymentState deployment,
    ArmySideDefinition side,
  ) {
    if (!deployment.boardPieces.values.contains(PieceType.king) ||
        deployment.hand.pieces.contains(PieceType.king) ||
        deployment.boardPieces.keys.any(
          (p) => !side.deploymentArea.contains(p),
        )) {
      return false;
    }
    final counts = <PieceType, int>{};
    for (final type in [
      ...deployment.boardPieces.values,
      ...deployment.hand.pieces,
    ]) {
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return PieceType.values.every(
      (type) => (counts[type] ?? 0) == formation.count(type),
    );
  }
}
