import '../entities/planning_snapshot.dart';

/// Validates domain invariants before a planning snapshot can be published.
///
/// The validator is deterministic and has no persistence dependency. It does
/// not decide whether a revision is the latest one; that invariant belongs to
/// the repository transaction.
class PlanningSnapshotValidator {
  const PlanningSnapshotValidator();

  List<String> validate(PlanningSnapshot snapshot) {
    final errors = <String>[];

    if (snapshot.year < 1) {
      errors.add('year must be greater than zero');
    }
    if (snapshot.month < 1 || snapshot.month > 12) {
      errors.add('month must be between 1 and 12');
    }
    if (snapshot.configurationId.trim().isEmpty) {
      errors.add('configurationId must not be empty');
    }
    if (snapshot.configurationVersion < 1) {
      errors.add('configurationVersion must be greater than zero');
    }
    if (snapshot.engineVersion.trim().isEmpty) {
      errors.add('engineVersion must not be empty');
    }
    if (snapshot.revision < 1) {
      errors.add('revision must be greater than zero');
    }
    final staffDates = <String>{};
    for (final assignment in snapshot.assignments) {
      final date = DateTime(
        assignment.date.year,
        assignment.date.month,
        assignment.date.day,
      );
      if (date.year != snapshot.year || date.month != snapshot.month) {
        errors.add('assignment date is outside the snapshot month');
      }
      final key = '${assignment.staffId}|${date.toIso8601String()}';
      if (!staffDates.add(key)) {
        errors.add(
          'duplicate assignment: staff ${assignment.staffId} on ${date.toIso8601String()}',
        );
      }
    }

    if (snapshot.publishedAt != null &&
        snapshot.publishedAt!.isBefore(snapshot.createdAt)) {
      errors.add('publishedAt cannot be before createdAt');
    }

    if (snapshot.continuityDate != null &&
        snapshot.continuityDate!.year == snapshot.year &&
        snapshot.continuityDate!.month == snapshot.month &&
        snapshot.continuityDate!.day > snapshot.daysInMonth) {
      errors.add('continuityDate is invalid for the snapshot month');
    }

    return List.unmodifiable(errors);
  }

  void validateOrThrow(PlanningSnapshot snapshot) {
    final errors = validate(snapshot);
    if (errors.isNotEmpty) {
      throw StateError(
        'Planning snapshot validation failed: ${errors.join('; ')}',
      );
    }
  }
}
