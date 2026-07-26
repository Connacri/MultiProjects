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
/// Generation is strictly read-only with respect to persisted history. A
/// draft is derived from the latest published continuity checkpoint and the
/// current configuration; it is never derived from an unpublished draft.
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
    _validatePeriod(year, month);

    final existing = await planningRepository.findLatestByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );

    if (existing != null) {
      throw StateError(
        'Planning already exists for $year-${month.toString().padLeft(2, '0')}. '
        'Historical snapshots and drafts are immutable once persisted.',
      );
    }

    final continuity = await continuityResolver.resolve(
      targetDate: DateTime.utc(year, month, 1),
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

    final lastDate = DateTime.utc(
      year,
      month,
      DateTime(year, month + 1, 0).day,
    );
    final rotationState = _buildRotationStateSnapshot(
      date: lastDate,
      configuration: configuration,
      teamShifts: teamSchedule[lastDate] ?? const <String, ShiftType>{},
    );

    final now = DateTime.now().toUtc();
    final snapshot = PlanningSnapshot(
      // Persistence identity is owned by ObjectBox. A new domain snapshot
      // must carry an empty ID so the repository can insert it atomically.
      id: '',
      year: year,
      month: month,
      branchId: branchId,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      engineVersion: '2.0.0',
      revision: 1,
      createdAt: now,
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

  void _validatePeriod(int year, int month) {
    if (year < 1) {
      throw ArgumentError.value(year, 'year', 'Year must be positive.');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(year, 'month', 'Month must be between 1 and 12.');
    }
  }

  RotationStateSnapshot _buildRotationStateSnapshot({
    required DateTime date,
    required RotationConfiguration configuration,
    required Map<String, ShiftType> teamShifts,
  }) {
    if (configuration.cycle.isEmpty) {
      throw StateError('Rotation configuration cycle cannot be empty.');
    }

    final teamPhaseByTeam = <String, int>{};
    for (final team in configuration.teamOrder) {
      final shift = teamShifts[team];
      if (shift == null) continue;
      final index = configuration.cycle.indexOf(shift);
      if (index >= 0) {
        teamPhaseByTeam[team] = index;
      }
    }

    final referenceOnly = DateTime.utc(
      configuration.referenceDate.year,
      configuration.referenceDate.month,
      configuration.referenceDate.day,
    );
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
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
