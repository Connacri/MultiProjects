import '../../../../../objectbox.g.dart';
import '../objectbox/planning_snapshot_entity.dart';
import '../objectbox/rotation_state_snapshot_entity.dart';

/// Low-level ObjectBox store for immutable Planning snapshots.
///
/// Snapshot, rotation checkpoint and assignments are persisted atomically.
/// Higher layers own validation and publication business rules; this store
/// enforces the final compare-and-write invariants inside the ObjectBox write
/// transaction.
class ObjectBoxPlanningSnapshotStore {
  final Store store;
  final Box<PlanningSnapshotEntity> snapshotBox;
  final Box<PlanningAssignmentEntity> assignmentBox;
  final Box<RotationStateSnapshotEntity> rotationStateBox;

  const ObjectBoxPlanningSnapshotStore({
    required this.store,
    required this.snapshotBox,
    required this.assignmentBox,
    required this.rotationStateBox,
  });

  PlanningSnapshotEntity? findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    return _findSingle(
      year: year,
      month: month,
      branchId: branchId,
      predicate: (snapshot) => snapshot.publishedAtEpochMs != null,
      preferPublished: true,
    );
  }

  PlanningSnapshotEntity? findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    return _findSingle(
      year: year,
      month: month,
      branchId: branchId,
      predicate: (_) => true,
      preferPublished: false,
    );
  }

  PlanningSnapshotEntity? findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month) &
              PlanningSnapshotEntity_.revision.equals(revision),
        )
        .build();

    try {
      for (final snapshot in query.find()) {
        if (_matchesBranch(snapshot, branchId)) return snapshot;
      }
      return null;
    } finally {
      query.close();
    }
  }

  PlanningSnapshotEntity? findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) {
    final targetMonth = year * 100 + month;
    final candidates = snapshotBox
        .getAll()
        .where(
          (snapshot) =>
              snapshot.publishedAtEpochMs != null &&
              _matchesBranch(snapshot, branchId) &&
              (snapshot.year * 100 + snapshot.month) < targetMonth,
        )
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final monthCompare =
          (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
      if (monthCompare != 0) return monthCompare;
      final publishedCompare =
          (b.publishedAtEpochMs ?? 0).compareTo(a.publishedAtEpochMs ?? 0);
      if (publishedCompare != 0) return publishedCompare;
      final revisionCompare = b.revision.compareTo(a.revision);
      if (revisionCompare != 0) return revisionCompare;
      return b.id.compareTo(a.id);
    });

    return candidates.first;
  }

  /// Persists a new immutable snapshot revision with its rotation checkpoint
  /// and assignments atomically.
  ///
  /// Existing rows are never updated. The only valid operation is insertion
  /// of a strictly newer revision for the same month and branch.
  void putAtomically({
    required PlanningSnapshotEntity snapshot,
    required RotationStateSnapshotEntity rotationState,
    required List<PlanningAssignmentEntity> assignments,
  }) {
    _assertNewEntity(snapshot.id, 'snapshot');
    _assertNewEntity(rotationState.id, 'rotation state');

    if (snapshot.year != rotationState.year ||
        snapshot.month != rotationState.month ||
        snapshot.revision != rotationState.revision ||
        snapshot.branchId != rotationState.branchId) {
      throw ArgumentError(
        'Snapshot and rotation state must belong to the same branch, month '
        'and revision.',
      );
    }

    for (final assignment in assignments) {
      _assertNewEntity(assignment.id, 'planning assignment');
      if (assignment.snapshot.targetId != 0) {
        throw StateError(
          'Planning assignments must not reference an existing snapshot.',
        );
      }
    }

    store.runInTransaction(TxMode.write, () {
      final latest = findLatestByMonth(
        year: snapshot.year,
        month: snapshot.month,
        branchId: snapshot.branchId,
      );
      if (latest != null && snapshot.revision <= latest.revision) {
        throw StateError(
          'Planning snapshot revisions must increase monotonically. '
          'Expected a revision greater than ${latest.revision}.',
        );
      }

      final published = findPublishedByMonth(
        year: snapshot.year,
        month: snapshot.month,
        branchId: snapshot.branchId,
      );
      if (published != null && snapshot.revision <= published.revision) {
        throw StateError(
          'A published planning snapshot is immutable. '
          'New revisions must be strictly greater than ${published.revision}.',
        );
      }

      final rotationStateId = rotationStateBox.put(rotationState);
      snapshot.rotationState.targetId = rotationStateId;
      final snapshotId = snapshotBox.put(snapshot);

      for (final assignment in assignments) {
        assignment.snapshot.targetId = snapshotId;
        assignmentBox.put(assignment);
      }
    });
  }

  /// Atomically publishes an already persisted draft revision.
  ///
  /// This is a compare-and-publish operation. The target must still be the
  /// latest persisted revision and must still be unpublished at transaction
  /// time. No read-then-write race in the application layer can bypass these
  /// checks because the compare happens inside the ObjectBox write transaction.
  void publishAtomically({
    required PlanningSnapshotEntity snapshot,
  }) {
    if (snapshot.id == 0) {
      throw StateError('A persisted snapshot ID is required for publication.');
    }
    if (snapshot.publishedAtEpochMs == null) {
      throw StateError(
        'A snapshot must contain publishedAtEpochMs before publication.',
      );
    }

    store.runInTransaction(TxMode.write, () {
      final persisted = snapshotBox.get(snapshot.id);
      if (persisted == null) {
        throw StateError('Planning snapshot ${snapshot.id} no longer exists.');
      }

      if (persisted.publishedAtEpochMs != null) {
        if (persisted.publishedAtEpochMs == snapshot.publishedAtEpochMs) {
          return;
        }
        throw StateError(
          'Planning snapshot ${snapshot.id} is already published.',
        );
      }

      final latest = findLatestByMonth(
        year: persisted.year,
        month: persisted.month,
        branchId: persisted.branchId,
      );
      if (latest == null || latest.id != persisted.id) {
        throw StateError(
          'Cannot publish stale planning revision ${persisted.revision}. '
          'A newer revision is already persisted.',
        );
      }

      if (snapshot.year != persisted.year ||
          snapshot.month != persisted.month ||
          snapshot.revision != persisted.revision ||
          snapshot.branchId != persisted.branchId) {
        throw StateError(
          'Publication payload does not match the persisted planning revision.',
        );
      }

      if (snapshot.publishedAtEpochMs! < persisted.createdAtEpochMs) {
        throw StateError(
          'Publication date cannot be before snapshot creation date.',
        );
      }

      persisted.publishedAtEpochMs = snapshot.publishedAtEpochMs;
      snapshotBox.put(persisted);
    });
  }

  void _assertNewEntity(int id, String entityName) {
    if (id != 0) {
      throw StateError(
        'Persisting an existing $entityName entity is forbidden.',
      );
    }
  }

  PlanningSnapshotEntity? _findSingle({
    required int year,
    required int month,
    required int? branchId,
    required bool Function(PlanningSnapshotEntity snapshot) predicate,
    required bool preferPublished,
  }) {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month),
        )
        .build();

    try {
      final snapshots = query
          .find()
          .where(
            (snapshot) =>
                _matchesBranch(snapshot, branchId) && predicate(snapshot),
          )
          .toList();

      if (snapshots.isEmpty) return null;

      snapshots.sort((a, b) {
        if (preferPublished) {
          final publishedCompare =
              (b.publishedAtEpochMs ?? 0).compareTo(a.publishedAtEpochMs ?? 0);
          if (publishedCompare != 0) return publishedCompare;
        }
        final revisionCompare = b.revision.compareTo(a.revision);
        if (revisionCompare != 0) return revisionCompare;
        final createdCompare = b.createdAtEpochMs.compareTo(a.createdAtEpochMs);
        if (createdCompare != 0) return createdCompare;
        return b.id.compareTo(a.id);
      });

      return snapshots.first;
    } finally {
      query.close();
    }
  }

  bool _matchesBranch(PlanningSnapshotEntity snapshot, int? branchId) {
    if (branchId == null) return true;
    return snapshot.branchId == branchId;
  }
}
