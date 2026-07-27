class PlanningSnapshotModel {
  final String id;
  final int year;
  final int month;
  final String status;
  final String rotationVersion;
  final DateTime createdAt;

  const PlanningSnapshotModel({
    required this.id,
    required this.year,
    required this.month,
    required this.status,
    required this.rotationVersion,
    required this.createdAt,
  });

  bool get isPublished => status == 'PUBLISHED';
}
