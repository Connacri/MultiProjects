import '../entities/planning_assignment.dart';
import '../entities/staff_availability.dart';

/// Applies staff availability constraints after the baseline rotation is built.
///
/// Availability never changes the team rotation itself. It only changes the
/// staff assignment status for affected dates. This separation prevents a
/// single absence from corrupting the global team cycle.
class StaffAvailabilityApplier {
  const StaffAvailabilityApplier();

  List<PlanningAssignment> apply({
    required List<PlanningAssignment> assignments,
    required List<StaffAvailability> availability,
  }) {
    if (availability.isEmpty) return List.unmodifiable(assignments);

    final result = <PlanningAssignment>[];
    for (final assignment in assignments) {
      final constraint = _findConstraint(assignment, availability);
      if (constraint == null ||
          constraint.type == StaffAvailabilityType.available) {
        result.add(assignment);
        continue;
      }

      result.add(
        assignment.copyWith(
          code: _codeFor(constraint.type),
          note: constraint.note ?? assignment.note,
        ),
      );
    }

    return List.unmodifiable(result);
  }

  StaffAvailability? _findConstraint(
    PlanningAssignment assignment,
    List<StaffAvailability> availability,
  ) {
    for (final item in availability) {
      if (item.staffId == assignment.staffId &&
          item.contains(assignment.date)) {
        return item;
      }
    }
    return null;
  }

  String _codeFor(StaffAvailabilityType type) {
    switch (type) {
      case StaffAvailabilityType.leave:
        return 'RE';
      case StaffAvailabilityType.sickLeave:
        return 'CM';
      case StaffAvailabilityType.training:
        return 'FORMATION';
      case StaffAvailabilityType.mission:
        return 'MISSION';
      case StaffAvailabilityType.unavailable:
        return 'INDISPONIBLE';
      case StaffAvailabilityType.available:
        return 'G';
    }
  }
}
