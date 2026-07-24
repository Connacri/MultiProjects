import 'package:flutter_test/flutter_test.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_override.dart';
import 'package:multi_projects/features/planning/domain/entities/staff_availability.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/domain/services/planning_draft_pipeline.dart';

void main() {
  const pipeline = PlanningDraftPipeline();

  test('availability is applied before manual override', () {
    final baseline = [
      const PlanningAssignment(
        staffId: 1,
        date: DateTime(2026, 1, 5),
        team: 'A',
        shift: ShiftType.day,
      ),
    ];

    final result = pipeline.process(
      baseline: baseline,
      availability: [
        const StaffAvailability(
          staffId: 1,
          startDate: DateTime(2026, 1, 5),
          endDate: DateTime(2026, 1, 5),
          type: StaffAvailabilityType.leave,
        ),
      ],
      overrides: [
        const PlanningOverride(
          staffId: 1,
          date: DateTime(2026, 1, 5),
          shift: ShiftType.night,
          code: 'MANUAL',
        ),
      ],
    );

    expect(result.single.shift, ShiftType.night);
    expect(result.single.code, 'MANUAL');
    expect(result.single.team, 'A');
  });

  test('availability does not alter the team baseline', () {
    final result = pipeline.process(
      baseline: [
        const PlanningAssignment(
          staffId: 1,
          date: DateTime(2026, 1, 5),
          team: 'C',
          shift: ShiftType.night,
        ),
      ],
      availability: [
        const StaffAvailability(
          staffId: 1,
          startDate: DateTime(2026, 1, 5),
          endDate: DateTime(2026, 1, 5),
          type: StaffAvailabilityType.sickLeave,
        ),
      ],
      overrides: const [],
    );

    expect(result.single.team, 'C');
    expect(result.single.shift, ShiftType.night);
    expect(result.single.code, 'CM');
  });
}
