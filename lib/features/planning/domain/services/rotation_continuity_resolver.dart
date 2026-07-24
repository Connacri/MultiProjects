import '../entities/rotation_configuration.dart';
import '../entities/rotation_state.dart';
import '../entities/rotation_state_snapshot.dart';
import '../enums/rotation_policy.dart';
import '../repositories/planning_repository.dart';

/// Resolves the persisted rotation checkpoint from which a new planning
/// period must continue.
///
/// Continuity is restored from the last published RotationStateSnapshot, never
/// reconstructed from mutable assignments. This guarantees that editing leave
/// or team order in the current month cannot silently change the next month's
/// rotation checkpoint.
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
    if (checkpoint == null) return null;

    return _toRotationState(
      checkpoint,
      configuration: configuration,
    );
  }

  RotationState _toRotationState(
    RotationStateSnapshot checkpoint, {
    required RotationConfiguration configuration,
  }) {
    final currentTeams = configuration.teamOrder.toSet();
    final retained = <String, int>{
      for (final entry in checkpoint.teamPhaseByTeam.entries)
        if (currentTeams.contains(entry.key)) entry.key: entry.value,
    };

    return RotationState(
      date: checkpoint.date,
      teamShifts: Map.unmodifiable({
        for (final entry in retained.entries)
          entry.key: configuration.cycle[
            entry.value % configuration.cycle.length
          ],
      }),
    );
  }
}
