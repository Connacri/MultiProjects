import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connection_manager.dart';
import 'p2p_managers.dart';
import 'sync_manager.dart';

/// 🔍 Banner de statut simplifié (SANS dépendance à P2PIntegration)
class P2PStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p2p = Provider.of<P2PManager>(context);
    final conn = Provider.of<ConnectionManager>(context);

    // Détermine si P2P est initialisé via le nodeId
    final bool isInitialized = p2p.nodeId.isNotEmpty;

    return Container(
      color: _getStatusColor(isInitialized, conn),
      padding: EdgeInsets.all(8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Statut général
            Row(
              children: [
                Icon(
                  isInitialized ? Icons.cloud_done : Icons.cloud_off,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  isInitialized ? 'P2P Actif' : 'P2P Init...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Stats rapides
            Row(
              children: [
                _QuickStat(
                  icon: Icons.dns,
                  value: conn.isRunning ? '✓' : '✗',
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                _QuickStat(
                  icon: Icons.people,
                  value: '${conn.neighbors.length}',
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.white),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SimpleDiagnosticPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(bool isInitialized, ConnectionManager conn) {
    if (!isInitialized) return Colors.orange;
    if (!conn.isRunning) return Colors.red[700]!;
    if (conn.neighbors.isEmpty) return Colors.amber[700]!;
    return Colors.green[700]!;
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 🔧 Page de diagnostic simplifiée
class SimpleDiagnosticPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnostic P2P'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(),
            SizedBox(height: 16),
            _NetworkCard(),
            SizedBox(height: 16),
            _ActionsCard(),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p2p = Provider.of<P2PManager>(context);
    final conn = Provider.of<ConnectionManager>(context);
    final sync = Provider.of<SyncManager>(context);

    final bool isInitialized = p2p.nodeId.isNotEmpty;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'État du Système',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            _InfoRow(
              'P2P Initialisé',
              isInitialized ? '✅ OUI' : '⏳ En cours...',
              isInitialized,
            ),
            _InfoRow(
              'Node ID',
              isInitialized
                  ? '${p2p.nodeId.substring(0, 20)}...'
                  : 'Non généré',
              isInitialized,
            ),
            _InfoRow(
              'Serveur',
              conn.isRunning ? '✅ Port ${conn.serverPort}' : '❌ Arrêté',
              conn.isRunning,
            ),
            _InfoRow(
              'Voisins Connectés',
              '${conn.neighbors.length}',
              conn.neighbors.isNotEmpty,
            ),
            _InfoRow(
              'Synchronisation',
              sync.isSyncing ? '🔄 En cours' : '✅ Au repos',
              !sync.isSyncing,
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox('Syncs ✅', '${sync.successfulSyncs}', Colors.green),
                _StatBox('Syncs ❌', '${sync.failedSyncs}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conn = Provider.of<ConnectionManager>(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Voisins (${conn.neighbors.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            if (conn.neighbors.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aucun voisin connecté',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...conn.neighbors.map((nodeId) {
                final ip = conn.nodeIps[nodeId] ?? 'IP inconnue';
                return ListTile(
                  leading: Icon(Icons.computer, color: Colors.green),
                  title: Text(
                    nodeId.length > 30
                        ? '${nodeId.substring(0, 30)}...'
                        : nodeId,
                    style: TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(ip),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conn = Provider.of<ConnectionManager>(context, listen: false);
    final sync = Provider.of<SyncManager>(context, listen: false);

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Actions Rapides',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Redémarrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🔄 Redémarrage...')),
                    );
                    await conn.stop();
                    await Future.delayed(Duration(seconds: 1));
                    await conn.start();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Serveur redémarré'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.sync),
                  label: Text('Forcer Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    sync.triggerAntiEntropy();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🔄 Sync lancée')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.link),
                  label: Text('Test Connexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showTestDialog(context, conn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTestDialog(BuildContext context, ConnectionManager conn) {
    final ipController = TextEditingController(text: '192.168.1.');
    final portController = TextEditingController(text: '45455');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test de Connexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: 'Adresse IP',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: portController,
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '45455',
                prefixIcon: Icon(Icons.tag),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text;
              final port = int.tryParse(portController.text) ?? 45455;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🔄 Test vers $ip:$port...')),
              );

              final success = await conn.connectToNode(
                'test-${DateTime.now().millisecondsSinceEpoch}',
                ip,
                port,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '✅ Connexion réussie!' : '❌ Échec connexion',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text('Tester'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const _InfoRow(this.label, this.value, this.isOk);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isOk ? Colors.black87 : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
