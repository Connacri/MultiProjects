import '../entities/planning_snapshot.dart';

/// Persistence contract for the Planning revision lifecycle.
///
/// The repository deliberately exposes explicit read semantics so callers never
/// have to guess whether they are loading the current publication, the latest
/// draft, or an exact historical revision.
abstract interface class PlanningRepository {
  /// Returns the currently published revision for [year]/[month]/[branchId].
  Future<PlanningSnapshot?> findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  });

  /// Returns the latest effective revision (published or draft).
  Future<PlanningSnapshot?> findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  });

  /// Returns an exact revision.
  Future<PlanningSnapshot?> findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  });

  /// Returns the most recent published planning strictly before the requested
  /// month. Used to restore rotation continuity.
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  });

  /// Persists a new revision atomically with all its assignments.
  Future<void> saveRevision(PlanningSnapshot snapshot);

  /// Publishes a validated revision atomically.
  ///
  /// Implementations must preserve the previous published revision as history
  /// and must never leave a partially published state.
  Future<void> publishRevision(PlanningSnapshot snapshot);
}
