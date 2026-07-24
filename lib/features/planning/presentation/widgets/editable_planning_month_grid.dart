import 'package:flutter/material.dart';

import '../../domain/entities/planning.dart';
import '../../domain/entities/planning_assignment.dart';
import '../../domain/enums/shift_type.dart';
import '../providers/planning_editor_provider.dart';
import 'planning_assignment_editor_dialog.dart';

class EditablePlanningMonthGrid extends StatelessWidget {
  final Planning planning;
  final PlanningEditorProvider editorProvider;
  final Map<int, String> staffNames;

  const EditablePlanningMonthGrid({
    super.key,
    required this.planning,
    required this.editorProvider,
    this.staffNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final byStaff = <int, Map<int, PlanningAssignment>>{};
    for (final assignment in planning.assignments) {
      byStaff.putIfAbsent(assignment.staffId, () {})[assignment.date.day] =
          assignment;
    }

    final staffIds = byStaff.keys.toList()..sort();

    return Card(
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Personnel')),
              ...List.generate(
                planning.daysInMonth,
                (day) => DataColumn(label: Text('$day')),
              ),
            ],
            rows: staffIds.map((staffId) {
              final days = byStaff[staffId]!;
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 150),
                      child: Text(staffNames[staffId] ?? '#$staffId'),
                    ),
                  ),
                  ...List.generate(planning.daysInMonth, (index) {
                    final assignment = days[index + 1];
                    return DataCell(
                      _EditableAssignmentCell(
                        assignment: assignment,
                        onTap: assignment == null
                            ? null
                            : () => _edit(context, assignment),
                      ),
                    );
                  }),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    PlanningAssignment assignment,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => PlanningAssignmentEditorDialog(
        assignment: assignment,
        provider: editorProvider,
      ),
    );
  }
}

class _EditableAssignmentCell extends StatelessWidget {
  final PlanningAssignment? assignment;
  final VoidCallback? onTap;

  const _EditableAssignmentCell({required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (assignment == null) return const Text('—');

    final label = switch (assignment!.shift) {
      ShiftType.day => 'J',
      ShiftType.night => 'N',
      ShiftType.rest => 'R',
    };

    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: '${assignment!.shift.name} · ${assignment!.team ?? '-'}',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(label),
        ),
      ),
    );
  }
}
