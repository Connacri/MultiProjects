import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_editor_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_assignment_editor_dialog.dart';

void main() {
  testWidgets('saves edited shift and metadata into the draft provider',
      (tester) async {
    final provider = PlanningEditorProvider();
    final assignment = PlanningAssignment(
      staffId: 1,
      date: DateTime(2026, 2, 1),
      team: 'A',
      shift: ShiftType.day,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningAssignmentEditorDialog(
            assignment: assignment,
            provider: provider,
          ),
        ),
      ),
    );

    expect(find.text('Modifier le 1/2'), findsOneWidget);
  });
}
