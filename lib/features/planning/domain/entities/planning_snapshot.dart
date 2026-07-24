import 'planning_assignment.dart';

/// Immutable planning snapshot representing one revision of a monthly plan.
///
/// A snapshot is never updated in place after persistence. A modification of
/// an existing plan creates a new revision. Published revisions remain
/// historical facts and are never overwritten.
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
  final DateTime? continuityDate;
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
    this.continuityDate,
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
    DateTime? continuityDate,
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
      continuityDate: continuityDate ?? this.continuityDate,
      assignments: assignments ?? this.assignments,
    );
  }

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  bool get isPublished => publishedAt != null;

  /// A snapshot can only be published once it has been validated by the
  /// application layer. Persistence must not infer validation from this flag.
  bool get isHistorical => isPublished;

  /// Stable business key used by persistence and transaction guards.
  String get monthKey => '${branchId ?? 0}:$year:${month.toString().padLeft(2, '0')}';

  /// Creates the next immutable revision while preserving the current
  /// configuration and assignments unless explicitly replaced.
  PlanningSnapshot nextRevision({
    required DateTime createdAt,
    List<PlanningAssignment>? assignments,
    DateTime? continuityDate,
  }) {
    return PlanningSnapshot(
      id: '',
      year: year,
      month: month,
      branchId: branchId,
      configurationId: configurationId,
      configurationVersion: configurationVersion,
      rotationPeriodId: rotationPeriodId,
      engineVersion: engineVersion,
      revision: revision + 1,
      createdAt: createdAt,
      continuityDate: continuityDate ?? this.continuityDate,
      assignments: List.unmodifiable(assignments ?? this.assignments),
    );
  }
}
