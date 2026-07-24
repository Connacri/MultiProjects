import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning.dart';
import 'package:multi_projects/features/planning/domain/entities/planning_assignment.dart';
import 'package:multi_projects/features/planning/domain/enums/shift_type.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_month_grid.dart';

void main() {
  testWidgets('renders monthly columns and assignment cells', (tester) async {
    final planning = Planning(
      year: 2026,
      month: 2,
      dayTeamOrder: const ['A', 'C', 'D', 'B'],
      nightTeamOrder: const ['B', 'A', 'C', 'D'],
      assignments: const [
        PlanningAssignment(
          staffId: 1,
          date: DateTime(2026, 2, 1),
          team: 'A',
          shift: ShiftType.day,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningMonthGrid(
            planning: planning,
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
