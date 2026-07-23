import 'package:objectbox/objectbox.dart';

import '../../../objectBox/Entity.dart';
import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/enums/shift_type.dart';

/// Read-only adapter for the legacy Staff/ActiviteJour ObjectBox model.
///
/// It is intentionally isolated from the new planning domain. Historical
/// records are read and converted; they are never recalculated.
class LegacyPlanningReader {
  final Box<Staff> staffBox;

  const LegacyPlanningReader(this.staffBox);

  List<PlanningAssignment> readMonth({
    required int year,
    required int month,
  }) {
    final result = <PlanningAssignment>[];
    final maxDay = DateTime(year, month + 1, 0).day;

    for (final staff in staffBox.getAll()) {
      for (final activity in staff.activites) {
        if (activity.jour < 1 || activity.jour > maxDay) continue;

        final date = DateTime(year, month, activity.jour);
        result.add(
          PlanningAssignment(
            staffId: staff.id,
            date: date,
            team: staff.equipe,
            shift: _shift(activity.statut),
            code: activity.statut,
            note: null,
          ),
        );
      }
    }

    return List.unmodifiable(result);
  }

  PlanningSnapshot? toHistoricalSnapshot({
    required int year,
    required int month,
    String configurationId = 'legacy-import',
    int configurationVersion = 1,
  }) {
    final assignments = readMonth(year: year, month: month);
    if (assignments.isEmpty) return null;

    return PlanningSnapshot(
      id: 'legacy-$year-$month',
      year: year,
      month: month,
      branchId: null,
      configurationId: configurationId,
      configurationVersion: configurationVersion,
      engineVersion: 'legacy-import',
      revision: 1,
      createdAt: DateTime.now(),
      publishedAt: DateTime.now(),
      assignments: assignments,
      continuityDate: assignments
          .map((item) => item.date)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  ShiftType _shift(String status) {
    switch (status.trim().toLowerCase()) {
      case 'j':
      case 'jour':
      case 'day':
        return ShiftType.day;
      case 'n':
      case 'nuit':
      case 'night':
        return ShiftType.night;
      case 'r':
      case 're':
      case 'repos':
      case 'rest':
        return ShiftType.rest;
      default:
        return ShiftType.other;
    }
  }
}
