import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/presentation/providers/planning_editor_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_validation_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/rotation_configuration_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_workspace_flow.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_workspace_controller.dart';
import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';

void main() {
  test('workspace controller starts outside edit mode', () {
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

    expect(controller.isEditing, isFalse);
    expect(controller.hasDraft, isFalse);
    expect(controller.hasEditorDraft, isFalse);
  });

  test('validation provider starts without validation result', () {
    final validation = PlanningValidationProvider(
      validator: const PlanningValidator(),
    );
    expect(validation.hasResult, isFalse);
    expect(validation.isValid, isFalse);
  });

  // Compile-time coverage for the integrated workspace dependencies.
  expectType<PlanningWorkspaceFlow>(
    PlanningWorkspaceFlow(
      planningProvider: planning,
      editorProvider: editor,
      validationProvider: validation,
      rotationProvider: throw UnimplementedError(),
      controller: controller,
    ),
  );
}
