import '../entities/planning_snapshot.dart';
import '../entities/rotation_configuration.dart';
import '../enums/planning_snapshot_status.dart';
import '../enums/team_shift.dart';
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
  }) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Month must be between 1 and 12.');
    }

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final assignments = <DateTime, Map<String, TeamShift>>{};

    for (var day = firstDay;
        !day.isAfter(lastDay);
        day = day.add(const Duration(days: 1))) {
      assignments[day] = _engine.shiftsForDate(
        configuration: configuration,
        date: day,
      );
    }

    return PlanningSnapshot(
      id: snapshotId,
      year: year,
      month: month,
      configurationId: configuration.id,
      configurationVersion: configuration.version,
      status: PlanningSnapshotStatus.draft,
      assignments: assignments,
    );
  }
}
