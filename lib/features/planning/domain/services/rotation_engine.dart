import '../entities/rotation_configuration.dart';
import '../enums/shift_type.dart';

/// Pure deterministic team rotation engine.
///
/// The engine knows nothing about Flutter, Provider, ObjectBox or Supabase.
/// A published planning is never recalculated by this service.
class RotationEngine {
  const RotationEngine();

  ShiftType shiftFor({
    required String team,
    required DateTime date,
    required RotationConfiguration configuration,
  }) {
    final teamIndex = configuration.teamOrder.indexOf(team);
    if (teamIndex < 0) {
      throw ArgumentError.value(team, 'team', 'Team is not in configuration');
    }

    final days = _dateOnly(date)
        .difference(_dateOnly(configuration.referenceDate))
        .inDays;
    final phase = _floorMod(
      configuration.referencePhaseIndex + days - teamIndex,
      configuration.cycle.length,
    );
    return configuration.cycle[phase];
  }

  Map<String, ShiftType> shiftsForDate({
    required DateTime date,
    required RotationConfiguration configuration,
  }) {
    return Map.unmodifiable({
      for (final team in configuration.teamOrder)
        team: shiftFor(
          team: team,
          date: date,
          configuration: configuration,
        ),
    });
  }

  List<Map<String, ShiftType>> generateMonth({
    required int year,
    required int month,
    required RotationConfiguration configuration,
  }) {
    final days = DateTime(year, month + 1, 0).day;
    return List.unmodifiable([
      for (var day = 1; day <= days; day++)
        shiftsForDate(
          date: DateTime(year, month, day),
          configuration: configuration,
        ),
    ]);
  }

  int _floorMod(int value, int modulus) {
    final remainder = value % modulus;
    return remainder < 0 ? remainder + modulus : remainder;
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
}
