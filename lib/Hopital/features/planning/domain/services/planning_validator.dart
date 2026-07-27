import '../entities/planning_assignment.dart';
import '../entities/planning_snapshot.dart';

class PlanningValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const PlanningValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });

  bool get isValid => errors.isEmpty;
}

/// Pure validation of a planning snapshot before publication.
class PlanningValidator {
  const PlanningValidator();

  PlanningValidationResult validate(PlanningSnapshot snapshot) {
    final errors = <String>[];
    final warnings = <String>[];
    final keys = <String>{};

    for (final assignment in snapshot.assignments) {
      final key = '${assignment.staffId}|${_dateKey(assignment.date)}';
      if (!keys.add(key)) {
        errors.add('Duplicate assignment: $key');
      }
    }

    final expectedYear = snapshot.year;
    final expectedMonth = snapshot.month;
    for (final assignment in snapshot.assignments) {
      if (assignment.date.year != expectedYear ||
          assignment.date.month != expectedMonth) {
        errors.add(
          'Assignment outside snapshot period: ${assignment.staffId} ${_dateKey(assignment.date)}',
        );
      }
    }

    if (snapshot.assignments.isEmpty) {
      warnings.add('Planning contains no staff assignments.');
    }

    return PlanningValidationResult(
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
