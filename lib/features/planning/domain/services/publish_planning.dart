import '../entities/planning_publication.dart';
import '../entities/planning_snapshot.dart';
import '../repositories/planning_repository.dart';
import 'planning_integrity_checker.dart';
import 'planning_validator.dart';

/// Publishes a validated draft exactly once.
///
/// The repository implementation is responsible for atomic persistence and
/// uniqueness enforcement. This use case never recalculates the snapshot.
class PublishPlanning {
  final PlanningRepository repository;
  final PlanningValidator validator;
  final PlanningIntegrityChecker integrityChecker;

  const PublishPlanning({
    required this.repository,
    required this.validator,
    required this.integrityChecker,
  });

  Future<PlanningPublication> call(PlanningSnapshot draft) async {
    final existing = await repository.findPublishedByMonth(
      year: draft.year,
      month: draft.month,
      branchId: draft.branchId,
    );

    if (existing != null) {
      throw StateError(
        'A planning snapshot already exists for ${draft.year}-${draft.month}.',
      );
    }

    final integrityErrors = integrityChecker.check(draft);
    if (integrityErrors.isNotEmpty) {
      throw StateError(
        'Planning integrity validation failed: ${integrityErrors.join('; ')}',
      );
    }

    final validation = validator.validate(draft);
    if (!validation.isValid) {
      throw StateError(
        'Planning validation failed: ${validation.errors.join('; ')}',
      );
    }

    final publishedAt = DateTime.now();
    final published = draft.copyWith(publishedAt: publishedAt);
    await repository.publishRevision(published);

    return PlanningPublication(
      snapshot: published,
      publishedAt: publishedAt,
    );
  }
}
