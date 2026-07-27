/// Persistence DTO for a monthly planning snapshot.
///
/// This model is intentionally separate from the domain snapshot. The
/// ObjectBox adapter can map it to a generated entity without leaking
/// persistence annotations into the domain layer.
class PlanningSnapshotRecord {
  final int id;
  final String cacheKey;
  final int? branchId;
  final int year;
  final int month;
  final String configurationId;
  final int configurationVersion;
  final String engineVersion;
  final int revision;
  final int status;
  final int createdAtEpochMs;
  final int? publishedAtEpochMs;
  final int? continuityStateId;

  const PlanningSnapshotRecord({
    required this.id,
    required this.cacheKey,
    required this.branchId,
    required this.year,
    required this.month,
    required this.configurationId,
    required this.configurationVersion,
    required this.engineVersion,
    required this.revision,
    required this.status,
    required this.createdAtEpochMs,
    required this.publishedAtEpochMs,
    required this.continuityStateId,
  });
}
