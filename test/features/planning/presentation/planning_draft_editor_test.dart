import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_editor_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_draft_editor.dart';

void main() {
  PlanningSnapshot snapshot() => PlanningSnapshot(
        id: 'draft-1',
        year: 2026,
        month: 2,
        configurationId: 'four-team',
        configurationVersion: 2,
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

  testWidgets('renders draft assignments and allows changing shift', (tester) async {
    final provider = PlanningEditorProvider();
    provider.load(snapshot());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningDraftEditor(
            provider: provider,
            staffNames: const {1: 'Agent 1'},
          ),
        ),
      ),
    );

    expect(find.text('Agent 1'), findsOneWidget);
    expect(find.text('Jour'), findsOneWidget);
    expect(find.text('1 modification(s)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuit'));
    await tester.pump();

    expect(provider.draft!.assignments.single.shift, ShiftType.night);
    expect(provider.overrides, hasLength(1));
  });
}
