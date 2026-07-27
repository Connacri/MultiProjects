import 'package:flutter/material.dart';

import '../providers/planning_provider.dart';
import '../providers/planning_validation_provider.dart';
import 'planning_validation_panel.dart';

/// Validation gate for the current draft before the publish action.
class PlanningValidationWorkspace extends StatelessWidget {
  final PlanningProvider planningProvider;
  final PlanningValidationProvider validationProvider;

  const PlanningValidationWorkspace({
    super.key,
    required this.planningProvider,
    required this.validationProvider,
  });

  @override
  Widget build(BuildContext context) {
    final draft = planningProvider.draft;

    return PlanningValidationPanel(
      result: validationProvider.result,
      onValidate:
          draft == null ? null : () => validationProvider.validate(draft),
    );
  }
}
