import 'package:flutter/material.dart';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/enums/shift_type.dart';
import '../providers/planning_editor_provider.dart';

/// Responsive draft editor. Only the in-memory draft is changed.
class PlanningDraftEditor extends StatelessWidget {
  final PlanningEditorProvider provider;
  final Map<int, String> staffNames;

  const PlanningDraftEditor({
    super.key,
    required this.provider,
    this.staffNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final draft = provider.draft;
    if (draft == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun brouillon à modifier.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Édition du brouillon — ${draft.year}/${draft.month}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text('${provider.overrides.length} modification(s)')),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Personnel')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Équipe')),
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Action')),
                ],
                rows: draft.assignments.map(_buildRow).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(PlanningAssignment assignment) {
    return DataRow(
      cells: [
        DataCell(Text(staffNames[assignment.staffId] ?? '#${assignment.staffId}')),
        DataCell(Text(_formatDate(assignment.date))),
        DataCell(Text(assignment.team ?? '-')),
        DataCell(Text(assignment.shift.label)),
        DataCell(
          PopupMenuButton<ShiftType>(
            tooltip: 'Modifier le service',
            onSelected: (shift) => provider.setAssignment(
              staffId: assignment.staffId,
              date: assignment.date,
              shift: shift,
              team: assignment.team,
              code: assignment.code,
              note: assignment.note,
            ),
            itemBuilder: (context) => ShiftType.values
                .map(
                  (shift) => PopupMenuItem<ShiftType>(
                    value: shift,
                    child: Text(shift.label),
                  ),
                )
                .toList(growable: false),
            child: const Icon(Icons.edit_outlined),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

extension on ShiftType {
  String get label {
    switch (this) {
      case ShiftType.day:
        return 'Jour';
      case ShiftType.night:
        return 'Nuit';
      case ShiftType.rest:
        return 'Repos';
    }
  }
}
