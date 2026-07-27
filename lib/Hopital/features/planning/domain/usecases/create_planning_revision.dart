import '../entities/planning_assignment.dart';
import '../entities/planning_snapshot.dart';
import '../entities/rotation_state_snapshot.dart';
import '../repositories/planning_repository.dart';

/// Creates a new immutable draft revision from an existing persisted revision.
///
/// Revision identity is monotonic per (branch, year, month). Persistence
/// identity is deliberately reset by PlanningSnapshot.nextRevision() so the
/// repository inserts a new ObjectBox entity instead of updating the source.
class CreatePlanningRevision {
  final PlanningRepository planningRepository;

  const CreatePlanningRevision({required this.planningRepository});

  Future<PlanningSnapshot> call({
    required PlanningSnapshot source,
    required DateTime createdAt,
    List<PlanningAssignment>? assignments,
    DateTime? continuityDate,
    RotationStateSnapshot? rotationState,
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

    if (latest.revision > source.revision) {
      throw StateError(
        'Cannot create a revision from a stale source. '
        'Latest revision is R${latest.revision}.',
      );
    }

    final next = source.nextRevision(
      createdAt: createdAt.toUtc(),
      assignments: assignments,
      continuityDate: continuityDate,
      rotationState: rotationState,
    );

    if (next.id.isNotEmpty) {
      throw StateError(
        'A new revision must not reuse persistence identity from its source.',
      );
    }

    if (next.revision != latest.revision + 1) {
      throw StateError(
        'Invalid revision sequence: expected R${latest.revision + 1}, '
        'got R${next.revision}.',
      );
    }

    if (next.isPublished) {
      throw StateError('A newly created revision must start as a draft.');
    }

    return next;
  }
}
