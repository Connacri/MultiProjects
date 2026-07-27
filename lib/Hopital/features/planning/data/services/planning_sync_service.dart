import '../../domain/entities/planning_snapshot.dart';
import '../datasources/supabase_planning_datasource.dart';

/// Coordinates remote synchronization without making Supabase the local
/// source of truth. Callers persist the snapshot in ObjectBox first, then
/// invoke [pushSnapshot].
class PlanningSyncService {
  PlanningSyncService({required SupabasePlanningDatasource remote})
      : _remote = remote;

  final SupabasePlanningDatasource _remote;

  Future<String> pushSnapshot({
    required PlanningSnapshot snapshot,
    required int branchId,
    required Map<String, dynamic> configurationPayload,
  }) async {
    final configurationRemoteId = await _remote.upsertConfiguration(
      branchId: branchId,
      configurationId: snapshot.configurationId,
      version: snapshot.configurationVersion,
      payload: configurationPayload,
    );

    final snapshotRemoteId = await _remote.upsertSnapshot(
      snapshot: snapshot,
      configurationRemoteId: configurationRemoteId,
      branchId: branchId,
    );

    await _remote.replaceAssignments(
      snapshotId: snapshotRemoteId,
      assignments: snapshot.assignments,
    );

    final rotationState = snapshot.rotationState;
    if (rotationState != null) {
      await _remote.upsertRotationState(
        snapshotId: snapshotRemoteId,
        rotationState: rotationState,
        branchId: branchId,
        year: snapshot.year,
        month: snapshot.month,
        revision: snapshot.revision,
        configurationRemoteId: configurationRemoteId,
      );
    }

    return snapshotRemoteId;
  }
}
