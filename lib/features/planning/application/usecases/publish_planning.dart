import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../../domain/services/planning_validator.dart';

class InvalidPlanningException implements Exception {
  final List<String> errors;

  const InvalidPlanningException(this.errors);

  @override
  String toString() => 'Invalid planning: ${errors.join('; ')}';
}

/// Validates and publishes a draft. Repository implementations must persist
/// the snapshot and its assignments atomically.
class PublishPlanning {
  final PlanningRepository planningRepository;
  final PlanningValidator validator;

  const PublishPlanning({
    required this.planningRepository,
    required this.validator,
  });

  Future<void> call(PlanningSnapshot snapshot) async {
    final validation = validator.validate(snapshot);
    if (!validation.isValid) {
      throw InvalidPlanningException(validation.errors);
    }

    final exists = await planningRepository.exists(
      year: snapshot.year,
      month: snapshot.month,
      branchId: snapshot.branchId,
    );

    if (exists) {
      throw StateError(
        'Cannot publish over an existing planning snapshot for '
        '${snapshot.year}-${snapshot.month}',
      );
    }

    await planningRepository.publish(snapshot);
  }
}
