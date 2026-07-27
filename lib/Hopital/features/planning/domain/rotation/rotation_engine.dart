import 'rotation_rule.dart';
import 'rotation_state.dart';
import 'shift_type.dart';

class RotationEngine {
  const RotationEngine();

  ShiftType calculate({
    required RotationRule rule,
    required RotationState state,
    required int dayIndex,
  }) {
    final index = (state.phaseIndex + dayIndex) % rule.cycleLength;

    return rule.phases[index].shift;
  }

  RotationState nextMonthState({
    required RotationRule rule,
    required RotationState current,
    required int daysInMonth,
  }) {
    return current.advance(
      daysInMonth,
      rule.cycleLength,
    );
  }
}
