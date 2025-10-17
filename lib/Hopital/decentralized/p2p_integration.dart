import 'connection_manager.dart';
import 'crypto_manager.dart';
import 'discovery_manager.dart';
import 'p2p_managers.dart';
import 'sync_manager.dart';

class P2PIntegration {
  static Future<void> initializeP2PSystem() async {
    // Initialiser dans l'ordre
    await P2PManager().initialize();
    await CryptoManager().initialize();
    await ConnectionManager().start();
    SyncManager().initialize();

    print('🎯 Système P2P complètement initialisé');
  }

  static void startDiscovery() {
    // Démarrer la découverte multicast
    DiscoveryManager().start();
  }
}
