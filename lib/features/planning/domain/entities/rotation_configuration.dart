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
    this.policy = 'default',
    this.referenceDate,
    this.referenceTeamIndex = 0,
  });

  final String id;
  final int version;
  final List<String> teamOrder;
  final List<TeamShift> cycle;
  final String policy;
  final DateTime? referenceDate;
  final int referenceTeamIndex;

  RotationConfiguration copyWith({
    String? id,
    int? version,
    List<String>? teamOrder,
    List<TeamShift>? cycle,
    String? policy,
    DateTime? referenceDate,
    int? referenceTeamIndex,
  }) {
    return RotationConfiguration(
      id: id ?? this.id,
      version: version ?? this.version,
      teamOrder: List.unmodifiable(teamOrder ?? this.teamOrder),
      cycle: List.unmodifiable(cycle ?? this.cycle),
      policy: policy ?? this.policy,
      referenceDate: referenceDate ?? this.referenceDate,
      referenceTeamIndex: referenceTeamIndex ?? this.referenceTeamIndex,
    );
  }
}
