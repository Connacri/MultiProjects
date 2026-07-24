import 'package:flutter/material.dart';

import '../../domain/entities/planning_snapshot.dart';
import '../providers/planning_editor_provider.dart';
import '../providers/planning_validation_provider.dart';
import 'editable_planning_month_grid.dart';

/// Draft grid that keeps validation synchronized with editor changes.
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
  }

  @override
  void dispose() {
    widget.editorProvider.removeListener(_onEditorChanged);
    super.dispose();
  }

  void _onEditorChanged() {
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
        _DraftMeta(snapshot: draft),
        const SizedBox(height: 12),
        EditablePlanningMonthGrid(
          planning: _toPlanning(draft),
          editorProvider: widget.editorProvider,
          staffNames: widget.staffNames,
        ),
      ],
    );
  }

  // The grid is intentionally a presentation adapter. The immutable snapshot
  // remains the source of truth for the draft editor and publication pipeline.
  PlanningSnapshot _toPlanningSnapshot(PlanningSnapshot snapshot) => snapshot;

  dynamic _toPlanning(PlanningSnapshot snapshot) {
    return _toPlanningSnapshot(snapshot);
  }
}

class _DraftMeta extends StatelessWidget {
  final PlanningSnapshot snapshot;

  const _DraftMeta({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('${snapshot.year}/${snapshot.month}')),
        Chip(label: Text('${snapshot.assignments.length} affectations')),
        Chip(label: Text('Révision ${snapshot.revision}')),
      ],
    );
  }
}
