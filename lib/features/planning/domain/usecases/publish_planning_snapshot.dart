import '../entities/planning_snapshot.dart';

/// Publishes a validated draft snapshot as a new immutable historical fact.
///
/// Validation is intentionally explicit and supplied by the application layer;
/// this use case only performs the domain transition. A published snapshot is
/// never mutated in place and cannot be published twice.
class PublishPlanningSnapshot {
  const PublishPlanningSnapshot();

  PlanningSnapshot call({
    required PlanningSnapshot snapshot,
    required bool isValid,
    DateTime? publishedAt,
  }) {
    if (snapshot.isPublished) {
      return snapshot;
    }

    if (!isValid) {
      throw StateError(
        'A planning snapshot must be validated before publication.',
      );
    }

    return snapshot.copyWith(
      publishedAt: publishedAt ?? DateTime.now().toUtc(),
    );
  }
}
