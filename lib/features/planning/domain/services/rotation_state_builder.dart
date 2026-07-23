import '../entities/planning_snapshot.dart';
import '../entities/rotation_configuration_v2.dart';
import '../entities/rotation_state_snapshot.dart';
import 'rotation_engine_v2.dart';

/// Builds the exact continuity state that belongs to a published snapshot.
///
/// This state is derived once at publication time and stored with the
/// snapshot. Future months can resume from it without reinterpreting historical
/// assignments or depending on today's configuration.
class RotationStateBuilder {
  final RotationEngineV2 engine;

  const RotationStateBuilder({this.engine = const RotationEngineV2()});

  RotationStateSnapshot build({
    required PlanningSnapshot snapshot,
    required RotationConfigurationV2 configuration,
  }) {
    if (snapshot.assignments.isEmpty) {
      throw StateError('Cannot build rotation state from an empty snapshot.');
    }

    final lastDate = snapshot.assignments
        .map((item) => item.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final state = engine.stateAt(
      configuration: configuration,
      date: lastDate,
      previousState: null,
    );

    final teamPhase = <String, int>{
      ...state.teamPhaseByTeam,
    };

    for (final team in configuration.teamOrder) {
      final assignment = snapshot.assignments
          .where((item) => item.team == team && _sameDay(item.date, lastDate))
          .toList();
      if (assignment.isEmpty) continue;

      final index = configuration.cycle.indexOf(assignment.first.shift.name);
      if (index >= 0) teamPhase[team] = index;
    }

    return RotationStateSnapshot(
      date: DateTime(lastDate.year, lastDate.month, lastDate.day),
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      phaseIndex: state.phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(teamPhase),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
