import 'package:objectbox/objectbox.dart';

import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../../domain/validators/planning_snapshot_validator.dart';
import '../mappers/planning_snapshot_mapper.dart';
import 'objectbox_planning_snapshot_store.dart';

/// Planning repository backed by the atomic ObjectBox snapshot store.
///
/// The repository is the final persistence boundary for the planning
/// lifecycle. Domain validation happens before any write and publication is
/// persisted only as a new immutable revision.
class ObjectBoxPlanningRepository implements PlanningRepository {
  final ObjectBoxPlanningSnapshotStore snapshotStore;
  final PlanningSnapshotMapper mapper;
  final PlanningSnapshotValidator validator;

  const ObjectBoxPlanningRepository({
    required this.snapshotStore,
    this.mapper = const PlanningSnapshotMapper(),
    this.validator = const PlanningSnapshotValidator(),
  });

  @override
  Future<PlanningSnapshot?> findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final entity = snapshotStore.findPublishedByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    return entity == null ? null : mapper.fromObjectBox(entity);
  }

  @override
  Future<PlanningSnapshot?> findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final entity = snapshotStore.findLatestByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    return entity == null ? null : mapper.fromObjectBox(entity);
  }

  @override
  Future<PlanningSnapshot?> findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) async {
    final entity = snapshotStore.findByRevision(
      year: year,
      month: month,
      revision: revision,
      branchId: branchId,
    );
    return entity == null ? null : mapper.fromObjectBox(entity);
  }

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final entity = snapshotStore.findPreviousPublished(
      year: year,
      month: month,
      branchId: branchId,
    );
    return entity == null ? null : mapper.fromObjectBox(entity);
  }

  @override
  Future<void> saveRevision(PlanningSnapshot snapshot) async {
    validator.validateOrThrow(snapshot);
    if (snapshot.isPublished) {
      throw StateError(
        'Use publishRevision() for a published planning snapshot.',
      );
    }
    await _persist(snapshot);
  }

  @override
  Future<void> publishRevision(PlanningSnapshot snapshot) async {
    validator.validateOrThrow(snapshot);
    if (!snapshot.isPublished) {
      throw StateError(
        'publishRevision expects a snapshot already marked with publishedAt.',
      );
    }
    if (snapshot.publishedAt!.isBefore(snapshot.createdAt)) {
      throw StateError(
        'A published planning snapshot cannot have publishedAt before createdAt.',
      );
    }
    await _persist(snapshot);
  }

  /// Compatibility helper for older callers.
  Future<bool> exists({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return (await findLatestByMonth(
              year: year,
              month: month,
              branchId: branchId,
            )) !=
        null;
  }

  /// Compatibility helper for older callers.
  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return findLatestByMonth(year: year, month: month, branchId: branchId);
  }

  /// Compatibility helper for older callers.
  Future<void> publish(PlanningSnapshot snapshot) async {
    await publishRevision(snapshot);
  }

  Future<void> _persist(PlanningSnapshot snapshot) async {
    final rotationState = snapshot.rotationState;
    if (rotationState == null) {
      throw StateError(
        'PlanningSnapshot.rotationState must be set before persistence.',
      );
    }

    final snapshotEntity = mapper.toObjectBox(snapshot);
    final rotationStateEntity = mapper.toRotationStateObjectBox(
      rotationState,
      branchId: snapshot.branchId ?? 0,
      year: snapshot.year,
      month: snapshot.month,
      revision: snapshot.revision,
    );
    final assignmentEntities = snapshot.assignments
        .map(mapper.toObjectBoxAssignment)
        .toList(growable: false);

    snapshotStore.putAtomically(
      snapshot: snapshotEntity,
      rotationState: rotationStateEntity,
      assignments: assignmentEntities,
    );
  }
}
