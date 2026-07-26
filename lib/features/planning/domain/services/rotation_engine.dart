import '../entities/rotation_configuration.dart';
import '../enums/team_shift.dart';

/// Pure, deterministic rotation engine.
///
/// No persistence, UI or ObjectBox dependency is allowed here. Given the same
/// configuration and date, the result is always identical.
class RotationEngine {
  const RotationEngine();

  Map<String, TeamShift> shiftsForDate({
    required RotationConfiguration configuration,
    required DateTime date,
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
      configuration.referenceDate ?? date,
    );
    final targetDate = _dateOnly(date);
    final dayOffset = targetDate.difference(referenceDate).inDays;
    final cycleLength = configuration.cycle.length;

    return {
      for (var teamIndex = 0;
          teamIndex < configuration.teamOrder.length;
          teamIndex++)
        configuration.teamOrder[teamIndex]: configuration.cycle[
          (configuration.referenceTeamIndex + teamIndex + dayOffset) %
              cycleLength
        ],
    };
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
}
