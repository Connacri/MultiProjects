import '../../domain/entities/planning_revision.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/services/planning_revision_policy.dart';
import '../providers/planning_revision_ui_provider.dart';
import '../providers/planning_validation_provider.dart';

/// Coordinates a post-validation edit so that validation cannot remain valid
/// after the draft has changed.
///
/// This is intentionally UI-framework agnostic: Desktop and Mobile can both
/// call the same coordinator after editing leave or team-order data.
class PlanningEditCoordinator {
  final PlanningRevisionUiProvider revisionProvider;
  final PlanningValidationProvider validationProvider;
  final PlanningRevisionPolicy policy;

  PlanningEditCoordinator({
    required this.revisionProvider,
    required this.validationProvider,
    this.policy = const PlanningRevisionPolicy(),
  });

  void applyLeaveEdit({
    required PlanningSnapshot draft,
    required PlanningRevision revision,
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
  }) {
    _assertCurrentMonth(draft, now);
    validationProvider.clear();
    revisionProvider.setRevision(revision);
    revisionProvider.applyLeaveEdit(
      now: now,
      modifiedBy: modifiedBy,
      effectiveSnapshotId: effectiveSnapshotId,
    );
  }

  void applyTeamOrderEdit({
    required PlanningSnapshot draft,
    required PlanningRevision revision,
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
  }) {
    _assertCurrentMonth(draft, now);
    validationProvider.clear();
    revisionProvider.setRevision(revision);
    revisionProvider.applyTeamOrderEdit(
      now: now,
      modifiedBy: modifiedBy,
      effectiveSnapshotId: effectiveSnapshotId,
    );
  }

  void _assertCurrentMonth(PlanningSnapshot draft, DateTime now) {
    if (!policy.canEditCurrentMonth(
      planningYear: draft.year,
      planningMonth: draft.month,
      now: now,
    )) {
      throw StateError(
        'Only the current month can be edited after validation.',
      );
    }
  }
}
