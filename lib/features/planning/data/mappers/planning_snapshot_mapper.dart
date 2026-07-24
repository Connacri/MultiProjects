import 'dart:convert';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/enums/shift_type.dart';
import '../objectbox/planning_snapshot_entity.dart';
import '../models/planning_persistence_record.dart';

/// Maps the immutable planning domain snapshot to/from ObjectBox.
///
/// The ObjectBox schema is intentionally kept aligned with the current
/// PlanningSnapshotEntity model. Rotation continuity is reconstructed from
/// the published assignments by RotationContinuityResolver rather than being
/// duplicated as an unversioned JSON field in the snapshot entity.
class PlanningSnapshotMapper {
  const PlanningSnapshotMapper();

  PlanningSnapshot fromObjectBox(PlanningSnapshotEntity entity) {
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
      assignments: List.unmodifiable(
        entity.assignments.map(fromObjectBoxAssignment),
      ),
    );
  }

  PlanningAssignment fromObjectBoxAssignment(PlanningAssignmentEntity entity) {
    return PlanningAssignment(
      staffId: entity.staffId,
      date: DateTime.fromMillisecondsSinceEpoch(entity.dateEpochMs),
      team: entity.team,
      shift: _shiftFromString(entity.shift),
      code: entity.code,
      note: entity.note,
    );
  }

  PlanningSnapshot fromLegacyRecord(PlanningPersistenceRecord record) {
    return PlanningSnapshot(
      id: 'legacy-${record.id}',
      year: record.year,
      month: record.month,
      branchId: record.branchId,
      configurationId: 'legacy:${record.teamOrder}',
      configurationVersion: 1,
      engineVersion: 'legacy',
      revision: 1,
      createdAt: DateTime(record.year, record.month, 1),
      publishedAt: DateTime(record.year, record.month, 1),
      assignments: _parseLegacyAssignments(
        record.snapshotJson,
        year: record.year,
        month: record.month,
      ),
    );
  }

  PlanningSnapshotEntity toObjectBox(PlanningSnapshot snapshot) {
    final entity = PlanningSnapshotEntity()
      ..branchId = snapshot.branchId ?? 0
      ..year = snapshot.year
      ..month = snapshot.month
      ..configurationId = snapshot.configurationId
      ..configurationVersion = snapshot.configurationVersion
      ..engineVersion = snapshot.engineVersion
      ..revision = snapshot.revision
      ..status = snapshot.publishedAt == null ? 0 : 1
      ..createdAtEpochMs = snapshot.createdAt.millisecondsSinceEpoch
      ..publishedAtEpochMs = snapshot.publishedAt?.millisecondsSinceEpoch;

    for (final assignment in snapshot.assignments) {
      entity.assignments.add(toObjectBoxAssignment(assignment));
    }

    return entity;
  }

  PlanningAssignmentEntity toObjectBoxAssignment(PlanningAssignment assignment) {
    return PlanningAssignmentEntity()
      ..staffId = assignment.staffId
      ..dateEpochMs = DateTime(
        assignment.date.year,
        assignment.date.month,
        assignment.date.day,
      ).millisecondsSinceEpoch
      ..team = assignment.team
      ..shift = assignment.shift.name
      ..code = assignment.code
      ..note = assignment.note;
  }

  ShiftType _shiftFromString(String value) {
    switch (value.toLowerCase()) {
      case 'day':
        return ShiftType.day;
      case 'night':
        return ShiftType.night;
      case 'leave':
        return ShiftType.leave;
      case 'training':
        return ShiftType.training;
      case 'activity':
        return ShiftType.activity;
      default:
        return ShiftType.rest;
    }
  }

  List<PlanningAssignment> _parseLegacyAssignments(
    String? json, {
    required int year,
    required int month,
  }) {
    if (json == null || json.isEmpty) return const [];

    try {
      final root = jsonDecode(json);
      if (root is! Map<String, dynamic>) return const [];

      final rawAssignments = root['activites'];
      if (rawAssignments is! List) return const [];

      final result = <PlanningAssignment>[];
      final maxDay = DateTime(year, month + 1, 0).day;

      for (final item in rawAssignments) {
        if (item is! Map) continue;
        final staffId = int.tryParse(item['staffId']?.toString() ?? '');
        final jours = item['jours'];
        final team = item['team']?.toString();
        if (staffId == null || jours is! List) continue;

        for (final dayItem in jours) {
          if (dayItem is! Map) continue;
          final day = int.tryParse(dayItem['jour']?.toString() ?? '');
          final status = dayItem['statut']?.toString() ?? '';
          if (day == null || day < 1 || day > maxDay) continue;

          result.add(
            PlanningAssignment(
              staffId: staffId,
              date: DateTime(year, month, day),
              team: team,
              shift: _legacyShift(status),
              code: status,
            ),
          );
        }
      }

      return List.unmodifiable(result);
    } catch (_) {
      return const [];
    }
  }

  ShiftType _legacyShift(String status) {
    switch (status.toUpperCase()) {
      case 'J':
      case 'DAY':
      case 'JOUR':
        return ShiftType.day;
      case 'N':
      case 'NIGHT':
      case 'NUIT':
        return ShiftType.night;
      case 'CM':
      case 'FORMATION':
      case 'MISSION':
      case 'ACT':
        return ShiftType.other;
      default:
        return ShiftType.rest;
    }
  }
}
