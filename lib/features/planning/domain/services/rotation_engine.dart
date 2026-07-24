import '../entities/planning.dart';
import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../enums/shift_type.dart';

/// Pure domain service responsible for deterministic team rotation.
///
/// Team identity is the continuity key. `teamOrder` only defines the current
/// configured ordering and must never reinterpret a previously published
/// team's phase when the user reorders teams.
///
/// No Flutter, Provider, ObjectBox or network dependency is allowed here.
class RotationEngine {
  const RotationEngine();

  List<String> rotate(List<String> order, {int steps = 1}) {
    if (order.isEmpty) return const [];
    final normalizedSteps = steps % order.length;
    if (normalizedSteps == 0) return List.unmodifiable(order);
    return List.unmodifiable([
      ...order.skip(normalizedSteps),
      ...order.take(normalizedSteps),
    ]);
  }

  Planning nextMonth(Planning current) {
    return current.copyWith(
      year: current.month == 12 ? current.year + 1 : current.year,
      month: current.month == 12 ? 1 : current.month + 1,
      dayTeamOrder: rotate(current.dayTeamOrder),
      nightTeamOrder: rotate(current.nightTeamOrder),
      assignments: const [],
    );
  }

  Planning previousMonth(Planning current) {
    return current.copyWith(
      year: current.month == 1 ? current.year - 1 : current.year,
      month: current.month == 1 ? 12 : current.month - 1,
      dayTeamOrder:
          rotate(current.dayTeamOrder, steps: current.dayTeamOrder.length - 1),
      nightTeamOrder: rotate(current.nightTeamOrder,
          steps: current.nightTeamOrder.length - 1),
      assignments: const [],
    );
  }

  /// Returns the shift for a team on a date.
  ///
  /// With [continuity], the team's own previously published shift is the
  /// authoritative anchor. The team's position in `teamOrder` is ignored for
  /// continuation, so reordering teams cannot silently change their phases.
  ShiftType shiftFor({
    required String team,
    required DateTime date,
    required RotationConfiguration configuration,
    RotationState? continuity,
  }) {
    if (!configuration.teamOrder.contains(team)) {
      throw ArgumentError.value(team, 'team', 'Team is not in configuration');
    }
    if (configuration.cycle.isEmpty) {
      throw StateError('Rotation cycle cannot be empty');
    }

    final previousShift = continuity?.shiftFor(team);
    if (previousShift != null && continuity != null) {
      final days =
          _dateOnly(date).difference(_dateOnly(continuity.date)).inDays;
      final previousPhase = configuration.cycle.indexOf(previousShift);
      if (previousPhase >= 0 && days >= 1) {
        return configuration
            .cycle[_floorMod(previousPhase + days, configuration.cycle.length)];
      }
      if (days == 0) return previousShift;
    }

    return _shiftFromReference(
      team: team,
      date: date,
      configuration: configuration,
    );
  }

  Map<String, ShiftType> shiftsForDate({
    required DateTime date,
    required RotationConfiguration configuration,
    RotationState? continuity,
  }) {
    return Map.unmodifiable({
      for (final team in configuration.teamOrder)
        team: shiftFor(
          team: team,
          date: date,
          configuration: configuration,
          continuity: continuity,
        ),
    });
  }

  List<Map<String, ShiftType>> generateMonth({
    required int year,
    required int month,
    required RotationConfiguration configuration,
    RotationState? continuity,
  }) {
    final days = DateTime(year, month + 1, 0).day;
    return List.unmodifiable([
      for (var day = 1; day <= days; day++)
        shiftsForDate(
          date: DateTime(year, month, day),
          configuration: configuration,
          continuity: continuity,
        ),
    ]);
  }

  ShiftType _shiftFromReference({
    required String team,
    required DateTime date,
    required RotationConfiguration configuration,
  }) {
    final teamIndex = configuration.teamOrder.indexOf(team);
    final days = _dateOnly(date)
        .difference(_dateOnly(configuration.referenceDate))
        .inDays;
    final phase = _floorMod(
      configuration.referencePhaseIndex + days - teamIndex,
      configuration.cycle.length,
    );
    return configuration.cycle[phase];
  }

  int _floorMod(int value, int modulus) {
    final remainder = value % modulus;
    return remainder < 0 ? remainder + modulus : remainder;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
