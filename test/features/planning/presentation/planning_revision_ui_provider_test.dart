import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_revision.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_revision_ui_provider.dart';

void main() {
  PlanningRevision revision({
    int year = 2026,
    int month = 7,
    bool validated = true,
    List<String> changedFields = const [],
    int number = 1,
  }) {
    return PlanningRevision(
      id: 'revision-$number',
      baseSnapshotId: 'snapshot-1',
      effectiveSnapshotId: 'snapshot-$number',
      year: year,
      month: month,
      revision: number,
      modifiedAt: DateTime(2026, 7, 24),
      modifiedBy: 'user-1',
      changedFields: changedFields,
      validated: validated,
    );
  }

  test('leave edit marks the revision modified and requires revalidation', () {
    final provider = PlanningRevisionUiProvider()
      ..setRevision(revision());

    provider.applyLeaveEdit(
      now: DateTime(2026, 7, 24),
      modifiedBy: 'user-2',
      effectiveSnapshotId: 'snapshot-2',
    );

    expect(provider.isModified, isTrue);
    expect(provider.requiresRevalidation, isTrue);
    expect(provider.isValidated, isFalse);
    expect(provider.changedFields, contains('leave'));
  });

  test('team order edit marks the revision modified and requires revalidation', () {
    final provider = PlanningRevisionUiProvider()
      ..setRevision(revision());

    provider.applyTeamOrderEdit(
      now: DateTime(2026, 7, 24),
      modifiedBy: 'user-2',
      effectiveSnapshotId: 'snapshot-3',
    );

    expect(provider.isModified, isTrue);
    expect(provider.requiresRevalidation, isTrue);
    expect(provider.changedFields, contains('teamOrder'));
  });

  test('validated revision can be restored after revalidation', () {
    final provider = PlanningRevisionUiProvider()
      ..setRevision(revision(validated: false));

    expect(provider.requiresRevalidation, isTrue);

    provider.markValidated(validatedAt: DateTime(2026, 7, 24, 12));

    expect(provider.isValidated, isTrue);
    expect(provider.isModified, isFalse);
    expect(provider.requiresRevalidation, isFalse);
  });

  test('past month edits are rejected by the domain policy', () {
    final provider = PlanningRevisionUiProvider()
      ..setRevision(revision(year: 2026, month: 6));

    expect(
      () => provider.applyLeaveEdit(
        now: DateTime(2026, 7, 24),
        modifiedBy: 'user-2',
        effectiveSnapshotId: 'snapshot-4',
      ),
      throwsStateError,
    );
  });
}
