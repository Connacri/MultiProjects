import '../entities/planning_revision.dart';

/// Business rules for modifications made after a planning was validated.
///
/// Only the current month can be edited after validation. Every accepted
/// post-validation edit creates or updates an unvalidated revision, regardless
/// of whether the change concerns leave or team ordering.
class PlanningRevisionPolicy {
  const PlanningRevisionPolicy();

  static const String leaveField = 'leave';
  static const String teamOrderField = 'teamOrder';

  bool canEditCurrentMonth({
    required int planningYear,
    required int planningMonth,
    required DateTime now,
  }) {
    return planningYear == now.year && planningMonth == now.month;
  }

  bool canEditPostValidation({
    required int planningYear,
    required int planningMonth,
    required DateTime now,
  }) => canEditCurrentMonth(
        planningYear: planningYear,
        planningMonth: planningMonth,
        now: now,
      );

  bool requiresRevalidation(PlanningRevision revision) => !revision.validated;

  bool isModified(PlanningRevision revision) => !revision.validated;

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
    if (!canEditPostValidation(
      planningYear: year,
      planningMonth: month,
      now: now,
    )) {
      throw StateError(
        'Post-validation editing is only allowed for the current month.',
      );
    }

    final fields = changedFields
        .map((field) => field.trim())
        .where((field) => field.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return PlanningRevision(
      id: id,
      baseSnapshotId: baseSnapshotId,
      effectiveSnapshotId: effectiveSnapshotId,
      year: year,
      month: month,
      revision: revision,
      modifiedAt: now,
      modifiedBy: modifiedBy,
      changedFields: List.unmodifiable(fields),
      validated: false,
    );
  }

  PlanningRevision editLeave({
    required PlanningRevision revision,
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
  }) {
    _assertCurrentMonthRevision(revision, now);
    return _applyModification(
      revision: revision,
      now: now,
      modifiedBy: modifiedBy,
      effectiveSnapshotId: effectiveSnapshotId,
      changedField: leaveField,
    );
  }

  PlanningRevision editTeamOrder({
    required PlanningRevision revision,
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
  }) {
    _assertCurrentMonthRevision(revision, now);
    return _applyModification(
      revision: revision,
      now: now,
      modifiedBy: modifiedBy,
      effectiveSnapshotId: effectiveSnapshotId,
      changedField: teamOrderField,
    );
  }

  PlanningRevision markValidated({
    required PlanningRevision revision,
    required DateTime validatedAt,
  }) {
    return revision.copyWith(validated: true, modifiedAt: validatedAt);
  }

  void _assertCurrentMonthRevision(PlanningRevision revision, DateTime now) {
    if (!canEditCurrentMonth(
      planningYear: revision.year,
      planningMonth: revision.month,
      now: now,
    )) {
      throw StateError(
        'Post-validation editing is only allowed for the current month.',
      );
    }
  }

  PlanningRevision _applyModification({
    required PlanningRevision revision,
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
    required String changedField,
  }) {
    final fields = <String>{...revision.changedFields, changedField};
    return revision.copyWith(
      effectiveSnapshotId: effectiveSnapshotId,
      revision: revision.revision + 1,
      modifiedAt: now,
      modifiedBy: modifiedBy,
      changedFields: fields.toList(growable: false),
      validated: false,
    );
  }
}
