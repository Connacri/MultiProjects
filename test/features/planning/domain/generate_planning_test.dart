import 'package:flutter_test/flutter_test.dart';

import 'package:kenzy/features/planning/application/usecases/generate_planning_draft.dart';
import 'package:kenzy/features/planning/domain/entities/planning_assignment.dart';
import 'package:kenzy/features/planning/domain/entities/planning_snapshot.dart';
import 'package:kenzy/features/planning/domain/entities/rotation_configuration.dart';
import 'package:kenzy/features/planning/domain/entities/rotation_state_snapshot.dart';
import 'package:kenzy/features/planning/domain/enums/rotation_policy.dart';
import 'package:kenzy/features/planning/domain/enums/shift_type.dart';
import 'package:kenzy/features/planning/domain/repositories/planning_repository.dart';
import 'package:kenzy/features/planning/domain/services/generate_planning.dart';
import 'package:kenzy/features/planning/domain/services/planning_draft_pipeline.dart';
import 'package:kenzy/features/planning/domain/services/planning_validator.dart';
import 'package:kenzy/features/planning/domain/services/rotation_continuity_resolver.dart';
import 'package:kenzy/features/planning/domain/services/rotation_engine.dart';
import 'package:kenzy/features/planning/domain/services/team_schedule_generator.dart';

class _InMemoryPlanningRepository implements PlanningRepository {
  final Map<String, PlanningSnapshot> snapshots = {};

  String _key(int year, int month, int? branchId) => '$year-$month-${branchId ?? 0}';

  @override
  Future<PlanningSnapshot?> findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async => snapshots[_key(year, month, branchId)];

  @override
  Future<PlanningSnapshot?> findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async => snapshots[_key(year, month, branchId)];

  @override
  Future<PlanningSnapshot?> findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) async {
    final snapshot = snapshots[_key(year, month, branchId)];
    if (snapshot == null || snapshot.revision != revision) return null;
    return snapshot;
  }

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async => null;

  @override
  Future<void> saveRevision(PlanningSnapshot snapshot) async {
    snapshots[_key(snapshot.year, snapshot.month, snapshot.branchId)] = snapshot;
  }

  @override
  Future<void> publishRevision(PlanningSnapshot snapshot) async {
    snapshots[_key(snapshot.year, snapshot.month, snapshot.branchId)] = snapshot;
  }
}

void main() {
  test('GeneratePlanning stores rotation checkpoint in generated snapshot', () async {
    final repository = _InMemoryPlanningRepository();
    final configuration = RotationConfiguration(
      id: 'four-team',
      version: 2,
      teamOrder: const ['A', 'C', 'D', 'B'],
      cycle: const [ShiftType.day, ShiftType.night, ShiftType.rest, ShiftType.rest],
      policy: RotationPolicy.continueFromPreviousPublished,
      referenceDate: DateTime(2026, 1, 1),
    );

    final useCase = GeneratePlanning(
      planningRepository: repository,
      teamScheduleGenerator: const TeamScheduleGenerator(RotationEngine()),
      continuityResolver: RotationContinuityResolver(planningRepository: repository),
      draftPipeline: const PlanningDraftPipeline(),
      validator: const PlanningValidator(),
    );

    final snapshot = await useCase(
      year: 2026,
      month: 2,
      configuration: configuration,
      staffIds: const [1],
      staffTeams: const {1: 'A'},
    );

    expect(snapshot.configurationId, 'four-team');
    expect(snapshot.configurationVersion, 2);
    expect(snapshot.rotationState, isNotNull);
    expect(snapshot.rotationState!.configurationId, 'four-team');
    expect(snapshot.rotationState!.configurationVersion, 2);
    expect(snapshot.rotationState!.teamPhaseByTeam, isNotEmpty);
  });

  test('GeneratePlanning refuses to overwrite an existing historical snapshot', () async {
    final repository = _InMemoryPlanningRepository();
    final configuration = RotationConfiguration(
      id: 'four-team',
      version: 1,
      teamOrder: const ['A', 'B', 'C', 'D'],
      cycle: const [ShiftType.day, ShiftType.night, ShiftType.rest, ShiftType.rest],
      policy: RotationPolicy.continueFromPreviousPublished,
      referenceDate: DateTime(2026, 1, 1),
    );

    final useCase = GeneratePlanning(
      planningRepository: repository,
      teamScheduleGenerator: const TeamScheduleGenerator(RotationEngine()),
      continuityResolver: RotationContinuityResolver(planningRepository: repository),
      draftPipeline: const PlanningDraftPipeline(),
      validator: const PlanningValidator(),
    );

    final first = await useCase(
      year: 2026,
      month: 2,
      configuration: configuration,
      staffIds: const [1],
      staffTeams: const {1: 'A'},
    );
    await repository.publishRevision(first);

    expect(
      () => useCase(
        year: 2026,
        month: 2,
        configuration: configuration.copyWith(version: 2),
        staffIds: const [1],
        staffTeams: const {1: 'A'},
      ),
      throwsA(isA<StateError>()),
    );
  });
}
