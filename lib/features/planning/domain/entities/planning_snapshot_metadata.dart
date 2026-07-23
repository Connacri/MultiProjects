class PlanningSnapshotMetadata {
  final int id;
  final int? branchId;
  final int year;
  final int month;
  final String configurationId;
  final int configurationVersion;
  final String engineVersion;
  final int revision;
  final PlanningSnapshotStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final int? continuityStateId;

  const PlanningSnapshotMetadata({
    required this.id,
    required this.branchId,
    required this.year,
    required this.month,
    required this.configurationId,
    required this.configurationVersion,
    required this.engineVersion,
    required this.revision,
    required this.status,
    required this.createdAt,
    required this.publishedAt,
    required this.continuityStateId,
  });

  bool get isPublished => status == PlanningSnapshotStatus.published;

  String get cacheKey =>
      'branch:${branchId ?? 0}|$year|${month.toString().padLeft(2, '0')}|'
      '$configurationId|$configurationVersion';
}

enum PlanningSnapshotStatus {
  draft,
  validated,
  published,
  archived,
}
