import 'planning_assignment.dart';
import 'rotation_state_snapshot.dart';

/// Immutable planning snapshot representing one persisted revision.
///
/// A revision is append-only. A draft is simply an unpublished revision and
/// may be superseded by a newer revision; it is never updated in place.
/// Published revisions are historical facts and are never overwritten.
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
  final RotationStateSnapshot? rotationState;
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
    this.rotationState,
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
    RotationStateSnapshot? rotationState,
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
      rotationState: rotationState ?? this.rotationState,
      assignments: List.unmodifiable(assignments ?? this.assignments),
    );
  }

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  bool get isPublished => publishedAt != null;

  bool get isDraft => !isPublished;

  bool get isHistorical => isPublished;

  String get monthKey =>
      '${branchId ?? 0}:$year:${month.toString().padLeft(2, '0')}';

  /// Creates the next immutable revision from this revision.
  ///
  /// The returned revision is always unpublished. Publishing is a separate
  /// state transition handled by the canonical publication use case.
  PlanningSnapshot nextRevision({
    required DateTime createdAt,
    List<PlanningAssignment>? assignments,
    DateTime? continuityDate,
    RotationStateSnapshot? rotationState,
  }) {
    final normalizedCreatedAt = createdAt.toUtc();
    final normalizedSourceCreatedAt = createdAt.toUtc();

    if (normalizedCreatedAt.isBefore(normalizedSourceCreatedAt)) {
      throw ArgumentError.value(
        createdAt,
        'createdAt',
        'A new revision cannot be created before the source snapshot.',
      );
    }

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
      createdAt: normalizedCreatedAt,
      continuityDate: continuityDate ?? this.continuityDate,
      rotationState: rotationState ?? this.rotationState,
      assignments: List.unmodifiable(assignments ?? this.assignments),
    );
  }
}
