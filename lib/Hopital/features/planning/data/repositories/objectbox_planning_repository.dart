import '../../../../../objectBox/Entity.dart';
import '../../../../../objectbox.g.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/rotation_period.dart';
import '../../domain/enums/rotation_policy.dart';
import '../../domain/enums/team_shift.dart';
import '../../domain/repositories/planning_repository.dart';
import '../../domain/repositories/rotation_configuration_repository.dart';
import '../../domain/validators/planning_snapshot_validator.dart';
import '../mappers/planning_snapshot_mapper.dart';
import '../models/planning_persistence_record.dart';
import '../objectbox/rotation_configuration_entity.dart';
import 'objectbox_planning_snapshot_store.dart';

/// Planning repository backed by the atomic ObjectBox snapshot store.
///
/// The repository is the final persistence boundary for the planning
/// lifecycle. Domain validation happens before any write, while the store
/// performs the final compare-and-write checks inside ObjectBox transactions.
class ObjectBoxPlanningRepository
    implements PlanningRepository, RotationConfigurationRepository {
  final ObjectBoxPlanningSnapshotStore snapshotStore;
  final Box<Planification>? legacyPlanificationBox;
  final PlanningSnapshotMapper mapper;
  final PlanningSnapshotValidator validator;

  const ObjectBoxPlanningRepository({
    required this.snapshotStore,
    this.legacyPlanificationBox,
    this.mapper = const PlanningSnapshotMapper(),
    this.validator = const PlanningSnapshotValidator(),
  });

  @override
  Future<PlanningSnapshot?> findPublishedByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final entity = snapshotStore.findPublishedByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    if (entity != null) return mapper.fromObjectBox(entity);
    return _findLegacyByMonth(year: year, month: month, branchId: branchId);
  }

  @override
  Future<PlanningSnapshot?> findLatestByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final entity = snapshotStore.findLatestByMonth(
      year: year,
      month: month,
      branchId: branchId,
    );
    if (entity != null) return mapper.fromObjectBox(entity);
    return _findLegacyByMonth(year: year, month: month, branchId: branchId);
  }

  PlanningSnapshot? _findLegacyByMonth({
    required int year,
    required int month,
    int? branchId,
  }) {
    final box = legacyPlanificationBox;
    if (box == null) return null;

    final query = box
        .query(Planification_.annee.equals(year) & Planification_.mois.equals(month))
        .build();
    try {
      for (final legacy in query.find()) {
        if (branchId != null && legacy.branch.targetId != branchId) continue;
        return mapper.fromLegacyRecord(
          PlanningPersistenceRecord(
            id: legacy.id,
            month: legacy.mois,
            year: legacy.annee,
            teamOrder: legacy.ordreEquipes,
            branchId: legacy.branch.targetId,
            snapshotJson: legacy.activitesJson,
          ),
        );
      }
      return null;
    } finally {
      query.close();
    }
  }

  @override
  Future<PlanningSnapshot?> findByRevision({
    required int year,
    required int month,
    required int revision,
    int? branchId,
  }) async {
    final entity = snapshotStore.findByRevision(
      year: year,
      month: month,
      revision: revision,
      branchId: branchId,
    );
    return entity == null ? null : mapper.fromObjectBox(entity);
  }

  @override
  Future<PlanningSnapshot?> findPreviousPublished({
    required int year,
    required int month,
    int? branchId,
  }) async {
    final entity = snapshotStore.findPreviousPublished(
      year: year,
      month: month,
      branchId: branchId,
    );
    if (entity != null) return mapper.fromObjectBox(entity);

    final box = legacyPlanificationBox;
    if (box == null) return null;

    final targetMonth = year * 100 + month;
    final candidates = box.getAll().where((legacy) {
      final legacyMonth = legacy.annee * 100 + legacy.mois;
      if (branchId != null && legacy.branch.targetId != branchId) return false;
      return legacyMonth < targetMonth;
    }).toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final monthCompare =
          (b.annee * 100 + b.mois).compareTo(a.annee * 100 + a.mois);
      if (monthCompare != 0) return monthCompare;
      return b.id.compareTo(a.id);
    });

    final legacy = candidates.first;
    return mapper.fromLegacyRecord(
      PlanningPersistenceRecord(
        id: legacy.id,
        month: legacy.mois,
        year: legacy.annee,
        teamOrder: legacy.ordreEquipes,
        branchId: legacy.branch.targetId,
        snapshotJson: legacy.activitesJson,
      ),
    );
  }

  @override
  Future<void> saveRevision(PlanningSnapshot snapshot) async {
    validator.validateOrThrow(snapshot);
    if (snapshot.isPublished) {
      throw StateError(
        'Use publishRevision() for a published planning snapshot.',
      );
    }
    await _persistNewRevision(snapshot);
  }

  @override
  Future<void> publishRevision(PlanningSnapshot snapshot) async {
    validator.validateOrThrow(snapshot);
    if (!snapshot.isPublished) {
      throw StateError(
        'publishRevision expects a snapshot already marked with publishedAt.',
      );
    }
    if (snapshot.publishedAt!.isBefore(snapshot.createdAt)) {
      throw StateError(
        'A published planning snapshot cannot have publishedAt before createdAt.',
      );
    }

    final snapshotEntity = mapper.toObjectBox(snapshot);
    snapshotStore.publishAtomically(snapshot: snapshotEntity);
  }

  /// Compatibility helper for older callers.
  Future<bool> exists({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return (await findLatestByMonth(
              year: year,
              month: month,
              branchId: branchId,
            )) !=
        null;
  }

  /// Compatibility helper for older callers.
  Future<PlanningSnapshot?> findByMonth({
    required int year,
    required int month,
    int? branchId,
  }) async {
    return findLatestByMonth(year: year, month: month, branchId: branchId);
  }

  /// Compatibility helper for older callers.
  Future<void> publish(PlanningSnapshot snapshot) async {
    await publishRevision(snapshot);
  }

  Future<void> _persistNewRevision(PlanningSnapshot snapshot) async {
    final rotationState = snapshot.rotationState;
    if (rotationState == null) {
      throw StateError(
        'PlanningSnapshot.rotationState must be set before persistence.',
      );
    }

    final snapshotEntity = mapper.toObjectBox(snapshot);
    final rotationStateEntity = mapper.toRotationStateObjectBox(
      rotationState,
      branchId: snapshot.branchId ?? 0,
      year: snapshot.year,
      month: snapshot.month,
      revision: snapshot.revision,
    );
    final assignmentEntities = snapshot.assignments
        .map(mapper.toObjectBoxAssignment)
        .toList(growable: false);

    snapshotStore.putAtomically(
      snapshot: snapshotEntity,
      rotationState: rotationStateEntity,
      assignments: assignmentEntities,
    );
  }

  // --- RotationConfigurationRepository ---

  @override
  Future<RotationConfiguration?> findById(String id) async {
    final box = Box<RotationConfigurationEntity>(snapshotStore.store);
    final query = box.query(RotationConfigurationEntity_.name.equals(id)).build();
    final entity = query.findFirst();
    query.close();
    if (entity == null) return null;
    return _mapConfigEntity(entity);
  }

  @override
  Future<RotationConfiguration?> findActive() async {
    final box = Box<RotationConfigurationEntity>(snapshotStore.store);
    final query = box
        .query(RotationConfigurationEntity_.active.equals(true))
        .order(RotationConfigurationEntity_.version, flags: Order.descending)
        .build();
    final entity = query.findFirst();
    query.close();
    if (entity == null) return null;
    return _mapConfigEntity(entity);
  }

  @override
  Future<RotationPeriod?> findPeriodFor(DateTime date) async {
    final epoch = date.millisecondsSinceEpoch;
    final box = Box<RotationPeriodEntity>(snapshotStore.store);
    final query = box
        .query(RotationPeriodEntity_.startDateEpochMs.lessOrEqual(epoch))
        .build();
    final results = query.find();
    query.close();
    for (final entity in results) {
      if (entity.endDateEpochMs == null || epoch <= entity.endDateEpochMs!) {
        return RotationPeriod(
          id: entity.id.toString(),
          startDate: DateTime.fromMillisecondsSinceEpoch(entity.startDateEpochMs),
          endDate: entity.endDateEpochMs != null
              ? DateTime.fromMillisecondsSinceEpoch(entity.endDateEpochMs!)
              : null,
          configurationId: entity.configurationId.toString(),
          configurationVersion: 1,
        );
      }
    }
    return null;
  }

  @override
  Future<RotationConfiguration> saveVersion({
    required RotationConfiguration configuration,
  }) async {
    final box = Box<RotationConfigurationEntity>(snapshotStore.store);
    final entity = RotationConfigurationEntity()
      ..branchId = 0
      ..version = configuration.version
      ..name = configuration.id
      ..teamOrderJson = configuration.teamOrder.join(',')
      ..cycleJson =
          configuration.cycle.map((s) => s.name).join(',')
      ..policy = configuration.policy.index
      ..referenceDateEpochMs =
          configuration.referenceDate?.millisecondsSinceEpoch ?? 0
      ..referencePhaseIndex = configuration.referencePhaseIndex
      ..active = true;
    box.put(entity);
    return configuration;
  }

  RotationConfiguration _mapConfigEntity(RotationConfigurationEntity entity) {
    final teamOrder = entity.teamOrderJson.split(',').where((s) => s.isNotEmpty).toList();
    final cycle = entity.cycleJson
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) {
          switch (s.toLowerCase()) {
            case 'day': return TeamShift.day;
            case 'night': return TeamShift.night;
            case 'rest': return TeamShift.rest;
            default: return TeamShift.rest;
          }
        })
        .toList();
    return RotationConfiguration(
      id: entity.name.isEmpty ? 'obx-${entity.id}' : entity.name,
      version: entity.version,
      teamOrder: teamOrder,
      cycle: cycle,
      policy: entity.policy >= 0 && entity.policy < RotationPolicy.values.length
          ? RotationPolicy.values[entity.policy]
          : RotationPolicy.continueFromPreviousPublished,
      referenceDate: entity.referenceDateEpochMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(entity.referenceDateEpochMs)
          : null,
      referencePhaseIndex: entity.referencePhaseIndex,
    );
  }
}
