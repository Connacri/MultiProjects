import '../entities/planning_snapshot.dart';

abstract interface class PlanningRepository {
  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  });

  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  });

  Future<bool> exists({
    required int year,
    required int month,
    int? branchId,
  });

  Future<void> publish(PlanningSnapshot snapshot);
}
