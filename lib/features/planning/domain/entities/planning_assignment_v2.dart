import '../enums/shift_type.dart';

/// One generated staff assignment. The theoretical rotation and actual
/// availability are deliberately stored separately.
class PlanningAssignmentV2 {
  final int staffId;
  final DateTime date;
  final String team;
  final ShiftType rotationShift;
  final ShiftType effectiveShift;
  final String? rotationCode;
  final String? availabilityCode;
  final String? note;

  const PlanningAssignmentV2({
    required this.staffId,
    required this.date,
    required this.team,
    required this.rotationShift,
    required this.effectiveShift,
    this.rotationCode,
    this.availabilityCode,
    this.note,
  });

  bool get isOnLeave => availabilityCode == 'LEAVE';

  PlanningAssignmentV2 copyWith({
    int? staffId,
    DateTime? date,
    String? team,
    ShiftType? rotationShift,
    ShiftType? effectiveShift,
    String? rotationCode,
    String? availabilityCode,
    String? note,
  }) {
    return PlanningAssignmentV2(
      staffId: staffId ?? this.staffId,
      date: date ?? this.date,
      team: team ?? this.team,
      rotationShift: rotationShift ?? this.rotationShift,
      effectiveShift: effectiveShift ?? this.effectiveShift,
      rotationCode: rotationCode ?? this.rotationCode,
      availabilityCode: availabilityCode ?? this.availabilityCode,
      note: note ?? this.note,
    );
  }
}
