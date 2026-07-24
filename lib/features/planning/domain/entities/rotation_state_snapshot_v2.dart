class RotationStateSnapshotV2 {
  final DateTime date;
  final String configurationId;
  final int configurationVersion;
  final int phaseIndex;
  final Map<String, int> teamPhaseByTeam;

  const RotationStateSnapshotV2({
    required this.date,
    required this.configurationId,
    required this.configurationVersion,
    required this.phaseIndex,
    required this.teamPhaseByTeam,
  });
}
