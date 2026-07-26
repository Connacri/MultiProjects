import 'package:flutter_test/flutter_test.dart';

import 'package:kenzy/features/planning/domain/entities/planning_assignment.dart';
import 'package:kenzy/features/planning/domain/entities/planning_snapshot.dart';
import 'package:kenzy/features/planning/domain/entities/rotation_state_snapshot.dart';
import 'package:kenzy/features/planning/domain/enums/shift_type.dart';
import 'package:kenzy/features/planning/domain/repositories/planning_repository.dart';
import 'package:kenzy/features/planning/domain/usecases/publish_planning_snapshot.dart';

void main() {
  group('PublishPlanningSnapshot', () {
    test('publishes only after validation and persists the published revision',
        () async {
      final repository = _FakePlanningRepository();
      final useCase = PublishPlanningSnapshot(
        planningRepository: repository,
      );
      final draft = _snapshot();

      final published = await useCase(snapshot: draft);

      expect(published.isPublished, isTrue);
      expect(repository.published, hasLength(1));
      expect(repository.published.single.revision, draft.revision);
    });

    test('does not persist an invalid snapshot', () async {
      final repository = _FakePlanningRepository();
      final useCase = PublishPlanningSnapshot(
        planningRepository: repository,
      );
      final invalid = _snapshot(assignments: const []);

      await expectLater(
        useCase(snapshot: invalid),
        throwsStateError,
      );
      expect(repository.published, isEmpty);
    });

    test('does not republish an already published snapshot', () async {
      final repository = _FakePlanningRepository();
      final useCase = PublishPlanningSnapshot(
        planningRepository: repository,
      );
      final published = _snapshot(
        publishedAt: DateTime.utc(2026, 7, 2),
      );

      final result = await useCase(snapshot: published);

      expect(identical(result, published), isTrue);
      expect(repository.published, isEmpty);
    });
  });
}

PlanningSnapshot _snapshot({
  DateTime? publishedAt,
  List<PlanningAssignment>? assignments,
}) {
  return PlanningSnapshot(
    id: 'draft-1',
    year: 2026,
    month: 7,
    configurationId: 'rotation-v2',
    configurationVersion: 1,
    engineVersion: 'engine-v2',
    revision: 1,
    createdAt: DateTime.utc(2026, 7, 1),
    publishedAt: publishedAt,
    rotationState: RotationStateSnapshot(
      date: DateTime.utc(2026, 7, 31),
      configurationId: 'rotation-v2',
      configurationVersion: 1,
      phaseIndex: 0,
      teamPhaseByTeam: const {'team-a': 0},
    ),
    assignments: assignments ??
        List.generate(
          31,
          (index) => PlanningAssignment(
            staffId: 1,
            date: DateTime(2026, 7, index + 1),
            shift: ShiftType.day,
            team: 'team-a',
          ),
        ),
  );
}

class _FakePlanningRepository implements PlanningRepository {
  final List<PlanningSnapshot> published = [];

  @override
  Future<PlanningSnapshot?> findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async =>
      published.isEmpty ? null : published.last;

  @override
  Future<PlanningSnapshot?> findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async =>
      published.isEmpty ? null : published.last;

  @override
  Future<PlanningSnapshot?> findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) async {
    for (final item in published) {
      if (item.year == year &&
          item.month == month &&
          item.revision == revision &&
          item.branchId == branchId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async =>
      null;

  @override
  Future<void> saveRevision(PlanningSnapshot snapshot) async {}

  @override
  Future<void> publishRevision(PlanningSnapshot snapshot) async {
    published.add(snapshot);
  }
}
