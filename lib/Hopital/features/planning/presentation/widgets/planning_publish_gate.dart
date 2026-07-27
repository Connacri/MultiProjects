import 'package:flutter/material.dart';

import '../providers/planning_provider.dart';
import '../providers/planning_validation_provider.dart';
import 'planning_validation_panel.dart';

/// UI gate that makes the validation state explicit before publishing.
///
/// The final business validation still happens in PublishPlanning; this widget
/// only improves the UX and prevents an obvious invalid UI action.
class PlanningPublishGate extends StatelessWidget {
  final PlanningProvider planningProvider;
  final PlanningValidationProvider validationProvider;
  final VoidCallback? onPublish;

  const PlanningPublishGate({
    super.key,
    required this.planningProvider,
    required this.validationProvider,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final draft = planningProvider.draft;
    final valid = validationProvider.isValid;
    final hasValidation = validationProvider.hasResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlanningValidationPanel(
          result: validationProvider.result,
          onValidate:
              draft == null ? null : () => validationProvider.validate(draft),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: draft == null ||
                  planningProvider.isBusy ||
                  !hasValidation ||
                  !valid
              ? null
              : onPublish,
          icon: planningProvider.isPublishing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.publish_outlined),
          label: Text(
            !hasValidation
                ? 'Valider avant de publier'
                : valid
                    ? 'Publier le planning'
                    : 'Corriger les erreurs avant publication',
          ),
        ),
      ],
    );
  }
}
