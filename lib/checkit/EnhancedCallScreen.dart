import 'dart:async';
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class EnhancedCallScreen extends StatefulWidget {
  const EnhancedCallScreen({super.key});

  @override
  State<EnhancedCallScreen> createState() => _EnhancedCallScreenState();
}

class _EnhancedCallScreenState extends State<EnhancedCallScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _loadingStates = {};
  final int _pageSize = 20;

  List<CallLogEntry> _calls = [];
  Set<String> _reportedNumbers = {};
  List<String> _cachedNumbers = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _permissionGranted = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // Future<void> _initialize() async {
  //   await _checkPermissions();
  //   if (_permissionGranted) {
  //     await _loadCache();
  //     _loadCallLog();
  //   }
  // }
  Future<void> _initialize() async {
    await _checkPermissions();
    if (_permissionGranted) {
      await _loadCache();
      await _fetchReportedNumbers(); // New method
      _loadCallLog();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.phone.status;
      setState(() => _permissionGranted = status.isGranted);

      if (!_permissionGranted) {
        final result = await Permission.phone.request();
        setState(() => _permissionGranted = result.isGranted);
      }
    } catch (e) {
      _showError('Erreur de permissions: ${e.toString()}');
    }
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedNumbers = prefs.getStringList('reported_cache') ?? [];
    _reportedNumbers = _cachedNumbers.toSet();
  }

  Future<void> _updateCache(String number) async {
    if (!_cachedNumbers.contains(number)) {
      _cachedNumbers.add(number);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('reported_cache', _cachedNumbers);
    }
  }

  Future<void> _loadCallLog({bool loadMore = false}) async {
    if (!_permissionGranted) return;

    try {
      if (!loadMore) {
        _currentPage = 1;
        _calls.clear();
      }

      final result = await CallLog.query(
        dateTimeFrom: DateTime.now().subtract(const Duration(days: 30)),
        dateTimeTo: DateTime.now(),
      );

      final List<CallLogEntry> resultList = result.toList();
      final filtered = _applySearchFilter(resultList);

      setState(() {
        if (filtered.length > _pageSize) {
          _calls = loadMore
              ? [..._calls, ...filtered.sublist(0, _pageSize)]
              : filtered.sublist(0, _pageSize);
          _hasMore = true;
        } else {
          _calls = loadMore ? [..._calls, ...filtered] : filtered;
          _hasMore = false;
        }
        _loading = false;
      });
    } catch (e) {
      _showError('Erreur de chargement: ${e.toString()}');
    }
  }

  List<CallLogEntry> _applySearchFilter(List<CallLogEntry> entries) {
    if (_searchController.text.isEmpty) return entries;

    return entries.where((entry) {
      final number = entry.number ?? '';
      return number.contains(_searchController.text);
    }).toList();
  }

  Future<void> _checkNumber(String number) async {
    if (number.isEmpty || _cachedNumbers.contains(number)) return;

    setState(() => _loadingStates[number] = true);

    try {
      final response =
          await _supabase.from('signalements').select().eq('numero', number);

      if (response.isNotEmpty) {
        setState(() => _reportedNumbers.add(number));
        _updateCache(number);
      }
    } finally {
      setState(() => _loadingStates.remove(number));
    }
  }

  Future<void> _reportNumber(String number) async {
    if (number.isEmpty || _reportedNumbers.contains(number)) return;

    setState(() => _loadingStates[number] = true);

    try {
      await _supabase.from('signalements').insert({
        'numero': number,
        'motif': 'Spam', // Valeur par défaut
        'gravite': 1, // Valeur par défaut
        'date': DateTime.now().toIso8601String(),
        'signalePar': _supabase.auth.currentUser?.id,
      });

      setState(() {
        _reportedNumbers.add(number);
        _cachedNumbers.add(number);
      });
      _updateCache(number);
      // setState(() => _reportedNumbers.add(number));
      _updateCache(number);
    } catch (e) {
      _showError('Erreur: ${e.toString()}');
    } finally {
      setState(() => _loadingStates.remove(number));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////
  Future<void> _fetchReportedNumbers() async {
    try {
      final response = await _supabase.from('signalements').select('numero');
      final List<Map<String, dynamic>> data = response;
      setState(() {
        _reportedNumbers = data.map((e) => e['numero'] as String).toSet();
        _cachedNumbers = _reportedNumbers.toList();
      });
    } catch (e) {
      _showError('Erreur de récupération des signalements: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return Scaffold(body: Center(child: _buildPermissionDenied()));
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un numéro...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _loadCallLog,
            ),
          ),
          onChanged: (value) {
            _searchDebounce?.cancel();
            _searchDebounce =
                Timer(const Duration(milliseconds: 500), _loadCallLog);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCallLog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _calls.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _calls.length) {
                  return _hasMore
                      ? _buildLoadMoreButton()
                      : const SizedBox.shrink();
                }
                return _buildCallItem(_calls[index]);
              },
            ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Permission requise pour accéder aux appels'),
          ElevatedButton(
            onPressed: _checkPermissions,
            child: const Text('Autoriser l\'accès'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          _currentPage++;
          _loadCallLog(loadMore: true);
        },
        child: const Text('Charger plus'),
      ),
    );
  }

  Widget _buildCallItem(CallLogEntry entry) {
    final number = entry.number ?? 'Inconnu';
    //WidgetsBinding.instance.addPostFrameCallback((_) => _checkNumber(number));

    return ListTile(
      leading: const Icon(Icons.phone),
      title: Text(number),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${_getCallType(entry.callType)}'),
          Text('Date: ${_formatDate(entry.timestamp)}'),
        ],
      ),
      trailing: _loadingStates[number] ?? false
          ? const CircularProgressIndicator(strokeWidth: 2)
          : IconButton(
              icon: Icon(
                _reportedNumbers.contains(number) ? Icons.block : Icons.report,
                color: _reportedNumbers.contains(number)
                    ? Colors.red
                    : Colors.grey,
              ),
              onPressed: () => _reportNumber(number),
            ),
    );
  }

  String _getCallType(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return 'Entrant';
      case CallType.outgoing:
        return 'Sortant';
      case CallType.missed:
        return 'Manqué';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(int? timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp ?? 0),
    );
  }
}
