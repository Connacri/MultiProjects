import '../entities/planning_assignment.dart';
import '../entities/rotation_configuration.dart';
import '../enums/shift_type.dart';
import 'rotation_engine.dart';

/// Generates the team-level schedule first, then projects it to staff.
///
/// This avoids recalculating the same rotation for every staff member.
class TeamScheduleGenerator {
  final RotationEngine rotationEngine;

  const TeamScheduleGenerator(this.rotationEngine);

  Map<DateTime, Map<String, ShiftType>> generateMonth({
    required int year,
    required int month,
    required RotationConfiguration configuration,
  }) {
    final result = <DateTime, Map<String, ShiftType>>{};
    final days = DateTime(year, month + 1, 0).day;

    for (var day = 1; day <= days; day++) {
      final date = DateTime(year, month, day);
      result[date] = rotationEngine.shiftsForDate(
        date: date,
        configuration: configuration,
      );
    }

    return Map.unmodifiable(result);
  }

  List<PlanningAssignment> projectStaff({
    required List<int> staffIds,
    required Map<int, String> staffTeams,
    required Map<DateTime, Map<String, ShiftType>> schedule,
  }) {
    final assignments = <PlanningAssignment>[];

    for (final entry in schedule.entries) {
      final date = entry.key;
      final teamShifts = entry.value;

      for (final staffId in staffIds) {
        final team = staffTeams[staffId];
        if (team == null) continue;

        final shift = teamShifts[team];
        if (shift == null) continue;

        assignments.add(
          PlanningAssignment(
            staffId: staffId,
            date: date,
            team: team,
            shift: shift,
          ),
        );
      }
    }

    return List.unmodifiable(assignments);
  }
}
