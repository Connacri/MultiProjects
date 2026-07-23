import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../datasources/objectbox_planning_datasource.dart';

/// Repository implementation used during the legacy-to-Clean-Architecture
/// migration. Existing snapshots are read from ObjectBox and never generated
/// again merely because the architecture changed.
class ObjectBoxPlanningRepository implements PlanningRepository {
  final ObjectBoxPlanningDataSource dataSource;

  const ObjectBoxPlanningRepository(this.dataSource);

  @override
  Future<bool> exists({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return dataSource.findByMonth(
          year: year,
          month: month,
          branchId: branchId,
        ) !=
        null;
  }

  @override
  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return dataSource.findByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
  }

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final snapshots = dataSource.findPublishedBefore(
      year: year,
      month: month,
      branchId: branchId,
    );
    return snapshots.isEmpty ? null : snapshots.first;
  }

  @override
  Future<void> publish(PlanningSnapshot snapshot) async {
    throw UnimplementedError(
      'Publishing through the new repository is intentionally disabled until '
      'the ObjectBox schema migration and atomic write transaction are in place.',
    );
  }
}
