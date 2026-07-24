import 'package:flutter/material.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_provider.dart';
import '../providers/planning_validation_provider.dart';
import '../providers/rotation_configuration_provider.dart';
import 'planning_draft_editor.dart';
import 'planning_publish_gate.dart';
import 'planning_workspace_controller.dart';
import 'rotation_team_order_editor.dart';

/// Full responsive planning workflow surface.
///
/// Keeps orchestration in the controller/providers and presentation in widgets.
class PlanningWorkspaceFlow extends StatelessWidget {
  final PlanningProvider planningProvider;
  final PlanningEditorProvider editorProvider;
  final PlanningValidationProvider validationProvider;
  final RotationConfigurationProvider rotationProvider;
  final PlanningWorkspaceController controller;
  final Map<int, String> staffNames;

  const PlanningWorkspaceFlow({
    super.key,
    required this.planningProvider,
    required this.editorProvider,
    required this.validationProvider,
    required this.rotationProvider,
    required this.controller,
    this.staffNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final editor = controller.isEditing
            ? PlanningDraftEditor(
                provider: editorProvider,
                staffNames: staffNames,
              )
            : null;

        final actions = PlanningPublishGate(
          planningProvider: planningProvider,
          validationProvider: validationProvider,
          onPublish: controller.publishEditedDraft,
        );

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
                      children: [
                        RotationTeamOrderEditor(
                          provider: rotationProvider,
                          compact: true,
                        ),
                        const SizedBox(height: 12),
                        actions,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: RotationTeamOrderEditor(
                            provider: rotationProvider,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: actions),
                      ],
                    ),
              if (editor != null) ...[
                const SizedBox(height: 16),
                editor,
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
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (!controller.isEditing && planningProvider.draft != null)
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
          ),
        );
      },
    );
  }
}
