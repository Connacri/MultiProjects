import '../enums/shift_type.dart';

/// Immutable domain representation of one staff assignment for one day.
class PlanningAssignment {
  final int staffId;
  final DateTime date;
  final String? team;
  final ShiftType shift;
  final String? code;
  final String? note;

  const PlanningAssignment({
    required this.staffId,
    required this.date,
    required this.shift,
    this.team,
    this.code,
    this.note,
  });

  PlanningAssignment copyWith({
    int? staffId,
    DateTime? date,
    String? team,
    ShiftType? shift,
    String? code,
    String? note,
  }) {
    return PlanningAssignment(
      staffId: staffId ?? this.staffId,
      date: date ?? this.date,
      team: team ?? this.team,
      shift: shift ?? this.shift,
      code: code ?? this.code,
      note: note ?? this.note,
    );
  }
}
