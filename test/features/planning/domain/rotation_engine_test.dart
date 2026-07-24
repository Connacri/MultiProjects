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
}
