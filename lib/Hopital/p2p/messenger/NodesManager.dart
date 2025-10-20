import 'package:flutter/material.dart';

import '../connection_manager_fixed.dart';
import '../p2p_manager_fixed.dart';

enum NodeStatus { online, offline, idle }

class NetworkNode {
  final String nodeId;
  final String displayName;
  final NodeStatus status;
  final DateTime lastSeen;

  NetworkNode({
    required this.nodeId,
    required this.displayName,
    required this.status,
    required this.lastSeen,
  });

  String get statusLabel {
    switch (status) {
      case NodeStatus.online:
        return 'En ligne';
      case NodeStatus.offline:
        return 'Hors ligne';
      case NodeStatus.idle:
        return 'Inactif';
    }
  }

  Color get statusColor {
    switch (status) {
      case NodeStatus.online:
        return Colors.green;
      case NodeStatus.offline:
        return Colors.grey;
      case NodeStatus.idle:
        return Colors.orange;
    }
  }
}

class NodesManager {
  static final NodesManager _instance = NodesManager._internal();

  factory NodesManager() => _instance;

  NodesManager._internal();

  late P2PManager _p2pManager;
  late ConnectionManager _connectionManager;
  List<NetworkNode> _cachedNodes = [];

  Future<void> initialize(
    P2PManager p2pManager,
    ConnectionManager connectionManager,
  ) async {
    _p2pManager = p2pManager;
    _connectionManager = connectionManager;

    // Écouter les changements dans ConnectionManager
    _connectionManager.addListener(_onConnectionManagerChanged);

    await refreshNodes();
  }

  void _onConnectionManagerChanged() {
    // Rafraîchir automatiquement quand ConnectionManager change
    refreshNodes();
  }

  List<NetworkNode> get availableNodes => _cachedNodes;

  /// Récupère les nœuds voisins découverts
  Future<void> refreshNodes() async {
    try {
      print('[NodesManager] 🔄 Rafraîchissement des nœuds...');

      // Récupérer les voisins depuis ConnectionManager
      // ConnectionManager a une propriété: Set<String> get neighbors => _neighbors;
      final neighborsSet = _connectionManager.neighbors;

      if (neighborsSet.isEmpty) {
        print('[NodesManager] ⚠️ Aucun voisin découvert');
        _cachedNodes = [];
        return;
      }

      // Convertir en NetworkNode
      _cachedNodes = neighborsSet.map((nodeId) {
        return NetworkNode(
          nodeId: nodeId,
          displayName: _getDisplayName(nodeId),
          status: NodeStatus.online, // Les voisins sont par définition en ligne
          lastSeen: DateTime.now(),
        );
      }).toList();

      // Trier par nom d'affichage
      _cachedNodes.sort((a, b) => a.displayName.compareTo(b.displayName));

      print('[NodesManager] ✅ ${_cachedNodes.length} nœud(s) découvert(s)');

      // Afficher les nœuds pour debug
      for (var node in _cachedNodes) {
        print('[NodesManager]   - ${node.displayName} (${node.nodeId})');
      }
    } catch (e) {
      print('[NodesManager] ❌ Erreur rafraîchissement: $e');
      _cachedNodes = [];
    }
  }

  /// Extrait un nom lisible du nodeId
  String _getDisplayName(String nodeId) {
    // Les nodeIds ont le format: 'node-{timestamp}-{hostname}'
    // On extrait le hostname (dernière partie)
    try {
      final parts = nodeId.split('-');
      if (parts.length >= 3) {
        // Retourner tout sauf 'node' et le timestamp
        return parts.skip(2).join('-');
      }
      return nodeId;
    } catch (e) {
      return nodeId;
    }
  }

  void dispose() {
    _connectionManager.removeListener(_onConnectionManagerChanged);
  }
}
