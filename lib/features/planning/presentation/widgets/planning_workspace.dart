import 'package:flutter/material.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_history_provider.dart';
import '../providers/planning_provider.dart';
import '../providers/planning_validation_provider.dart';
import '../providers/rotation_configuration_provider.dart';
import 'planning_history_panel.dart';
import 'planning_publish_gate.dart';
import 'planning_workspace_controller.dart';
import 'planning_workspace_editor.dart';
import 'planning_workflow_actions.dart';
import 'rotation_team_order_editor.dart';

/// Responsive Planning workspace shared by Windows Desktop and Mobile.
///
/// The widget is presentation-only: all persistence and generation are
/// delegated to Providers. Historical snapshots remain read-only.
class PlanningWorkspace extends StatelessWidget {
  final PlanningProvider planningProvider;
  final RotationConfigurationProvider rotationProvider;
  final PlanningEditorProvider? editorProvider;
  final PlanningValidationProvider? validationProvider;
  final PlanningWorkspaceController? workspaceController;
  final PlanningHistoryProvider? historyProvider;
  final int? historyYear;
  final int? historyMonth;
  final int? historyBranchId;
  final Map<int, String> staffNames;
  final VoidCallback? onEditDraft;

  const PlanningWorkspace({
    super.key,
    required this.planningProvider,
    required this.rotationProvider,
    this.editorProvider,
    this.validationProvider,
    this.workspaceController,
    this.historyProvider,
    this.historyYear,
    this.historyMonth,
    this.historyBranchId,
    this.staffNames = const {},
    this.onEditDraft,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final controller = workspaceController;
        final editor = editorProvider;
        final validation = validationProvider;

        final hasIntegratedFlow =
            controller != null && editor != null && validation != null;

        final rotation = RotationTeamOrderEditor(
          provider: rotationProvider,
          compact: compact,
        );

        final workflow = hasIntegratedFlow
            ? PlanningPublishGate(
                planningProvider: planningProvider,
                validationProvider: validation,
                onPublish: controller.publishEditedDraft,
              )
            : PlanningWorkflowActions(
                provider: planningProvider,
                onEdit: onEditDraft,
              );

        final history = historyProvider != null &&
                historyYear != null &&
                historyMonth != null
            ? PlanningHistoryPanel(
                provider: historyProvider!,
                year: historyYear!,
                month: historyMonth!,
                branchId: historyBranchId,
              )
            : null;

        final editorSurface = hasIntegratedFlow && controller.isEditing
            ? PlanningWorkspaceEditor(
                planningProvider: planningProvider,
                editorProvider: editor,
                controller: controller,
                staffNames: staffNames,
              )
            : null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Planning des équipes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        rotation,
                        const SizedBox(height: 12),
                        workflow
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: rotation),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: workflow),
                      ],
                    ),
              if (hasIntegratedFlow &&
                  !controller.isEditing &&
                  planningProvider.hasDraft) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: planningProvider.isBusy
                        ? null
                        : controller.beginEditing,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier le brouillon'),
                  ),
                ),
              ],
              if (editorSurface != null) ...[
                const SizedBox(height: 16),
                editorSurface,
              ],
              const SizedBox(height: 16),
              _PlanningStatusCard(provider: planningProvider),
              if (history != null) ...[
                const SizedBox(height: 16),
                history,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlanningStatusCard extends StatelessWidget {
  final PlanningProvider provider;

  const _PlanningStatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final draft = provider.draft;
    final current = provider.current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'État du planning',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (draft != null) Text('Brouillon : ${draft.year}/${draft.month}'),
            if (current != null)
              Text('Publié : ${current.year}/${current.month}'),
            if (draft == null && current == null)
              const Text('Aucun planning chargé.'),
            if (provider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
