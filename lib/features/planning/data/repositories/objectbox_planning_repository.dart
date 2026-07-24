import 'package:objectbox/objectbox.dart';

import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../mappers/planning_snapshot_mapper.dart';
import 'objectbox_planning_snapshot_store.dart';

/// Planning repository backed by the atomic ObjectBox snapshot store.
///
/// This repository is the bridge between the clean application/domain API and
/// the low-level ObjectBox store. Snapshots are read and written explicitly by
/// status so the caller never has to guess which revision is loaded.
class ObjectBoxPlanningRepository implements PlanningRepository {
  final ObjectBoxPlanningSnapshotStore snapshotStore;
  final PlanningSnapshotMapper mapper;

  const ObjectBoxPlanningRepository({
    required this.snapshotStore,
    this.mapper = const PlanningSnapshotMapper(),
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
    await _persist(snapshot);
  }

  @override
  Future<void> publishRevision(PlanningSnapshot snapshot) async {
    if (!snapshot.isPublished) {
      throw StateError(
        'publishRevision expects a snapshot already marked with publishedAt.',
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
    return (await findLatestByMonth(year: year, month: month, branchId: branchId))
        !=
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
    await saveRevision(snapshot);
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
