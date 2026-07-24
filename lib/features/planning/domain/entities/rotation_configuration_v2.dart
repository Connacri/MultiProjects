import '../enums/rotation_policy.dart';

class RotationConfigurationV2 {
  final String id;
  final int version;
  final List<String> teamOrder;
  final List<String> cycle;
  final RotationPolicy policy;
  final DateTime referenceDate;
  final int referencePhaseIndex;

  const RotationConfigurationV2({
    required this.id,
    required this.version,
    required this.teamOrder,
    required this.cycle,
    required this.policy,
    required this.referenceDate,
    this.referencePhaseIndex = 0,
  });
}
