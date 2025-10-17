import 'connection_manager.dart';
import 'crypto_manager.dart';
import 'discovery_manager.dart';
import 'p2p_managers.dart';
import 'sync_manager.dart';

class P2PIntegration {
  static bool _initialized = false;

  // ✅ Getter public pour vérifier l'état
  static bool get isInitialized => _initialized;

  static Future<void> initializeP2PSystem() async {
    if (_initialized) {
      print('⚠️ P2P déjà initialisé');
      return;
    }

    try {
      print('🔄 Initialisation P2P...');

      // Initialiser dans l'ordre avec timeouts
      await _initWithTimeout(
        'P2PManager',
        () => P2PManager().initialize(),
      );

      await _initWithTimeout(
        'CryptoManager',
        () => CryptoManager().initialize(),
      );

      await _initWithTimeout(
        'ConnectionManager',
        () => ConnectionManager().start(),
      );

      await _initWithTimeout(
        'SyncManager',
        () => SyncManager().initialize(),
      );

      _initialized = true;
      print('✅ Système P2P complètement initialisé');
    } catch (e) {
      print('❌ Erreur critique P2P: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// ⏱️ Exécute une fonction avec timeout
  static Future<void> _initWithTimeout(
    String name,
    Future<void> Function() fn,
  ) async {
    try {
      await fn().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('$name timeout après 5s');
        },
      );
      print('✅ $name initialisé');
    } catch (e) {
      print('❌ Erreur $name: $e');
      rethrow;
    }
  }

  static void startDiscovery() {
    if (!_initialized) {
      print('⚠️ P2P non initialisé, découverte ignorée');
      return;
    }

    try {
      DiscoveryManager().start();
      print('📡 Découverte réseau démarrée');
    } catch (e) {
      print('⚠️ Erreur découverte: $e');
    }
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
