import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/enums/shift_type.dart';
import '../objectbox/planning_snapshot_entity.dart';

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
      assignments: List.unmodifiable(
        entity.assignments.map(_assignmentToDomain),
      ),
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

  String shiftToString(ShiftType shift) => shift.name;
}
