import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../../domain/services/planning_validator.dart';

class InvalidPlanningException implements Exception {
  final List<String> errors;

  const InvalidPlanningException(this.errors);

  @override
  String toString() => 'Invalid planning: ${errors.join('; ')}';
}

/// Validates and publishes a draft.
///
/// Publication always validates at the application boundary. The repository
/// owns the atomic persistence boundary and must persist the immutable snapshot
/// together with its assignments and rotation checkpoint.
class PublishPlanning {
  final PlanningRepository planningRepository;
  final PlanningValidator validator;

  const PublishPlanning({
    required this.planningRepository,
    required this.validator,
  });

  Future<PlanningSnapshot> call(PlanningSnapshot snapshot) async {
    final validation = validator.validate(snapshot);
    if (!validation.isValid) {
      throw InvalidPlanningException(validation.errors);
    }

    final published = snapshot.copyWith(
      publishedAt: DateTime.now(),
    );

    await planningRepository.publishRevision(published);
    return published;
  }
}
