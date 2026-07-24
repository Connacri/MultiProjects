import 'package:flutter/material.dart';

import '../../domain/entities/planning.dart';
import '../../domain/entities/planning_assignment.dart';
import '../../domain/enums/shift_type.dart';

/// Monthly planning grid optimized for desktop and usable on mobile through
/// horizontal scrolling. It is read/write only through [onEdit].
class PlanningMonthGrid extends StatelessWidget {
  final Planning planning;
  final Map<int, String> staffNames;
  final bool editable;
  final ValueChanged<PlanningAssignment>? onEdit;

  const PlanningMonthGrid({
    super.key,
    required this.planning,
    this.staffNames = const {},
    this.editable = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final assignmentsByStaff = <int, Map<int, PlanningAssignment>>{};
    for (final assignment in planning.assignments) {
      assignmentsByStaff
          .putIfAbsent(assignment.staffId, () => {})[assignment.date.day] =
          assignment;
    }

    final staffIds = assignmentsByStaff.keys.toList()..sort();
    final columns = <DataColumn>[
      const DataColumn(label: Text('Personnel')),
      ...List.generate(
        planning.daysInMonth,
        (index) => DataColumn(label: Text('${index + 1}')),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: staffIds.map((staffId) {
                final byDay = assignmentsByStaff[staffId]!;
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 150),
                        child: Text(staffNames[staffId] ?? '#$staffId'),
                      ),
                    ),
                    ...List.generate(planning.daysInMonth, (index) {
                      final assignment = byDay[index + 1];
                      return DataCell(
                        _AssignmentCell(
                          assignment: assignment,
                          editable: editable,
                          onEdit: onEdit,
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
}

class _AssignmentCell extends StatelessWidget {
  final PlanningAssignment? assignment;
  final bool editable;
  final ValueChanged<PlanningAssignment>? onEdit;

  const _AssignmentCell({
    required this.assignment,
    required this.editable,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final value = assignment;
    if (value == null) return const Text('—');

    final label = switch (value.shift) {
      ShiftType.day => 'J',
      ShiftType.night => 'N',
      ShiftType.rest => 'R',
      ShiftType.leave => 'C',
      ShiftType.training => 'F',
      ShiftType.activity => 'A',
      ShiftType.other => '—',
    };

    final content = Tooltip(
      message: '${value.shift.name}${value.team == null ? '' : ' · ${value.team}'}',
      child: Text(label),
    );

    if (!editable || onEdit == null) return content;

    return InkWell(
      onTap: () => onEdit!(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: content,
      ),
    );
  }
}
