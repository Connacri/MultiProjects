import 'planning_assignment.dart';

/// Immutable monthly planning aggregate.
///
/// The aggregate is independent from Flutter, Provider and ObjectBox.
class Planning {
  final int year;
  final int month;
  final int? branchId;
  final List<String> dayTeamOrder;
  final List<String> nightTeamOrder;
  final List<PlanningAssignment> assignments;

  const Planning({
    required this.year,
    required this.month,
    required this.dayTeamOrder,
    required this.nightTeamOrder,
    this.branchId,
    this.assignments = const [],
  });

  Planning copyWith({
    int? year,
    int? month,
    int? branchId,
    List<String>? dayTeamOrder,
    List<String>? nightTeamOrder,
    List<PlanningAssignment>? assignments,
  }) {
    return Planning(
      year: year ?? this.year,
      month: month ?? this.month,
      branchId: branchId ?? this.branchId,
      dayTeamOrder: List.unmodifiable(dayTeamOrder ?? this.dayTeamOrder),
      nightTeamOrder: List.unmodifiable(nightTeamOrder ?? this.nightTeamOrder),
      assignments: List.unmodifiable(assignments ?? this.assignments),
    );
  }

  DateTime get firstDay => DateTime(year, month, 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  DateTime get lastDay => DateTime(year, month, daysInMonth);
}
