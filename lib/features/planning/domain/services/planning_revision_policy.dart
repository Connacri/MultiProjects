import '../entities/planning_revision.dart';

/// Business rules for modifications made after a planning was validated.
class PlanningRevisionPolicy {
  const PlanningRevisionPolicy();

  bool canEditCurrentMonth({
    required int planningYear,
    required int planningMonth,
    required DateTime now,
  }) {
    return planningYear == now.year && planningMonth == now.month;
  }

  PlanningRevision createRevision({
    required String id,
    required String baseSnapshotId,
    required String effectiveSnapshotId,
    required int year,
    required int month,
    required DateTime now,
    required String modifiedBy,
    required int revision,
    required List<String> changedFields,
  }) {
    if (!canEditCurrentMonth(
      planningYear: year,
      planningMonth: month,
      now: now,
    )) {
      throw StateError(
        'Post-validation editing is only allowed for the current month.',
      );
    }

    return PlanningRevision(
      id: id,
      baseSnapshotId: baseSnapshotId,
      effectiveSnapshotId: effectiveSnapshotId,
      year: year,
      month: month,
      revision: revision,
      modifiedAt: now,
      modifiedBy: modifiedBy,
      changedFields: List.unmodifiable(changedFields),
      validated: false,
    );
  }
}
