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

  PlanningSnapshot copyWith({
    String? id,
    int? year,
    int? month,
    int? branchId,
    String? configurationId,
    int? configurationVersion,
    String? rotationPeriodId,
    String? engineVersion,
    int? revision,
    DateTime? createdAt,
    DateTime? publishedAt,
    List<PlanningAssignment>? assignments,
  }) {
    return PlanningSnapshot(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      branchId: branchId ?? this.branchId,
      configurationId: configurationId ?? this.configurationId,
      configurationVersion: configurationVersion ?? this.configurationVersion,
      rotationPeriodId: rotationPeriodId ?? this.rotationPeriodId,
      engineVersion: engineVersion ?? this.engineVersion,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      assignments: assignments ?? this.assignments,
    );
  }

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  bool get isPublished => publishedAt != null;
}
