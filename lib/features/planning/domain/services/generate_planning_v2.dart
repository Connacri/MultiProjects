import '../entities/planning_assignment.dart';
import '../entities/planning_input.dart';
import '../entities/planning_snapshot.dart';
import '../entities/staff_member.dart';
import '../entities/rotation_state_snapshot.dart';
import '../enums/shift_type.dart';
import 'rotation_engine_v2.dart';

class GeneratePlanningV2 {
  final RotationEngineV2 rotationEngine;

  const GeneratePlanningV2({
    this.rotationEngine = const RotationEngineV2(),
  });

  PlanningSnapshot execute({
    required PlanningInput input,
    RotationStateSnapshot? continuityState,
  }) {
    _validateInput(input);

    final rotationDays = rotationEngine.generateMonth(
      year: input.year,
      month: input.month,
      configuration: input.rotation,
      previousState: continuityState == null
          ? null
          : _toRotationState(continuityState),
    );

    final assignments = <PlanningAssignment>[];

    for (final day in rotationDays) {
      final staffByTeam = <String, List<StaffMember>>{};
      for (final staff in input.staff) {
        staffByTeam.putIfAbsent(staff.team, () => []).add(staff);
      }

      for (final teamEntry in staffByTeam.entries) {
        final shiftName = day.phaseByTeam[teamEntry.key];
        final shift = _shiftFromName(shiftName);

        for (final staff in teamEntry.value) {
          final onLeave = input.leaves.any(
            (leave) => leave.staffId == staff.id && leave.covers(day.date),
          );

          assignments.add(
            PlanningAssignment(
              staffId: staff.id,
              date: day.date,
              team: staff.team,
              shift: onLeave ? ShiftType.leave : shift,
              code: onLeave ? 'LEAVE' : shiftName,
              note: onLeave ? 'Unavailable during generated rotation' : null,
            ),
          );
        }
      }
    }

    final now = DateTime.now();
    return PlanningSnapshot(
      id: 'draft-${input.year}-${input.month}-${now.microsecondsSinceEpoch}',
      year: input.year,
      month: input.month,
      branchId: input.branchId,
      configurationId: input.rotation.id,
      configurationVersion: input.rotation.version,
      engineVersion: 'rotation-engine-v2',
      revision: 1,
      createdAt: now,
      publishedAt: null,
      assignments: List.unmodifiable(assignments),
      continuityDate: assignments.isEmpty
          ? null
          : assignments.map((a) => a.date).reduce(
              (a, b) => a.isAfter(b) ? a : b,
            ),
    );
  }

  void _validateInput(PlanningInput input) {
    if (input.year < 2000 || input.year > 2200) {
      throw ArgumentError.value(input.year, 'year');
    }
    if (input.month < 1 || input.month > 12) {
      throw ArgumentError.value(input.month, 'month');
    }
    if (input.staff.isEmpty) {
      throw StateError('At least one staff member is required.');
    }

    final ids = <int>{};
    for (final staff in input.staff) {
      if (!ids.add(staff.id)) {
        throw StateError('Duplicate staff id: ${staff.id}');
      }
      if (staff.team.trim().isEmpty) {
        throw StateError('Staff ${staff.id} has no team.');
      }
    }

    final unknownLeave = input.leaves.where(
      (leave) => !ids.contains(leave.staffId),
    );
    if (unknownLeave.isNotEmpty) {
      throw StateError('A leave references an unknown staff member.');
    }
  }

  ShiftType _shiftFromName(String? value) {
    switch (value?.toLowerCase()) {
      case 'day':
      case 'jour':
        return ShiftType.day;
      case 'night':
      case 'nuit':
        return ShiftType.night;
      case 'rest':
      case 'repos':
        return ShiftType.rest;
      default:
        return ShiftType.other;
    }
  }

  dynamic _toRotationState(RotationStateSnapshot state) {
    return null;
  }
}
