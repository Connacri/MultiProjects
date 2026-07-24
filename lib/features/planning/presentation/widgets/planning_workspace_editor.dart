import 'package:flutter/material.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_provider.dart';
import 'planning_draft_editor.dart';
import 'planning_workspace_controller.dart';

/// Responsive editor surface for the current Planning draft.
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
    if (!controller.isEditing) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlanningDraftEditor(
              provider: editorProvider,
              staffNames: staffNames,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: planningProvider.isBusy
                      ? null
                      : controller.cancelEditing,
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
                FilledButton.icon(
                  onPressed: planningProvider.isBusy
                      ? null
                      : controller.publishEditedDraft,
                  icon: planningProvider.isPublishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: const Text('Appliquer et publier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
