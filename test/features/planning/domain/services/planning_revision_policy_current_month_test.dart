import 'package:flutter_test/flutter_test.dart';
import 'package:mult_projects/features/planning/domain/entities/planning_revision.dart';
import 'package:mult_projects/features/planning/domain/services/planning_revision_policy.dart';

void main() {
  const policy = PlanningRevisionPolicy();
  final now = DateTime(2026, 7, 24, 10);

  PlanningRevision revision() => PlanningRevision(
        id: 'rev-1',
        baseSnapshotId: 'snap-published',
        effectiveSnapshotId: 'snap-edit',
        year: 2026,
        month: 7,
        revision: 1,
        modifiedAt: now,
        modifiedBy: 'user-1',
        changedFields: const [],
        validated: true,
      );

  test('allows current month post-validation leave edit and requires revalidation', () {
    final updated = policy.editLeave(
      revision: revision(),
      now: now,
      modifiedBy: 'user-2',
      effectiveSnapshotId: 'snap-leave-edit',
    );

    expect(updated.validated, isFalse);
    expect(policy.isModified(updated), isTrue);
    expect(policy.requiresRevalidation(updated), isTrue);
    expect(updated.changedFields, contains(PlanningRevisionPolicy.leaveField));
    expect(updated.effectiveSnapshotId, 'snap-leave-edit');
    expect(updated.revision, 2);
  });

  test('allows current month post-validation team order edit and requires revalidation', () {
    final updated = policy.editTeamOrder(
      revision: revision(),
      now: now,
      modifiedBy: 'user-2',
      effectiveSnapshotId: 'snap-team-order-edit',
    );

    expect(updated.validated, isFalse);
    expect(policy.isModified(updated), isTrue);
    expect(policy.requiresRevalidation(updated), isTrue);
    expect(updated.changedFields, contains(PlanningRevisionPolicy.teamOrderField));
    expect(updated.effectiveSnapshotId, 'snap-team-order-edit');
  });

  test('rejects post-validation leave edits for a past month', () {
    expect(
      () => policy.editLeave(
        revision: revision().copyWith(),
        now: DateTime(2026, 8, 1),
        modifiedBy: 'user-2',
        effectiveSnapshotId: 'snap-edit',
      ),
      throwsStateError,
    );
  });
}
