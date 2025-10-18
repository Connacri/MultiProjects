import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connection_manager_fixed.dart';
import 'crypto_manager_complete.dart';
import 'objectbox_p2p.dart';
import 'p2p_manager_fixed.dart';
import 'sync_manager_complete.dart';
import 'udp_broadcast_discovery.dart';

class P2PIntegration with ChangeNotifier {
  static P2PIntegration? _instance;

  factory P2PIntegration() {
    _instance ??= P2PIntegration._internal();
    return _instance!;
  }

  P2PIntegration._internal();

  // Managers
  final P2PManager _p2pManager = P2PManager();
  final ConnectionManager _connectionManager = ConnectionManager();
  final CryptoManager _cryptoManager = CryptoManager();
  final DiscoveryManagerBroadcast _discoveryManager =
      DiscoveryManagerBroadcast();
  final SyncManager _syncManager = SyncManager();
  late ObjectBoxP2P _objectBox;

  // État
  bool _initialized = false;

  bool get isInitialized => _initialized;

  String _initializationStatus = 'Non initialisé';

  String get initializationStatus => _initializationStatus;

  // Auto-connexion
  Timer? _autoConnectTimer;
  static const int autoConnectInterval = 5; // secondes

  /// Initialise le système P2P complet avec gestion d'erreur robuste
  Future<void> initializeP2PSystem() async {
    if (_initialized) {
      print('[P2PIntegration] Système déjà initialisé');
      return;
    }

    try {
      print('[P2PIntegration] Démarrage de l\'initialisation P2P');

      // 1. Initialiser Discovery Manager
      _updateStatus('Initialisation Discovery Manager...');
      await _initWithTimeout('DiscoveryManager', () async {
        await _discoveryManager.initialize();
      });

      // 2. Initialiser P2PManager
      _updateStatus('Initialisation P2PManager...');
      await _initWithTimeout('P2PManager', () async {
        await _p2pManager.initialize();
      });

      // 3. Initialiser CryptoManager
      _updateStatus('Initialisation CryptoManager...');
      await _initWithTimeout('CryptoManager', () async {
        await _cryptoManager.initialize();
      });

      // 4. Initialiser ObjectBoxP2P
      _updateStatus('Initialisation ObjectBoxP2P...');
      await _initWithTimeout('ObjectBoxP2P', () async {
        _objectBox = await ObjectBoxP2P.getInstance();
      });

      // 5. Initialiser SyncManager
      _updateStatus('Initialisation SyncManager...');
      await _initWithTimeout('SyncManager', () async {
        await _syncManager.initialize();
      });

      // 6. Démarrer ConnectionManager (avec retry)
      _updateStatus('Démarrage du serveur de connexion...');
      await _initWithTimeout('ConnectionManager', () async {
        await _connectionManager.start();
      });

      // 7. Démarrer la découverte réseau
      _updateStatus('Démarrage de la découverte réseau...');
      await _initWithTimeout('DiscoveryManager.start', () async {
        await _discoveryManager.start(
          _p2pManager.nodeId,
          _connectionManager.serverPort,
        );
      });

      // 8. Écouter les messages entrants
      _setupMessageListener();

      // 9. Démarrer l'auto-connexion
      _startAutoConnect();

      _initialized = true;
      _updateStatus('P2P opérationnel');
      notifyListeners();

      print('[P2PIntegration] ✅ Système P2P complètement initialisé');
      _logSystemStatus();
    } catch (e) {
      print('[P2PIntegration] ❌ Erreur critique: $e');
      _updateStatus('Erreur: $e');
      _initialized = false;
      await shutdown();
      notifyListeners();
      rethrow;
    }
  }

