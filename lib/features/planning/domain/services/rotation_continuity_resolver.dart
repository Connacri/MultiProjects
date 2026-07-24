import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../enums/rotation_policy.dart';
import '../enums/shift_type.dart';
import '../repositories/planning_repository.dart';

/// Resolves the state from which a new planning period must continue.
///
/// Published snapshots are historical facts. This service only reads them and
/// reconstructs continuity by team identity. The current `teamOrder` is never
/// used to remap a previously published team's phase.
class RotationContinuityResolver {
  final PlanningRepository planningRepository;

  const RotationContinuityResolver(this.planningRepository);

  Future<RotationState?> resolve({
    required DateTime targetDate,
    required RotationConfiguration configuration,
    int? branchId,
  }) async {
    if (configuration.policy == RotationPolicy.fixedReference) {
      return null;
    }

    final previous = await planningRepository.findPreviousPublished(
      year: targetDate.year,
      month: targetDate.month,
      branchId: branchId,
    );

    if (previous == null || previous.assignments.isEmpty) return null;

    final lastDay = DateTime(
      previous.year,
      previous.month,
      previous.daysInMonth,
    );

    final shifts = <String, ShiftType>{};
    for (final assignment in previous.assignments) {
      if (assignment.date.year == lastDay.year &&
          assignment.date.month == lastDay.month &&
          assignment.date.day == lastDay.day &&
          assignment.team != null) {
        shifts[assignment.team!] = assignment.shift;
      }
    }

    if (shifts.isEmpty) return null;

    // A configuration reorder must not discard continuity for teams that were
    // already published. Keep only teams that still exist in the new config;
    // newly introduced teams fall back to the reference-date calculation.
    final currentTeams = configuration.teamOrder.toSet();
    final retained = <String, ShiftType>{
      for (final entry in shifts.entries)
        if (currentTeams.contains(entry.key)) entry.key: entry.value,
    };

    if (retained.isEmpty) return null;

    return RotationState(
      date: lastDay,
      teamShifts: Map.unmodifiable(retained),
    );
  }
}
