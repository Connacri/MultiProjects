import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../entities/rotation_state_snapshot.dart';
import '../enums/rotation_policy.dart';
import '../repositories/planning_repository.dart';

/// Resolves the persisted rotation checkpoint from which a new planning
/// period must continue.
///
/// Continuity is restored exclusively from the last published
/// RotationStateSnapshot. Mutable assignments, leave changes, or draft
/// revisions are never used as the continuity source.
class RotationContinuityResolver {
  final PlanningRepository planningRepository;

  const RotationContinuityResolver(this.planningRepository);

  Future<RotationState?> resolve({
    required DateTime targetDate,
    required RotationConfiguration configuration,
    int? branchId,
  }) async {
    if (configuration.policy == RotationPolicy.fixedReference) {
      return null;
    }

    final previous = await planningRepository.findPreviousPublished(
      year: targetDate.year,
      month: targetDate.month,
      branchId: branchId,
    );

    final checkpoint = previous?.rotationState;
    if (checkpoint == null) {
      return null;
    }

    return _toRotationState(
      checkpoint,
      configuration: configuration,
    );
  }

  RotationState _toRotationState(
    RotationStateSnapshot checkpoint, {
    required RotationConfiguration configuration,
  }) {
    if (configuration.cycle.isEmpty) {
      throw StateError('Rotation configuration cycle cannot be empty.');
    }

    final currentTeams = configuration.teamOrder.toSet();
    final retained = <String, int>{
      for (final entry in checkpoint.teamPhaseByTeam.entries)
        if (currentTeams.contains(entry.key)) entry.key: entry.value,
    };

    return RotationState(
      date: checkpoint.date,
      teamShifts: Map.unmodifiable({
        for (final entry in retained.entries)
          entry.key:
              configuration.cycle[entry.value % configuration.cycle.length],
      }),
    );
  }
}
