import '../../../../objectBox/Entity.dart';
import '../../../../objectBox/classeObjectBox.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../mappers/legacy_planning_mapper.dart';
import '../models/planning_persistence_record.dart';

/// ObjectBox-only data source for planning persistence.
///
/// It reads legacy `Planification` entities without recalculating their
/// activities. The existing ObjectBox database remains the source of truth
/// during migration.
class ObjectBoxPlanningDataSource {
  final ObjectBox objectBox;
  final LegacyPlanningMapper mapper;

  const ObjectBoxPlanningDataSource({
    required this.objectBox,
    this.mapper = const LegacyPlanningMapper(),
  });

  PlanningSnapshot? findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    final query = objectBox.planificationBox
        .query(Planification_.annee.equals(year) & Planification_.mois.equals(month))
        .build();

    try {
      final records = query.find();
      for (final record in records) {
        if (branchId == null || record.branch.targetId == branchId) {
          return mapper.toDomain(_toRecord(record));
        }
      }
      return null;
    } finally {
      query.close();
    }
  }

  List<PlanningSnapshot> findPublishedBefore({
    required int year,
    required int month,
    int? branchId,
  }) {
    final all = objectBox.planificationBox.getAll();
    final records = all
        .where((record) {
          if (branchId != null && record.branch.targetId != branchId) return false;
          if (record.annee < year) return true;
          return record.annee == year && record.mois < month;
        })
        .map(mapper.toDomain)
        .toList()
      ..sort((a, b) {
        final aKey = a.year * 100 + a.month;
        final bKey = b.year * 100 + b.month;
        return bKey.compareTo(aKey);
      });

    return List.unmodifiable(records);
  }

  PlanningPersistenceRecord _toRecord(Planification entity) {
    return PlanningPersistenceRecord(
      id: entity.id,
      month: entity.mois,
      year: entity.annee,
      teamOrder: entity.ordreEquipes,
      branchId: entity.branch.targetId,
      snapshotJson: entity.activitesJson,
    );
  }
}
