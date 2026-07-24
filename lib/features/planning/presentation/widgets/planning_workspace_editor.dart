import 'package:flutter/material.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_provider.dart';
import 'editable_planning_snapshot_grid.dart';
import 'planning_workspace_controller.dart';

/// Responsive editor surface for the current Planning draft.
///
/// The draft is edited through PlanningEditorProvider only. The grid is backed
/// directly by PlanningSnapshot; no legacy Planning conversion is performed.
class PlanningWorkspaceEditor extends StatelessWidget {
  final PlanningProvider planningProvider;
  final PlanningEditorProvider editorProvider;
  final PlanningWorkspaceController controller;
  final Map<int, String> staffNames;

  const PlanningWorkspaceEditor({
    super.key,
    required this.planningProvider,
    required this.editorProvider,
    required this.controller,
    this.staffNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final draft = editorProvider.draft;
    if (!controller.isEditing || draft == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Édition du brouillon — ${draft.year}/${draft.month}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                    label: Text(
                        '${editorProvider.overrides.length} modification(s)')),
              ],
            ),
            const SizedBox(height: 12),
            EditablePlanningSnapshotGrid(
              snapshot: draft,
              editorProvider: editorProvider,
              staffNames: staffNames,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      planningProvider.isBusy ? null : controller.cancelEditing,
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                ),
                FilledButton.icon(
                  onPressed: planningProvider.isBusy
                      ? null
                      : controller.applyEditorDraft,
                  icon: const Icon(Icons.check),
                  label: const Text('Appliquer au brouillon'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
