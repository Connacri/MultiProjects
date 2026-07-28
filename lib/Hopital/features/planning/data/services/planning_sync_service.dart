import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectBox/Entity.dart';
import '../../../../objectBox/classeObjectBox.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../datasources/supabase_planning_datasource.dart';

/// Coordinates remote synchronization without making Supabase the local
/// source of truth. Callers persist the snapshot in ObjectBox first, then
/// invoke [pushSnapshot].
class PlanningSyncService {
  PlanningSyncService({required SupabasePlanningDatasource remote})
      : _remote = remote;

  final SupabasePlanningDatasource _remote;
  final ObjectBox _objectBox = ObjectBox();
  final SupabaseClient _client = Supabase.instance.client;

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

    await _ensureStaffsExist(snapshot.assignments);
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

  Future<void> _ensureStaffsExist(
      List<PlanningAssignment> assignments) async {
    final staffIds = assignments.map((a) => a.staffId).toSet();
    if (staffIds.isEmpty) return;

    final existingIds = (await _client
            .from('staffs')
            .select('id')
            .in_('id', staffIds.toList()))
        .map((r) => r['id'] as int)
        .toSet();

    final missingIds = staffIds.difference(existingIds);
    if (missingIds.isEmpty) return;

    final staffs = _objectBox.staffBox
        .getMany(missingIds.toList())
        .where((s) => s != null)
        .cast<Staff>()
        .toList();

    if (staffs.isNotEmpty) {
      await _client.from('staffs').upsert(
            staffs.map((s) => {
              'id': s.id,
              'nom': s.nom,
              'grade': s.grade,
              'groupe': s.groupe,
              'equipe': s.equipe ?? '',
              'ordre': s.ordre ?? 0,
              'branch_id':
                  s.branch.targetId != 0 ? s.branch.targetId : null,
            }).toList(),
          );
    }
  }
}
