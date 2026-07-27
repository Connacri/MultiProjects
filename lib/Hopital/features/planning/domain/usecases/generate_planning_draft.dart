import '../entities/planning_assignment.dart';
import '../entities/planning_snapshot.dart';
import '../entities/rotation_configuration.dart';
import '../services/rotation_engine.dart';

/// Creates a draft snapshot without persisting or publishing it.
class GeneratePlanningDraft {
  const GeneratePlanningDraft(this._engine);

  final RotationEngine _engine;

  PlanningSnapshot call({
    required String snapshotId,
    required int year,
    required int month,
    required RotationConfiguration configuration,
    required List<int> staffIds,
    required Map<int, String> staffTeams,
  }) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Month must be between 1 and 12.');
    }

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final assignments = <PlanningAssignment>[];

    for (var day = firstDay;
        !day.isAfter(lastDay);
        day = day.add(const Duration(days: 1))) {
      final teamShifts = _engine.shiftsForDate(
        configuration: configuration,
        date: day,
      );
      for (final entry in teamShifts.entries) {
        for (final staffId in staffIds) {
          final team = staffTeams[staffId];
          if (team == entry.key) {
            assignments.add(PlanningAssignment(
              staffId: staffId,
              date: day,
              shift: entry.value,
              team: team,
            ));
          }
        }
      }
    }

    return PlanningSnapshot(
      id: snapshotId,
      year: year,
      month: month,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      revision: 1,
      createdAt: DateTime.now().toUtc(),
      engineVersion: '2.0.0',
      assignments: assignments,
    );
  }
}
