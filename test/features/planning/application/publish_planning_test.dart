import 'package:flutter_test/flutter_test.dart';

import 'package:kenzy/features/planning/application/usecases/publish_planning.dart';
import 'package:kenzy/features/planning/domain/entities/planning_snapshot.dart';
import 'package:kenzy/features/planning/domain/repositories/planning_repository.dart';
import 'package:kenzy/features/planning/domain/services/planning_validator.dart';

class _FakePlanningRepository implements PlanningRepository {
  bool alreadyExists;
  PlanningSnapshot? published;

  _FakePlanningRepository({this.alreadyExists = false});

  @override
  Future<bool> exists({required int year, required int month, int? branchId}) async =>
      alreadyExists;

  @override
  Future<PlanningSnapshot?> findByMonth({required int year, required int month, int? branchId}) async =>
      published;

  @override
  Future<PlanningSnapshot?> findPreviousPublished({required int year, required int month, int? branchId}) async =>
      null;

  @override
  Future<void> publish(PlanningSnapshot snapshot) async {
    published = snapshot;
  }
}

PlanningSnapshot _snapshot({
  List<({int staffId, DateTime date})> assignments = const [],
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
    assignments: assignments
        .map(
          (item) => PlanningAssignment(
            staffId: item.staffId,
            date: item.date,
            status: 'J',
          ),
        )
        .toList(),
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
        (staffId: 1, date: duplicateDate),
        (staffId: 1, date: duplicateDate),
      ],
    );

    expect(
      () => useCase(snapshot),
      throwsA(isA<InvalidPlanningException>()),
    );
    expect(repository.published, isNull);
  });

  test('valid planning is published when no existing snapshot exists', () async {
    final repository = _FakePlanningRepository();
    final useCase = PublishPlanning(
      planningRepository: repository,
      validator: const PlanningValidator(),
    );

    final snapshot = _snapshot(
      assignments: [(staffId: 1, date: DateTime(2026, 7, 24))],
    );

    final published = await useCase(snapshot);

    expect(published.isPublished, isTrue);
    expect(repository.published?.id, 'draft-1');
  });

  test('publication rejects replacing an existing snapshot', () async {
    final repository = _FakePlanningRepository(alreadyExists: true);
    final useCase = PublishPlanning(
      planningRepository: repository,
      validator: const PlanningValidator(),
    );

    final snapshot = _snapshot(
      assignments: [(staffId: 1, date: DateTime(2026, 7, 24))],
    );

    expect(
      () => useCase(snapshot),
      throwsA(isA<StateError>()),
    );
    expect(repository.published, isNull);
  });
}
