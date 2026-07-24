import 'package:flutter/material.dart';

/// Shared Desktop/Mobile badge for a planning revision that changed after
/// publication and must be validated again.
class PlanningRevisionStatusBadge extends StatelessWidget {
  final bool isModified;
  final bool requiresRevalidation;

  const PlanningRevisionStatusBadge({
    super.key,
    required this.isModified,
    required this.requiresRevalidation,
  });

  @override
  Widget build(BuildContext context) {
    if (!isModified && !requiresRevalidation) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Semantics(
      label: requiresRevalidation
          ? 'Planning modifié, validation requise'
          : 'Planning modifié',
      liveRegion: true,
      child: Chip(
        avatar: Icon(
          requiresRevalidation
              ? Icons.warning_amber_rounded
              : Icons.edit_outlined,
          size: 18,
          color: theme.colorScheme.onErrorContainer,
        ),
        label: Text(
          requiresRevalidation ? 'Modifié • À revalider' : 'Modifié',
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        labelStyle: TextStyle(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
