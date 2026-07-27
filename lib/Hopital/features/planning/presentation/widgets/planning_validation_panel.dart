import 'package:flutter/material.dart';

import '../../domain/services/planning_validator.dart';

class PlanningValidationPanel extends StatelessWidget {
  final PlanningValidationResult? result;
  final VoidCallback? onValidate;

  const PlanningValidationPanel({
    super.key,
    required this.result,
    this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final value = result;
    if (value == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.rule_outlined),
          title: const Text('Validation métier'),
          subtitle:
              const Text('Le brouillon doit être validé avant publication.'),
          trailing: FilledButton.icon(
            onPressed: onValidate,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Valider'),
          ),
        ),
      );
    }

    final valid = value.isValid;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  valid ? Icons.check_circle : Icons.error,
                  color: valid
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valid ? 'Planning valide' : 'Planning invalide',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onValidate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Revalider'),
                ),
              ],
            ),
            if (value.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...value.errors.map(
                (error) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.error_outline),
                  title: Text(error),
                ),
              ),
            ],
            if (value.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...value.warnings.map(
                (warning) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(warning),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
