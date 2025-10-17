import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connection_manager.dart';
import 'crypto_manager.dart';
import 'p2p_managers.dart' hide SyncManager;
import 'sync_manager.dart';

class P2PAdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin P2P'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [_buildP2PStatusIndicator(context)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NetworkStatusCard(),
            SizedBox(height: 16),
            _SyncStatisticsCard(),
            SizedBox(height: 16),
            _NeighborsCard(),
            SizedBox(height: 16),
            _CryptographyCard(),
            SizedBox(height: 16),
            _AdminActionsCard(),
          ],
        ),
      ),
    );
  }
}

// E.3 Ajout dans ton AppBar existant
Widget _buildP2PStatusIndicator(BuildContext context) {
  final p2pManager = Provider.of<P2PManager>(context);
  final connectionManager = Provider.of<ConnectionManager>(context);

  return Row(
    children: [
      Icon(
        p2pManager.isConnected ? Icons.cloud_done : Icons.cloud_off,
        color: p2pManager.isConnected ? Colors.green : Colors.red,
        size: 20,
      ),
      SizedBox(width: 4),
      Text(
        '${connectionManager.neighbors.length}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: p2pManager.isConnected ? Colors.green : Colors.red,
        ),
      ),
      SizedBox(width: 8),
      GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => P2PAdminDashboard(),
            )),
        child: Icon(Icons.info_outline, size: 20),
      ),
    ],
  );
}

class _NetworkStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p2pManager = Provider.of<P2PManager>(context);
    final connectionManager = Provider.of<ConnectionManager>(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Statut Réseau',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _StatusRow(
              label: 'Nœud ID',
              value: p2pManager.nodeId.substring(0, 16) + '...',
            ),
            _StatusRow(
              label: 'Statut Serveur',
              value: connectionManager.isRunning ? '🟢 Actif' : '🔴 Inactif',
              valueColor:
                  connectionManager.isRunning ? Colors.green : Colors.red,
            ),
            _StatusRow(
              label: 'Port',
              value: '${connectionManager.serverPort}',
            ),
            _StatusRow(
              label: 'Connexions Actives',
              value: '${connectionManager.neighbors.length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatisticsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final syncManager = Provider.of<SyncManager>(context);

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Statistiques Synchronisation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _StatusRow(
              label: 'Statut',
              value: syncManager.isSyncing
                  ? '🔄 Synchronisation...'
                  : '🟢 Au repos',
              valueColor: syncManager.isSyncing ? Colors.orange : Colors.green,
            ),
            _StatusRow(
              label: 'Syncs Réussies',
              value: '${syncManager.successfulSyncs}',
            ),
            _StatusRow(
              label: 'Syncs Échouées',
              value: '${syncManager.failedSyncs}',
            ),
            _StatusRow(
              label: 'File d\'attente',
              value: '${syncManager.isSyncing ? 'Traitement...' : 'Vide'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _NeighborsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context);

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
                  'Voisins Connectés (${connectionManager.neighbors.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (connectionManager.neighbors.isEmpty)
              Text('Aucun voisin connecté',
                  style: TextStyle(color: Colors.grey)),
            ...connectionManager.neighbors
                .map((nodeId) => ListTile(
                      leading: Icon(Icons.computer, color: Colors.blue),
                      title: Text(nodeId.length > 20
                          ? '${nodeId.substring(0, 20)}...'
                          : nodeId),
                      subtitle: Text(
                          connectionManager.nodeIps[nodeId] ?? 'IP inconnue'),
                      trailing:
                          Icon(Icons.signal_wifi_4_bar, color: Colors.green),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}

class _CryptographyCard extends StatefulWidget {
  @override
  State<_CryptographyCard> createState() => _CryptographyCardState();
}

class _CryptographyCardState extends State<_CryptographyCard> {
  late final CryptoManager cryptoManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCrypto();
  }

  Future<void> _initializeCrypto() async {
    await CryptoManager().initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Card(child: CircularProgressIndicator());
    }

    final cryptoManager = CryptoManager();
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Cryptographie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _StatusRow(
              label: 'Algorithme',
              value: 'AES-256-GCM + HMAC-SHA256',
            ),
            _StatusRow(
              label: 'Clé Publique',
              value: cryptoManager.publicKeyBase64!.substring(0, 20) + '...',
            ),
            _StatusRow(
              label: 'ECDH',
              value: 'X25519 activé',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connectionManager = Provider.of<ConnectionManager>(context);
    final syncManager = Provider.of<SyncManager>(context);
    final cryptoManager = CryptoManager();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Actions Administrateur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Anti-Entropie'),
                  onPressed: () => syncManager.triggerAntiEntropy(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.vpn_key),
                  label: Text('Rotation Clés'),
                  onPressed: () => cryptoManager.rotateKeys(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.qr_code),
                  label: Text('QR Onboarding'),
                  onPressed: () => _showQRDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.network_check),
                  label: Text('Test Connexion'),
                  onPressed: () => _testConnection(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    final qrData = CryptoManager().generateOnboardingQR();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Onboarding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scannez ce QR pour ajouter un nouveau nœud:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                jsonEncode(qrData),
                style: TextStyle(fontFamily: 'Monospace', fontSize: 10),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Node ID: ${qrData['nodeId']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _testConnection(BuildContext context) {
    // Test de connexion manuel
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test de Connexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Adresse IP',
                hintText: '192.168.1.100',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '45455',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implémenter le test de connexion
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Test de connexion envoyé')),
              );
            },
            child: Text('Tester'),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
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
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
