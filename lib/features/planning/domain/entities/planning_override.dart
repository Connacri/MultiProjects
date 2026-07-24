import '../enums/shift_type.dart';

/// A manual change applied to a draft planning before publication.
///
/// Overrides are explicit domain data. They are never silently overwritten by
/// the rotation engine and become part of the published snapshot once saved.
class PlanningOverride {
  final int staffId;
  final DateTime date;
  final String? team;
  final ShiftType shift;
  final String? code;
  final String? note;

  const PlanningOverride({
    required this.staffId,
    required this.date,
    required this.shift,
    this.team,
    this.code,
    this.note,
  });
}
