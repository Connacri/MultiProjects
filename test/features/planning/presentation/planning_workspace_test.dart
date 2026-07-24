import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/presentation/providers/planning_provider.dart';
import 'package:multi_projects/features/planning/presentation/providers/rotation_configuration_provider.dart';
import 'package:multi_projects/features/planning/presentation/widgets/planning_workspace.dart';

class _FakePlanningProvider extends PlanningProvider {
  _FakePlanningProvider()
      : super(
          generatePlanning: throw UnimplementedError(),
          publishPlanning: throw UnimplementedError(),
          loadPlanning: throw UnimplementedError(),
        );
}

class _FakeRotationProvider extends RotationConfigurationProvider {
  _FakeRotationProvider() : super(repository: throw UnimplementedError());
}

void main() {
  testWidgets('PlanningWorkspace renders compact mobile layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningWorkspace(
            planningProvider: _FakePlanningProvider(),
            rotationProvider: _FakeRotationProvider(),
          ),
        ),
      ),
    );

    expect(find.text('Planning des équipes'), findsOneWidget);
    expect(find.text('Aucune configuration de rotation active.'), findsOneWidget);
    expect(find.text('Aucun planning chargé.'), findsOneWidget);
  });

  testWidgets('PlanningWorkspace renders desktop structure', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanningWorkspace(
            planningProvider: _FakePlanningProvider(),
            rotationProvider: _FakeRotationProvider(),
          ),
        ),
      ),
    );

    expect(find.text('Planning des équipes'), findsOneWidget);
    expect(find.text('État du planning'), findsOneWidget);
  });
}
