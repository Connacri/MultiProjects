import 'package:flutter/material.dart';

import '../providers/planning_history_provider.dart';
import '../providers/planning_provider.dart';
import '../providers/rotation_configuration_provider.dart';
import 'planning_history_panel.dart';
import 'planning_workflow_actions.dart';
import 'rotation_team_order_editor.dart';

/// Responsive Planning workspace shared by Windows Desktop and Mobile.
///
/// The widget is presentation-only: all persistence and generation are
/// delegated to Providers. Historical snapshots remain read-only.
class PlanningWorkspace extends StatelessWidget {
  final PlanningProvider planningProvider;
  final RotationConfigurationProvider rotationProvider;
  final PlanningHistoryProvider? historyProvider;
  final int? historyYear;
  final int? historyMonth;
  final int? historyBranchId;
  final VoidCallback? onEditDraft;

  const PlanningWorkspace({
    super.key,
    required this.planningProvider,
    required this.rotationProvider,
    this.historyProvider,
    this.historyYear,
    this.historyMonth,
    this.historyBranchId,
    this.onEditDraft,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        final rotation = RotationTeamOrderEditor(
          provider: rotationProvider,
          compact: compact,
        );
        final workflow = PlanningWorkflowActions(
          provider: planningProvider,
          onEdit: onEditDraft,
        );

        final controls = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [rotation, const SizedBox(height: 12), workflow],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: rotation),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: workflow),
                ],
              );

        final history = historyProvider != null &&
                historyYear != null &&
                historyMonth != null
            ? PlanningHistoryPanel(
                provider: historyProvider!,
                year: historyYear!,
                month: historyMonth!,
                branchId: historyBranchId,
              )
            : null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Planning des équipes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              controls,
              const SizedBox(height: 16),
              _PlanningStatusCard(provider: planningProvider),
              if (history != null) ...[
                const SizedBox(height: 16),
                history,
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlanningStatusCard extends StatelessWidget {
  final PlanningProvider provider;

  const _PlanningStatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final draft = provider.draft;
    final current = provider.current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'État du planning',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (draft != null) Text('Brouillon : ${draft.year}/${draft.month}'),
            if (current != null) Text('Publié : ${current.year}/${current.month}'),
            if (draft == null && current == null)
              const Text('Aucun planning chargé.'),
            if (provider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
