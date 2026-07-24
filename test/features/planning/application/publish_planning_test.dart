import 'package:flutter_test/flutter_test.dart';

import 'package:kenzy/features/planning/application/usecases/publish_planning.dart';
import 'package:kenzy/features/planning/domain/entities/planning_assignment.dart';
import 'package:kenzy/features/planning/domain/entities/planning_snapshot.dart';
import 'package:kenzy/features/planning/domain/entities/rotation_state_snapshot.dart';
import 'package:kenzy/features/planning/domain/repositories/planning_repository.dart';
import 'package:kenzy/features/planning/domain/services/planning_validator.dart';

class _FakePlanningRepository implements PlanningRepository {
  PlanningSnapshot? published;

  String _key(int year, int month, int? branchId) => '$year-$month-${branchId ?? 0}';

  @override
  Future<PlanningSnapshot?> findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async => published != null && _key(published!.year, published!.month, published!.branchId) == _key(year, month, branchId)
      ? published
      : null;

  @override
  Future<PlanningSnapshot?> findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async => published != null && _key(published!.year, published!.month, published!.branchId) == _key(year, month, branchId)
      ? published
      : null;

  @override
  Future<PlanningSnapshot?> findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) async => published != null &&
          published!.year == year &&
          published!.month == month &&
          published!.revision == revision &&
          published!.branchId == branchId
      ? published
      : null;

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async => null;

  @override
  Future<void> saveRevision(PlanningSnapshot snapshot) async {
    published = snapshot;
  }

  @override
  Future<void> publishRevision(PlanningSnapshot snapshot) async {
    published = snapshot;
  }
}

PlanningSnapshot _snapshot({
  List<PlanningAssignment> assignments = const [],
  RotationStateSnapshot? rotationState,
}) {
  return PlanningSnapshot(
    id: 'draft-1',
    year: 2026,
    month: 7,
    configurationId: 'config-1',
    configurationVersion: 1,
    engineVersion: 'test',
    revision: 1,
    createdAt: DateTime(2026, 7, 24),
    rotationState: rotationState ??
        RotationStateSnapshot(
          date: DateTime(2026, 7, 31),
          configurationId: 'config-1',
          configurationVersion: 1,
          phaseIndex: 2,
          teamPhaseByTeam: const {'A': 2},
        ),
    assignments: assignments,
  );
}

void main() {
  test('publication boundary rejects invalid planning even without UI gate', () async {
    final repository = _FakePlanningRepository();
    final useCase = PublishPlanning(
      planningRepository: repository,
      validator: const PlanningValidator(),
    );

    final duplicateDate = DateTime(2026, 7, 24);
    final snapshot = _snapshot(
      assignments: [
        PlanningAssignment(staffId: 1, date: duplicateDate, status: 'J'),
        PlanningAssignment(staffId: 1, date: duplicateDate, status: 'J'),
      ],
    );

    expect(
      () => useCase(snapshot),
      throwsA(isA<InvalidPlanningException>()),
    );
    expect(repository.published, isNull);
  });

  test('publication rejects replacing an existing snapshot', () async {
    final repository = _FakePlanningRepository();
    repository.published = _snapshot();
    final useCase = PublishPlanning(
      planningRepository: repository,
      validator: const PlanningValidator(),
    );

    final snapshot = _snapshot(
      assignments: [
        PlanningAssignment(
          staffId: 1,
          date: DateTime(2026, 7, 24),
          status: 'J',
        ),
      ],
    );

    expect(
      () => useCase(snapshot),
      throwsA(isA<StateError>()),
    );
    expect(repository.published, isNotNull);
  });
}
