import 'package:flutter_test/flutter_test.dart';
import 'package:multi_projects/features/planning/domain/entities/rotation_configuration.dart';
import 'package:multi_projects/features/planning/domain/enums/rotation_policy.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/domain/services/rotation_engine.dart';
import 'package:multi_projects/features/planning/domain/services/team_schedule_generator.dart';

void main() {
  const configuration = RotationConfiguration(
    id: 'test',
    version: 1,
    teamOrder: ['A', 'B', 'C', 'D'],
    cycle: [ShiftType.day, ShiftType.night, ShiftType.rest, ShiftType.rest],
    policy: RotationPolicy.fixedReference,
    referenceDate: DateTime(2026, 1, 1),
  );

  const generator = TeamScheduleGenerator(RotationEngine());

  test('generates team schedule once per date', () {
    final result = generator.generateMonth(
      year: 2026,
      month: 1,
      configuration: configuration,
    );

    expect(result, hasLength(31));
    expect(result[DateTime(2026, 1, 1)]!['A'], ShiftType.day);
    expect(result[DateTime(2026, 1, 1)]!['D'], ShiftType.night);
  });

  test('projects team schedule to staff without recalculating rotation', () {
    final schedule = generator.generateMonth(
      year: 2026,
      month: 1,
      configuration: configuration,
    );

    final assignments = generator.projectStaff(
      staffIds: [1, 2, 3],
      staffTeams: {1: 'A', 2: 'B', 3: 'D'},
      schedule: schedule,
    );

    expect(assignments, hasLength(93));
    expect(assignments.first.staffId, 1);
    expect(assignments.first.team, 'A');
    expect(assignments.first.shift, ShiftType.day);
  });
}
