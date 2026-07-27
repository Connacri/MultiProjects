import 'package:flutter/material.dart';

import '../providers/planning_provider.dart';

/// Shared workflow actions used by Desktop and Mobile planning screens.
class PlanningWorkflowActions extends StatelessWidget {
  final PlanningProvider provider;
  final VoidCallback? onEdit;

  const PlanningWorkflowActions({
    super.key,
    required this.provider,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasDraft = provider.hasDraft;
    final isBusy = provider.isBusy;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: isBusy || !hasDraft ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier'),
        ),
        FilledButton.icon(
          onPressed: isBusy || !hasDraft ? null : provider.publish,
          icon: provider.isPublishing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.publish_outlined),
          label: const Text('Publier'),
        ),
        OutlinedButton.icon(
          onPressed: isBusy || !hasDraft ? null : provider.clearDraft,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Annuler le brouillon'),
        ),
      ],
    );
  }
}
