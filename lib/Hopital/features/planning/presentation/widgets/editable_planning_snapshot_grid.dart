import 'package:flutter/material.dart';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/enums/shift_type.dart';
import '../providers/planning_editor_provider.dart';
import 'planning_assignment_editor_dialog.dart';

/// Editable monthly grid backed directly by PlanningSnapshot.
///
/// This is the single draft-grid representation. It deliberately does not
/// convert a PlanningSnapshot into the legacy Planning aggregate.
class EditablePlanningSnapshotGrid extends StatefulWidget {
  final PlanningSnapshot snapshot;
  final PlanningEditorProvider editorProvider;
  final Map<int, String> staffNames;

  const EditablePlanningSnapshotGrid({
    super.key,
    required this.snapshot,
    required this.editorProvider,
    this.staffNames = const {},
  });

  @override
  State<EditablePlanningSnapshotGrid> createState() =>
      _EditablePlanningSnapshotGridState();
}

class _EditablePlanningSnapshotGridState
    extends State<EditablePlanningSnapshotGrid> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byStaff = <int, Map<int, PlanningAssignment>>{};
    for (final assignment in widget.snapshot.assignments) {
      byStaff.putIfAbsent(assignment.staffId,
          () => <int, PlanningAssignment>{})[assignment.date.day] = assignment;
    }

    final staffIds = widget.staffNames.keys.toList()..sort();
    if (staffIds.isEmpty) {
      staffIds.addAll(byStaff.keys.toList()..sort());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Personnel')),
                ...List.generate(
                  widget.snapshot.daysInMonth,
                  (index) => DataColumn(label: Text('${index + 1}')),
                ),
              ],
              rows: staffIds.map((staffId) {
                final days = byStaff[staffId] ?? <int, PlanningAssignment>{};
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 150),
                        child: Text(widget.staffNames[staffId] ?? '#$staffId'),
                      ),
                    ),
                    ...List.generate(widget.snapshot.daysInMonth, (index) {
                      final assignment = days[index + 1];
                      return DataCell(
                        _SnapshotAssignmentCell(
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
        provider: widget.editorProvider,
      ),
    );
  }
}

class _SnapshotAssignmentCell extends StatelessWidget {
  final PlanningAssignment? assignment;
  final VoidCallback? onTap;

  const _SnapshotAssignmentCell({required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (assignment == null) return const Text('—');

    final label = switch (assignment!.shift) {
      ShiftType.day => 'J',
      ShiftType.night => 'N',
      ShiftType.rest => 'R',
      ShiftType.leave => 'C',
      ShiftType.training => 'F',
      ShiftType.activity => 'A',
      ShiftType.other => '—',
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
