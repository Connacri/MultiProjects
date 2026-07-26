import '../enums/rotation_policy.dart';
import '../enums/team_shift.dart';

/// Immutable configuration for the cyclic team rotation.
class RotationConfiguration {
  const RotationConfiguration({
    required this.id,
    required this.version,
    required this.teamOrder,
    this.cycle = const <TeamShift>[
      TeamShift.day,
      TeamShift.night,
      TeamShift.rest,
      TeamShift.rest,
    ],
    this.policy = RotationPolicy.continueFromPreviousPublished,
    this.referenceDate,
    this.referencePhaseIndex = 0,
  });

  final String id;
  final int version;
  final List<String> teamOrder;
  final List<TeamShift> cycle;
  final RotationPolicy policy;
  final DateTime? referenceDate;
  final int referencePhaseIndex;

  RotationConfiguration copyWith({
    String? id,
    int? version,
    List<String>? teamOrder,
    List<TeamShift>? cycle,
    RotationPolicy? policy,
    DateTime? referenceDate,
    int? referencePhaseIndex,
  }) {
    return RotationConfiguration(
      id: id ?? this.id,
      version: version ?? this.version,
      teamOrder: List.unmodifiable(teamOrder ?? this.teamOrder),
      cycle: List.unmodifiable(cycle ?? this.cycle),
      policy: policy ?? this.policy,
      referenceDate: referenceDate ?? this.referenceDate,
      referencePhaseIndex: referencePhaseIndex ?? this.referencePhaseIndex,
    );
  }
}
