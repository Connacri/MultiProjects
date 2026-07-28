import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataViewerPage extends StatefulWidget {
  const SupabaseDataViewerPage({super.key});

  @override
  State<SupabaseDataViewerPage> createState() => _SupabaseDataViewerPageState();
}

class _SupabaseDataViewerPageState extends State<SupabaseDataViewerPage> {
  final _client = Supabase.instance.client;
  String _selectedTable = 'staffs';
  List<Map<String, dynamic>> _rows = const [];
  int? _selectedRowIndex;

  static const _tables = [
    'branches',
    'staffs',
    'type_activites',
    'activite_jours',
    'time_offs',
    'planifications',
    'planning_hebdos',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _client.from(_selectedTable).select().limit(50);
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
            itemBuilder: (_) => _tables.map((t) {
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
      body: _rows.isEmpty
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                  rows: [
                    for (var i = 0; i < _rows.length; i++)
                      DataRow(
                        selected: i == _selectedRowIndex,
                        onSelectChanged: (selected) {
                          setState(() => _selectedRowIndex = selected == true ? i : null);
                        },
                        cells: [
                          for (final col in columns)
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200),
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
    );
  }
}
