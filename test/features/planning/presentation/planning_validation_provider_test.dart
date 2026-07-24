import 'package:flutter_test/flutter_test.dart';

import 'package:multi_projects/features/planning/domain/entities/planning_snapshot.dart';
import 'package:multi_projects/features/planning/domain/services/planning_validator.dart';
import 'package:multi_projects/features/planning/presentation/providers/planning_validation_provider.dart';

void main() {
  test('stores validation result and exposes validity', () {
    final provider = PlanningValidationProvider(
      validator: const PlanningValidator(),
    );

    final snapshot = PlanningSnapshot(
      id: 'draft',
      year: 2026,
      month: 2,
      configurationId: 'config',
      configurationVersion: 1,
      engineVersion: 'test',
      revision: 1,
      createdAt: DateTime(2026, 2, 1),
      assignments: const [],
    );

    final result = provider.validate(snapshot);

    expect(provider.hasResult, isTrue);
    expect(provider.isValid, isTrue);
    expect(result.warnings, isNotEmpty);
    expect(provider.error, isNull);
  });
}
