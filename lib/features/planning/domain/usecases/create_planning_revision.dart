import '../entities/planning_snapshot.dart';
import '../repositories/planning_repository.dart';

/// Creates a new draft revision from an existing planning snapshot.
///
/// This use case is intentionally distinct from initial monthly generation:
/// generation creates revision 1 for a month that has no persisted snapshot,
/// while this flow creates revision N+1 from an existing immutable revision.
class CreatePlanningRevision {
  final PlanningRepository planningRepository;

  const CreatePlanningRevision({required this.planningRepository});

  Future<PlanningSnapshot> call({
    required PlanningSnapshot source,
    required DateTime createdAt,
    List<dynamic>? assignments,
    DateTime? continuityDate,
  }) async {
    final latest = await planningRepository.findLatestByMonth(
      year: source.year,
      month: source.month,
      branchId: source.branchId,
    );

    if (latest == null) {
      throw StateError(
        'Cannot create a revision without a persisted source snapshot.',
      );
    }

    if (latest.revision < source.revision) {
      throw StateError(
        'The source snapshot is stale. A newer revision already exists.',
      );
    }

    final next = source.nextRevision(
      createdAt: createdAt.toUtc(),
      assignments: assignments == null
          ? null
          : assignments.cast(),
      continuityDate: continuityDate,
      rotationState: source.rotationState,
    );

    if (next.revision <= latest.revision) {
      throw StateError(
        'The next revision must be greater than the latest persisted revision.',
      );
    }

    return next;
  }
}
