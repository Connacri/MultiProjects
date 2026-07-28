import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kenzy/objectBox/Entity.dart';
import 'package:kenzy/objectBox/classeObjectBox.dart';
import '../../domain/entities/planning_assignment.dart';
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
    print('[Sync] --- Début pushSnapshot ---');
    print('[Sync] branchId=$branchId, year=${snapshot.year}, month=${snapshot.month}, revision=${snapshot.revision}');

    print('[Sync] Upsert configuration...');
    final configurationRemoteId = await _remote.upsertConfiguration(
      branchId: branchId,
      configurationId: snapshot.configurationId,
      version: snapshot.configurationVersion,
      payload: configurationPayload,
    );
    print('[Sync] ✅ Configuration upserted: id=$configurationRemoteId');

    print('[Sync] Upsert snapshot...');
    final snapshotRemoteId = await _remote.upsertSnapshot(
      snapshot: snapshot,
      configurationRemoteId: configurationRemoteId,
      branchId: branchId,
    );
    print('[Sync] ✅ Snapshot upserted: id=$snapshotRemoteId');

    print('[Sync] Ensure staffs exist (${snapshot.assignments.length} assignments)...');
    await _ensureStaffsExist(snapshot.assignments);

    print('[Sync] Replace assignments...');
    await _remote.replaceAssignments(
      snapshotId: snapshotRemoteId,
      assignments: snapshot.assignments,
    );
    print('[Sync] ✅ Assignments remplacés (${snapshot.assignments.length})');

    final rotationState = snapshot.rotationState;
    if (rotationState != null) {
      print('[Sync] Upsert rotation state...');
      await _remote.upsertRotationState(
        snapshotId: snapshotRemoteId,
        rotationState: rotationState,
        branchId: branchId,
        year: snapshot.year,
        month: snapshot.month,
        revision: snapshot.revision,
        configurationRemoteId: configurationRemoteId,
      );
      print('[Sync] ✅ Rotation state upserted');
    } else {
      print('[Sync] ⏭ Pas de rotation state');
    }

    print('[Sync] --- pushSnapshot terminé ---');
    return snapshotRemoteId;
  }

  Future<void> _ensureStaffsExist(
      List<PlanningAssignment> assignments) async {
    final staffIds = assignments.map((a) => a.staffId).toSet();
    print('[Sync] Staff IDs référencés: ${staffIds.join(', ')}');
    if (staffIds.isEmpty) {
      print('[Sync] ⏭ Aucun staff dans les assignments');
      return;
    }

    print('[Sync] Vérification staffs existants dans Supabase...');
    final allRemote = await _client.from('staffs').select('id');
    final existingIds = allRemote.map((r) => r['id'] as int).toSet();
    print('[Sync] Staffs existants: ${existingIds.join(", ")}');

    final missingIds = staffIds.difference(existingIds);
    print('[Sync] Staffs manquants: ${missingIds.join(", ")}');
    if (missingIds.isEmpty) {
      print('[Sync] ✅ Tous les staffs existent déjà');
      return;
    }

    final staffs = _objectBox.staffBox.getMany(missingIds.toList());
    final nonNull = <Staff>[];
    for (final s in staffs) {
      if (s != null) nonNull.add(s);
    }
    print('[Sync] Staffs trouvés dans ObjectBox pour upsert: ${nonNull.length}');

    if (nonNull.isNotEmpty) {
      final payload = nonNull.map((s) {
        final branchId = s.branch.targetId;
        return {
          'id': s.id,
          'nom': s.nom,
          'grade': s.grade,
          'groupe': s.groupe,
          'equipe': s.equipe ?? '',
          'ordre': s.ordre ?? 0,
          'branch_id': branchId != 0 ? branchId : null,
        };
      }).toList();
      print('[Sync] Upsert staffs (ids: ${payload.map((p) => p['id']).join(", ")})');
      await _client.from('staffs').upsert(payload);
      print('[Sync] ✅ Staffs upserted');
    }
  }
}