  /// Exécute une fonction d'initialisation avec timeout
  Future<void> _initWithTimeout(
    String name,
    Future<void> Function() fn,
  ) async {
    try {
      await fn().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('$name timeout après 10 secondes');
        },
      );
      print('[P2PIntegration] ✅ $name initialisé');
    } catch (e) {
      print('[P2PIntegration] ❌ Erreur $name: $e');
      rethrow;
    }
  }

  /// Met à jour le statut d'initialisation
  void _updateStatus(String status) {
    _initializationStatus = status;
    print('[P2PIntegration] Status: $status');
    notifyListeners();
  }

  /// Configure l'écoute des messages entrants
  void _setupMessageListener() {
    _connectionManager.onMessage.listen((message) async {
      try {
        final type = message['type'];
        final nodeId = message['nodeId'];

        // ✅ CORRECTION : Gérer les erreurs de parsing JSON
        if (type == null) {
          print('[P2PIntegration] ⚠️ Message sans type reçu');
          return;
        }

        if (type == 'delta' && nodeId != null) {
          await _handleDeltaMessage(nodeId, message);
        } else if (type == 'hello') {
          print('[P2PIntegration] 👋 Hello reçu de $nodeId');
        }
      } catch (e) {
        print('[P2PIntegration] ❌ Erreur traitement message: $e');
      }
    });

    print('[P2PIntegration] Écouteur de messages configuré');
  }

  /// Traite les messages delta reçus
  Future<void> _handleDeltaMessage(
    String nodeId,
    Map<String, dynamic> message,
  ) async {
    try {
      final encrypted = message['payload'] as Map<String, dynamic>?;
      if (encrypted == null) {
        print('[P2PIntegration] ⚠️ Pas de payload dans le delta');
        return;
      }

      // Vérifier l'authentification
      final isValid = await _cryptoManager.verifyDelta(encrypted);
      if (!isValid) {
        print('[P2PIntegration] ⚠️ Delta invalide de $nodeId');
        return;
      }

      // Déchiffrer
      final delta = await _cryptoManager.decryptDelta(encrypted);

      // Appliquer localement
      _objectBox.applyDelta(delta);

      // Queue pour sync
      _syncManager.queueForSync(delta);

      print('[P2PIntegration] ✅ Delta appliqué: ${delta['entity']}');
    } catch (e) {
      print('[P2PIntegration] ❌ Erreur traitement delta: $e');
    }
  }

  /// Démarre l'auto-connexion aux nœuds découverts
  void _startAutoConnect() {
    _autoConnectTimer?.cancel();

    _autoConnectTimer =
        Timer.periodic(Duration(seconds: autoConnectInterval), (_) async {
      await _tryConnectToDiscoveredNodes();
    });

    print('[P2PIntegration] Auto-connexion lancée');
  }

  /// Essaie de se connecter aux nœuds découverts
  Future<void> _tryConnectToDiscoveredNodes() async {
    final discoveredNodes = _discoveryManager.getDiscoveredNodesInfo();
    final connectedNodes = _connectionManager.neighbors;
    final localNodeId = _p2pManager.nodeId; // ✅ AJOUT

    for (final node in discoveredNodes) {
      final nodeId = node['nodeId'] as String;
      final ip = node['ip'] as String;
      final port = node['port'] as int;

      // ✅ CORRECTION : Ne pas se connecter à soi-même
      if (nodeId == localNodeId) {
        continue;
      }

      // Skip si déjà connecté
      if (connectedNodes.contains(nodeId)) {
        continue;
      }

      // Essayer de se connecter
      try {
        final success =
            await _connectionManager.connectToNode(nodeId, ip, port);
        if (success) {
          print('[P2PIntegration] ✅ Auto-connexion réussie: $nodeId');
        }
      } catch (e) {
        print('[P2PIntegration] ⚠️ Auto-connexion échouée pour $nodeId: $e');
      }
    }

    notifyListeners();
  }

  /// Broadcaster un delta à tous les pairs
  Future<void> broadcastDelta(Map<String, dynamic> delta) async {
    try {
      final encrypted = await _cryptoManager.encryptDelta(delta);
      _connectionManager.broadcastMessage({
        'type': 'delta',
        'nodeId': _p2pManager.nodeId,
        'payload': encrypted,
      });

      print(
          '[P2PIntegration] Delta broadcasté à ${_connectionManager.neighbors.length} pairs');
    } catch (e) {
      print('[P2PIntegration] ❌ Erreur broadcast: $e');
    }
  }

  /// Obtient les statistiques réseau complètes
  Map<String, dynamic> getNetworkStats() {
    return {
      'nodeId': _p2pManager.nodeId,
      'isInitialized': _initialized,
      'initializationStatus': _initializationStatus,
      'serverPort': _connectionManager.serverPort,
      'isServerRunning': _connectionManager.isRunning,
      'connectedNeighbors': _connectionManager.neighbors.length,
      'discoveredNodes': _discoveryManager.discoveredNodes.length,
      'discoveredNodesInfo': _discoveryManager.getDiscoveredNodesInfo(),
      'isSyncing': _syncManager.isSyncing,
      'successfulSyncs': _syncManager.successfulSyncs,
      'failedSyncs': _syncManager.failedSyncs,
      'connectionStats': _connectionManager.getStats(),
    };
  }

  /// Log le statut complet du système
  void _logSystemStatus() {
    final stats = getNetworkStats();
    print('[P2PIntegration] ========== STATUT SYSTÈME P2P ==========');
    print('[P2PIntegration] Node ID: ${stats['nodeId']}');
    print(
        '[P2PIntegration] Serveur: ${stats['isServerRunning']} (port ${stats['serverPort']})');
    print('[P2PIntegration] Voisins connectés: ${stats['connectedNeighbors']}');
    print('[P2PIntegration] Nœuds découverts: ${stats['discoveredNodes']}');
    print('[P2PIntegration] Synchronisation: ${stats['isSyncing']}');
    print('[P2PIntegration] Syncs réussies: ${stats['successfulSyncs']}');
    print('[P2PIntegration] Syncs échouées: ${stats['failedSyncs']}');
    print('[P2PIntegration] =====================================');
  }

  /// Arrête le système P2P
  Future<void> shutdown() async {
    print('[P2PIntegration] Arrêt du système P2P');

    _autoConnectTimer?.cancel();
    _discoveryManager.stop();
    await _connectionManager.stop();

    _initialized = false;
    _updateStatus('Arrêté');
    notifyListeners();

    print('[P2PIntegration] ✅ Système P2P arrêté');
  }

  /// Redémarre le système P2P
  Future<void> restart() async {
    print('[P2PIntegration] Redémarrage du système P2P');
    await shutdown();
    await Future.delayed(Duration(seconds: 2));
    await initializeP2PSystem();
  }

  void dispose() {
    shutdown();
  }
}
