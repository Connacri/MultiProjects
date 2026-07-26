import '../../domain/entities/planning_snapshot.dart';
import '../../domain/usecases/publish_planning_snapshot.dart';

/// Compatibility facade for the legacy application-layer publication API.
///
/// The publication pipeline is intentionally delegated to the canonical
/// domain use case so validation, UTC timestamps, persistence verification and
/// immutable revision rules cannot diverge between entry points.
class PublishPlanning {
  final PublishPlanningSnapshot publishPlanningSnapshot;

  const PublishPlanning({
    required this.publishPlanningSnapshot,
  });

  Future<PlanningSnapshot> call(PlanningSnapshot snapshot) {
    return publishPlanningSnapshot(snapshot: snapshot);
  }
}
