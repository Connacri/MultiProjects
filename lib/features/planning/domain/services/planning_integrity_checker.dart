import '../entities/planning_snapshot.dart';

/// Detects integrity issues that must block publication.
class PlanningIntegrityChecker {
  const PlanningIntegrityChecker();

  List<String> check(PlanningSnapshot snapshot) {
    final errors = <String>[];
    final seen = <String>{};

    for (final assignment in snapshot.assignments) {
      final date = DateTime(
        assignment.date.year,
        assignment.date.month,
        assignment.date.day,
      );
      final key = '${assignment.staffId}|${date.millisecondsSinceEpoch}';

      if (!seen.add(key)) {
        errors.add('Duplicate staff/date assignment: $key');
      }

      if (assignment.date.year != snapshot.year ||
          assignment.date.month != snapshot.month) {
        errors.add(
          'Assignment outside planning period: staff=${assignment.staffId}, date=${assignment.date.toIso8601String()}',
        );
      }
    }

    return List.unmodifiable(errors);
  }
}
