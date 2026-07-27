import 'package:flutter/foundation.dart';

import '../../domain/entities/planning_override.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/enums/shift_type.dart';
import '../../domain/services/planning_override_applier.dart';

/// Local draft editor. It never writes to ObjectBox directly.
///
/// The editor modifies an in-memory immutable snapshot. Publication remains
/// the responsibility of PlanningProvider/PublishPlanning.
class PlanningEditorProvider extends ChangeNotifier {
  final PlanningOverrideApplier overrideApplier;

  PlanningSnapshot? _draft;
  final List<PlanningOverride> _overrides = [];

  PlanningEditorProvider({
    this.overrideApplier = const PlanningOverrideApplier(),
  });

  PlanningSnapshot? get draft => _draft;
  List<PlanningOverride> get overrides => List.unmodifiable(_overrides);

  void load(PlanningSnapshot snapshot) {
    _draft = snapshot;
    _overrides.clear();
    notifyListeners();
  }

  void setAssignment({
    required int staffId,
    required DateTime date,
    required ShiftType shift,
    String? team,
    String? code,
    String? note,
  }) {
    final current = _draft;
    if (current == null) {
      throw StateError('No draft loaded.');
    }

    final override = PlanningOverride(
      staffId: staffId,
      date: date,
      shift: shift,
      team: team,
      code: code,
      note: note,
    );

    _upsertOverride(override);
    final assignments = overrideApplier.apply(
      assignments: current.assignments,
      overrides: [_overrides.last],
    );

    _draft = current.copyWith(assignments: assignments);
    notifyListeners();
  }

  void removeOverride({required int staffId, required DateTime date}) {
    _overrides.removeWhere(
      (item) =>
          item.staffId == staffId &&
          item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day,
    );
    notifyListeners();
  }

  void clear() {
    _draft = null;
    _overrides.clear();
    notifyListeners();
  }

  void _upsertOverride(PlanningOverride override) {
    _overrides.removeWhere(
      (item) =>
          item.staffId == override.staffId &&
          item.date.year == override.date.year &&
          item.date.month == override.date.month &&
          item.date.day == override.date.day,
    );
    _overrides.add(override);
  }
}
