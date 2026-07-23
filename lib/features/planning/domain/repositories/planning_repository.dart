import '../models/leave_model.dart';
import '../models/planning_assignment_model.dart';
import '../models/planning_snapshot_model.dart';

abstract class PlanningRepository {
  Future<PlanningSnapshotModel?> getSnapshot({
    required int year,
    required int month,
  });

  Future<void> saveSnapshot(
    PlanningSnapshotModel snapshot,
  );

  Future<void> saveAssignments(
    List<PlanningAssignmentModel> assignments,
  );

  Future<List<PlanningAssignmentModel>> getAssignments({
    required String snapshotId,
  });

  Future<List<LeaveModel>> getLeaves({
    required String staffId,
  });
}
