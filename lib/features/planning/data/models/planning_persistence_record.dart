/// Persistence-neutral record for the legacy monthly planning snapshot.
///
/// This record intentionally preserves the original `Planification` payload.
/// It is a migration boundary: legacy snapshots are read as-is and mapped to
/// the domain without invoking the rotation engine.
class PlanningPersistenceRecord {
  final int id;
  final int month;
  final int year;
  final String teamOrder;
  final int? branchId;
  final String? snapshotJson;

  const PlanningPersistenceRecord({
    required this.id,
    required this.month,
    required this.year,
    required this.teamOrder,
    required this.branchId,
    required this.snapshotJson,
  });

  String get monthKey =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
}
