import 'package:flutter/material.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_validation_provider.dart';
import 'editable_planning_snapshot_grid.dart';

/// Draft grid that keeps validation synchronized with editor changes.
///
/// The draft is rendered directly from PlanningSnapshot. No legacy Planning
/// aggregate or presentation conversion is involved.
class PlanningDraftGridWorkspace extends StatefulWidget {
  final PlanningEditorProvider editorProvider;
  final PlanningValidationProvider validationProvider;
  final Map<int, String> staffNames;

  const PlanningDraftGridWorkspace({
    super.key,
    required this.editorProvider,
    required this.validationProvider,
    this.staffNames = const {},
  });

  @override
  State<PlanningDraftGridWorkspace> createState() =>
      _PlanningDraftGridWorkspaceState();
}

class _PlanningDraftGridWorkspaceState
    extends State<PlanningDraftGridWorkspace> {
  @override
  void initState() {
    super.initState();
    widget.editorProvider.addListener(_onEditorChanged);
  }

  @override
  void didUpdateWidget(covariant PlanningDraftGridWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorProvider != widget.editorProvider) {
      oldWidget.editorProvider.removeListener(_onEditorChanged);
      widget.editorProvider.addListener(_onEditorChanged);
    }
    if (oldWidget.validationProvider != widget.validationProvider) {
      oldWidget.validationProvider.clear();
      _validateCurrentDraft();
    }
  }

  @override
  void dispose() {
    widget.editorProvider.removeListener(_onEditorChanged);
    super.dispose();
  }

  void _onEditorChanged() => _validateCurrentDraft();

  void _validateCurrentDraft() {
    final draft = widget.editorProvider.draft;
    if (draft == null) {
      widget.validationProvider.clear();
      return;
    }
    widget.validationProvider.validate(draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.editorProvider.draft;
    if (draft == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun brouillon à modifier.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Édition du brouillon',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${draft.year}/${draft.month}')),
            Chip(label: Text('${draft.assignments.length} affectations')),
            Chip(label: Text('Révision ${draft.revision}')),
          ],
        ),
        const SizedBox(height: 12),
        EditablePlanningSnapshotGrid(
          snapshot: draft,
          editorProvider: widget.editorProvider,
          staffNames: widget.staffNames,
        ),
      ],
    );
  }
}
