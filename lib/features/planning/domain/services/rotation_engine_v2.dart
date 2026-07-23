import '../entities/rotation_configuration_v2.dart';
import '../entities/rotation_state_v2.dart';

class RotationDayV2 {
  final DateTime date;
  final Map<String, String> phaseByTeam;

  const RotationDayV2({required this.date, required this.phaseByTeam});
}

/// Pure deterministic rotation engine.
///
/// The engine does not know about ObjectBox, Flutter or Staff. It only maps a
/// date and a configuration to team phases. The cycle is continuous across
/// calendar boundaries by using the configured reference date and phase.
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
      final dayPhase = (startPhase + index) % configuration.cycle.length;
      final phases = <String, String>{};

      for (var teamIndex = 0; teamIndex < configuration.teamOrder.length; teamIndex++) {
        final team = configuration.teamOrder[teamIndex];
        final phase = (dayPhase + teamIndex) % configuration.cycle.length;
        phases[team] = configuration.cycle[phase];
      }

      return RotationDayV2(date: date, phaseByTeam: Map.unmodifiable(phases));
    });
  }

  RotationStateV2 stateAt({
    required RotationConfigurationV2 configuration,
    required DateTime date,
    required RotationStateV2? previousState,
  }) {
    final phase = _resolveStartPhase(date, configuration, previousState);
    final map = <String, int>{};
    for (var i = 0; i < configuration.teamOrder.length; i++) {
      map[configuration.teamOrder[i]] =
          (phase + i) % configuration.cycle.length;
    }
    return RotationStateV2(
      date: DateTime(date.year, date.month, date.day),
      phaseIndex: phase,
      teamPhaseByTeam: Map.unmodifiable(map),
    );
  }

  int _resolveStartPhase(
    DateTime target,
    RotationConfigurationV2 configuration,
    RotationStateV2? previousState,
  ) {
    if (previousState != null) {
      final delta = DateTime(target.year, target.month, target.day)
          .difference(DateTime(
            previousState.date.year,
            previousState.date.month,
            previousState.date.day,
          ))
          .inDays;
      return _mod(previousState.phaseIndex + delta, configuration.cycle.length);
    }

    final delta = DateTime(target.year, target.month, target.day)
        .difference(DateTime(
          configuration.referenceDate.year,
          configuration.referenceDate.month,
          configuration.referenceDate.day,
        ))
        .inDays;
    return _mod(configuration.referencePhaseIndex + delta, configuration.cycle.length);
  }

  int _mod(int value, int divisor) => ((value % divisor) + divisor) % divisor;
}
