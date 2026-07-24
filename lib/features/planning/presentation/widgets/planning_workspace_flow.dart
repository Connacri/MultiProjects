import 'package:flutter/material.dart';

import '../providers/planning_editor_provider.dart';
import '../providers/planning_provider.dart';
import '../providers/planning_validation_provider.dart';
import '../providers/rotation_configuration_provider.dart';
import 'planning_publish_gate.dart';
import 'planning_workspace_controller.dart';
import 'planning_workspace_editor.dart';
import 'rotation_team_order_editor.dart';

/// Full responsive planning workflow surface.
///
/// The active draft editor is PlanningWorkspaceEditor, backed directly by
/// PlanningSnapshot. Legacy draft-grid widgets are intentionally not used.
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
        final editor = PlanningWorkspaceEditor(
          planningProvider: planningProvider,
          editorProvider: editorProvider,
          controller: controller,
          staffNames: staffNames,
        );

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
              const SizedBox(height: 16),
              editor,
              if (!controller.isEditing && planningProvider.draft != null) ...[
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
            ],
          ),
        );
      },
    );
  }
}
