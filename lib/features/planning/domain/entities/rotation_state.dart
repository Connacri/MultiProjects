import '../enums/shift_type.dart';

/// Immutable state required to continue a rotation across planning periods.
class RotationState {
  final DateTime date;
  final Map<String, ShiftType> teamShifts;

  const RotationState({
    required this.date,
    required this.teamShifts,
  });

  ShiftType? shiftFor(String team) => teamShifts[team];
}
