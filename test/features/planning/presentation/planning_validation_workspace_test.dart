import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_validation_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_validation_workspace.dart';

class _FakePlanningProvider extends PlanningProvider {
  _FakePlanningProvider()
      : super(
          generatePlanning: throw UnimplementedError(),
          publishPlanning: throw UnimplementedError(),
          loadPlanning: throw UnimplementedError(),
        );
}

void main() {
  testWidgets('disables validation when no draft exists', (tester) async {
    final planning = _FakePlanningProvider();
    final validation = PlanningValidationProvider(
      validator: const PlanningValidator(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningValidationWorkspace(
            planningProvider: planning,
            validationProvider: validation,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Valider'),
    );
    expect(button.onPressed, isNull);
  });
}
