/// A post-validation revision of the current month's planning.
///
/// The original published snapshot remains immutable. A revision records that
/// the current month was changed after validation and points to the effective
/// snapshot that must be revalidated before becoming the new published state.
class PlanningRevision {
  final String id;
  final String baseSnapshotId;
  final String effectiveSnapshotId;
  final int year;
  final int month;
  final int revision;
  final DateTime modifiedAt;
  final String modifiedBy;
  final List<String> changedFields;
  final bool validated;

  const PlanningRevision({
    required this.id,
    required this.baseSnapshotId,
    required this.effectiveSnapshotId,
    required this.year,
    required this.month,
    required this.revision,
    required this.modifiedAt,
    required this.modifiedBy,
    required this.changedFields,
    required this.validated,
  });

  bool get isCurrentMonth =>
      year == modifiedAt.year && month == modifiedAt.month;

  PlanningRevision copyWith({
    String? effectiveSnapshotId,
    int? revision,
    DateTime? modifiedAt,
    String? modifiedBy,
    List<String>? changedFields,
    bool? validated,
  }) {
    return PlanningRevision(
      id: id,
      baseSnapshotId: baseSnapshotId,
      effectiveSnapshotId: effectiveSnapshotId ?? this.effectiveSnapshotId,
      year: year,
      month: month,
      revision: revision ?? this.revision,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      changedFields: changedFields ?? this.changedFields,
      validated: validated ?? this.validated,
    );
  }
}
