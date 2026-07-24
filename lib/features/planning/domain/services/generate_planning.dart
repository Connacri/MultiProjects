import '../entities/planning_assignment.dart';
import '../entities/planning_snapshot.dart';
import '../entities/rotation_configuration.dart';
import '../entities/rotation_state_snapshot.dart';
import '../entities/staff_availability.dart';
import '../entities/planning_override.dart';
import '../enums/shift_type.dart';
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
    final existing = await planningRepository.findLatestByMonth(
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

    final lastDate = DateTime(year, month, DateTime(year, month + 1, 0).day);
    final rotationState = _buildRotationStateSnapshot(
      date: lastDate,
      configuration: configuration,
      teamShifts: teamSchedule[lastDate] ?? const <String, ShiftType>{},
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
      continuityDate: rotationState.date,
      rotationState: rotationState,
      assignments: List<PlanningAssignment>.unmodifiable(assignments),
    );

    final result = validator.validate(snapshot);
    if (!result.isValid) {
      throw StateError(
        'Generated planning is invalid: ${result.errors.join('; ')}',
      );
    }

    return snapshot;
  }

  RotationStateSnapshot _buildRotationStateSnapshot({
    required DateTime date,
    required RotationConfiguration configuration,
    required Map<String, ShiftType> teamShifts,
  }) {
    final teamPhaseByTeam = <String, int>{};
    for (final team in configuration.teamOrder) {
      final shift = teamShifts[team];
      if (shift == null) continue;
      final index = configuration.cycle.indexOf(shift);
      if (index >= 0) {
        teamPhaseByTeam[team] = index;
      }
    }

    final referenceOnly = DateTime(
      configuration.referenceDate.year,
      configuration.referenceDate.month,
      configuration.referenceDate.day,
    );
    final dateOnly = DateTime(date.year, date.month, date.day);
    final phaseIndex = _floorMod(
      configuration.referencePhaseIndex +
          dateOnly.difference(referenceOnly).inDays,
      configuration.cycle.length,
    );

    return RotationStateSnapshot(
      date: dateOnly,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      phaseIndex: phaseIndex,
      teamPhaseByTeam: Map.unmodifiable(teamPhaseByTeam),
    );
  }

  int _floorMod(int value, int modulus) {
    final remainder = value % modulus;
    return remainder < 0 ? remainder + modulus : remainder;
  }
}
