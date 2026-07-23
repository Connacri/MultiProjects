import 'package:objectbox/objectbox.dart';

import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';
import '../mappers/planning_objectbox_mapper.dart';
import '../objectbox/planning_snapshot_entity.dart';

/// ObjectBox implementation for new planning snapshots.
///
/// Publication uses one write transaction for the snapshot and all its
/// assignments. The month uniqueness check is repeated inside the transaction
/// to reduce the risk of concurrent duplicate publications.
class ObjectBoxPlanningRepositoryV2 implements PlanningRepository {
  final Store store;
  final Box<PlanningSnapshotEntity> snapshotBox;
  final PlanningObjectBoxMapper mapper;

  const ObjectBoxPlanningRepositoryV2({
    required this.store,
    required this.snapshotBox,
    this.mapper = const PlanningObjectBoxMapper(),
  });

  @override
  Future<bool> exists({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return await findByMonth(
          year: year,
          month: month,
          branchId: branchId,
        ) !=
        null;
  }

  @override
  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final query = snapshotBox
        .query(
          PlanningSnapshotEntity_.year.equals(year) &
              PlanningSnapshotEntity_.month.equals(month),
        )
        .build();
    try {
      final entities = query.find();
      for (final entity in entities) {
        if (branchId == null || entity.branchId == branchId) {
          return mapper.toDomain(entity);
        }
      }
      return null;
    } finally {
      query.close();
    }
  }

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final candidates = snapshotBox.getAll()
      ..removeWhere((item) {
        if (branchId != null && item.branchId != branchId) return true;
        if (item.publishedAtEpochMs == null) return true;
        return item.year > year ||
            (item.year == year && item.month >= month);
      });

    candidates.sort((a, b) {
      final left = a.year * 100 + a.month;
      final right = b.year * 100 + b.month;
      return right.compareTo(left);
    });

    return candidates.isEmpty ? null : mapper.toDomain(candidates.first);
  }

  @override
  Future<void> publish(PlanningSnapshot snapshot) async {
    store.runInTx(TxMode.write, () {
      final existing = _findEntityByMonth(
        year: snapshot.year,
        month: snapshot.month,
        branchId: snapshot.branchId,
      );
      if (existing != null) {
        throw StateError('Planning already published for this month.');
      }

      final entity = PlanningSnapshotEntity()
        ..branchId = snapshot.branchId ?? 0
        ..year = snapshot.year
        ..month = snapshot.month
        ..configurationId = snapshot.configurationId
        ..configurationVersion = snapshot.configurationVersion
        ..engineVersion = snapshot.engineVersion
        ..revision = snapshot.revision
        ..status = 1
        ..createdAtEpochMs = snapshot.createdAt.millisecondsSinceEpoch
        ..publishedAtEpochMs = snapshot.publishedAt?.millisecondsSinceEpoch;

      for (final assignment in snapshot.assignments) {
        final item = PlanningAssignmentEntity()
          ..staffId = assignment.staffId
          ..dateEpochMs = DateTime(
            assignment.date.year,
            assignment.date.month,
            assignment.date.day,
          ).millisecondsSinceEpoch
          ..team = assignment.team
          ..shift = mapper.shiftToString(assignment.shift)
          ..code = assignment.code
          ..note = assignment.note;
        entity.assignments.add(item);
      }

      snapshotBox.put(entity);
    });
  }

  PlanningSnapshotEntity? _findEntityByMonth({
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
}
