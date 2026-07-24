import 'package:flutter_test/flutter_test.dart';

import 'package:kenzy/features/planning/domain/entities/planning_revision.dart';
import 'package:kenzy/features/planning/domain/entities/planning_snapshot.dart';
import 'package:kenzy/features/planning/domain/services/planning_revision_policy.dart';
import 'package:kenzy/features/planning/presentation/providers/planning_revision_ui_provider.dart';
import 'package:kenzy/features/planning/presentation/providers/planning_validation_provider.dart';
import 'package:kenzy/features/planning/presentation/services/planning_edit_coordinator.dart';

class _FakeValidationProvider extends PlanningValidationProvider {
  _FakeValidationProvider() : super(validator: const _NoopValidator());
}

class _NoopValidator extends PlanningValidator {
  const _NoopValidator();
}

PlanningRevision _revision({
  int revision = 1,
  bool validated = true,
  List<String> changedFields = const [],
}) {
  return PlanningRevision(
    id: 'revision-1',
    baseSnapshotId: 'published-1',
    effectiveSnapshotId: 'draft-1',
    year: 2026,
    month: 7,
    revision: revision,
    modifiedAt: DateTime(2026, 7, 24, 10),
    modifiedBy: 'admin',
    changedFields: changedFields,
    validated: validated,
  );
}

PlanningSnapshot _snapshot() {
  return PlanningSnapshot(
    id: 'draft-1',
    year: 2026,
    month: 7,
    configurationId: 'config-1',
    configurationVersion: 1,
    engineVersion: 'test',
    revision: 1,
    createdAt: DateTime(2026, 7, 1),
    assignments: const [],
  );
}

void main() {
  test('leave edit invalidates validation and marks revision modified', () {
    final revisionProvider = PlanningRevisionUiProvider();
    final validationProvider = _FakeValidationProvider();
    final coordinator = PlanningEditCoordinator(
      revisionProvider: revisionProvider,
      validationProvider: validationProvider,
    );

    revisionProvider.setRevision(_revision());

    coordinator.applyLeaveEdit(
      draft: _snapshot(),
      revision: _revision(),
      now: DateTime(2026, 7, 24, 11),
      modifiedBy: 'admin',
      effectiveSnapshotId: 'draft-2',
    );

    expect(revisionProvider.isModified, isTrue);
    expect(revisionProvider.requiresRevalidation, isTrue);
    expect(revisionProvider.isValidated, isFalse);
    expect(revisionProvider.revision?.effectiveSnapshotId, 'draft-2');
    expect(revisionProvider.changedFields, contains(PlanningRevisionPolicy.leaveField));
  });

  test('team-order edit invalidates validation and marks revision modified', () {
    final revisionProvider = PlanningRevisionUiProvider();
    final validationProvider = _FakeValidationProvider();
    final coordinator = PlanningEditCoordinator(
      revisionProvider: revisionProvider,
      validationProvider: validationProvider,
    );

    revisionProvider.setRevision(_revision());

    coordinator.applyTeamOrderEdit(
      draft: _snapshot(),
      revision: _revision(),
      now: DateTime(2026, 7, 24, 12),
      modifiedBy: 'admin',
      effectiveSnapshotId: 'draft-3',
    );

    expect(revisionProvider.isModified, isTrue);
    expect(revisionProvider.requiresRevalidation, isTrue);
    expect(revisionProvider.isValidated, isFalse);
    expect(revisionProvider.revision?.effectiveSnapshotId, 'draft-3');
    expect(
      revisionProvider.changedFields,
      contains(PlanningRevisionPolicy.teamOrderField),
    );
  });

  test('post-validation edit is rejected for a previous month', () {
    final revisionProvider = PlanningRevisionUiProvider();
    final validationProvider = _FakeValidationProvider();
    final coordinator = PlanningEditCoordinator(
      revisionProvider: revisionProvider,
      validationProvider: validationProvider,
    );

    final previousMonth = PlanningSnapshot(
      id: 'draft-old',
      year: 2026,
      month: 6,
      configurationId: 'config-1',
      configurationVersion: 1,
      engineVersion: 'test',
      revision: 1,
      createdAt: DateTime(2026, 6, 1),
      assignments: const [],
    );

    expect(
      () => coordinator.applyLeaveEdit(
        draft: previousMonth,
        revision: _revision(),
        now: DateTime(2026, 7, 24),
        modifiedBy: 'admin',
        effectiveSnapshotId: 'draft-old-2',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
