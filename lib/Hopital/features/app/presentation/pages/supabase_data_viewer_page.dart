import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataViewerPage extends StatefulWidget {
  const SupabaseDataViewerPage({super.key});

  @override
  State<SupabaseDataViewerPage> createState() => _SupabaseDataViewerPageState();
}

class _SupabaseDataViewerPageState extends State<SupabaseDataViewerPage> {
  final _client = Supabase.instance.client;
  String _selectedTable = 'planning_snapshots';
  List<Map<String, dynamic>> _rows = const [];
  int? _selectedRowIndex;

  static const _planningTables = [
    'planning_snapshots',
    'planning_assignments',
    'planning_configurations',
    'rotation_state_snapshots',
    'planning_overrides',
    'planning_revisions',
    'rotation_periods',
    'branches',
    'staffs',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _client.from(_selectedTable).select().limit(100);
      setState(() => _rows = data);
    } catch (e) {
      setState(() => _rows = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearTable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la table'),
        content: Text('Voulez-vous vraiment vider la table "$_selectedTable" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _client.from(_selectedTable).delete().neq('id', 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Table vidée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearAllTables() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Vider toute la base'),
        content: const Text(
          'ATTENTION : Cette action va supprimer toutes les données '
          'des tables de planning dans Supabase.\n\n'
          'Cette opération est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tout vider'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      for (final table in _planningTables.reversed) {
        await _client.from(table).delete().neq('id', 0);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les tables planning ont été vidées'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = _rows.isNotEmpty ? _rows.first.keys.toList() : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Supabase — $_selectedTable (${_rows.length})'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedTable,
            onSelected: (table) {
              setState(() => _selectedTable = table);
              _fetchData();
            },
            itemBuilder: (_) => _planningTables.map((t) {
              return PopupMenuItem(
                value: t,
                child: Text(t),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.dangerous, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Zone de danger',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectedTable == 'staffs'
                      ? null
                      : _clearTable,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Vider $_selectedTable'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _clearAllTables,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Tout vider'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _rows.isEmpty
                ? const Center(child: Text('Aucune donnée'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          for (final col in columns)
                            DataColumn(
                              label: Text(
                                col,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                        rows: [
                          for (var i = 0; i < _rows.length; i++)
                            DataRow(
                              selected: i == _selectedRowIndex,
                              onSelectChanged: (selected) {
                                setState(() => _selectedRowIndex =
                                    selected == true ? i : null);
                              },
                              cells: [
                                for (final col in columns)
                                  DataCell(
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        '${_rows[i][col] ?? ''}',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
