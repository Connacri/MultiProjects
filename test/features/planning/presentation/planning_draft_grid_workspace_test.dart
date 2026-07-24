import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_editor_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_validation_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_draft_grid_workspace.dart';
import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';

void main() {
  testWidgets('renders draft snapshot directly in the editable grid',
      (tester) async {
    final snapshot = PlanningSnapshot(
      id: 'draft-1',
      year: 2026,
      month: 2,
      configurationId: 'config-1',
      configurationVersion: 1,
      engineVersion: 'test',
      revision: 1,
      createdAt: DateTime(2026, 2, 1),
      assignments: const [
        PlanningAssignment(
          staffId: 1,
          date: DateTime(2026, 2, 1),
          team: 'A',
          shift: ShiftType.day,
        ),
      ],
    );

    final editor = PlanningEditorProvider()..load(snapshot);
    final validation = PlanningValidationProvider(
      validator: const PlanningValidator(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningDraftGridWorkspace(
            editorProvider: editor,
            validationProvider: validation,
            staffNames: const {1: 'Agent 1'},
          ),
        ),
      ),
    );

    expect(find.text('Édition du brouillon'), findsOneWidget);
    expect(find.text('Agent 1'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
  });
}
