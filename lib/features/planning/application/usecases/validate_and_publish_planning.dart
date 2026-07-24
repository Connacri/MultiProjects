import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../../domain/services/planning_validator.dart';

class InvalidPlanningException implements Exception {
  final List<String> errors;

  const InvalidPlanningException(this.errors);

  @override
  String toString() => 'Invalid planning: ${errors.join('; ')}';
}

/// Application-level publication gate.
///
/// Publication is always revalidated from the current snapshot. A previous UI
/// validation result is never trusted as proof that the draft is still valid.
class ValidateAndPublishPlanning {
  final PlanningRepository planningRepository;
  final PlanningValidator validator;

  const ValidateAndPublishPlanning({
    required this.planningRepository,
    required this.validator,
  });

  Future<PlanningSnapshot> call(PlanningSnapshot snapshot) async {
    final validation = validator.validate(snapshot);
    if (!validation.isValid) {
      throw InvalidPlanningException(validation.errors);
    }

    final exists = await planningRepository.findLatestByMonth(
      year: snapshot.year,
      month: snapshot.month,
      branchId: snapshot.branchId,
    );

    if (exists != null && exists.id != snapshot.id) {
      throw StateError(
        'Cannot publish over an existing planning snapshot for '
        '${snapshot.year}-${snapshot.month}',
      );
    }

    final published = snapshot.copyWith(
      publishedAt: DateTime.now(),
    );

    await planningRepository.publishRevision(published);
    return published;
  }
}
