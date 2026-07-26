import '../entities/planning_snapshot.dart';
import '../repositories/planning_repository.dart';
import '../validators/planning_snapshot_validator.dart';

/// Publishes a validated draft snapshot as a new immutable historical fact.
///
/// The use case owns the domain gate. The repository owns the atomic write and
/// revision-ordering guarantees. The caller receives the persisted historical
/// snapshot only after the repository confirms the write.
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

    final publicationDate = publishedAt ?? DateTime.now().toUtc();
    if (publicationDate.isBefore(snapshot.createdAt)) {
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
