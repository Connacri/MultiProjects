import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../enums/rotation_policy.dart';
import '../enums/shift_type.dart';
import '../repositories/planning_repository.dart';

/// Resolves the state from which a new planning period must continue.
///
/// Existing published snapshots are treated as historical facts. This service
/// only reads them and never recalculates or mutates them.
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

    // The repository contract interprets this as: return the latest published
    // snapshot strictly before targetDate. Implementations must not return the
    // target month itself.
    final previous = await planningRepository.findPreviousPublished(
      year: targetDate.year,
      month: targetDate.month,
      branchId: branchId,
    );

    if (previous == null || previous.assignments.isEmpty) {
      return null;
    }

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

    return RotationState(
      date: lastDay,
      teamShifts: Map.unmodifiable(shifts),
    );
  }
}
