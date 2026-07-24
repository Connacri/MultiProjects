import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/presentation/providers/planning_editor_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_validation_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/rotation_configuration_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_workspace.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_workspace_controller.dart';
import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';

void main() {
  test('workspace supports the integrated draft workflow dependencies', () {
    final planning = PlanningProvider(
      generatePlanning: throw UnimplementedError(),
      publishPlanning: throw UnimplementedError(),
      loadPlanning: throw UnimplementedError(),
    );
    final editor = PlanningEditorProvider();
    final controller = PlanningWorkspaceController(
      planningProvider: planning,
      editorProvider: editor,
    );
    final validation = PlanningValidationProvider(
      validator: const PlanningValidator(),
    );

    final workspace = PlanningWorkspace(
      planningProvider: planning,
      rotationProvider: throw UnimplementedError(),
      editorProvider: editor,
      validationProvider: validation,
      workspaceController: controller,
    );

    expect(workspace.editorProvider, same(editor));
    expect(workspace.validationProvider, same(validation));
    expect(workspace.workspaceController, same(controller));
  });
}
