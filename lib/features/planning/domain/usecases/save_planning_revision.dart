import '../entities/planning_snapshot.dart';
import '../repositories/planning_repository.dart';
import '../validators/planning_snapshot_validator.dart';

/// Persists a new immutable planning revision without publishing it.
///
/// This is the persistence boundary for editable drafts that must survive
/// application restarts. It never updates an existing revision and delegates
/// monotonicity and atomic ObjectBox writes to the repository.
class SavePlanningRevision {
  final PlanningRepository planningRepository;
  final PlanningSnapshotValidator validator;

  const SavePlanningRevision({
    required this.planningRepository,
    this.validator = const PlanningSnapshotValidator(),
  });

  Future<PlanningSnapshot> call({
    required PlanningSnapshot snapshot,
  }) async {
    if (snapshot.isPublished) {
      throw StateError(
        'A published planning snapshot cannot be saved as a draft revision.',
      );
    }

    validator.validateOrThrow(snapshot);

    final latest = await planningRepository.findLatestByMonth(
      year: snapshot.year,
      month: snapshot.month,
      branchId: snapshot.branchId,
    );

    if (latest != null && snapshot.revision <= latest.revision) {
      throw StateError(
        'Revision ${snapshot.revision} is stale. '
        'Latest persisted revision is ${latest.revision}.',
      );
    }

    await planningRepository.saveRevision(snapshot);

    final persisted = await planningRepository.findByRevision(
      year: snapshot.year,
      month: snapshot.month,
      revision: snapshot.revision,
      branchId: snapshot.branchId,
    );

    if (persisted == null) {
      throw StateError(
        'Planning revision ${snapshot.revision} was not readable after persistence.',
      );
    }

    if (persisted.isPublished) {
      throw StateError(
        'A revision saved as a draft must not be persisted as published.',
      );
    }

    return persisted;
  }
}
