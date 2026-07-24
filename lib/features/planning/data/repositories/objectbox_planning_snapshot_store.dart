import 'package:objectbox/objectbox.dart';

import '../../../../objectbox.g.dart';
import '../objectbox/planning_snapshot_entity.dart';
import '../objectbox/rotation_state_snapshot_entity.dart';

/// Low-level ObjectBox store for immutable Planning snapshots.
///
/// Snapshot, rotation checkpoint and assignments are persisted atomically.
/// Higher layers own validation and publication business rules.
class ObjectBoxPlanningSnapshotStore {
  final Store store;
  final Box<PlanningSnapshotEntity> snapshotBox;
  final Box<PlanningAssignmentEntity> assignmentBox;
  final Box<RotationStateSnapshotEntity> rotationStateBox;

  const ObjectBoxPlanningSnapshotStore({
    required this.store,
    required this.snapshotBox,
    required this.assignmentBox,
    required this.rotationStateBox,
  });

  PlanningSnapshotEntity? findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    return _findSingle(
      year: year,
      month: month,
      branchId: branchId,
      predicate: (snapshot) => snapshot.publishedAtEpochMs != null,
    );
  }

  PlanningSnapshotEntity? findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    return _findSingle(
      year: year,
      month: month,
      branchId: branchId,
      predicate: (_) => true,
    );
  }

  PlanningSnapshotEntity? findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month) &
              PlanningSnapshotEntity_.revision.equals(revision),
        )
        .build();

    try {
      for (final snapshot in query.find()) {
        if (_matchesBranch(snapshot, branchId)) return snapshot;
      }
      return null;
    } finally {
      query.close();
    }
  }

  PlanningSnapshotEntity? findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) {
    final targetMonth = year * 100 + month;
    final candidates = snapshotBox
        .getAll()
        .where(
          (snapshot) =>
              snapshot.publishedAtEpochMs != null &&
              _matchesBranch(snapshot, branchId) &&
              (snapshot.year * 100 + snapshot.month) < targetMonth,
        )
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final monthCompare =
          (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
      if (monthCompare != 0) return monthCompare;
      final revisionCompare = b.revision.compareTo(a.revision);
      if (revisionCompare != 0) return revisionCompare;
      return b.id.compareTo(a.id);
    });

    return candidates.first;
  }

  /// Persists snapshot, its rotation checkpoint and assignments atomically.
  ///
  /// The rotation checkpoint is attached to the snapshot before the snapshot
  /// is written. If any write fails, ObjectBox rolls back the whole unit.
  void putAtomically({
    required PlanningSnapshotEntity snapshot,
    required RotationStateSnapshotEntity rotationState,
    required List<PlanningAssignmentEntity> assignments,
  }) {
    if (snapshot.year != rotationState.year ||
        snapshot.month != rotationState.month ||
        snapshot.revision != rotationState.revision ||
        snapshot.branchId != rotationState.branchId) {
      throw ArgumentError(
        'Snapshot and rotation state must belong to the same branch, month '
        'and revision.',
      );
    }

    store.runInTransaction(TxMode.write, () {
      final rotationStateId = rotationStateBox.put(rotationState);
      snapshot.rotationState.targetId = rotationStateId;
      final snapshotId = snapshotBox.put(snapshot);

      for (final assignment in assignments) {
        assignment.snapshot.targetId = snapshotId;
        assignmentBox.put(assignment);
      }
    });
  }

  PlanningSnapshotEntity? _findSingle({
    required int year,
    required int month,
    required int? branchId,
    required bool Function(PlanningSnapshotEntity snapshot) predicate,
  }) {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month),
        )
        .build();

    try {
      final snapshots = query
          .find()
          .where(
            (snapshot) =>
                _matchesBranch(snapshot, branchId) && predicate(snapshot),
          )
          .toList();

      if (snapshots.isEmpty) return null;

      snapshots.sort((a, b) {
        final revisionCompare = b.revision.compareTo(a.revision);
        if (revisionCompare != 0) return revisionCompare;
        return b.id.compareTo(a.id);
      });

      return snapshots.first;
    } finally {
      query.close();
    }
  }

  bool _matchesBranch(PlanningSnapshotEntity snapshot, int? branchId) {
    return snapshot.branchId == (branchId ?? 0);
  }
}
