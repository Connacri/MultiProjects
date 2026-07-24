import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_editor_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/editable_planning_snapshot_grid.dart';

void main() {
  testWidgets('renders a snapshot directly without legacy Planning conversion',
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditablePlanningSnapshotGrid(
            snapshot: snapshot,
            editorProvider: editor,
            staffNames: const {1: 'Agent 1'},
          ),
        ),
      ),
    );

    expect(find.text('Personnel'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('Agent 1'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
  });
}
