import 'package:flutter/foundation.dart';

import '../../domain/entities/planning_revision.dart';
import '../../domain/services/planning_revision_policy.dart';

/// Presentation state for post-validation edits shared by Desktop and Mobile.
///
/// This provider deliberately keeps the revision state independent from the
/// validation result: any accepted leave/team-order edit invalidates the
/// previous validation and requires a fresh validation before publication.
class PlanningRevisionUiProvider extends ChangeNotifier {
  final PlanningRevisionPolicy policy;

  PlanningRevisionUiProvider({this.policy = const PlanningRevisionPolicy()});

  PlanningRevision? _revision;

  PlanningRevision? get revision => _revision;
  bool get isModified => _revision != null && policy.isModified(_revision!);
  bool get requiresRevalidation =>
      _revision != null && policy.requiresRevalidation(_revision!);
  bool get isValidated => _revision?.validated ?? false;
  List<String> get changedFields =>
      List.unmodifiable(_revision?.changedFields ?? const <String>[]);

  void setRevision(PlanningRevision? revision) {
    _revision = revision;
    notifyListeners();
  }

  void applyLeaveEdit({
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
  }) {
    final revision = _revision;
    if (revision == null) {
      throw StateError('No planning revision is available.');
    }
    _revision = policy.editLeave(
      revision: revision,
      now: now,
      modifiedBy: modifiedBy,
      effectiveSnapshotId: effectiveSnapshotId,
    );
    notifyListeners();
  }

  void applyTeamOrderEdit({
    required DateTime now,
    required String modifiedBy,
    required String effectiveSnapshotId,
  }) {
    final revision = _revision;
    if (revision == null) {
      throw StateError('No planning revision is available.');
    }
    _revision = policy.editTeamOrder(
      revision: revision,
      now: now,
      modifiedBy: modifiedBy,
      effectiveSnapshotId: effectiveSnapshotId,
    );
    notifyListeners();
  }

  void markValidated({required DateTime validatedAt}) {
    final revision = _revision;
    if (revision == null) return;
    _revision = policy.markValidated(
      revision: revision,
      validatedAt: validatedAt,
    );
    notifyListeners();
  }

  void clear() {
    _revision = null;
    notifyListeners();
  }
}
