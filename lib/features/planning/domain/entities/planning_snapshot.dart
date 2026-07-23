import 'planning_assignment.dart';

/// Immutable published planning snapshot.
///
/// Published snapshots are historical facts. They must never be silently
/// recalculated when configuration or staff data changes.
class PlanningSnapshot {
  final String id;
  final int year;
  final int month;
  final int? branchId;
  final String configurationId;
  final int configurationVersion;
  final String? rotationPeriodId;
  final String engineVersion;
  final int revision;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final List<PlanningAssignment> assignments;

  const PlanningSnapshot({
    required this.id,
    required this.year,
    required this.month,
    required this.configurationId,
    required this.configurationVersion,
    required this.engineVersion,
    required this.revision,
    required this.createdAt,
    this.branchId,
    this.rotationPeriodId,
    this.publishedAt,
    this.assignments = const [],
  });

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  bool get isPublished => publishedAt != null;
}
