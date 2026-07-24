import 'dart:convert';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_state_snapshot.dart';
import '../../domain/enums/shift_type.dart';
import '../objectbox/planning_snapshot_entity.dart';
import '../objectbox/rotation_state_snapshot_entity.dart';

class PlanningObjectBoxMapper {
  const PlanningObjectBoxMapper();

  PlanningSnapshot toDomain(PlanningSnapshotEntity entity) {
    return PlanningSnapshot(
      id: 'obx-${entity.id}',
      year: entity.year,
      month: entity.month,
      branchId: entity.branchId == 0 ? null : entity.branchId,
      configurationId: entity.configurationId,
      configurationVersion: entity.configurationVersion,
      engineVersion: entity.engineVersion,
      revision: entity.revision,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAtEpochMs),
      publishedAt: entity.publishedAtEpochMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(entity.publishedAtEpochMs!),
      rotationState: entity.rotationState.target == null
          ? null
          : _rotationStateToDomain(entity.rotationState.target!),
      assignments: List.unmodifiable(
        entity.assignments.map(_assignmentToDomain),
      ),
    );
  }

  RotationStateSnapshot _rotationStateToDomain(
    RotationStateSnapshotEntity entity,
  ) {
    final decoded = jsonDecode(entity.teamPhaseByTeamJson);
    final teamPhaseByTeam = decoded is Map
        ? Map<String, int>.from(
            decoded.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ),
          )
        : const <String, int>{};

    return RotationStateSnapshot(
      date: DateTime.fromMillisecondsSinceEpoch(entity.dateEpochMs),
      configurationId: entity.configurationId,
      configurationVersion: entity.configurationVersion,
      phaseIndex: entity.phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(teamPhaseByTeam),
    );
  }

  PlanningAssignment _assignmentToDomain(PlanningAssignmentEntity entity) {
    return PlanningAssignment(
      staffId: entity.staffId,
      date: DateTime.fromMillisecondsSinceEpoch(entity.dateEpochMs),
      team: entity.team,
      shift: _shiftFromString(entity.shift),
      code: entity.code,
      note: entity.note,
    );
  }

  RotationStateSnapshotEntity rotationStateToEntity(
    RotationStateSnapshot state, {
    required int branchId,
    required int year,
    required int month,
    required int revision,
  }) {
    return RotationStateSnapshotEntity()
      ..branchId = branchId
      ..year = year
      ..month = month
      ..revision = revision
      ..dateEpochMs = state.date.millisecondsSinceEpoch
      ..configurationId = state.configurationId
      ..configurationVersion = state.configurationVersion
      ..phaseIndex = state.phaseIndex
      ..teamPhaseByTeamJson = jsonEncode(state.teamPhaseByTeam);
  }

  String shiftToString(ShiftType shift) => shift.name;

  ShiftType _shiftFromString(String value) {
    switch (value.toLowerCase()) {
      case 'day':
        return ShiftType.day;
      case 'night':
        return ShiftType.night;
      default:
        return ShiftType.rest;
    }
  }
}
