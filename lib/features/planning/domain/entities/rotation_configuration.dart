import '../enums/rotation_policy.dart';
import '../enums/shift_type.dart';

/// Immutable configuration used by the planning domain.
///
/// The team order is configurable and never hard-coded in the engine.
/// The default four-team cycle is DAY -> NIGHT -> REST -> REST.
class RotationConfiguration {
  final String id;
  final int version;
  final List<String> teamOrder;
  final List<ShiftType> cycle;
  final RotationPolicy policy;
  final DateTime referenceDate;
  final int referencePhaseIndex;

  const RotationConfiguration({
    required this.id,
    required this.version,
    required this.teamOrder,
    required this.cycle,
    required this.policy,
    required this.referenceDate,
    this.referencePhaseIndex = 0,
  })  : assert(teamOrder.length > 0),
        assert(cycle.length > 0);

  RotationConfiguration copyWith({
    String? id,
    int? version,
    List<String>? teamOrder,
    List<ShiftType>? cycle,
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

  static final defaultFourTeam = RotationConfiguration(
    id: 'four-team-day-night-rest-rest',
    version: 1,
    teamOrder: const ['A', 'B', 'C', 'D'],
    cycle: const [
      ShiftType.day,
      ShiftType.night,
      ShiftType.rest,
      ShiftType.rest
    ],
    policy: RotationPolicy.continueFromPreviousPublished,
    referenceDate: DateTime(2026, 1, 1),
  );
}
