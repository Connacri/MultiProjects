import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connection_manager_fixed.dart';
import 'p2p_manager_fixed.dart';
import 'sync_manager_complete.dart';
import 'udp_broadcast_discovery.dart';

/// 📊 Page de diagnostic P2P avec détection de plateforme
class P2PDiagnosticPage extends StatefulWidget {
  const P2PDiagnosticPage({Key? key}) : super(key: key);

  @override
  State<P2PDiagnosticPage> createState() => _P2PDiagnosticPageState();
}

class _P2PDiagnosticPageState extends State<P2PDiagnosticPage> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  Map<String, String> _platformInfo = {};
  Map<String, Map<String, String>> _connectedNodesPlatforms = {};
  bool _isLoadingPlatformInfo = true;

  @override
  void initState() {
    super.initState();
    _loadPlatformInfo();
  }

  /// 🔍 Détecte la plateforme actuelle
  Future<void> _loadPlatformInfo() async {
    try {
      Map<String, String> info = {};

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info = {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt.toString(),
          'device': '${androidInfo.manufacturer} ${androidInfo.model}',
          'icon': '🤖',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info = {
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'device': iosInfo.model,
          'name': iosInfo.name,
          'icon': '🍎',
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info = {
          'platform': 'Windows',
          'version': windowsInfo.productName,
          'build': windowsInfo.buildNumber.toString(),
          'device': windowsInfo.computerName,
          'icon': '🪟',
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info = {
          'platform': 'Linux',
          'version': linuxInfo.prettyName,
          'device': linuxInfo.name,
          'icon': '🐧',
        };
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        info = {
          'platform': 'macOS',
          'version': macInfo.osRelease,
          'device': macInfo.computerName,
          'icon': '🍏',
        };
      } else {
        info = {
          'platform': 'Unknown',
          'version': 'N/A',
          'device': 'Unknown Device',
          'icon': '❓',
        };
      }

      if (mounted) {
        setState(() {
          _platformInfo = info;
          _isLoadingPlatformInfo = false;
        });
        print(
            '[Diagnostic] ✅ Plateforme détectée: ${info['platform']} ${info['icon']}');
      }
    } catch (e) {
      print('[Diagnostic] ❌ Erreur détection plateforme: $e');
      if (mounted) {
        setState(() {
          _platformInfo = {
            'platform': 'Error',
            'version': 'N/A',
            'device': 'Detection Failed',
            'icon': '⚠️',
          };
          _isLoadingPlatformInfo = false;
        });
      }
    }
  }

  /// 🔍 Devine la plateforme d'un nœud basé sur son nodeId
  Map<String, String> _guessPlatformFromNodeId(String nodeId) {
    // Le nodeId est généré comme: 'node-timestamp-hostname'
    final parts = nodeId.split('-');

    if (parts.length < 3) {
      return {'platform': 'Unknown', 'icon': '❓'};
    }

    final hostname = parts.sublist(2).join('-').toLowerCase();

    // Détection par patterns dans le hostname
    if (hostname.contains('android') || hostname.contains('mobile')) {
      return {'platform': 'Android', 'icon': '🤖'};
    } else if (hostname.contains('iphone') || hostname.contains('ipad')) {
      return {'platform': 'iOS', 'icon': '🍎'};
    } else if (hostname.contains('desktop') ||
        hostname.contains('pc') ||
        hostname.contains('win')) {
      return {'platform': 'Windows', 'icon': '🪟'};
    } else if (hostname.contains('linux') || hostname.contains('ubuntu')) {
      return {'platform': 'Linux', 'icon': '🐧'};
    } else if (hostname.contains('mac') || hostname.contains('macbook')) {
      return {'platform': 'macOS', 'icon': '🍏'};
    }

    // Par défaut
    return {'platform': 'Desktop', 'icon': '💻'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic P2P Complet'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoadingPlatformInfo)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: () {
                setState(() {
                  _isLoadingPlatformInfo = true;
                });
                _loadPlatformInfo();
              },
            ),
        ],
      ),
      body: Consumer4<P2PManager, ConnectionManager, SyncManager,
          DiscoveryManagerBroadcast>(
        builder: (context, p2p, conn, sync, discovery, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await _loadPlatformInfo();
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖥️ Section: Ce périphérique
                  _buildPlatformSection(),
                  const SizedBox(height: 16),

                  // 📊 Section: État général
                  _buildGeneralStatusSection(p2p, conn, sync),
                  const SizedBox(height: 16),

                  // 🔗 Section: Connexions actives avec plateformes
                  _buildActiveConnectionsSection(conn),
                  const SizedBox(height: 16),

                  // 🔍 Section: Nœuds découverts
                  _buildDiscoveredNodesSection(discovery),
                  const SizedBox(height: 16),

                  // 📈 Section: Statistiques
                  _buildStatisticsSection(sync, conn),
                  const SizedBox(height: 16),

                  // ⚙️ Section: Actions
                  _buildActionsSection(conn, sync),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🖥️ Section plateforme actuelle
  Widget _buildPlatformSection() {
    return Card(
      elevation: 3,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _platformInfo['icon'] ?? '❓',
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ce Périphérique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      Text(
                        _platformInfo['platform'] ?? 'Chargement...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_isLoadingPlatformInfo)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Détection de la plateforme...'),
                    ],
                  ),
                ),
              )
            else if (_platformInfo.isNotEmpty) ...[
              _buildInfoTile('Plateforme', _platformInfo['platform'] ?? 'N/A'),
              _buildInfoTile('Version', _platformInfo['version'] ?? 'N/A'),
              _buildInfoTile('Appareil', _platformInfo['device'] ?? 'N/A'),
              if (_platformInfo['build'] != null)
                _buildInfoTile('Build', _platformInfo['build']!),
              if (_platformInfo['sdk'] != null)
                _buildInfoTile('SDK', _platformInfo['sdk']!),
              if (_platformInfo['name'] != null)
                _buildInfoTile('Nom', _platformInfo['name']!),
            ] else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Impossible de détecter la plateforme',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 📊 Section état général
  Widget _buildGeneralStatusSection(
    P2PManager p2p,
    ConnectionManager conn,
    SyncManager sync,
  ) {
    final isOperational = p2p.nodeId.isNotEmpty && conn.isRunning;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOperational ? Icons.check_circle : Icons.warning,
                  color: isOperational ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOperational
                            ? 'Système Opérationnel'
                            : 'Initialisation',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOperational
                            ? '${conn.neighbors.length} connexion(s) active(s)'
                            : 'En attente de connexions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoTile(
                'Node ID',
                p2p.nodeId.isEmpty
                    ? 'Non initialisé'
                    : '${p2p.nodeId.substring(0, 30)}...'),
            _buildInfoTile(
              'Serveur P2P',
              conn.isRunning ? '✅ Actif (Port ${conn.serverPort})' : '❌ Arrêté',
            ),
            _buildInfoTile(
              'État réseau',
              p2p.isConnected ? '✅ Connecté' : '⚠️ Déconnecté',
            ),
          ],
        ),
      ),
    );
  }

  /// 🔗 Section connexions actives avec plateformes
  Widget _buildActiveConnectionsSection(ConnectionManager conn) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connexions Actives',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[800],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${conn.neighbors.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (conn.neighbors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune connexion active',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...conn.neighbors.map((nodeId) {
              final ip = conn.nodeIps[nodeId] ?? 'IP inconnue';
              final platformInfo = _guessPlatformFromNodeId(nodeId);

              return ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      platformInfo['icon']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                title: Text(
                  nodeId.length > 40 ? '${nodeId.substring(0, 40)}...' : nodeId,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IP: $ip', style: const TextStyle(fontSize: 11)),
                    Text(
                      platformInfo['platform']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                dense: true,
              );
            }).toList(),
        ],
      ),
    );
  }

  /// 🔍 Section nœuds découverts
  Widget _buildDiscoveredNodesSection(DiscoveryManagerBroadcast discovery) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nœuds Découverts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange[800],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${discovery.discoveredNodes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (discovery.discoveredNodes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Recherche de nœuds...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...discovery.discoveredNodes.map((nodeKey) {
              final parts = nodeKey.split('@');
              final nodeId = parts.isNotEmpty ? parts[0] : nodeKey;
              final platformInfo = _guessPlatformFromNodeId(nodeId);

              return ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      platformInfo['icon']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                title: Text(
                  nodeKey.length > 45
                      ? '${nodeKey.substring(0, 45)}...'
                      : nodeKey,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  platformInfo['platform']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                trailing: const Icon(
                  Icons.search,
                  color: Colors.orange,
                  size: 18,
                ),
                dense: true,
              );
            }).toList(),
        ],
      ),
    );
  }

  /// 📈 Section statistiques
  Widget _buildStatisticsSection(SyncManager sync, ConnectionManager conn) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques de Synchronisation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[800],
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  'Réussies',
                  sync.successfulSyncs.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatBox(
                  'Échouées',
                  sync.failedSyncs.toString(),
                  Colors.red,
                  Icons.error,
                ),
                _buildStatBox(
                  'En cours',
                  sync.isSyncing ? 'Oui' : 'Non',
                  sync.isSyncing ? Colors.blue : Colors.grey,
                  sync.isSyncing ? Icons.sync : Icons.sync_disabled,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoTile(
                'Connexions réussies', conn.successfulConnections.toString()),
            _buildInfoTile(
                'Connexions échouées', conn.failedConnections.toString()),
          ],
        ),
      ),
    );
  }

  /// ⚙️ Section actions
  Widget _buildActionsSection(ConnectionManager conn, SyncManager sync) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Redémarrer Serveur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  await conn.restart();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Serveur redémarré'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Forcer Synchronisation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  await sync.triggerAntiEntropy();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Synchronisation lancée'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget helper: Info tile
  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper: Stat box
  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
