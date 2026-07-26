import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_state_snapshot.dart';

/// Remote persistence boundary for Planning V2.
///
/// This datasource deliberately does not mutate ObjectBox. ObjectBox remains
/// the offline-first read model; the repository/sync layer decides when to
/// push or pull remote state.
class SupabasePlanningDatasource {
  SupabasePlanningDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> upsertConfiguration({
    required int branchId,
    required String configurationId,
    required int version,
    required Map<String, dynamic> payload,
  }) async {
    final row = await _client
        .from('planning_configurations')
        .upsert(
          {
            'branch_id': branchId,
            'configuration_key': configurationId,
            'version': version,
            'payload': payload,
          },
          onConflict: 'branch_id,configuration_key,version',
        )
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<String> upsertSnapshot({
    required PlanningSnapshot snapshot,
    required String configurationRemoteId,
    required int branchId,
  }) async {
    final row = await _client
        .from('planning_snapshots')
        .upsert(
          {
            'branch_id': branchId,
            'year': snapshot.year,
            'month': snapshot.month,
            'configuration_id': configurationRemoteId,
            'configuration_version': snapshot.configurationVersion,
            'engine_version': snapshot.engineVersion,
            'revision': snapshot.revision,
            'status': snapshot.publishedAt == null ? 0 : 1,
            'created_at': snapshot.createdAt.toUtc().toIso8601String(),
            'published_at': snapshot.publishedAt?.toUtc().toIso8601String(),
          },
          onConflict: 'branch_id,year,month,revision',
        )
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> replaceAssignments({
    required String snapshotId,
    required List<PlanningAssignment> assignments,
  }) async {
    await _client
        .from('planning_assignments')
        .delete()
        .eq('snapshot_id', snapshotId);

    if (assignments.isEmpty) return;

    await _client.from('planning_assignments').insert(
          assignments
              .map(
                (assignment) => {
                  'snapshot_id': snapshotId,
                  'staff_id': assignment.staffId,
                  'date': _dateOnly(assignment.date),
                  'team': assignment.team,
                  'shift': assignment.shift.name,
                  'code': assignment.code,
                  'note': assignment.note,
                },
              )
              .toList(growable: false),
        );
  }

  Future<void> upsertRotationState({
    required String snapshotId,
    required RotationStateSnapshot rotationState,
    required int branchId,
    required int year,
    required int month,
    required int revision,
    required String configurationRemoteId,
  }) async {
    await _client.from('rotation_state_snapshots').upsert(
      {
        'snapshot_id': snapshotId,
        'branch_id': branchId,
        'year': year,
        'month': month,
        'revision': revision,
        'state_date': _dateOnly(rotationState.date),
        'configuration_id': configurationRemoteId,
        'configuration_version': rotationState.configurationVersion,
        'phase_index': rotationState.phaseIndex,
        'team_phase_by_team': rotationState.teamPhaseByTeam,
      },
      onConflict: 'snapshot_id',
    );
  }

  Future<Map<String, dynamic>?> fetchSnapshot({
    required int branchId,
    required int year,
    required int month,
    required int revision,
  }) async {
    final rows = await _client
        .from('planning_snapshots')
        .select('*, planning_assignments(*), rotation_state_snapshots(*)')
        .eq('branch_id', branchId)
        .eq('year', year)
        .eq('month', month)
        .eq('revision', revision)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> fetchSnapshots({
    required int branchId,
    int? year,
    int? month,
  }) async {
    var query = _client
        .from('planning_snapshots')
        .select('*, planning_assignments(*), rotation_state_snapshots(*)')
        .eq('branch_id', branchId);

    if (year != null) query = query.eq('year', year);
    if (month != null) query = query.eq('month', month);

    final rows = await query.order('year').order('month').order('revision');
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  String _dateOnly(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
