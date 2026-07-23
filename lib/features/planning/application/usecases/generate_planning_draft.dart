import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/rotation_period.dart';
import '../../domain/repositories/planning_repository.dart';
import '../../domain/services/rotation_engine.dart';

class PlanningAlreadyExistsException implements Exception {
  final int year;
  final int month;

  const PlanningAlreadyExistsException(this.year, this.month);

  @override
  String toString() => 'Planning already exists for $year-$month';
}

/// Generates a new draft only when no published snapshot exists for the month.
/// This use case deliberately does not persist or publish anything.
class GeneratePlanningDraft {
  final PlanningRepository planningRepository;
  final RotationEngine rotationEngine;

  const GeneratePlanningDraft({
    required this.planningRepository,
    required this.rotationEngine,
  });

  Future<PlanningSnapshot> call({
    required int year,
    required int month,
    required RotationConfiguration configuration,
    RotationPeriod? rotationPeriod,
    int? branchId,
    String engineVersion = '2.0.0',
  }) async {
    final exists = await planningRepository.exists(
      year: year,
      month: month,
      branchId: branchId,
    );

    if (exists) {
      throw PlanningAlreadyExistsException(year, month);
    }

    final teamShifts = rotationEngine.generateMonth(
      year: year,
      month: month,
      configuration: configuration,
    );

    // The team-level result is intentionally not converted to staff assignments
    // here. Staff projection and exceptions belong to the generator layer.
    // This first draft establishes the immutable snapshot metadata and keeps
    // the domain boundary explicit.
    return PlanningSnapshot(
      id: 'draft-$year-$month-${DateTime.now().microsecondsSinceEpoch}',
      year: year,
      month: month,
      branchId: branchId,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      rotationPeriodId: rotationPeriod?.id,
      engineVersion: engineVersion,
      revision: 1,
      createdAt: DateTime.now(),
      assignments: const [],
    );
  }
}
