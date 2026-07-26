import 'package:flutter/foundation.dart';

import 'data/repositories/objectbox_planning_repository.dart';
import 'domain/repositories/planning_repository.dart';
import 'domain/services/generate_planning.dart';
import 'domain/services/planning_draft_pipeline.dart';
import 'domain/services/planning_validator.dart';
import 'domain/services/rotation_continuity_resolver.dart';
import 'domain/services/rotation_engine.dart';
import 'domain/services/team_schedule_generator.dart';
import 'domain/usecases/create_planning_revision.dart';
import 'domain/usecases/save_planning_revision.dart';
import 'application/usecases/load_planning.dart';
import 'application/usecases/publish_planning.dart';
import 'presentation/providers/planning_editor_provider.dart';
import 'presentation/providers/planning_provider.dart';
import 'presentation/providers/planning_validation_provider.dart';
import 'presentation/providers/rotation_configuration_provider.dart';
import 'presentation/widgets/planning_workspace_controller.dart';

/// Composition root for the Planning feature.
///
/// Keeps dependency construction out of widgets and makes the complete
/// feature graph explicit. The caller owns the ObjectBox store lifecycle.
class PlanningComposition {
  final PlanningRepository repository;
  final PlanningProvider planningProvider;
  final RotationConfigurationProvider rotationConfigurationProvider;
  final PlanningEditorProvider editorProvider;
  final PlanningValidationProvider validationProvider;
  final PlanningWorkspaceController workspaceController;

  PlanningComposition._({
    required this.repository,
    required this.planningProvider,
    required this.rotationConfigurationProvider,
    required this.editorProvider,
    required this.validationProvider,
    required this.workspaceController,
  });

  factory PlanningComposition.fromStore(dynamic store) {
    final repository = ObjectBoxPlanningRepository(store);
    final rotationEngine = const RotationEngine();
    final teamScheduleGenerator = TeamScheduleGenerator(rotationEngine);
    final continuityResolver = RotationContinuityResolver(repository);
    final draftPipeline = const PlanningDraftPipeline();
    final validator = const PlanningValidator();

    final generatePlanning = GeneratePlanning(
      planningRepository: repository,
      teamScheduleGenerator: teamScheduleGenerator,
      continuityResolver: continuityResolver,
      draftPipeline: draftPipeline,
      validator: validator,
    );

    final createRevision = CreatePlanningRevision(
      planningRepository: repository,
    );
    final saveRevision = SavePlanningRevision(
      planningRepository: repository,
    );
    final loadPlanning = LoadPlanning(
      planningRepository: repository,
    );
    final publishPlanning = PublishPlanning(
      planningRepository: repository,
      validator: validator,
    );

    final planningProvider = PlanningProvider(
      generatePlanning: generatePlanning,
      createPlanningRevision: createRevision,
      savePlanningRevision: saveRevision,
      loadPlanning: loadPlanning,
      publishPlanning: publishPlanning,
    );

    final rotationConfigurationProvider = RotationConfigurationProvider(
      repository: repository,
    );
    final editorProvider = PlanningEditorProvider();
    final validationProvider = PlanningValidationProvider(
      validator: validator,
    );
    final workspaceController = PlanningWorkspaceController(
      planningProvider: planningProvider,
      editorProvider: editorProvider,
    );

    return PlanningComposition._(
      repository: repository,
      planningProvider: planningProvider,
      rotationConfigurationProvider: rotationConfigurationProvider,
      editorProvider: editorProvider,
      validationProvider: validationProvider,
      workspaceController: workspaceController,
    );
  }

  void dispose() {
    planningProvider.dispose();
    rotationConfigurationProvider.dispose();
    editorProvider.dispose();
    validationProvider.dispose();
    workspaceController.dispose();
  }

  @visibleForTesting
  static PlanningComposition forTesting({required PlanningRepository repository}) {
    final rotationEngine = const RotationEngine();
    final validator = const PlanningValidator();
    final planningProvider = PlanningProvider(
      generatePlanning: GeneratePlanning(
        planningRepository: repository,
        teamScheduleGenerator: TeamScheduleGenerator(rotationEngine),
        continuityResolver: RotationContinuityResolver(repository),
        draftPipeline: const PlanningDraftPipeline(),
        validator: validator,
      ),
      createPlanningRevision: CreatePlanningRevision(
        planningRepository: repository,
      ),
      savePlanningRevision: SavePlanningRevision(
        planningRepository: repository,
      ),
      loadPlanning: LoadPlanning(planningRepository: repository),
      publishPlanning: PublishPlanning(
        planningRepository: repository,
        validator: validator,
      ),
    );
    final editorProvider = PlanningEditorProvider();
    final validationProvider = PlanningValidationProvider(validator: validator);

    return PlanningComposition._(
      repository: repository,
      planningProvider: planningProvider,
      rotationConfigurationProvider: RotationConfigurationProvider(
        repository: repository,
      ),
      editorProvider: editorProvider,
      validationProvider: validationProvider,
      workspaceController: PlanningWorkspaceController(
        planningProvider: planningProvider,
        editorProvider: editorProvider,
      ),
    );
  }
}
