import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'P2PDiagnosticPage.dart';
import 'connection_manager_fixed.dart';
import 'p2p_manager_fixed.dart';
import 'sync_manager_complete.dart';
import 'udp_broadcast_discovery.dart';

/// Widget de bannière d'état P2P compact
class P2PStatusBanner extends StatelessWidget {
  const P2PStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer4<P2PManager, ConnectionManager, SyncManager,
        DiscoveryManagerBroadcast>(
      builder: (context, p2p, conn, sync, discovery, _) {
        final isReady = p2p.nodeId.isNotEmpty;
        final isConnected = conn.isRunning && conn.neighbors.isNotEmpty;
        final hasDiscovered = discovery.discoveredNodes.isNotEmpty;

        // Déterminer la couleur selon l'état
        Color bannerColor;
        String statusText;
        IconData statusIcon;

        if (isConnected) {
          bannerColor = Colors.green;
          statusIcon = Icons.cloud_done;
          statusText = 'P2P Connecté';
        } else if (isReady && conn.isRunning) {
          bannerColor = Colors.amber;
          statusIcon = Icons.cloud;
          statusText = 'P2P Actif (En attente)';
        } else if (isReady) {
          bannerColor = Colors.orange;
          statusIcon = Icons.cloud_queue;
          statusText = 'P2P Initialisation';
        } else {
          bannerColor = Colors.red;
          statusIcon = Icons.cloud_off;
          statusText = 'P2P Arrêté';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Voisins: ${conn.neighbors.length} | Découverts: ${discovery.discoveredNodes.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                iconSize: 18,
                tooltip: 'Détails P2P',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const P2PDiagnosticPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// /// Page de diagnostic et détails P2P
// class SimpleDiagnosticPage extends StatelessWidget {
//   const SimpleDiagnosticPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Diagnostic P2P'),
//         backgroundColor: Colors.blue[800],
//         foregroundColor: Colors.white,
//       ),
//       body: Consumer4<P2PManager, ConnectionManager, SyncManager,
//           DiscoveryManagerBroadcast>(
//         builder: (context, p2p, conn, sync, discovery, _) {
//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Section: État général
//                 _buildSection(
//                   'État Général',
//                   [
//                     _buildInfoRow('Node ID', p2p.nodeId.isEmpty
//                         ? 'Non initialisé'
//                         : '${p2p.nodeId.substring(0, 30)}...'),
//                     _buildInfoRow('Serveur', conn.isRunning
//                         ? 'Actif (Port ${conn.serverPort})'
//                         : 'Arrêté'),
//                     _buildInfoRow('Status', p2p.isConnected ? 'Connecté' : 'Déconnecté'),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Section: Connexions
//                 _buildSection(
//                   'Connexions Actives (${conn.neighbors.length})',
//                   conn.neighbors.isEmpty
//                       ? [
//                           Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Center(
//                               child: Text(
//                                 'Aucune connexion active',
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                             ),
//                           ),
//                         ]
//                       : conn.neighbors
//                           .map((nodeId) => _buildNeighborTile(nodeId, conn))
//                           .toList(),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Section: Découverte
//                 _buildSection(
//                   'Nœuds Découverts (${discovery.discoveredNodes.length})',
//                   discovery.discoveredNodes.isEmpty
//                       ? [
//                           Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Center(
//                               child: Text(
//                                 'Recherche en cours...',
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                             ),
//                           ),
//                         ]
//                       : discovery.discoveredNodes
//                           .map((nodeKey) => _buildDiscoveredNodeTile(nodeKey))
//                           .toList(),
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Section: Statistiques
//                 _buildSection(
//                   'Statistiques Synchronisation',
//                   [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 8),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _buildStatBox(
//                             'Réussies',
//                             sync.successfulSyncs.toString(),
//                             Colors.green,
//                           ),
//                           _buildStatBox(
//                             'Échouées',
//                             sync.failedSyncs.toString(),
//                             Colors.red,
//                           ),
//                           _buildStatBox(
//                             'En cours',
//                             sync.isSyncing ? 'Oui' : 'Non',
//                             sync.isSyncing ? Colors.blue : Colors.grey,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Section: Actions
//                 _buildSection(
//                   'Actions',
//                   [
//                     Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         children: [
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton.icon(
//                               icon: const Icon(Icons.refresh),
//                               label: const Text('Redémarrer Serveur'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue,
//                                 foregroundColor: Colors.white,
//                               ),
//                               onPressed: () async {
//                                 await conn.stop();
//                                 await Future.delayed(
//                                     const Duration(seconds: 1));
//                                 await conn.start();
//                                 if (context.mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text('✅ Serveur redémarré'),
//                                       backgroundColor: Colors.green,
//                                     ),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton.icon(
//                               icon: const Icon(Icons.sync),
//                               label: const Text('Forcer Synchronisation'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                                 foregroundColor: Colors.white,
//                               ),
//                               onPressed: () async {
//                                 await sync.triggerAntiEntropy();
//                                 if (context.mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                           '✅ Synchronisation lancée'),
//                                       backgroundColor: Colors.green,
//                                     ),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   /// Construit une section avec titre et contenu
//   Widget _buildSection(String title, List<Widget> children) {
//     return Card(
//       elevation: 2,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(4),
//                 topRight: Radius.circular(4),
//               ),
//             ),
//             child: Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//                 color: Colors.blue[800],
//               ),
//             ),
//           ),
//           ...children,
//         ],
//       ),
//     );
//   }
//
//   /// Construit une ligne d'information
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Flexible(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontFamily: 'monospace',
//                 fontSize: 12,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Tile pour voisin connecté
//   Widget _buildNeighborTile(String nodeId, ConnectionManager conn) {
//     final ip = conn.nodeIps[nodeId] ?? 'IP inconnue';
//     return ListTile(
//       leading: const Icon(Icons.computer, color: Colors.green),
//       title: Text(
//         nodeId.length > 40 ? '${nodeId.substring(0, 40)}...' : nodeId,
//         style: const TextStyle(fontSize: 12),
//       ),
//       subtitle: Text(ip),
//       trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
//       dense: true,
//     );
//   }
//
//   /// Tile pour nœud découvert
//   Widget _buildDiscoveredNodeTile(String nodeKey) {
//     return ListTile(
//       leading: const Icon(Icons.cloud, color: Colors.blue),
//       title: Text(
//         nodeKey.length > 50 ? '${nodeKey.substring(0, 50)}...' : nodeKey,
//         style: const TextStyle(fontSize: 11),
//       ),
//       trailing: const Icon(Icons.search, color: Colors.orange, size: 18),
//       dense: true,
//     );
//   }
//
//   /// Box de statistiques
//   Widget _buildStatBox(String label, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color),
//       ),
//       child: Column(
//         children: [
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 11),
//           ),
//         ],
//       ),
//     );
//   }
// }
