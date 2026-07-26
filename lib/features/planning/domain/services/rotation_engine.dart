import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../enums/team_shift.dart';

/// Pure, deterministic rotation engine.
///
/// No persistence, UI or ObjectBox dependency is allowed here. Given the same
/// configuration, date and continuity state, the result is deterministic.
class RotationEngine {
  const RotationEngine();

  Map<String, TeamShift> shiftsForDate({
    required RotationConfiguration configuration,
    required DateTime date,
    RotationState? continuity,
  }) {
    if (configuration.teamOrder.isEmpty) {
      return const <String, TeamShift>{};
    }
    if (configuration.cycle.isEmpty) {
      throw ArgumentError.value(
        configuration.cycle,
        'configuration.cycle',
        'Rotation cycle cannot be empty.',
      );
    }

    final referenceDate = _dateOnly(
      continuity?.date ?? configuration.referenceDate ?? date,
    );
    final targetDate = _dateOnly(date);
    final dayOffset = targetDate.difference(referenceDate).inDays;
    final cycleLength = configuration.cycle.length;
    final continuityOffset = continuity?.phaseIndex ?? 0;

    return {
      for (var teamIndex = 0;
          teamIndex < configuration.teamOrder.length;
          teamIndex++)
        configuration.teamOrder[teamIndex]: configuration.cycle[
          _floorMod(
            configuration.referenceTeamIndex +
                teamIndex +
                continuityOffset +
                dayOffset,
            cycleLength,
          )
        ],
    };
  }

  int _floorMod(int value, int modulus) {
    final remainder = value % modulus;
    return remainder < 0 ? remainder + modulus : remainder;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
