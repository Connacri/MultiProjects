import 'package:flutter_test/flutter_test.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';

void main() {
  const validator = PlanningValidator();

  PlanningSnapshot snapshotWith(List<PlanningAssignment> assignments) {
    return PlanningSnapshot(
      id: 'snapshot-1',
      year: 2026,
      month: 1,
      configurationId: 'config-1',
      configurationVersion: 1,
      engineVersion: '2.0.0',
      revision: 1,
      createdAt: DateTime(2026, 1, 1),
      assignments: assignments,
    );
  }

  test('accepts unique assignments inside the snapshot month', () {
    final result = validator.validate(snapshotWith([
      const PlanningAssignment(
        staffId: 1,
        date: DateTime(2026, 1, 1),
        team: 'A',
        shift: ShiftType.day,
      ),
      const PlanningAssignment(
        staffId: 1,
        date: DateTime(2026, 1, 2),
        team: 'A',
        shift: ShiftType.night,
      ),
    ]));

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('rejects duplicate staff/date assignments', () {
    final result = validator.validate(snapshotWith([
      const PlanningAssignment(
        staffId: 1,
        date: DateTime(2026, 1, 1),
        team: 'A',
        shift: ShiftType.day,
      ),
      const PlanningAssignment(
        staffId: 1,
        date: DateTime(2026, 1, 1),
        team: 'B',
        shift: ShiftType.night,
      ),
    ]));

    expect(result.isValid, isFalse);
    expect(result.errors, hasLength(1));
  });

  test('rejects assignments outside the snapshot month', () {
    final result = validator.validate(snapshotWith([
      const PlanningAssignment(
        staffId: 1,
        date: DateTime(2026, 2, 1),
        team: 'A',
        shift: ShiftType.day,
      ),
    ]));

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('outside snapshot period'));
  });

  test('empty snapshot is valid but emits a warning', () {
    final result = validator.validate(snapshotWith(const []));

    expect(result.isValid, isTrue);
    expect(result.warnings, hasLength(1));
  });
}
