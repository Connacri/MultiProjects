import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/services/planning_revision_policy.dart';

void main() {
  const policy = PlanningRevisionPolicy();

  test('allows post-validation edits only for the current month', () {
    final now = DateTime(2026, 7, 24);

    expect(
      policy.canEditCurrentMonth(
        planningYear: 2026,
        planningMonth: 7,
        now: now,
      ),
      isTrue,
    );

    expect(
      policy.canEditCurrentMonth(
        planningYear: 2026,
        planningMonth: 6,
        now: now,
      ),
      isFalse,
    );
  });

  test('new revision is unvalidated and keeps its audit metadata', () {
    final revision = policy.createRevision(
      id: 'rev-1',
      baseSnapshotId: 'snapshot-1',
      effectiveSnapshotId: 'snapshot-2',
      year: 2026,
      month: 7,
      now: DateTime(2026, 7, 24),
      modifiedBy: 'user-1',
      revision: 2,
      changedFields: const ['leave', 'team_order'],
    );

    expect(revision.validated, isFalse);
    expect(revision.baseSnapshotId, 'snapshot-1');
    expect(revision.effectiveSnapshotId, 'snapshot-2');
    expect(revision.changedFields, containsAll(['leave', 'team_order']));
  });

  test('rejects revision creation for a past month', () {
    expect(
      () => policy.createRevision(
        id: 'rev-old',
        baseSnapshotId: 'snapshot-1',
        effectiveSnapshotId: 'snapshot-2',
        year: 2026,
        month: 6,
        now: DateTime(2026, 7, 24),
        modifiedBy: 'user-1',
        revision: 2,
        changedFields: const ['leave'],
      ),
      throwsStateError,
    );
  });
}
