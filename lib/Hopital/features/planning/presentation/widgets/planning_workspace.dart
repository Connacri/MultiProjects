import 'package:flutter/material.dart';

import '../../data/services/hospital_pdf_seed_import.dart';
import '../providers/planning_editor_provider.dart';
import '../providers/planning_history_provider.dart';
import '../providers/planning_provider.dart';
import '../providers/planning_sync_provider.dart';
import '../providers/planning_validation_provider.dart';
import '../providers/rotation_configuration_provider.dart';
import 'planning_history_panel.dart';
import 'planning_publish_gate.dart';
import 'planning_workspace_controller.dart';
import 'planning_workspace_editor.dart';
import 'planning_workflow_actions.dart';
import 'rotation_team_order_editor.dart';

/// Responsive Planning workspace shared by Windows Desktop and Mobile.
///
/// The widget is presentation-only: all persistence and generation are
/// delegated to Providers. Historical snapshots remain read-only.
class PlanningWorkspace extends StatelessWidget {
  final PlanningProvider planningProvider;
  final RotationConfigurationProvider rotationProvider;
  final PlanningEditorProvider? editorProvider;
  final PlanningValidationProvider? validationProvider;
  final PlanningWorkspaceController? workspaceController;
  final PlanningHistoryProvider? historyProvider;
  final PlanningSyncProvider? syncProvider;
  final int? historyYear;
  final int? historyMonth;
  final int? historyBranchId;
  final Map<int, String> staffNames;
  final VoidCallback? onEditDraft;

  const PlanningWorkspace({
    super.key,
    required this.planningProvider,
    required this.rotationProvider,
    this.editorProvider,
    this.validationProvider,
    this.workspaceController,
    this.historyProvider,
    this.syncProvider,
    this.historyYear,
    this.historyMonth,
    this.historyBranchId,
    this.staffNames = const {},
    this.onEditDraft,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final controller = workspaceController;
        final editor = editorProvider;
        final validation = validationProvider;

        final hasIntegratedFlow =
            controller != null && editor != null && validation != null;

        final rotation = RotationTeamOrderEditor(
          provider: rotationProvider,
          compact: compact,
        );

        final workflow = hasIntegratedFlow
            ? PlanningPublishGate(
                planningProvider: planningProvider,
                validationProvider: validation,
                onPublish: controller.publishEditedDraft,
              )
            : PlanningWorkflowActions(
                provider: planningProvider,
                onEdit: onEditDraft,
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

        final editorSurface = hasIntegratedFlow && controller.isEditing
            ? PlanningWorkspaceEditor(
                planningProvider: planningProvider,
                editorProvider: editor,
                controller: controller,
                staffNames: staffNames,
              )
            : null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Planning des \u00e9quipes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        rotation,
                        const SizedBox(height: 12),
                        workflow,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: rotation),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: workflow),
                      ],
                    ),
              if (syncProvider != null) ...[
                const SizedBox(height: 12),
                _SyncButton(syncProvider: syncProvider!),
              ],
              if (hasIntegratedFlow && !controller.isEditing)
                ..._buildDraftActions(planningProvider, controller),
              if (editorSurface != null) ...[
                const SizedBox(height: 16),
                editorSurface,
              ],
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

  List<Widget> _buildDraftActions(
    PlanningProvider planningProvider,
    PlanningWorkspaceController controller,
  ) {
    if (planningProvider.hasDraft) {
      return [
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed:
                planningProvider.isBusy ? null : controller.beginEditing,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier le brouillon'),
          ),
        ),
      ];
    }
    if (planningProvider.hasCurrent && !planningProvider.hasDraft) {
      return [
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: planningProvider.isBusy
                ? null
                : () => planningProvider.createRevision(
                      createdAt: DateTime.now(),
                    ),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Créer un brouillon'),
          ),
        ),
      ];
    }
    return const [];
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
              '\u00c9tat du planning',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (draft != null) Text('Brouillon : ${draft.year}/${draft.month}'),
            if (current != null)
              Text('Publi\u00e9 : ${current.year}/${current.month}'),
            if (draft == null && current == null) ...[
              const Text('Aucun planning charg\u00e9.'),
              const SizedBox(height: 12),
              const _SeedImportButton(),
            ],
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

class _SeedImportButton extends StatefulWidget {
  const _SeedImportButton();

  @override
  State<_SeedImportButton> createState() => _SeedImportButtonState();
}

class _SeedImportButtonState extends State<_SeedImportButton> {
  bool _loading = false;

  Future<void> _import() async {
    setState(() => _loading = true);
    try {
      final importer = HospitalPdfSeedImportService();
      final result = await importer.importAout2026();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '${result.staffCount} staffs, ${result.timeOffCount} congés, '
          '${result.observationCount} observations importés.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur import: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _import,
      icon: _loading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_outlined),
      label: Text(_loading ? 'Importation\u2026' : 'Importer les données seed (Août 2026)'),
    );
  }
}

class _SyncButton extends StatefulWidget {
  final PlanningSyncProvider syncProvider;

  const _SyncButton({required this.syncProvider});

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.syncProvider.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.syncProvider.removeListener(_onStateChanged);
    super.dispose();
  }

  Future<void> _confirmForceSync() async {
    final sync = widget.syncProvider;
    final info = sync.conflictInfo;
    final remoteRevision = info?['revision'] as int?;
    final remoteCreatedAt =
        DateTime.tryParse(info?['created_at'] as String? ?? '');

    final message = StringBuffer('Les donn\u00e9es distantes ont \u00e9t\u00e9 '
        'modifi\u00e9es depuis la derni\u00e8re synchronisation');
    if (remoteRevision != null) {
      message.write(' (r\u00e9vision distante: $remoteRevision)');
    }
    if (remoteCreatedAt != null) {
      message.write(
          '\nDerni\u00e8re modification distante: ${_formatDateTime(remoteCreatedAt)}');
    }
    message.write(
        '\n\nForcer la synchronisation \u00e9crasera les donn\u00e9es distantes.');

    final force = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conflit de synchronisation'),
        content: Text(message.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Forcer'),
          ),
        ],
      ),
    );

    if (force == true && mounted) {
      sync.forceSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = widget.syncProvider;
    final state = sync.state;
    final canSync = sync.canSync;

    Widget button;
    switch (state) {
      case SyncUiState.syncing:
        button = OutlinedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Synchronisation\u2026'),
        );
      case SyncUiState.success:
        button = OutlinedButton.icon(
          onPressed: sync.reset,
          icon: Icon(Icons.cloud_done_outlined,
              color: Theme.of(context).colorScheme.primary),
          label: Text(
            'Synchronis\u00e9',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        );
      case SyncUiState.failed:
        button = OutlinedButton.icon(
          onPressed: canSync ? sync.sync : null,
          icon: Icon(Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.error),
          label: Text(
            'R\u00e9essayer',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      case SyncUiState.conflict:
        button = OutlinedButton.icon(
          onPressed: _confirmForceSync,
          icon: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
          label: const Text('Conflit'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
          ),
        );
      case SyncUiState.idle:
        button = OutlinedButton.icon(
          onPressed: canSync
              ? () {
                  print('[SyncUI] Clic Synchroniser (canSync=$canSync)');
                  sync.sync();
                }
              : null,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Synchroniser'),
        );
    }

    return Row(
      children: [
        button,
        if (state == SyncUiState.failed && sync.error != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: TooltipMessage(message: sync.error!),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class TooltipMessage extends StatelessWidget {
  final String message;
  const TooltipMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: Icon(Icons.info_outline,
          size: 18, color: Theme.of(context).colorScheme.error),
    );
  }
}
