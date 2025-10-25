import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connection_manager.dart';
import 'p2p_manager.dart';
import 'sync_manager.dart';
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
            ],
          ),
        );
      },
    );
  }
}
