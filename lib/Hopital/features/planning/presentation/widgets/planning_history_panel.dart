import 'package:flutter/material.dart';

import '../providers/planning_history_provider.dart';

/// Read-only history panel shared by Desktop and Mobile.
/// It never generates or mutates a planning snapshot.
class PlanningHistoryPanel extends StatelessWidget {
  final PlanningHistoryProvider provider;
  final int year;
  final int month;
  final int? branchId;

  const PlanningHistoryPanel({
    super.key,
    required this.provider,
    required this.year,
    required this.month,
    this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final planning = provider.planning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Historique du planning',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => provider.load(
                    year: year,
                    month: month,
                    branchId: branchId,
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text('Charger'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (planning == null)
              const Text('Aucun planning publié pour cette période.')
            else ...[
              Text('Période : ${planning.year}/${planning.month}'),
              const SizedBox(height: 4),
              Text('Équipe(s) / affectations : ${planning.assignments.length}'),
              const SizedBox(height: 4),
              const Text(
                  'Lecture seule — le planning historique ne peut pas être modifié ici.'),
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
