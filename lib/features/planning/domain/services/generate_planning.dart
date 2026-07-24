import '../entities/planning_assignment.dart';
import '../entities/planning_snapshot.dart';
import '../entities/rotation_configuration.dart';
import '../entities/staff_availability.dart';
import '../entities/planning_override.dart';
import '../services/planning_draft_pipeline.dart';
import '../services/planning_validator.dart';
import '../services/rotation_continuity_resolver.dart';
import '../services/team_schedule_generator.dart';
import '../repositories/planning_repository.dart';

/// Orchestrates generation of a new monthly planning draft.
///
/// Historical snapshots are read-only. If a snapshot already exists for the
/// requested period, generation is refused instead of recalculating or
/// overwriting it.
class GeneratePlanning {
  final PlanningRepository planningRepository;
  final TeamScheduleGenerator teamScheduleGenerator;
  final RotationContinuityResolver continuityResolver;
  final PlanningDraftPipeline draftPipeline;
  final PlanningValidator validator;

  const GeneratePlanning({
    required this.planningRepository,
    required this.teamScheduleGenerator,
    required this.continuityResolver,
    required this.draftPipeline,
    required this.validator,
  });

  Future<PlanningSnapshot> call({
    required int year,
    required int month,
    required RotationConfiguration configuration,
    required List<int> staffIds,
    required Map<int, String> staffTeams,
    List<StaffAvailability> availability = const [],
    List<PlanningOverride> overrides = const [],
    int? branchId,
  }) async {
    final existing = await planningRepository.findByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );

    if (existing != null) {
      throw StateError(
        'Planning already exists for $year-$month. Historical snapshots are immutable.',
      );
    }

    final continuity = await continuityResolver.resolve(
      targetDate: DateTime(year, month, 1),
      configuration: configuration,
      branchId: branchId,
    );

    final teamSchedule = teamScheduleGenerator.generateMonth(
      year: year,
      month: month,
      configuration: configuration,
      continuity: continuity,
    );

    final baseline = teamScheduleGenerator.projectStaff(
      staffIds: staffIds,
      staffTeams: staffTeams,
      schedule: teamSchedule,
    );

    final assignments = draftPipeline.process(
      baseline: baseline,
      availability: availability,
      overrides: overrides,
    );

    final snapshot = PlanningSnapshot(
      id: 'draft-$year-$month-${DateTime.now().microsecondsSinceEpoch}',
      year: year,
      month: month,
      branchId: branchId,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      engineVersion: '2.0.0',
      revision: 1,
      createdAt: DateTime.now(),
      assignments: List<PlanningAssignment>.unmodifiable(assignments),
      continuityDate: continuity?.date,
    );

    final result = validator.validate(snapshot);
    if (!result.isValid) {
      throw StateError('Generated planning is invalid: ${result.errors.join('; ')}');
    }

    return snapshot;
  }
}
