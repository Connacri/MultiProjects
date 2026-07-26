import '../entities/planning_snapshot.dart';
import '../repositories/planning_repository.dart';
import '../validators/planning_snapshot_validator.dart';

/// Publishes a validated draft snapshot as a new immutable historical fact.
///
/// Publication is guarded against stale revisions: only the latest persisted
/// revision for the target month/branch can be published. The repository then
/// owns the atomic write and final concurrency guarantees.
class PublishPlanningSnapshot {
  const PublishPlanningSnapshot({
    required this.planningRepository,
    this.validator = const PlanningSnapshotValidator(),
  });

  final PlanningRepository planningRepository;
  final PlanningSnapshotValidator validator;

  Future<PlanningSnapshot> call({
    required PlanningSnapshot snapshot,
    DateTime? publishedAt,
  }) async {
    if (snapshot.isPublished) {
      return snapshot;
    }

    validator.validateOrThrow(snapshot);

    final latest = await planningRepository.findLatestByMonth(
      year: snapshot.year,
      month: snapshot.month,
      branchId: snapshot.branchId,
    );

    if (latest == null) {
      throw StateError(
        'Cannot publish a planning revision that is not persisted.',
      );
    }

    if (latest.revision != snapshot.revision || latest.id != snapshot.id) {
      throw StateError(
        'Cannot publish stale planning revision ${snapshot.revision}. '
        'Latest persisted revision is ${latest.revision}.',
      );
    }

    if (latest.isPublished) {
      return latest;
    }

    final publicationDate = (publishedAt ?? DateTime.now()).toUtc();
    final createdAt = snapshot.createdAt.toUtc();
    if (publicationDate.isBefore(createdAt)) {
      throw ArgumentError.value(
        publishedAt,
        'publishedAt',
        'Publication date cannot be before snapshot creation date.',
      );
    }

    final publishedSnapshot = snapshot.copyWith(
      publishedAt: publicationDate,
    );

    await planningRepository.publishRevision(publishedSnapshot);

    final persisted = await planningRepository.findByRevision(
      year: publishedSnapshot.year,
      month: publishedSnapshot.month,
      revision: publishedSnapshot.revision,
      branchId: publishedSnapshot.branchId,
    );

    if (persisted == null || !persisted.isPublished) {
      throw StateError(
        'Planning publication completed without a readable published revision.',
      );
    }

    return persisted;
  }
}
