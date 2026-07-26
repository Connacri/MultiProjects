import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

import '../data/repositories/objectbox_planning_repository.dart';
import '../data/repositories/objectbox_planning_snapshot_store.dart';
import '../domain/repositories/planning_repository.dart';
import '../domain/services/generate_planning.dart';
import '../domain/services/planning_draft_pipeline.dart';
import '../domain/services/planning_validator.dart';
import '../domain/services/rotation_continuity_resolver.dart';
import '../domain/services/rotation_engine.dart';
import '../domain/services/team_schedule_generator.dart';
import '../domain/usecases/create_planning_revision.dart';
import '../domain/usecases/save_planning_revision.dart';
import '../application/usecases/load_planning.dart';
import '../application/usecases/publish_planning.dart';
import '../presentation/providers/planning_editor_provider.dart';
import '../presentation/providers/planning_provider.dart';
import '../presentation/providers/planning_validation_provider.dart';
import '../presentation/providers/rotation_configuration_provider.dart';
import '../presentation/widgets/planning_workspace_controller.dart';

/// Composition root for the Planning feature.
///
/// Production wiring owns the ObjectBox infrastructure. Tests can inject a
/// repository without constructing any ObjectBox object.
class PlanningComposition {
  final PlanningRepository repository;
  final ObjectBoxPlanningSnapshotStore? snapshotStore;
  final PlanningProvider planningProvider;
  final RotationConfigurationProvider rotationConfigurationProvider;
  final PlanningEditorProvider editorProvider;
  final PlanningValidationProvider validationProvider;
  final PlanningWorkspaceController workspaceController;

  PlanningComposition._({
    required this.repository,
    required this.snapshotStore,
    required this.planningProvider,
    required this.rotationConfigurationProvider,
    required this.editorProvider,
    required this.validationProvider,
    required this.workspaceController,
  });

  factory PlanningComposition.fromStore({
    required Store store,
    required Box<PlanningSnapshotEntity> snapshotBox,
    required Box<PlanningAssignmentEntity> assignmentBox,
    required Box<RotationStateSnapshotEntity> rotationStateBox,
  }) {
    final snapshotStore = ObjectBoxPlanningSnapshotStore(
      store: store,
      snapshotBox: snapshotBox,
      assignmentBox: assignmentBox,
      rotationStateBox: rotationStateBox,
    );
    final repository = ObjectBoxPlanningRepository(
      snapshotStore: snapshotStore,
    );

    return _fromRepository(
      repository: repository,
      snapshotStore: snapshotStore,
    );
  }

  static PlanningComposition _fromRepository({
    required PlanningRepository repository,
    ObjectBoxPlanningSnapshotStore? snapshotStore,
  }) {
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
      snapshotStore: snapshotStore,
      planningProvider: planningProvider,
      rotationConfigurationProvider: rotationConfigurationProvider,
      editorProvider: editorProvider,
      validationProvider: validationProvider,
      workspaceController: workspaceController,
    );
  }

  /// Creates the application graph for unit/integration tests.
  ///
  /// No ObjectBox store or ObjectBox entity box is constructed here. The
  /// repository is the persistence boundary and is fully injectable.
  @visibleForTesting
  static PlanningComposition forTesting({
    required PlanningRepository repository,
  }) {
    return _fromRepository(repository: repository);
  }

  void dispose() {
    planningProvider.dispose();
    rotationConfigurationProvider.dispose();
    editorProvider.dispose();
    validationProvider.dispose();
    workspaceController.dispose();
  }
}
