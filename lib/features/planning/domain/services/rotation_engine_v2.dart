import '../entities/rotation_configuration_v2.dart';
import '../entities/rotation_state_v2.dart';
import '../entities/rotation_state_snapshot.dart';

class RotationDayV2 {
  final DateTime date;
  final Map<String, String> phaseByTeam;

  const RotationDayV2({required this.date, required this.phaseByTeam});
}

/// Pure deterministic rotation engine. It has no Flutter, ObjectBox or staff
/// dependencies. Staff availability is applied by the generation use case.
class RotationEngineV2 {
  const RotationEngineV2();

  List<RotationDayV2> generateMonth({
    required int year,
    required int month,
    required RotationConfigurationV2 configuration,
    RotationStateV2? previousState,
  }) {
    if (configuration.cycle.isEmpty) {
      throw ArgumentError.value(configuration.cycle, 'cycle', 'Cannot be empty');
    }
    if (configuration.teamOrder.isEmpty) {
      throw ArgumentError.value(configuration.teamOrder, 'teamOrder', 'Cannot be empty');
    }

    final first = DateTime(year, month, 1);
    final count = DateTime(year, month + 1, 0).day;
    final startPhase = _resolveStartPhase(first, configuration, previousState);

    return List.generate(count, (index) {
      final date = DateTime(year, month, index + 1);
      final dayPhase = _mod(startPhase + index, configuration.cycle.length);
      final phases = <String, String>{};

      for (var teamIndex = 0; teamIndex < configuration.teamOrder.length; teamIndex++) {
        final team = configuration.teamOrder[teamIndex];
        final phase = _mod(dayPhase + teamIndex, configuration.cycle.length);
        phases[team] = configuration.cycle[phase];
      }

      return RotationDayV2(date: date, phaseByTeam: Map.unmodifiable(phases));
    });
  }

  RotationStateV2 stateAt({
    required RotationConfigurationV2 configuration,
    required DateTime date,
    RotationStateV2? previousState,
  }) {
    final phase = _resolveStartPhase(date, configuration, previousState);
    return RotationStateV2(
      date: _day(date),
      phaseIndex: phase,
      teamPhaseByTeam: Map.unmodifiable({
        for (var i = 0; i < configuration.teamOrder.length; i++)
          configuration.teamOrder[i] =>
              _mod(phase + i, configuration.cycle.length),
      }),
    );
  }

  RotationStateV2 stateFromSnapshot(RotationStateSnapshot snapshot) {
    return RotationStateV2(
      date: _day(snapshot.date),
      phaseIndex: snapshot.phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(snapshot.teamPhaseByTeam),
    );
  }

  RotationStateSnapshot snapshotState({
    required RotationStateV2 state,
    required RotationConfigurationV2 configuration,
  }) {
    return RotationStateSnapshot(
      date: _day(state.date),
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      phaseIndex: state.phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(state.teamPhaseByTeam),
    );
  }

  int _resolveStartPhase(
    DateTime target,
    RotationConfigurationV2 configuration,
    RotationStateV2? previousState,
  ) {
    if (previousState != null) {
      final delta = _day(target).difference(_day(previousState.date)).inDays;
      return _mod(previousState.phaseIndex + delta, configuration.cycle.length);
    }

    final delta = _day(target).difference(_day(configuration.referenceDate)).inDays;
    return _mod(configuration.referencePhaseIndex + delta, configuration.cycle.length);
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  int _mod(int value, int divisor) => ((value % divisor) + divisor) % divisor;
}
