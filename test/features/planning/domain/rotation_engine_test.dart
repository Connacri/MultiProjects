import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/rotation_configuration.dart';
import 'package:multi_projects/features/planning/domain/entities/rotation_state.dart';
import 'package:multi_projects/features/planning/domain/enums/rotation_policy.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/domain/services/rotation_engine.dart';

void main() {
  const engine = RotationEngine();

  RotationConfiguration configuration({
    List<String> order = const ['A', 'B', 'C', 'D'],
    int version = 1,
  }) {
    return RotationConfiguration(
      id: 'four-team',
      version: version,
      teamOrder: order,
      cycle: const [
        ShiftType.day,
        ShiftType.night,
        ShiftType.rest,
        ShiftType.rest,
      ],
      policy: RotationPolicy.continueFromPreviousPublished,
      referenceDate: DateTime(2026, 1, 1),
    );
  }

  test('default order generates the expected initial four-team phases', () {
    final result = engine.shiftsForDate(
      date: DateTime(2026, 1, 1),
      configuration: configuration(),
    );

    expect(result['A'], ShiftType.day);
    expect(result['B'], ShiftType.night);
    expect(result['C'], ShiftType.rest);
    expect(result['D'], ShiftType.rest);
  });

  test('reordering teams changes only the configured reference mapping', () {
    final result = engine.shiftsForDate(
      date: DateTime(2026, 1, 1),
      configuration: configuration(order: ['A', 'C', 'D', 'B'], version: 2),
    );

    expect(result['A'], ShiftType.day);
    expect(result['C'], ShiftType.night);
    expect(result['D'], ShiftType.rest);
    expect(result['B'], ShiftType.rest);
  });

  test('continuity follows team identity after team order changes', () {
    final previous = RotationState(
      date: DateTime(2026, 1, 31),
      shifts: const {
        'A': ShiftType.day,
        'B': ShiftType.night,
        'C': ShiftType.rest,
        'D': ShiftType.rest,
      },
    );

    final result = engine.shiftsForDate(
      date: DateTime(2026, 2, 1),
      configuration: configuration(order: ['A', 'C', 'D', 'B'], version: 2),
      continuity: previous,
    );

    // The order changed, but the teams continue from their own phases.
    expect(result['A'], ShiftType.night);
    expect(result['B'], ShiftType.rest);
    expect(result['C'], ShiftType.rest);
    expect(result['D'], ShiftType.day);
  });

  test('continuity advances correctly across a 28-day February', () {
    final previous = RotationState(
      date: DateTime(2026, 1, 31),
      shifts: const {'A': ShiftType.day},
    );

    final result = engine.shiftFor(
      team: 'A',
      date: DateTime(2026, 2, 28),
      configuration: configuration(),
      continuity: previous,
    );

    // 28 days after Jan 31: 27 modulo 4 = 3.
    expect(result, ShiftType.rest);
  });

  test('continuity advances correctly across leap-year February', () {
    final previous = RotationState(
      date: DateTime(2028, 1, 31),
      shifts: const {'A': ShiftType.day},
    );

    final result = engine.shiftFor(
      team: 'A',
      date: DateTime(2028, 2, 29),
      configuration: configuration(),
      continuity: previous,
    );

    // 29 days after Jan 31: 28 modulo 4 = 0.
    expect(result, ShiftType.day);
  });

  test('same-day continuity does not advance the phase', () {
    final previous = RotationState(
      date: DateTime(2026, 2, 1),
      shifts: const {'A': ShiftType.night},
    );

    final result = engine.shiftFor(
      team: 'A',
      date: DateTime(2026, 2, 1),
      configuration: configuration(),
      continuity: previous,
    );

    expect(result, ShiftType.night);
  });
}
