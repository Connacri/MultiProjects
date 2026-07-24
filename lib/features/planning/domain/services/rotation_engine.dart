import '../entities/planning.dart';
import '../entities/rotation_configuration.dart';
import '../enums/shift_type.dart';

/// Pure domain service responsible for deterministic team rotation.
///
/// This service has two interfaces:
/// 1. Legacy methods: rotate(), nextMonth(), previousMonth() for backward compatibility
/// 2. Clean Architecture methods: shiftFor(), shiftsForDate(), generateMonth()
///
/// No Flutter, Provider, ObjectBox or network dependency is allowed here.
/// A published planning is never recalculated by this service.
class RotationEngine {
  const RotationEngine();

  // ============================================================================
  // LEGACY INTERFACE - For backward compatibility
  // ============================================================================

  /// Rotates a team order by one position to obtain the next monthly state.
  ///
  /// Example: A,C,B,D -> C,B,D,A.
  List<String> rotate(List<String> order, {int steps = 1}) {
    if (order.isEmpty) return const [];

    final normalizedSteps = steps % order.length;
    if (normalizedSteps == 0) return List.unmodifiable(order);

    return List.unmodifiable([
      ...order.skip(normalizedSteps),
      ...order.take(normalizedSteps),
    ]);
  }

  /// Computes the next month's rotation while keeping the day/night orders
  /// independently controlled.
  Planning nextMonth(Planning current) {
    return current.copyWith(
      year: current.month == 12 ? current.year + 1 : current.year,
      month: current.month == 12 ? 1 : current.month + 1,
      dayTeamOrder: rotate(current.dayTeamOrder),
      nightTeamOrder: rotate(current.nightTeamOrder),
      assignments: const [],
    );
  }

  /// Computes the previous month's rotation.
  Planning previousMonth(Planning current) {
    return current.copyWith(
      year: current.month == 1 ? current.year - 1 : current.year,
      month: current.month == 1 ? 12 : current.month - 1,
      dayTeamOrder: rotate(current.dayTeamOrder, steps: current.dayTeamOrder.length - 1),
      nightTeamOrder:
          rotate(current.nightTeamOrder, steps: current.nightTeamOrder.length - 1),
      assignments: const [],
    );
  }

  // ============================================================================
  // CLEAN ARCHITECTURE INTERFACE - New deterministic engine
  // ============================================================================

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
