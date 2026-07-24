import 'package:objectbox/objectbox.dart';

import '../../../../objectbox.g.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/rotation_period.dart';
import '../../domain/repositories/rotation_configuration_repository.dart';
import '../mappers/rotation_configuration_mapper.dart';
import '../objectbox/rotation_configuration_entity.dart';

/// ObjectBox implementation for versioned rotation configurations and periods.
class ObjectBoxRotationConfigurationRepository
    implements RotationConfigurationRepository {
  final Store store;
  final int branchId;
  final RotationConfigurationMapper mapper;

  late final Box<RotationConfigurationEntity> configurationBox =
      Box<RotationConfigurationEntity>(store);
  late final Box<RotationPeriodEntity> periodBox =
      Box<RotationPeriodEntity>(store);

  ObjectBoxRotationConfigurationRepository({
    required this.store,
    this.branchId = 0,
    this.mapper = const RotationConfigurationMapper(),
  });

  @override
  Future<RotationConfiguration?> findById(String id) async {
    final query = configurationBox
        .query(
          RotationConfigurationEntity_.branchId.equals(branchId) &
              RotationConfigurationEntity_.name.equals(id),
        )
        .order(RotationConfigurationEntity_.version, flags: Order.descending)
        .build();
    try {
      final entity = query.findFirst();
      return entity == null ? null : mapper.fromObjectBox(entity);
    } finally {
      query.close();
    }
  }

  @override
  Future<RotationConfiguration?> findActive() async {
    final query = configurationBox
        .query(RotationConfigurationEntity_.branchId.equals(branchId))
        .order(RotationConfigurationEntity_.version, flags: Order.descending)
        .build();
    try {
      final entity = query.find().firstWhere(
            (item) => item.active,
            orElse: RotationConfigurationEntity.new,
          );
      return entity.id == 0 ? null : mapper.fromObjectBox(entity);
    } finally {
      query.close();
    }
  }

  @override
  Future<RotationPeriod?> findPeriodFor(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final periods = periodBox
        .query(RotationPeriodEntity_.branchId.equals(branchId))
        .order(RotationPeriodEntity_.startDateEpochMs, flags: Order.descending)
        .build();
    try {
      for (final entity in periods.find()) {
        final start =
            DateTime.fromMillisecondsSinceEpoch(entity.startDateEpochMs);
        final end = entity.endDateEpochMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(entity.endDateEpochMs!);
        final normalizedStart = DateTime(start.year, start.month, start.day);
        final normalizedEnd =
            end == null ? null : DateTime(end.year, end.month, end.day);
        if (!day.isBefore(normalizedStart) &&
            (normalizedEnd == null || !day.isAfter(normalizedEnd))) {
          final configuration = await _findConfigurationByObjectBoxId(
            entity.configurationId,
          );
          if (configuration == null) return null;
          return RotationPeriod(
            id: 'obx-period-${entity.id}',
            configurationId: configuration.id,
            configurationVersion: configuration.version,
            startDate: start,
            endDate: end,
          );
        }
      }
      return null;
    } finally {
      periods.close();
    }
  }

  /// Creates a new version. Existing versions are never mutated.
  Future<RotationConfiguration> saveVersion({
    required RotationConfiguration configuration,
  }) async {
    final existing = await findById(configuration.id);
    final nextVersion = existing == null
        ? configuration.version
        : (existing.version >= configuration.version
            ? existing.version + 1
            : configuration.version);

    final versioned = configuration.copyWith(version: nextVersion);
    store.runInTransaction(TxMode.write, () {
      final entity = mapper.toObjectBox(
        configuration: versioned,
        branchId: branchId,
      );
      configurationBox.put(entity);
    });
    return versioned;
  }

  Future<RotationConfiguration?> _findConfigurationByObjectBoxId(int id) async {
    final entity = configurationBox.get(id);
    return entity == null ? null : mapper.fromObjectBox(entity);
  }
}
