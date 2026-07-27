import '../rotation/rotation_rule.dart';
import '../rotation/rotation_state.dart';

class ContinuityResolver {
  const ContinuityResolver();

  RotationState resolveNextMonth({
    required RotationRule rule,
    required RotationState currentState,
    required int daysInPreviousMonth,
  }) {
    return currentState.advance(
      daysInPreviousMonth,
      rule.cycleLength,
    );
  }
}
