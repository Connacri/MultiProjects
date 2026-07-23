import 'package:objectbox/objectbox.dart';

import '../objectbox/planning_snapshot_entity.dart';

/// Low-level ObjectBox store for the new immutable snapshot model.
///
/// The caller is responsible for validation and application-level uniqueness
/// checks. Persistence is performed atomically through [Store.runInTx].
class ObjectBoxPlanningSnapshotStore {
  final Store store;
  final Box<PlanningSnapshotEntity> snapshotBox;
  final Box<PlanningAssignmentEntity> assignmentBox;

  const ObjectBoxPlanningSnapshotStore({
    required this.store,
    required this.snapshotBox,
    required this.assignmentBox,
  });

  PlanningSnapshotEntity? findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month),
        )
        .build();

    try {
      for (final snapshot in query.find()) {
        if (branchId == null || snapshot.branchId == branchId) {
          return snapshot;
        }
      }
      return null;
    } finally {
      query.close();
    }
  }

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
}
