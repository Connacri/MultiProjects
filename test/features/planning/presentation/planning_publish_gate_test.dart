import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_validation_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_publish_gate.dart';

class _FakePlanningProvider extends PlanningProvider {
  _FakePlanningProvider()
      : super(
          generatePlanning: throw UnimplementedError(),
          publishPlanning: throw UnimplementedError(),
          loadPlanning: throw UnimplementedError(),
        );
}

void main() {
  testWidgets('publish is disabled until validation succeeds', (tester) async {
    final planning = _FakePlanningProvider();
    final validation = PlanningValidationProvider(
      validator: const PlanningValidator(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningPublishGate(
            planningProvider: planning,
            validationProvider: validation,
            onPublish: () {},
          ),
        ),
      ),
    );

    expect(find.text('Valider avant de publier'), findsOneWidget);
    final buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));
    expect(buttons.any((button) => button.onPressed != null), isFalse);
  });
}
