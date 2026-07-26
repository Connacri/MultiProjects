import '../entities/planning_snapshot.dart';
import '../validators/planning_snapshot_validator.dart';

/// Publishes a validated draft snapshot as a new immutable historical fact.
///
/// Validation is performed inside the use case so every caller follows the
/// same domain gate. Persistence remains responsible for revision ordering
/// and atomicity.
class PublishPlanningSnapshot {
  const PublishPlanningSnapshot({
    this.validator = const PlanningSnapshotValidator(),
  });

  final PlanningSnapshotValidator validator;

  PlanningSnapshot call({
    required PlanningSnapshot snapshot,
    DateTime? publishedAt,
  }) {
    if (snapshot.isPublished) {
      return snapshot;
    }

    validator.validateOrThrow(snapshot);

    final publicationDate = publishedAt ?? DateTime.now().toUtc();
    if (publicationDate.isBefore(snapshot.createdAt)) {
      throw ArgumentError.value(
        publishedAt,
        'publishedAt',
        'Publication date cannot be before snapshot creation date.',
      );
    }

    return snapshot.copyWith(
      publishedAt: publicationDate,
    );
  }
}
