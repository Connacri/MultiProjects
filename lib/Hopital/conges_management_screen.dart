import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';

/// Staff and leave management, backed by the local ObjectBox database.
class CongesManagementScreen extends StatefulWidget {
  const CongesManagementScreen({super.key});

  @override
  State<CongesManagementScreen> createState() => _CongesManagementScreenState();
}

class _CongesManagementScreenState extends State<CongesManagementScreen> {
  static const _pageSize = 30;
  final _objectBox = ObjectBox();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  List<Staff> _staff = const [];
  Map<int, List<TimeOff>> _leavesByStaff = const {};
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final staff = _objectBox.staffBox.getAll()..sort((a, b) => a.nom.compareTo(b.nom));
    final leaves = <int, List<TimeOff>>{};
    for (final leave in _objectBox.timeOffBox.getAll()) {
      leaves.putIfAbsent(leave.staff.targetId, () => []).add(leave);
    }
    for (final history in leaves.values) {
      history.sort((a, b) => b.debut.compareTo(a.debut));
    }
    setState(() {
      _staff = staff;
      _leavesByStaff = leaves;
      _visibleCount = _visibleCount
          .clamp(_pageSize, staff.isEmpty ? _pageSize : staff.length)
          .toInt();
    });
  }

  void _loadMore() {
    if (_visibleCount >= _staff.length) return;
    setState(() => _visibleCount =
        (_visibleCount + _pageSize).clamp(0, _staff.length).toInt());
  }

  Future<void> _editStaff([Staff? existing]) async {
    final name = TextEditingController(text: existing?.nom ?? '');
    final grade = TextEditingController(text: existing?.grade ?? '');
    final group = TextEditingController(text: existing?.groupe ?? '');
    final team = TextEditingController(text: existing?.equipe ?? '');
    final order = TextEditingController(text: existing?.ordre?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Ajouter un membre' : 'Modifier le personnel'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _input(name, 'Nom *'),
            _input(grade, 'Grade *'),
            _input(group, 'Groupe *'),
            _input(team, 'Équipe'),
            _input(order, 'Ordre', keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || grade.text.trim().isEmpty || group.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Nom, grade et groupe sont obligatoires.')),
                );
                return;
              }
              final staff = existing ?? Staff(nom: name.text.trim(), grade: grade.text.trim(), groupe: group.text.trim());
              staff
                ..nom = name.text.trim()
                ..grade = grade.text.trim()
                ..groupe = group.text.trim()
                ..equipe = team.text.trim().isEmpty ? null : team.text.trim()
                ..ordre = int.tryParse(order.text.trim());
              _objectBox.staffBox.put(staff);
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    for (final controller in [name, grade, group, team, order]) { controller.dispose(); }
    if (saved == true && mounted) _reload();
  }

  TextField _input(TextEditingController controller, String label, {TextInputType? keyboardType}) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      );

  Future<void> _deleteStaff(Staff staff) async {
    if (!await _confirm('Supprimer ${staff.nom} ?', 'Son historique de congés sera également supprimé.')) return;
    final leaves = _leavesByStaff[staff.id] ?? const [];
    _objectBox.timeOffBox.removeMany(leaves.map((leave) => leave.id).toList());
    _objectBox.staffBox.remove(staff.id);
    _reload();
  }

  Future<void> _editLeave(Staff staff, [TimeOff? existing]) async {
    var start = existing?.debut ?? DateTime.now();
    var end = existing?.fin ?? start;
    final reason = TextEditingController(text: existing?.motif ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Ajouter un congé' : 'Modifier le congé'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(alignment: Alignment.centerLeft, child: Text(staff.nom, style: Theme.of(context).textTheme.titleMedium)),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Motif (facultatif)')),
            _DateField(label: 'Début', value: start, formatter: _dateFormat, onChanged: (date) => setDialogState(() => start = date)),
            _DateField(label: 'Fin', value: end, formatter: _dateFormat, onChanged: (date) => setDialogState(() => end = date)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                if (end.isBefore(start)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('La fin doit être après le début.')));
                  return;
                }
                final leave = existing ?? TimeOff(debut: start, fin: end);
                leave
                  ..debut = start
                  ..fin = end
                  ..motif = reason.text.trim().isEmpty ? null : reason.text.trim()
                  ..staff.targetId = staff.id;
                _objectBox.timeOffBox.put(leave);
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    reason.dispose();
    if (saved == true && mounted) _reload();
  }

  Future<void> _deleteLeave(TimeOff leave) async {
    if (!await _confirm('Supprimer ce congé ?', 'Cette action est définitive.')) return;
    _objectBox.timeOffBox.remove(leave.id);
    _reload();
  }

  Future<bool> _confirm(String title, String content) async =>
      await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(title), content: Text(content), actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      )) ?? false;

  @override
  Widget build(BuildContext context) {
    final count = _visibleCount.clamp(0, _staff.length).toInt();
    return Scaffold(
      appBar: AppBar(title: Text('Personnel et congés (${_staff.length})')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editStaff(), icon: const Icon(Icons.person_add), label: const Text('Personnel'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 250) _loadMore();
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: count + (count < _staff.length ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == count) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
              return _StaffHistoryCard(
                staff: _staff[index],
                history: _leavesByStaff[_staff[index].id] ?? const [],
                formatter: _dateFormat,
                onEditStaff: () => _editStaff(_staff[index]),
                onDeleteStaff: () => _deleteStaff(_staff[index]),
                onAddLeave: () => _editLeave(_staff[index]),
                onEditLeave: (leave) => _editLeave(_staff[index], leave),
                onDeleteLeave: _deleteLeave,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StaffHistoryCard extends StatelessWidget {
  const _StaffHistoryCard({required this.staff, required this.history, required this.formatter, required this.onEditStaff, required this.onDeleteStaff, required this.onAddLeave, required this.onEditLeave, required this.onDeleteLeave});
  final Staff staff;
  final List<TimeOff> history;
  final DateFormat formatter;
  final VoidCallback onEditStaff;
  final VoidCallback onDeleteStaff;
  final VoidCallback onAddLeave;
  final ValueChanged<TimeOff> onEditLeave;
  final ValueChanged<TimeOff> onDeleteLeave;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(staff.nom),
      subtitle: Text('${staff.grade} • ${staff.groupe}${staff.equipe == null ? '' : ' • ${staff.equipe}'}'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) { if (value == 'edit') onEditStaff(); if (value == 'delete') onDeleteStaff(); },
        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Modifier')), PopupMenuItem(value: 'delete', child: Text('Supprimer'))],
      ),
      children: [
        ListTile(leading: const Icon(Icons.add_circle_outline), title: const Text('Ajouter un congé'), onTap: onAddLeave),
        if (history.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Aucun congé dans l’historique.')),
        for (final leave in history) ListTile(
          leading: const Icon(Icons.event_busy),
          title: Text('${formatter.format(leave.debut)} – ${formatter.format(leave.fin)}'),
          subtitle: leave.motif?.isNotEmpty == true ? Text(leave.motif!) : null,
          onTap: () => onEditLeave(leave),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => onDeleteLeave(leave)),
        ),
      ],
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.formatter, required this.onChanged});
  final String label;
  final DateTime value;
  final DateFormat formatter;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero, title: Text(label), subtitle: Text(formatter.format(value)), trailing: const Icon(Icons.calendar_today_outlined),
    onTap: () async { final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (date != null) onChanged(date); },
  );
}
