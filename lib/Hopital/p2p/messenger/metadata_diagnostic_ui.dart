import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fonctions.dart';
import 'node_metadata_manager.dart';

/// 🔍 Page de diagnostic des métadonnées P2P
/// À ajouter dans votre app pour vérifier l'envoi/réception
class MetadataDiagnosticPage extends StatefulWidget {
  const MetadataDiagnosticPage({Key? key}) : super(key: key);

  @override
  State<MetadataDiagnosticPage> createState() => _MetadataDiagnosticPageState();
}

class _MetadataDiagnosticPageState extends State<MetadataDiagnosticPage> {
  late NodeMetadataManager _metadataManager;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _metadataManager = NodeMetadataManager();

    // Auto-refresh toutes les 2 secondes
    if (_autoRefresh) {
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted && _autoRefresh) {
          setState(() {});
          return true;
        }
        return false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnostic Métadonnées'),
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() => _autoRefresh = !_autoRefresh);
            },
            tooltip: _autoRefresh ? 'Pause' : 'Reprendre',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _metadataManager.refreshAllMetadata();
              setState(() {});
            },
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyReport,
            tooltip: 'Copier rapport',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 Résumé
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // 📄 Métadonnées locales
            _buildLocalMetadataCard(),
            const SizedBox(height: 16),

            // 👥 Nœuds distants
            _buildRemoteNodesCard(),
            const SizedBox(height: 16),

            // 📝 Logs en temps réel
            _buildLogsCard(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'broadcast',
            onPressed: () {
              _metadataManager.broadcastMetadata();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📡 Broadcast envoyé')),
              );
            },
            child: const Icon(Icons.wifi_tethering),
            tooltip: 'Forcer broadcast',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            mini: true,
            heroTag: 'cleanup',
            onPressed: () {
              _metadataManager.cleanupStaleMetadata();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ Nettoyage effectué')),
              );
            },
            child: const Icon(Icons.cleaning_services),
            tooltip: 'Nettoyer cache',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '📊 RÉSUMÉ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _metadataManager.isInitialized
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _metadataManager.isInitialized ? '✅ ACTIF' : '❌ INACTIF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildStatRow('Messages envoyés', _metadataManager.messagesSent,
                Icons.upload),
            _buildStatRow('Messages reçus', _metadataManager.messagesReceived,
                Icons.download),
            _buildStatRow(
                'Requêtes envoyées', _metadataManager.requestsSent, Icons.send),
            _buildStatRow('Requêtes reçues', _metadataManager.requestsReceived,
                Icons.inbox),
            _buildStatRow('Nœuds connus',
                _metadataManager.remoteMetadata.length, Icons.people),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: value > 0 ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value > 0 ? Colors.blue[900] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smartphone, size: 20),
                SizedBox(width: 8),
                Text(
                  '📄 MÉTADONNÉES LOCALES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Ces données sont envoyées aux autres nœuds:',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: getCurrentPlatform(),
              builder: (context, snapshot) {
                return _buildInfoTile(
                  'Platform',
                  snapshot.data ?? 'Chargement...',
                  Icons.computer,
                );
              },
            ),
            _buildInfoTile(
              'Branch',
              getBranchForCurrentUser() ?? 'No Branch',
              Icons.business,
            ),
            _buildInfoTile(
              'DisplayName',
              'Extrait du nodeId',
              Icons.badge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ces données sont broadcastées toutes les 30 secondes',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteNodesCard() {
    final remoteNodes = _metadataManager.remoteMetadata.values.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '👥 NŒUDS DISTANTS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: remoteNodes.isEmpty ? Colors.grey : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${remoteNodes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (remoteNodes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aucun nœud distant découvert',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...remoteNodes.map((metadata) => _buildRemoteNodeTile(metadata)),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteNodeTile(NodeMetadata metadata) {
    final age = DateTime.now().difference(metadata.lastUpdate);
    final isStale = age.inMinutes > 5;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isStale ? Colors.red[50] : Colors.green[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isStale ? Colors.red[100] : Colors.green[100],
          child: Icon(
            getPlatformIcon(metadata.platform),
            color: isStale ? Colors.red[700] : Colors.green[700],
          ),
        ),
        title: Text(
          metadata.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.computer, size: 12, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    metadata.platform,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            if (metadata.branch != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.business, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      metadata.branch!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 2),
            Text(
              'Dernière màj: ${_formatDuration(age)}',
              style: TextStyle(
                fontSize: 10,
                color: isStale ? Colors.red[700] : Colors.grey[600],
                fontWeight: isStale ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            _metadataManager.requestMetadata(metadata.nodeId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Demande envoyée à ${metadata.displayName}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Rafraîchir ce nœud',
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    final logs = _metadataManager.logs.reversed.take(50).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '📝 LOGS EN TEMPS RÉEL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: const Text('Effacer', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    // Les logs sont en lecture seule, on peut juste rafraîchir
                    setState(() {});
                  },
                ),
              ],
            ),
            const Divider(),
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Aucun log disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogEntry(log);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(DiagnosticLog log) {
    Color categoryColor = _getCategoryColor(log.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatLogTime(log.timestamp),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: categoryColor, width: 1),
            ),
            child: Text(
              log.category,
              style: TextStyle(
                color: categoryColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (category.contains('✅') || category.contains('INIT')) {
      return Colors.green;
    } else if (category.contains('❌') || category.contains('ERROR')) {
      return Colors.red;
    } else if (category.contains('⚠️') || category.contains('WARN')) {
      return Colors.orange;
    } else if (category.contains('📡') || category.contains('SEND')) {
      return Colors.blue;
    } else if (category.contains('📨') || category.contains('RECV')) {
      return Colors.purple;
    } else if (category.contains('🔍') || category.contains('REQUEST')) {
      return Colors.cyan;
    }
    return Colors.grey;
  }

  String _formatLogTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return 'il y a ${duration.inSeconds}s';
    if (duration.inMinutes < 60) return 'il y a ${duration.inMinutes}m';
    if (duration.inHours < 24) return 'il y a ${duration.inHours}h';
    return 'il y a ${duration.inDays}j';
  }

  void _copyReport() {
    final report = _metadataManager.getDiagnosticReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Rapport copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
