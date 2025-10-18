import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connection_manager_fixed.dart';
import 'udp_broadcast_discovery.dart';
import 'p2p_manager_fixed.dart'; // ✅ AJOUT pour accéder au nodeId local

/// Service d'auto-connexion aux nœuds découverts avec stratégies multiples
class AutoConnectService with ChangeNotifier {
  static final AutoConnectService _instance = AutoConnectService._internal();

  factory AutoConnectService() => _instance;

  AutoConnectService._internal();

  final DiscoveryManagerBroadcast _discoveryManager =
  DiscoveryManagerBroadcast();
  final ConnectionManager _connectionManager = ConnectionManager();
  final P2PManager _p2pManager = P2PManager(); // ✅ AJOUT

  Timer? _autoConnectTimer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // Statistiques
  int _totalConnectionAttempts = 0;
  int _totalSuccessfulConnections = 0;
  int _totalFailedConnections = 0;

  int get totalConnectionAttempts => _totalConnectionAttempts;

  int get totalSuccessfulConnections => _totalSuccessfulConnections;

  int get totalFailedConnections => _totalFailedConnections;

  static const int autoConnectInterval = 5; // secondes
  static const int maxRetriesPerNode = 3;

  // Tracking des tentatives par nœud
  final Map<String, int> _nodeRetries = {};

  /// Démarre le service d'auto-connexion
  void start() {
    if (_isRunning) {
      print('[AutoConnectService] Service déjà en cours d\'exécution');
      return;
    }

    _isRunning = true;
    print('[AutoConnectService] Service d\'auto-connexion démarré');

    // Première tentative immédiatement
    _tryConnectToDiscoveredNodes();

    // Puis toutes les 5 secondes
    _autoConnectTimer?.cancel();
    _autoConnectTimer =
        Timer.periodic(Duration(seconds: autoConnectInterval), (_) {
          _tryConnectToDiscoveredNodes();
        });

    notifyListeners();
  }

  /// Arrête le service
  void stop() {
    _autoConnectTimer?.cancel();
    _isRunning = false;
    print('[AutoConnectService] Service d\'auto-connexion arrêté');
    notifyListeners();
  }

  /// Essaie de se connecter aux nœuds découverts
  Future<void> _tryConnectToDiscoveredNodes() async {
    try {
      final nodes = _discoveryManager.getDiscoveredNodesInfo();
      final currentConnections = _connectionManager.neighbors;
      final localNodeId = _p2pManager.nodeId; // ✅ AJOUT : récupérer notre ID

      if (nodes.isEmpty) {
        print(
            '[AutoConnectService] Aucun nœud découvert, attente de la découverte...');
        return;
      }

      print('[AutoConnectService] ${nodes.length} nœud(s) découvert(s)');

      for (final node in nodes) {
        final nodeId = node['nodeId'] as String;
        final ip = node['ip'] as String;
        final port = node['port'] as int;

        // ✅ CORRECTION : Skip si c'est nous-mêmes
        if (nodeId == localNodeId) {
          print('[AutoConnectService] 🚫 Skip self-connection: $nodeId');
          continue;
        }

        // Skip si déjà connecté
        if (currentConnections.contains(nodeId)) {
          print('[AutoConnectService] $nodeId déjà connecté');
          _nodeRetries.remove(nodeId); // Reset retries
          continue;
        }

        // Vérifier le nombre de tentatives
        final retries = _nodeRetries[nodeId] ?? 0;
        if (retries >= maxRetriesPerNode) {
          print(
              '[AutoConnectService] Max tentatives atteint pour $nodeId ($retries/$maxRetriesPerNode)');
          continue;
        }

        // Essayer la connexion
        _totalConnectionAttempts++;
        try {
          print(
              '[AutoConnectService] Tentative connexion #${retries +
                  1}: $nodeId ($ip:$port)');

          final success = await _connectionManager.connectToNode(
            nodeId,
            ip,
            port,
          );

          if (success) {
            print('[AutoConnectService] ✅ Connexion réussie: $nodeId');
            _totalSuccessfulConnections++;
            _nodeRetries.remove(nodeId); // Reset retries on success
          } else {
            print('[AutoConnectService] ⚠️ Connexion échouée: $nodeId');
            _totalFailedConnections++;
            _nodeRetries[nodeId] = retries + 1;
          }
        } catch (e) {
          print('[AutoConnectService] ❌ Erreur connexion $nodeId: $e');
          _totalFailedConnections++;
          _nodeRetries[nodeId] = retries + 1;
        }
      }

      notifyListeners();
    } catch (e) {
      print('[AutoConnectService] Erreur traitement nœuds découverts: $e');
    }
  }

  /// Obtient les statistiques
  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'discoveredCount': _discoveryManager.discoveredNodes.length,
      'connectedCount': _connectionManager.neighbors.length,
      'totalAttempts': _totalConnectionAttempts,
      'successfulConnections': _totalSuccessfulConnections,
      'failedConnections': _totalFailedConnections,
      'discoveredNodesInfo': _discoveryManager.getDiscoveredNodesInfo(),
    };
  }

  /// Réinitialise les retries pour un nœud
  void resetRetries(String nodeId) {
    _nodeRetries.remove(nodeId);
    print('[AutoConnectService] Retries réinitialisés pour $nodeId');
    notifyListeners();
  }

  /// Réinitialise tous les retries
  void resetAllRetries() {
    _nodeRetries.clear();
    print('[AutoConnectService] Tous les retries réinitialisés');
    notifyListeners();
  }

  void dispose() {
    stop();
  }
}