import 'package:flutter_test/flutter_test.dart';
import 'package:multi_projects/features/planning/domain/entities/rotation_configuration.dart';
import 'package:multi_projects/features/planning/domain/enums/rotation_policy.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/domain/services/rotation_engine.dart';

void main() {
  const engine = RotationEngine();
  const configuration = RotationConfiguration(
    id: 'test',
    version: 1,
    teamOrder: ['A', 'B', 'C', 'D'],
    cycle: [ShiftType.day, ShiftType.night, ShiftType.rest, ShiftType.rest],
    policy: RotationPolicy.fixedReference,
    referenceDate: DateTime(2026, 1, 1),
  );

  group('RotationEngine v2', () {
    test('matches the canonical four-team rotation on day 1', () {
      final result = engine.shiftsForDate(
        date: DateTime(2026, 1, 1),
        configuration: configuration,
      );

      expect(result['A'], ShiftType.day);
      expect(result['B'], ShiftType.rest);
      expect(result['C'], ShiftType.rest);
      expect(result['D'], ShiftType.night);
    });

    test('matches the canonical four-team rotation on day 2', () {
      final result = engine.shiftsForDate(
        date: DateTime(2026, 1, 2),
        configuration: configuration,
      );

      expect(result['A'], ShiftType.night);
      expect(result['B'], ShiftType.day);
      expect(result['C'], ShiftType.rest);
      expect(result['D'], ShiftType.rest);
    });

    test('matches the canonical four-team rotation on day 3', () {
      final result = engine.shiftsForDate(
        date: DateTime(2026, 1, 3),
        configuration: configuration,
      );

      expect(result['A'], ShiftType.rest);
      expect(result['B'], ShiftType.night);
      expect(result['C'], ShiftType.day);
      expect(result['D'], ShiftType.rest);
    });

    test('matches the canonical four-team rotation on day 4', () {
      final result = engine.shiftsForDate(
        date: DateTime(2026, 1, 4),
        configuration: configuration,
      );

      expect(result['A'], ShiftType.rest);
      expect(result['B'], ShiftType.rest);
      expect(result['C'], ShiftType.night);
      expect(result['D'], ShiftType.day);
    });

    test('repeats the four-day cycle on day 5', () {
      final result = engine.shiftsForDate(
        date: DateTime(2026, 1, 5),
        configuration: configuration,
      );

      expect(result['A'], ShiftType.day);
      expect(result['B'], ShiftType.rest);
      expect(result['C'], ShiftType.rest);
      expect(result['D'], ShiftType.night);
    });

    test('supports a configurable team order', () {
      final custom = configuration.copyWith(teamOrder: ['A', 'C', 'D', 'B']);
      final result = engine.shiftsForDate(
        date: DateTime(2026, 1, 1),
        configuration: custom,
      );

      expect(result['A'], ShiftType.day);
      expect(result['C'], ShiftType.rest);
      expect(result['D'], ShiftType.rest);
      expect(result['B'], ShiftType.night);
    });

    test('supports February leap years', () {
      final result = engine.generateMonth(
        year: 2028,
        month: 2,
        configuration: configuration,
      );

      expect(result, hasLength(29));
    });

    test('supports non-leap February', () {
      final result = engine.generateMonth(
        year: 2027,
        month: 2,
        configuration: configuration,
      );

      expect(result, hasLength(28));
    });

    test('supports 30-day months', () {
      final result = engine.generateMonth(
        year: 2026,
        month: 4,
        configuration: configuration,
      );

      expect(result, hasLength(30));
    });

    test('supports 31-day months', () {
      final result = engine.generateMonth(
        year: 2026,
        month: 1,
        configuration: configuration,
      );

      expect(result, hasLength(31));
    });

    test('rejects an unknown team', () {
      expect(
        () => engine.shiftFor(
          team: 'X',
          date: DateTime(2026, 1, 1),
          configuration: configuration,
        ),
        throwsArgumentError,
      );
    });
  });
}
