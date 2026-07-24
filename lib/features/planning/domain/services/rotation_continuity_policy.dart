import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../enums/rotation_policy.dart';

/// Defines whether the previous published month must be used as the starting
/// state for the next month.
class RotationContinuityPolicy {
  const RotationContinuityPolicy();

  bool shouldContinue(RotationConfiguration configuration) {
    return configuration.policy == RotationPolicy.continueFromPreviousPublished;
  }

  RotationState? normalize({
    required RotationConfiguration configuration,
    required RotationState? previous,
  }) {
    if (!shouldContinue(configuration)) return null;
    return previous;
  }
}
