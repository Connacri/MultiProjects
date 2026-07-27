import 'package:flutter/material.dart';

import '../providers/rotation_configuration_provider.dart';

/// Shared responsive team-order editor for Desktop and Mobile.
///
/// Desktop uses a wide reorderable list while Mobile keeps the same business
/// behavior in a compact card. Persistence is delegated to the provider.
class RotationTeamOrderEditor extends StatelessWidget {
  final RotationConfigurationProvider provider;
  final bool compact;

  const RotationTeamOrderEditor({
    super.key,
    required this.provider,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final configuration = provider.active;
    if (configuration == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucune configuration de rotation active.'),
        ),
      );
    }

    final content = ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: configuration.teamOrder.length,
      buildDefaultDragHandles: !compact,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final order = [...configuration.teamOrder];
        final item = order.removeAt(oldIndex);
        order.insert(newIndex, item);
        await provider.reorderTeams(order);
      },
      itemBuilder: (context, index) {
        final team = configuration.teamOrder[index];
        return ListTile(
          key: ValueKey(team),
          leading: CircleAvatar(
            child: Text(team.isEmpty ? '?' : team[0].toUpperCase()),
          ),
          title: Text('Équipe $team'),
          subtitle: Text('Position ${index + 1}'),
          trailing: compact
              ? const Icon(Icons.drag_handle)
              : const Icon(Icons.open_with),
        );
      },
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ordre des équipes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (provider.isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Configuration v${configuration.version}'),
            const SizedBox(height: 8),
            content,
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
