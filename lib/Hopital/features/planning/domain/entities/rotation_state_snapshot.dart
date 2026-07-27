class RotationStateSnapshot {
  final DateTime date;
  final String configurationId;
  final int configurationVersion;
  final int phaseIndex;
  final Map<String, int> teamPhaseByTeam;

  const RotationStateSnapshot({
    required this.date,
    required this.configurationId,
    required this.configurationVersion,
    required this.phaseIndex,
    required this.teamPhaseByTeam,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'configurationId': configurationId,
        'configurationVersion': configurationVersion,
        'phaseIndex': phaseIndex,
        'teamPhaseByTeam': teamPhaseByTeam,
      };

  factory RotationStateSnapshot.fromJson(Map<String, dynamic> json) {
    return RotationStateSnapshot(
      date: DateTime.parse(json['date'] as String),
      configurationId: json['configurationId'] as String,
      configurationVersion: json['configurationVersion'] as int,
      phaseIndex: json['phaseIndex'] as int,
      teamPhaseByTeam: Map<String, int>.from(
        (json['teamPhaseByTeam'] as Map).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      ),
    );
  }
}
