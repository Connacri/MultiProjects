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
  final List<_LogEntry> _logs = [];
  final ScrollController _logScroll = ScrollController();

  /// Ordre de suppression : les enfants avant les parents.
  /// On insère d'abord les tables qui référencent, puis les référencées.
  static const _cleanupOrder = [
    // enfants (ceux qui ont des FK)
    'planning_overrides',
    'planning_assignments',
    'planning_hebdos',
    'time_offs',
    'activite_jours',
    'planifications',
    'rotation_periods',
    'rotation_state_snapshots',  // snapshot_id sera mis à NULL avant
    'planning_snapshots',
    'planning_configurations',
    'planning_revisions',
    'staffs',
    'type_activites',
    'branches',
  ];

  @override
  void initState() {
    super.initState();
    _addLog('INFO', 'Page chargée, table par défaut: $_selectedTable');
    _fetchData();
  }

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  void _addLog(String level, String message) {
    setState(() {
      _logs.insert(0, _LogEntry(
        time: DateTime.now(),
        level: level,
        message: message,
      ));
    });
  }

  Future<void> _fetchData() async {
    _addLog('INFO', 'Récupération de $_selectedTable...');
    try {
      final data = await _client.from(_selectedTable).select().limit(100);
      setState(() => _rows = data);
      _addLog('SUCCÈS', '${data.length} lignes récupérées');
    } catch (e) {
      setState(() => _rows = []);
      _addLog('ERREUR', '$e');
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

    _addLog('INFO', '🗑 Suppression de toutes les lignes de $_selectedTable...');
    try {
      int deleted = 0;
      await _deleteAllRows(_selectedTable, (count) { deleted = count; });
      _addLog('SUCCÈS', '✅ $_selectedTable vidée ($deleted supprimée(s))');
      _fetchData();
    } catch (e) {
      _addLog('ERREUR', '❌ $_selectedTable: $e');
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

    _addLog('INFO', '🗑 Vidage complet de la base...');

    // 1) Casser les dépendances circulaires entre rotation_state_snapshots et planning_snapshots
    try {
      await _client.from('rotation_state_snapshots').update({'snapshot_id': null}).not('id', 'is', null);
      _addLog('SUCCÈS', '✅ rotation_state_snapshots.snapshot_id mis à NULL');
    } catch (e) {
      _addLog('INFO', '⏭ rotation_state_snapshots.snapshot_id déjà null ou table vide');
    }
    try {
      await _client.from('planning_snapshots').update({'rotation_state_id': null}).not('id', 'is', null);
      _addLog('SUCCÈS', '✅ planning_snapshots.rotation_state_id mis à NULL');
    } catch (e) {
      _addLog('INFO', '⏭ planning_snapshots.rotation_state_id déjà null ou table vide');
    }

    // 2) Supprimer chaque table dans l'ordre (enfants → parents)
    for (final table in _cleanupOrder) {
      try {
        int deleted = 0;
        await _deleteAllRows(table, (count) { deleted = count; });
        if (deleted > 0) {
          _addLog('SUCCÈS', '✅ $table vidée ($deleted supprimée(s))');
        }
      } catch (e) {
        _addLog('ERREUR', '❌ $table: $e');
      }
    }
    _addLog('INFO', '🏁 Vidage terminé');
    _fetchData();
  }

  Future<void> _deleteAllRows(String table, void Function(int) onDeleted) async {
    final rows = await _client.from(table).select('id').order('id');
    if (rows.isEmpty) {
      onDeleted(0);
      return;
    }
    _addLog('INFO', '🗑 $table: ${rows.length} ligne(s) à supprimer...');
    int total = 0;
    for (final row in rows) {
      final id = row['id'];
      await _client.from(table).delete().eq('id', id);
      total++;
    }
    onDeleted(total);
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
            itemBuilder: (_) => _cleanupOrder.map((t) {
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
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
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
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: TextButton.icon(
                        onPressed: _selectedTable == 'staffs' ? null : _clearTable,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text('Vider $_selectedTable', overflow: TextOverflow.ellipsis),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
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
            ),
          ),
          Expanded(
            flex: 2,
            child: _rows.isEmpty
                ? const Center(child: Text('Aucune donnée'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DataTable(
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
                          if (_selectedRowIndex != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                      const SizedBox(width: 6),
                                      Text('Détail ligne #${_selectedRowIndex! + 1}',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blue.shade800)),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedRowIndex = null),
                                        child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...columns.map((col) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 180,
                                          child: Text('$col:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade800)),
                                        ),
                                        Expanded(child: SelectableText(
                                          '${_rows[_selectedRowIndex!][col] ?? ''}',
                                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                        )),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Container(
            height: 160,
            color: Colors.grey.shade900,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  color: Colors.grey.shade800,
                  child: Row(
                    children: [
                      Icon(Icons.terminal, size: 16,
                          color: Colors.green.shade300),
                      const SizedBox(width: 8),
                      Text(
                        'Logs (${_logs.length})',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _logs.clear()),
                        child: Icon(Icons.clear_all, size: 16,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _logs.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune opération',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          controller: _logScroll,
                          padding: const EdgeInsets.all(4),
                          itemCount: _logs.length,
                          itemBuilder: (_, i) {
                            final log = _logs[i];
                            return _buildLogLine(log);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(_LogEntry log) {
    final time =
        '${log.time.hour.toString().padLeft(2, '0')}:'
        '${log.time.minute.toString().padLeft(2, '0')}:'
        '${log.time.second.toString().padLeft(2, '0')}';

    Color levelColor;
    switch (log.level) {
      case 'ERREUR':
        levelColor = Colors.red.shade300;
      case 'SUCCÈS':
        levelColor = Colors.green.shade300;
      default:
        levelColor = Colors.cyan.shade300;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            time,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          SelectableText(
            '[${log.level}]',
            style: TextStyle(
              color: levelColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              log.message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final DateTime time;
  final String level;
  final String message;

  const _LogEntry({
    required this.time,
    required this.level,
    required this.message,
  });
}
