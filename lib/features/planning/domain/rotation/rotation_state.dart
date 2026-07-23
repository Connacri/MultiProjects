class RotationState {
  final int phaseIndex;

  const RotationState({
    required this.phaseIndex,
  });

  RotationState advance(int days, int cycleLength) {
    return RotationState(
      phaseIndex: (phaseIndex + days) % cycleLength,
    );
  }
}
