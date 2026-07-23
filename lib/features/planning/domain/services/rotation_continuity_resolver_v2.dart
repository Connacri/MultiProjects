import '../entities/rotation_configuration_v2.dart';
import '../entities/rotation_state_v2.dart';
import '../repositories/planning_repository.dart';
import 'rotation_engine_v2.dart';

class RotationContinuityResolverV2 {
  final PlanningRepository repository;
  final RotationEngineV2 engine;

  const RotationContinuityResolverV2({
    required this.repository,
    this.engine = const RotationEngineV2(),
  });

  Future<RotationStateV2?> resolve({
    required DateTime targetDate,
    required RotationConfigurationV2 configuration,
    int? branchId,
  }) async {
    final previous = await repository.findPreviousPublished(
      year: targetDate.year,
      month: targetDate.month,
      branchId: branchId,
    );

    if (previous == null || previous.assignments.isEmpty) return null;

    final lastDate = previous.assignments
        .map((a) => a.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final lastTeamPhases = <String, int>{};
    for (final team in configuration.teamOrder) {
      final assignment = previous.assignments
          .where((a) => a.team == team && _sameDay(a.date, lastDate))
          .cast<dynamic>()
          .toList();
      if (assignment.isNotEmpty) {
        final shift = assignment.first.shift.name;
        final index = configuration.cycle.indexOf(shift);
        if (index >= 0) lastTeamPhases[team] = index;
      }
    }

    final base = engine.stateAt(
      configuration: configuration,
      date: lastDate,
      previousState: null,
    );

    return RotationStateV2(
      date: lastDate,
      phaseIndex: base.phaseIndex,
      teamPhaseByTeam: lastTeamPhases.isEmpty
          ? base.teamPhaseByTeam
          : Map.unmodifiable(lastTeamPhases),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
