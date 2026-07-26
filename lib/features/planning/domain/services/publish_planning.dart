import '../entities/planning_publication.dart';
import '../entities/planning_snapshot.dart';
import '../repositories/planning_repository.dart';
import 'planning_integrity_checker.dart';
import 'planning_validator.dart';

/// Publishes the current persisted draft exactly once.
///
/// Publication is an explicit state transition. The repository is the final
/// authority for atomic compare-and-publish semantics, so a stale draft or a
/// concurrent publication is rejected at the persistence boundary.
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
    if (draft.isPublished) {
      throw StateError(
        'A planning snapshot that is already published cannot be published again.',
      );
    }

    final persisted = await repository.findByRevision(
      year: draft.year,
      month: draft.month,
      revision: draft.revision,
      branchId: draft.branchId,
    );

    if (persisted == null) {
      throw StateError(
        'Planning revision ${draft.revision} must be persisted before publication.',
      );
    }

    if (persisted.isPublished) {
      throw StateError(
        'Planning revision ${draft.revision} is already published.',
      );
    }

    if (persisted.id != draft.id) {
      throw StateError(
        'The planning draft is stale: its persisted identity no longer matches.',
      );
    }

    final latest = await repository.findLatestByMonth(
      year: draft.year,
      month: draft.month,
      branchId: draft.branchId,
    );

    if (latest == null || latest.id != draft.id || latest.revision != draft.revision) {
      throw StateError(
        'The planning draft is stale. A newer revision is already persisted.',
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

    final publishedAt = DateTime.now().toUtc();
    final published = draft.copyWith(publishedAt: publishedAt);
    await repository.publishRevision(published);

    final confirmed = await repository.findByRevision(
      year: published.year,
      month: published.month,
      revision: published.revision,
      branchId: published.branchId,
    );

    if (confirmed == null || !confirmed.isPublished) {
      throw StateError(
        'Planning publication completed without a readable published revision.',
      );
    }

    return PlanningPublication(
      snapshot: confirmed,
      publishedAt: confirmed.publishedAt ?? publishedAt,
    );
  }
}
