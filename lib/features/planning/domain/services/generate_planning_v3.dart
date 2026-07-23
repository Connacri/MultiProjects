import '../entities/planning_assignment_v2.dart';
import '../entities/planning_input.dart';
import '../entities/planning_snapshot.dart';
import '../entities/rotation_state_snapshot.dart';
import '../entities/staff_member.dart';
import '../enums/shift_type.dart';
import 'rotation_engine_v2.dart';

class GeneratePlanningV3 {
  final RotationEngineV2 rotationEngine;

  const GeneratePlanningV3({this.rotationEngine = const RotationEngineV2()});

  PlanningGenerationResult execute({
    required PlanningInput input,
    RotationStateSnapshot? continuityState,
  }) {
    _validate(input);

    final previousState = continuityState == null
        ? null
        : rotationEngine.stateFromSnapshot(continuityState);

    final days = rotationEngine.generateMonth(
      year: input.year,
      month: input.month,
      configuration: input.rotation,
      previousState: previousState,
    );

    final staffByTeam = <String, List<StaffMember>>{};
    for (final staff in input.staff) {
      staffByTeam.putIfAbsent(staff.team, () => []).add(staff);
    }
    for (final members in staffByTeam.values) {
      members.sort((a, b) => a.order.compareTo(b.order));
    }

    final assignments = <PlanningAssignmentV2>[];
    for (final day in days) {
      for (final entry in staffByTeam.entries) {
        final theoretical = _shift(day.phaseByTeam[entry.key]);
        for (final staff in entry.value) {
          final leave = input.leaves.any(
            (item) => item.staffId == staff.id && item.covers(day.date),
          );
          assignments.add(
            PlanningAssignmentV2(
              staffId: staff.id,
              date: day.date,
              team: entry.key,
              rotationShift: theoretical,
              effectiveShift: leave ? ShiftType.leave : theoretical,
              rotationCode: day.phaseByTeam[entry.key],
              availabilityCode: leave ? 'LEAVE' : 'AVAILABLE',
              note: leave ? 'Leave does not alter team rotation.' : null,
            ),
          );
        }
      }
    }

    final now = DateTime.now();
    final snapshot = PlanningSnapshot(
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
      continuityDate: assignments.isEmpty ? null : assignments.last.date,
    );

    final finalState = rotationEngine.stateAt(
      configuration: input.rotation,
      date: DateTime(input.year, input.month + 1, 0),
      previousState: previousState,
    );

    return PlanningGenerationResult(
      snapshot: snapshot,
      assignments: List.unmodifiable(assignments),
      rotationState: rotationEngine.snapshotState(
        state: finalState,
        configuration: input.rotation,
      ),
    );
  }

  void _validate(PlanningInput input) {
    if (input.year < 2000 || input.year > 2200) throw ArgumentError('Invalid year');
    if (input.month < 1 || input.month > 12) throw ArgumentError('Invalid month');
    if (input.staff.isEmpty) throw StateError('No staff provided');
    final ids = <int>{};
    for (final staff in input.staff) {
      if (!ids.add(staff.id)) throw StateError('Duplicate staff id: ${staff.id}');
      if (staff.team.trim().isEmpty) throw StateError('Staff ${staff.id} has no team');
    }
    for (final leave in input.leaves) {
      if (!ids.contains(leave.staffId)) {
        throw StateError('Leave references unknown staff: ${leave.staffId}');
      }
      if (leave.endDate.isBefore(leave.startDate)) {
        throw StateError('Leave end date precedes start date');
      }
    }
  }

  ShiftType _shift(String? value) {
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
}

class PlanningGenerationResult {
  final PlanningSnapshot snapshot;
  final List<PlanningAssignmentV2> assignments;
  final RotationStateSnapshot rotationState;

  const PlanningGenerationResult({
    required this.snapshot,
    required this.assignments,
    required this.rotationState,
  });
}
