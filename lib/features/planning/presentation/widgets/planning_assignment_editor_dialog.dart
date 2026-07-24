import 'package:flutter/material.dart';

import '../../domain/entities/planning_assignment.dart';
import '../../domain/enums/shift_type.dart';
import '../providers/planning_editor_provider.dart';

class PlanningAssignmentEditorDialog extends StatefulWidget {
  final PlanningAssignment assignment;
  final PlanningEditorProvider provider;

  const PlanningAssignmentEditorDialog({
    super.key,
    required this.assignment,
    required this.provider,
  });

  @override
  State<PlanningAssignmentEditorDialog> createState() =>
      _PlanningAssignmentEditorDialogState();
}

class _PlanningAssignmentEditorDialogState
    extends State<PlanningAssignmentEditorDialog> {
  late ShiftType _shift;
  late final TextEditingController _team;
  late final TextEditingController _code;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _shift = widget.assignment.shift;
    _team = TextEditingController(text: widget.assignment.team ?? '');
    _code = TextEditingController(text: widget.assignment.code ?? '');
    _note = TextEditingController(text: widget.assignment.note ?? '');
  }

  @override
  void dispose() {
    _team.dispose();
    _code.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifier le ${widget.assignment.date.day}/${widget.assignment.date.month}',
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ShiftType>(
                value: _shift,
                decoration: const InputDecoration(labelText: 'Service'),
                items: ShiftType.values
                    .map(
                      (shift) => DropdownMenuItem(
                        value: shift,
                        child: Text(shift.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _shift = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _team,
                decoration: const InputDecoration(labelText: 'Équipe'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            widget.provider.setAssignment(
              staffId: widget.assignment.staffId,
              date: widget.assignment.date,
              shift: _shift,
              team: _team.text.trim().isEmpty ? null : _team.text.trim(),
              code: _code.text.trim().isEmpty ? null : _code.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            );
            Navigator.of(context).pop(true);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
