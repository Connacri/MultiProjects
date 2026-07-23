import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';

class LoadPlanning {
  final PlanningRepository repository;

  const LoadPlanning(this.repository);

  Future<PlanningSnapshot?> call({
    required int year,
    required int month,
    int? branchId,
  }) {
    return repository.findByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
  }
}
