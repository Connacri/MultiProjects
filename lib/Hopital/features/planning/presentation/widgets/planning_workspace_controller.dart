import 'package:flutter/foundation.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_provider.dart';

/// Coordinates the draft between PlanningProvider and PlanningEditorProvider.
///
/// This controller is presentation orchestration only. It does not persist
/// data and never mutates published snapshots.
class PlanningWorkspaceController extends ChangeNotifier {
  final PlanningProvider planningProvider;
  final PlanningEditorProvider editorProvider;

  bool _isEditing = false;

  PlanningWorkspaceController({
    required this.planningProvider,
    required this.editorProvider,
  });

  bool get isEditing => _isEditing;
  bool get hasDraft => planningProvider.draft != null;
  bool get hasEditorDraft => editorProvider.draft != null;
  bool get canPublish => hasEditorDraft && !_isEditingBusy;
  bool get _isEditingBusy => planningProvider.isBusy;

  void beginEditing() {
    final draft = planningProvider.draft;
    if (draft == null) {
      throw StateError('No planning draft is available for editing.');
    }

    editorProvider.load(draft);
    _isEditing = true;
    notifyListeners();
  }

  void applyEditorDraft() {
    final edited = editorProvider.draft;
    if (edited == null) {
      throw StateError('No edited planning draft is available.');
    }
    if (edited.assignments.isEmpty) {
      throw StateError(
        'The edited draft has no assignments. '
        'Cannot apply an empty draft.',
      );
    }

    planningProvider.setDraft(edited);
    _isEditing = false;
    notifyListeners();
  }

  void cancelEditing() {
    editorProvider.clear();
    _isEditing = false;
    notifyListeners();
  }

  Future<void> publishDraft() async {
    final draft = planningProvider.draft;
    if (draft == null) {
      throw StateError('No planning draft is available to publish.');
    }
    await planningProvider.publish();
  }

  Future<void> publishEditedDraft() async {
    final editorDraft = editorProvider.draft;
    if (editorDraft != null && editorDraft.assignments.isNotEmpty) {
      applyEditorDraft();
    }
    await publishDraft();
  }
}
