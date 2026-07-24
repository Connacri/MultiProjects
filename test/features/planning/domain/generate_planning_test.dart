import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/entities/rotation_configuration.dart';
import 'package:multi_projects/features/planning/domain/enums/rotation_policy.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/domain/services/generate_planning.dart';
import 'package:multi_projects/features/planning/domain/services/planning_draft_pipeline.dart';
import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';
import 'package:multi_projects/features/planning/domain/services/rotation_continuity_resolver.dart';
import 'package:multi_projects/features/planning/domain/services/team_schedule_generator.dart';
import 'package:multi_projects/features/planning/domain/repositories/planning_repository.dart';

class _InMemoryPlanningRepository implements PlanningRepository {
  final Map<String, PlanningSnapshot> snapshots = {};

  String _key(int year, int month, int? branchId) => '$year-$month-${branchId ?? 0}';

  @override
  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async => snapshots[_key(year, month, branchId)];

  @override
  Future<void> publish(PlanningSnapshot snapshot) async {
    snapshots[_key(snapshot.year, snapshot.month, snapshot.branchId)] = snapshot;
  }
}

class _StubContinuityResolver extends RotationContinuityResolver {
  final Map<String, dynamic> states;

  _StubContinuityResolver(this.states) : super(planningRepository: _InMemoryPlanningRepository());
}

void main() {
  test('GeneratePlanning stores configuration version in generated snapshot', () async {
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
      teamScheduleGenerator: TeamScheduleGenerator(),
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
      teamScheduleGenerator: TeamScheduleGenerator(),
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
    await repository.publish(first);

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
