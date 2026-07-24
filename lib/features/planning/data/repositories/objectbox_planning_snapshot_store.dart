import 'package:objectbox/objectbox.dart';

import '../../../../objectbox.g.dart';
import '../objectbox/planning_snapshot_entity.dart';

/// Low-level ObjectBox store for immutable Planning snapshots.
///
/// Persistence is atomic through [Store.runInTx]. Higher layers own
/// validation and publication business rules.
class ObjectBoxPlanningSnapshotStore {
  final Store store;
  final Box<PlanningSnapshotEntity> snapshotBox;
  final Box<PlanningAssignmentEntity> assignmentBox;

  const ObjectBoxPlanningSnapshotStore({
    required this.store,
    required this.snapshotBox,
    required this.assignmentBox,
  });

  /// Returns the currently published snapshot for a month and branch.
  ///
  /// A null [branchId] means the global branch (0), not "any branch".
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
      descendingRevision: true,
    );
  }

  /// Returns the latest effective snapshot for a month and branch.
  ///
  /// The latest revision is selected deterministically. This is the snapshot
  /// to use when editing or resuming the current planning draft.
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
      descendingRevision: true,
    );
  }

  /// Returns one exact revision for a month and branch.
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
      final snapshots = query.find();
      for (final snapshot in snapshots) {
        if (_matchesBranch(snapshot, branchId)) return snapshot;
      }
      return null;
    } finally {
      query.close();
    }
  }

  /// Persists a snapshot and all its assignments atomically.
  void putAtomically(
    PlanningSnapshotEntity snapshot,
    List<PlanningAssignmentEntity> assignments,
  ) {
    store.runInTx(TxMode.write, () {
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
    required bool descendingRevision,
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
        if (revisionCompare != 0) {
          return descendingRevision ? revisionCompare : -revisionCompare;
        }
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
