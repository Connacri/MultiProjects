class RotationStateV2 {
  final DateTime date;
  final int phaseIndex;
  final Map<String, int> teamPhaseByTeam;

  const RotationStateV2({
    required this.date,
    required this.phaseIndex,
    required this.teamPhaseByTeam,
  });

  RotationStateV2 copyWith({
    DateTime? date,
    int? phaseIndex,
    Map<String, int>? teamPhaseByTeam,
  }) {
    return RotationStateV2(
      date: date ?? this.date,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(
        teamPhaseByTeam ?? this.teamPhaseByTeam,
      ),
    );
  }
}
