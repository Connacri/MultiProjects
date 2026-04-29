import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auto_connect_service.dart';
import 'connection_manager.dart';
import 'crypto_manager_complete.dart';
import 'delta_generator_real.dart';
import 'objectbox_p2p.dart';
import 'objectbox_sync_observer.dart'; // ✅ AJOUT
import 'p2p_manager.dart';
import 'sync_manager.dart';
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
  final AutoConnectService _autoConnectService = AutoConnectService();
  final ObjectBoxSyncObserver _syncObserver =
      ObjectBoxSyncObserver(); // ✅ AJOUT

  late ObjectBoxP2P _objectBox;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  String _initializationStatus = 'Non initialisé';

  String get initializationStatus => _initializationStatus;

  ConnectionManager get connectionManager => _connectionManager;

  P2PManager get p2pManager => _p2pManager;

  /// ✅ CORRECTION MAJEURE : Initialise TOUT y compris l'observer
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

      // 6. Démarrer ConnectionManager
      _updateStatus('Démarrage du serveur de connexion...');
      await _initWithTimeout('ConnectionManager', () async {
        await _connectionManager.start();
      });

      // 7. Démarrer la découverte réseau
      _updateStatus('Démarrage de la découverte réseau...');
      try {
        await _initWithTimeout('DiscoveryManager.start', () async {
          await _discoveryManager.start(
            _p2pManager.nodeId,
            _connectionManager.serverPort,
          );
        });
      } catch (e) {
        print('[P2PIntegration] ⚠️ Échec démarrage DiscoveryManager (possiblement pas de réseau): $e');
        // On continue quand même l'initialisation pour ne pas bloquer l'app
      }

      // 8. Écouter les messages entrants
      _setupMessageListener();

      // 9. Démarrer l'auto-connexion
      _updateStatus('Démarrage de l\'auto-connexion...');
      _autoConnectService.start();
      print('[P2PIntegration] ✅ AutoConnectService démarré');

      // ✅ 10. CRITIQUE : CONFIGURER LE CALLBACK DE BROADCAST
      _updateStatus('Configuration DeltaGenerator...');
      final deltaGenerator = DeltaGenerator();
      deltaGenerator.setBroadcastCallback((delta) => broadcastDelta(delta));
      print('[P2PIntegration] ✅ DeltaGenerator configuré avec callback');

      // ✅ 11. CRITIQUE : DÉMARRER L'OBSERVER AUTOMATIQUE !
      _updateStatus('Démarrage de l\'observer automatique...');
      await _initWithTimeout('SyncObserver', () async {
        await _syncObserver.start();
      });
      print(
          '[P2PIntegration] ✅ SyncObserver démarré - modifications détectées automatiquement');

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

  Future<void> _initWithTimeout(String name, Future<void> Function() fn) async {
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

  void _updateStatus(String status) {
    _initializationStatus = status;
    print('[P2PIntegration] Status: $status');
    notifyListeners();
  }

  Future<void> _setupMessageListener() async {
    _connectionManager.onMessage.listen((message) async {
      try {
        final type = message['type'];
        final nodeId = message['nodeId'];

        if (type == null) {
          print('[P2PIntegration] ⚠️ Message sans type reçu');
          return;
        }

        if (type == 'delta' && nodeId != null) {
          print('[P2PIntegration] 📥 Delta reçu de $nodeId');
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

  Future<void> _handleDeltaMessage(
      String nodeId, Map<String, dynamic> message) async {
    try {
      final encrypted = message['payload'] as Map<String, dynamic>?;
      if (encrypted == null) {
        print('[P2PIntegration] ⚠️ Pas de payload dans le delta');
        return;
      }

      // Vérifier et déchiffrer
      final isValid = await _cryptoManager.verifyDelta(encrypted);
      if (!isValid) {
        print('[P2PIntegration] ⚠️ Delta invalide de $nodeId');
        return;
      }

      final delta = await _cryptoManager.decryptDelta(encrypted);
      print(
          '[P2PIntegration] 🔓 Delta déchiffré: ${delta['entity']} - ${delta['operation']}');

      // ✅ CRITIQUE : Marquer qu'on applique un delta distant
      _syncObserver.setApplyingRemoteDelta(true);

      try {
        _objectBox.applyDelta(delta);
        _syncManager.queueForSync(delta);
        print('[P2PIntegration] ✅ Delta appliqué: ${delta['entity']}');
        // ✅ AJOUT CRITIQUE : Notifier explicitement selon le type d'entité
        _notifyProviders(delta['entity'] as String);
      } finally {
        // ✅ Réactiver après un délai
        Future.delayed(Duration(seconds: 1), () {
          _syncObserver.setApplyingRemoteDelta(false);
        });
      }
    } catch (e) {
      print('[P2PIntegration] ❌ Erreur traitement delta: $e');
      _syncObserver.setApplyingRemoteDelta(false);
    }
  }

// ✅ NOUVELLE MÉTHODE : Notification explicite des providers
  void _notifyProviders(String entityType) {
    print('[P2PIntegration] 🔔 Notification providers pour: $entityType');

    // Notifier via les callbacks de l'observer
    switch (entityType) {
      case 'Staff':
        _syncObserver.notifyStaffListeners();
        break;
      case 'ActiviteJour':
        _syncObserver.notifyActiviteListeners();
        break;
      case 'Branch':
        _syncObserver.notifyBranchListeners();
        break;
      // Ajouter d'autres cas si nécessaire
    }
  }

  Future<void> broadcastDelta(Map<String, dynamic> delta) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[P2PIntegration] 🎯 DÉBUT broadcastDelta');
      print('[P2PIntegration] Delta: $delta');
      print(
          '[P2PIntegration] Nombre de voisins: ${_connectionManager.neighbors.length}');
      print(
          '[P2PIntegration] Voisins: ${_connectionManager.neighbors.toList()}');

      if (_connectionManager.neighbors.isEmpty) {
        print('[P2PIntegration] ⚠️⚠️⚠️ AUCUN VOISIN CONNECTÉ !');
        print('[P2PIntegration] ⚠️ Le delta ne sera envoyé à personne !');
        return;
      }

      print('[P2PIntegration] 🔐 Chiffrement du delta...');
      final encrypted = await _cryptoManager.encryptDelta(delta);
      print('[P2PIntegration] ✅ Delta chiffré');

      final message = {
        'type': 'delta',
        'nodeId': _p2pManager.nodeId,
        'payload': encrypted,
      };

      print('[P2PIntegration] 📤 Envoi du message...');
      _connectionManager.broadcastMessage(message);

      print(
          '[P2PIntegration] ✅ Delta broadcasté à ${_connectionManager.neighbors.length} pairs');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('[P2PIntegration] ❌ ERREUR broadcast: $e');
      print('[P2PIntegration] Stack trace: ${StackTrace.current}');
    }
  }

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
      'autoConnectStats': _autoConnectService.getStats(),
      'syncObserverStats': _syncObserver.getStats(), // ✅ AJOUT
    };
  }

  void _logSystemStatus() {
    final stats = getNetworkStats();
    print('[P2PIntegration] ========== STATUT SYSTÈME P2P ==========');
    print('[P2PIntegration] Node ID: ${stats['nodeId']}');
    print(
        '[P2PIntegration] Serveur: ${stats['isServerRunning']} (port ${stats['serverPort']})');
    print('[P2PIntegration] Voisins connectés: ${stats['connectedNeighbors']}');
    print('[P2PIntegration] Nœuds découverts: ${stats['discoveredNodes']}');
    print('[P2PIntegration] Synchronisation: ${stats['isSyncing']}');
    print(
        '[P2PIntegration] Observer actif: ${_syncObserver.isRunning}'); // ✅ AJOUT
    print('[P2PIntegration] =====================================');
  }

  Future<void> shutdown() async {
    print('[P2PIntegration] Arrêt du système P2P');

    _syncObserver.stop(); // ✅ AJOUT
    _autoConnectService.stop();
    _discoveryManager.stop();
    await _connectionManager.stop();

    _initialized = false;
    _updateStatus('Arrêté');
    notifyListeners();

    print('[P2PIntegration] ✅ Système P2P arrêté');
  }

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
