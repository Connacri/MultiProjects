import 'dart:convert';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/enums/shift_type.dart';
import '../models/planning_persistence_record.dart';

/// Maps legacy ObjectBox monthly snapshots to the new immutable domain model.
///
/// Critical rule: this mapper only reads persisted values. It never invokes
/// RotationEngine, so historical planning data cannot be recalculated during
/// migration.
class LegacyPlanningMapper {
  const LegacyPlanningMapper();

  PlanningSnapshot toDomain(PlanningPersistenceRecord record) {
    return PlanningSnapshot(
      id: 'legacy-${record.id}',
      year: record.year,
      month: record.month,
      branchId: record.branchId,
      configurationId: 'legacy:${record.teamOrder}',
      configurationVersion: 1,
      engineVersion: 'legacy',
      revision: 1,
      createdAt: DateTime(record.year, record.month, 1),
      publishedAt: DateTime(record.year, record.month, 1),
      assignments: _parseAssignments(
        record.snapshotJson,
        year: record.year,
        month: record.month,
      ),
    );
  }

  List<PlanningAssignment> _parseAssignments(
    String? json, {
    required int year,
    required int month,
  }) {
    if (json == null || json.isEmpty) return const [];

    try {
      final root = jsonDecode(json);
      if (root is! Map<String, dynamic>) return const [];
      final raw = root['activites'];
      if (raw is! List) return const [];

      final result = <PlanningAssignment>[];
      final maxDay = DateTime(year, month + 1, 0).day;

      for (final staffEntry in raw) {
        if (staffEntry is! Map) continue;
        final staffId = _toInt(staffEntry['staffId']);
        if (staffId == null) continue;
        final days = staffEntry['jours'];
        if (days is! List) continue;

        for (final dayEntry in days) {
          if (dayEntry is! Map) continue;
          final day = _toInt(dayEntry['jour']);
          if (day == null || day < 1 || day > maxDay) continue;
          final status = dayEntry['statut']?.toString() ?? '';
          result.add(
            PlanningAssignment(
              staffId: staffId,
              date: DateTime(year, month, day),
              shift: _mapShift(status),
              code: status,
            ),
          );
        }
      }
      return List.unmodifiable(result);
    } catch (_) {
      return const [];
    }
  }

  ShiftType _mapShift(String status) {
    switch (status.toUpperCase()) {
      case 'J':
      case 'G':
      case 'DAY':
        return ShiftType.day;
      case 'N':
      case 'NIGHT':
        return ShiftType.night;
      default:
        return ShiftType.rest;
    }
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}
