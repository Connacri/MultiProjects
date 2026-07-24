import '../entities/planning_assignment.dart';
import '../entities/planning_override.dart';

/// Applies explicit manual overrides to a generated draft.
///
/// The generated schedule remains the baseline. An override replaces exactly
/// one `staffId + date` assignment and is preserved in the resulting snapshot.
class PlanningOverrideApplier {
  const PlanningOverrideApplier();

  List<PlanningAssignment> apply({
    required List<PlanningAssignment> assignments,
    required List<PlanningOverride> overrides,
  }) {
    if (overrides.isEmpty) return List.unmodifiable(assignments);

    final byKey = <String, PlanningAssignment>{
      for (final assignment in assignments)
        _key(assignment.staffId, assignment.date): assignment,
    };

    for (final override in overrides) {
      final key = _key(override.staffId, override.date);
      final current = byKey[key];
      byKey[key] = PlanningAssignment(
        staffId: override.staffId,
        date: override.date,
        team: override.team ?? current?.team,
        shift: override.shift,
        code: override.code ?? current?.code,
        note: override.note ?? current?.note,
      );
    }

    final result = byKey.values.toList()
      ..sort((a, b) {
        final date = a.date.compareTo(b.date);
        return date != 0 ? date : a.staffId.compareTo(b.staffId);
      });

    return List.unmodifiable(result);
  }

  String _key(int staffId, DateTime date) =>
      '$staffId|${date.year}-${date.month}-${date.day}';
}
