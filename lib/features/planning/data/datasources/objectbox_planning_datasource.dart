import 'package:objectbox/objectbox.dart';

import '../../../../objectBox/Entity.dart';
import '../../../../objectBox/classeObjectBox.dart';
import '../../../../objectbox.g.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../mappers/planning_snapshot_mapper.dart';
import '../models/planning_persistence_record.dart';
import '../objectbox/planning_snapshot_entity.dart';

/// ObjectBox data source for immutable Planning snapshots.
///
/// New v2 snapshots are preferred. Legacy Planification records remain
/// readable for migration/backward compatibility, but are never overwritten
/// by the v2 publication path.
class ObjectBoxPlanningDataSource {
  final ObjectBox legacyObjectBox;
  final Store store;
  final PlanningSnapshotMapper mapper;

  late final Box<PlanningSnapshotEntity> snapshotBox =
      Box<PlanningSnapshotEntity>(store);
  late final Box<PlanningAssignmentEntity> assignmentBox =
      Box<PlanningAssignmentEntity>(store);

  ObjectBoxPlanningDataSource({
    required this.legacyObjectBox,
    required this.store,
    this.mapper = const PlanningSnapshotMapper(),
  });

  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final current = _findNewByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    if (current != null) return mapper.fromObjectBox(current);

    final legacy = _findLegacyByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    return legacy == null ? null : mapper.fromLegacyRecord(legacy);
  }

  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final candidates = <PlanningSnapshot>[];

    for (final entity in snapshotBox.getAll()) {
      if (entity.publishedAtEpochMs == null) continue;
      if (!_isBefore(entity.year, entity.month, year, month)) continue;
      if (branchId != null && entity.branchId != branchId) continue;
      candidates.add(mapper.fromObjectBox(entity));
    }

    for (final legacy in legacyObjectBox.planificationBox.getAll()) {
      if (!_isBefore(legacy.annee, legacy.mois, year, month)) continue;
      if (branchId != null && legacy.branch.targetId != branchId) continue;
      candidates.add(
        mapper.fromLegacyRecord(
          PlanningPersistenceRecord(
            id: legacy.id,
            month: legacy.mois,
            year: legacy.annee,
            teamOrder: legacy.ordreEquipes,
            branchId: legacy.branch.targetId,
            snapshotJson: legacy.activitesJson,
          ),
        ),
      );
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final left = a.year * 100 + a.month;
      final right = b.year * 100 + b.month;
      return right.compareTo(left);
    });
    return candidates.first;
  }

  Future<bool> exists({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return (await findByMonth(year: year, month: month, branchId: branchId)) !=
        null;
  }

  /// Publishes a snapshot exactly once.
  ///
  /// A month/branch that already has a v2 snapshot is immutable and cannot be
  /// replaced through this API. Legacy data is read-only from the v2 path.
  Future<void> publish(PlanningSnapshot snapshot) async {
    store.runInTx(TxMode.write, () {
      final existing = _findNewByMonth(
        year: snapshot.year,
        month: snapshot.month,
        branchId: snapshot.branchId,
      );
      if (existing != null) {
        throw StateError(
          'A planning snapshot already exists for ${snapshot.year}-${snapshot.month}.',
        );
      }

      final entity = mapper.toObjectBox(snapshot);
      final snapshotId = snapshotBox.put(entity);
      for (final assignment in entity.assignments) {
        assignment.snapshot.targetId = snapshotId;
        assignmentBox.put(assignment);
      }
    });
  }

  PlanningSnapshotEntity? _findNewByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month),
        )
        .build();
    try {
      for (final entity in query.find()) {
        if (branchId == null || entity.branchId == branchId) return entity;
      }
      return null;
    } finally {
      query.close();
    }
  }

  PlanningPersistenceRecord? _findLegacyByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    final query = legacyObjectBox.planificationBox
        .query(
          Planification_.annee.equals(year) &
              Planification_.mois.equals(month),
        )
        .build();

    try {
      for (final legacy in query.find()) {
        if (branchId == null || legacy.branch.targetId == branchId) {
          return PlanningPersistenceRecord(
            id: legacy.id,
            month: legacy.mois,
            year: legacy.annee,
            teamOrder: legacy.ordreEquipes,
            branchId: legacy.branch.targetId,
            snapshotJson: legacy.activitesJson,
          );
        }
      }
      return null;
    } finally {
      query.close();
    }
  }

  bool _isBefore(int leftYear, int leftMonth, int rightYear, int rightMonth) {
    if (leftYear != rightYear) return leftYear < rightYear;
    return leftMonth < rightMonth;
  }
}
