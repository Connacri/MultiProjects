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
    return dataSource.exists(
      year: year,
      month: month,
      branchId: branchId,
    );
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
    return dataSource.findPreviousPublished(
      year: year,
      month: month,
      branchId: branchId,
    );
  }

  @override
  Future<void> publish(PlanningSnapshot snapshot) async {
    await dataSource.publish(snapshot);
  }
}
