import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'p2p/connection_manager_fixed.dart';
import 'p2p/p2p_integration_fixed.dart';
import 'p2p/p2p_manager_fixed.dart';
import 'p2p/udp_broadcast_discovery.dart';

/// Widget de test de connexion P2P
/// Affiche l'état en temps réel et permet de forcer une connexion
class P2PConnectionTestWidget extends StatelessWidget {
  const P2PConnectionTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer4<P2PManager, ConnectionManager, DiscoveryManagerBroadcast,
        P2PIntegration>(
      builder: (context, p2p, conn, discovery, integration, _) {
        final stats = integration.getNetworkStats();
        final autoConnectStats =
            stats['autoConnectStats'] as Map<String, dynamic>;
        final discoveredNodesInfo = discovery.getDiscoveredNodesInfo();

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Icon(
                      conn.neighbors.isNotEmpty
                          ? Icons.check_circle
                          : Icons.warning,
                      color: conn.neighbors.isNotEmpty
                          ? Colors.green
                          : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'État Connexion P2P',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            conn.neighbors.isEmpty
                                ? 'En attente de pairs...'
                                : '${conn.neighbors.length} pair(s) connecté(s)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // Section: Identité
                _buildSection('🆔 Identité', [
                  _buildInfoRow('Node ID', p2p.nodeId.split('-').last),
                  _buildInfoRow('Port Serveur', conn.serverPort.toString()),
                  _buildInfoRow(
                    'Serveur',
                    conn.isRunning ? '✅ Actif' : '❌ Arrêté',
                  ),
                ]),

                const SizedBox(height: 16),

                // Section: Découverte
                _buildSection(
                  '🔍 Découverte (${discoveredNodesInfo.length})',
                  discoveredNodesInfo.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                'Recherche de nœuds...',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                        ]
                      : discoveredNodesInfo.map((node) {
                          final nodeId = node['nodeId'] as String;
                          final ip = node['ip'] as String;
                          final port = node['port'] as int;
                          final isSelf = nodeId == p2p.nodeId;

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isSelf ? Icons.person : Icons.computer,
                              color: isSelf ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                            title: Text(
                              isSelf ? 'Moi-même' : nodeId.split('-').last,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelf
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '$ip:$port',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: isSelf
                                ? const Chip(
                                    label: Text('MOI',
                                        style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.blue,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : null,
                          );
                        }).toList(),
                ),

                const SizedBox(height: 16),

                // Section: Connexions actives
                _buildSection(
                  '🔗 Connexions Actives (${conn.neighbors.length})',
                  conn.neighbors.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                '⚠️ Aucune connexion\n\nAssurez-vous d\'avoir 2+ appareils sur le même réseau',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : conn.neighbors.map((nodeId) {
                          final ip = conn.nodeIps[nodeId] ?? 'unknown';
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            title: Text(
                              nodeId.split('-').last,
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(
                              'IP: $ip',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(
                              Icons.sync,
                              color: Colors.blue,
                              size: 16,
                            ),
                          );
                        }).toList(),
                ),

                const SizedBox(height: 16),

                // Section: Statistiques Auto-Connect
                _buildSection('🤖 Auto-Connect', [
                  _buildInfoRow(
                    'Statut',
                    autoConnectStats['isRunning'] == true
                        ? '✅ Actif'
                        : '❌ Inactif',
                  ),
                  _buildInfoRow(
                    'Tentatives',
                    autoConnectStats['totalAttempts'].toString(),
                  ),
                  _buildInfoRow(
                    'Réussies',
                    '${autoConnectStats['successfulConnections']} ✅',
                  ),
                  _buildInfoRow(
                    'Échouées',
                    '${autoConnectStats['failedConnections']} ❌',
                  ),
                ]),

                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Redémarrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await integration.restart();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ P2P redémarré'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.info),
                        label: const Text('Logs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _showLogsDialog(context, stats);
                        },
                      ),
                    ),
                  ],
                ),

                // Aide
                if (conn.neighbors.isEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Comment tester ?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Lancez cette app sur un 2ème appareil\n'
                          '2. Assurez-vous qu\'ils sont sur le même WiFi\n'
                          '3. Les appareils se découvriront automatiquement\n'
                          '4. La connexion s\'établira en ~5 secondes',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques Complètes'),
        content: SingleChildScrollView(
          child: Text(
            stats.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
