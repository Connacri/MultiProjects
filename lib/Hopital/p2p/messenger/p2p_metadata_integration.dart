import 'package:flutter/material.dart';

import '../connection_manager.dart';
import '../p2p_manager.dart';
import 'messaging_integration.dart';
import 'messaging_manager.dart';
import 'node_metadata_manager.dart';

/// 🔥 Intégration complète du système de métadonnées P2P
/// À initialiser au démarrage de l'application
class P2PMetadataIntegration {
  static final P2PMetadataIntegration _instance =
      P2PMetadataIntegration._internal();

  factory P2PMetadataIntegration() => _instance;

  P2PMetadataIntegration._internal();

  late P2PManager _p2pManager;
  late ConnectionManager _connectionManager;
  late MessagingManager _messagingManager;
  late NodeMetadataManager _metadataManager;
  late MessagingP2PIntegration _messagingP2P;

  bool _initialized = false;

  /// ✅ Initialiser TOUS les composants P2P
  Future<void> initialize({
    required P2PManager p2pManager,
    required ConnectionManager connectionManager,
    required MessagingManager messagingManager,
  }) async {
    try {
      print('[P2PMetadataIntegration] 🚀 Initialisation...');

      _p2pManager = p2pManager;
      _connectionManager = connectionManager;
      _messagingManager = messagingManager;
      _metadataManager = NodeMetadataManager();
      _messagingP2P = MessagingP2PIntegration();

      // 1️⃣ Initialiser le gestionnaire de métadonnées
      await _metadataManager.initialize(
        _connectionManager,
        _messagingManager.currentNodeId,
      );
      print('[P2PMetadataIntegration] ✅ Gestionnaire métadonnées initialisé');

      // 2️⃣ Initialiser l'intégration messaging P2P
      await _messagingP2P.initialize(
        _messagingManager,
        null, // P2PIntegration n'est plus nécessaire
        _connectionManager,
        messagingManager.objectBox,
      );
      print('[P2PMetadataIntegration] ✅ Messaging P2P initialisé');

      // 3️⃣ Démarrer l'intégration messaging
      _messagingP2P.start();
      print('[P2PMetadataIntegration] ✅ Messaging P2P démarré');

      // 4️⃣ Écouter les changements de voisins pour broadcaster
      _connectionManager.addListener(_onConnectionManagerChanged);

      _initialized = true;
      print('[P2PMetadataIntegration] 🎉 Initialisation complète réussie');
    } catch (e, stackTrace) {
      print('[P2PMetadataIntegration] ❌ Erreur initialisation: $e');
      print('[P2PMetadataIntegration] Stack: $stackTrace');
      rethrow;
    }
  }

  /// ✅ Callback quand le ConnectionManager change (nouveaux voisins)
  void _onConnectionManagerChanged() {
    if (_initialized) {
      print(
          '[P2PMetadataIntegration] 🔄 Nouveaux voisins détectés, broadcast métadonnées');
      _metadataManager.broadcastMetadata();
    }
  }

  /// ✅ Arrêter tous les composants
  void stop() {
    try {
      _connectionManager.removeListener(_onConnectionManagerChanged);
      _messagingP2P.stop();
      _metadataManager.stop();
      _initialized = false;
      print('[P2PMetadataIntegration] 🛑 Arrêté');
    } catch (e) {
      print('[P2PMetadataIntegration] ⚠️ Erreur arrêt: $e');
    }
  }

  /// ✅ Obtenir les statistiques
  Map<String, dynamic> getStats() {
    return {
      'initialized': _initialized,
      'metadataNodes': _metadataManager.remoteMetadata.length,
      'messagingStats': _messagingP2P.getStats(),
      'neighbors': _connectionManager.neighbors.length,
    };
  }

  /// Getters pour accès externe
  NodeMetadataManager get metadataManager => _metadataManager;

  MessagingP2PIntegration get messagingP2P => _messagingP2P;

  bool get isInitialized => _initialized;
}

/// 🔥 Provider pour l'intégration P2P
/// À utiliser dans le MultiProvider de l'app
class P2PMetadataProvider with ChangeNotifier {
  final P2PMetadataIntegration _integration = P2PMetadataIntegration();

  P2PMetadataIntegration get integration => _integration;

  Future<void> initialize({
    required P2PManager p2pManager,
    required ConnectionManager connectionManager,
    required MessagingManager messagingManager,
  }) async {
    await _integration.initialize(
      p2pManager: p2pManager,
      connectionManager: connectionManager,
      messagingManager: messagingManager,
    );
    notifyListeners();
  }

  void stop() {
    _integration.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
