import 'rotation_phase.dart';

class RotationRule {
  final List<String> teams;
  final List<RotationPhase> phases;

  const RotationRule({
    required this.teams,
    required this.phases,
  });

  int get cycleLength => phases.length;
}
