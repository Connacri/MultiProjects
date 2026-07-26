import '../entities/planning_snapshot.dart';
import '../enums/planning_snapshot_status.dart';

class PublishPlanningSnapshot {
  const PublishPlanningSnapshot();

  PlanningSnapshot call(PlanningSnapshot snapshot) {
    if (snapshot.status != PlanningSnapshotStatus.draft) {
      return snapshot;
    }
    return snapshot.publish();
  }
}
