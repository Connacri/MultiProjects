import 'package:flutter_test/flutter_test.dart';

import 'package:kenzy/features/planning/domain/entities/rotation_configuration.dart';
import 'package:kenzy/features/planning/domain/entities/rotation_state.dart';
import 'package:kenzy/features/planning/domain/enums/rotation_policy.dart';
import 'package:kenzy/features/planning/domain/enums/shift_type.dart';
import 'package:kenzy/features/planning/domain/services/rotation_engine.dart';

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
      policy: RotationPolicy.sequential,
    );
  }

  test('team order is preserved in rotation configuration', () {
    final config = configuration(order: const ['A', 'C', 'D', 'B']);

    expect(config.teamOrder, ['A', 'C', 'D', 'B']);
  });

  test('configuration version changes when team order changes', () {
    final first = configuration(version: 1);
    final second = configuration(
      order: const ['A', 'C', 'D', 'B'],
      version: 2,
    );

    expect(first.version, isNot(second.version));
    expect(second.teamOrder, ['A', 'C', 'D', 'B']);
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
      configuration: configuration(order: const ['A', 'C', 'D', 'B'], version: 2),
      continuity: previous,
    );

    expect(result['A'], ShiftType.night);
    expect(result['B'], ShiftType.rest);
    expect(result['C'], ShiftType.day);
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
