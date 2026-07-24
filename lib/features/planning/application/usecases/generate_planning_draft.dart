import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/rotation_state_snapshot.dart';
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
    final exists = await planningRepository.findLatestByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );

    if (exists != null) {
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
    final date = DateTime(year, month, DateTime(year, month + 1, 0).day);
    final rotationState = _buildRotationStateSnapshot(
      date: date,
      configuration: configuration,
      teamShifts: teamShifts.isEmpty ? const <String, dynamic>{} : teamShifts.last,
    );

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
      continuityDate: rotationState.date,
      rotationState: rotationState,
      assignments: const [],
    );
  }

  RotationStateSnapshot _buildRotationStateSnapshot({
    required DateTime date,
    required RotationConfiguration configuration,
    required Map<String, dynamic> teamShifts,
  }) {
    final teamPhaseByTeam = <String, int>{};
    for (final team in configuration.teamOrder) {
      final shift = teamShifts[team];
      if (shift is! String) continue;
      final index = configuration.cycle.indexWhere((item) => item.name == shift);
      if (index >= 0) {
        teamPhaseByTeam[team] = index;
      }
    }

    final referenceOnly = DateTime(
      configuration.referenceDate.year,
      configuration.referenceDate.month,
      configuration.referenceDate.day,
    );
    final dateOnly = DateTime(date.year, date.month, date.day);
    final phaseIndex = _floorMod(
      configuration.referencePhaseIndex +
          dateOnly.difference(referenceOnly).inDays,
      configuration.cycle.length,
    );

    return RotationStateSnapshot(
      date: dateOnly,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      phaseIndex: phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(teamPhaseByTeam),
    );
  }

  int _floorMod(int value, int modulus) {
    final remainder = value % modulus;
    return remainder < 0 ? remainder + modulus : remainder;
  }
}
