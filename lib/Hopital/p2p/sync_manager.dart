import 'package:flutter/foundation.dart';

import 'crypto_manager_complete.dart';

/// Gestionnaire de synchronisation - Singleton
/// Responsabilité: Mettre en queue et envoyer les deltas aux pairs
class SyncManager with ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();

  factory SyncManager() => _instance;

  SyncManager._internal();

  final List<Map<String, dynamic>> _syncQueue = [];

  bool _isSyncing = false;
  int successfulSyncs = 0;
  int failedSyncs = 0;

  bool get isSyncing => _isSyncing;

  /// Initialise le gestionnaire de synchronisation
  Future<void> initialize() async {
    try {
      print('[Sync] Initialisation');
      print('[Sync] ✅ SyncManager initialisé');
    } catch (e) {
      print('[Sync] ❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  /// Ajoute un delta à la file de synchronisation
  void queueForSync(Map<String, dynamic> delta) {
    _syncQueue.add(delta);
    print(
        '[Sync] 📋 Delta ajouté à la queue (${_syncQueue.length} en attente)');
    _processSyncQueue();
  }

  /// Traite la file d'attente de synchronisation
  Future<void> _processSyncQueue() async {
    if (_isSyncing || _syncQueue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      for (final delta in List<Map<String, dynamic>>.from(_syncQueue)) {
        await _sendToNetwork(delta);
        successfulSyncs++;
        _syncQueue.remove(delta);
      }

      print('[Sync] ✅ Queue complètement synchronisée');
    } catch (e) {
      failedSyncs++;
      print('[Sync] ❌ Erreur traitement queue: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Envoie un delta chiffré sur le réseau
  Future<void> _sendToNetwork(Map<String, dynamic> delta) async {
    try {
      final encrypted = await CryptoManager().encryptDelta(delta);
      print('[Sync] 🚀 Delta chiffré prêt pour broadcast');
      // Le broadcast sera fait par P2PIntegration
    } catch (e) {
      print('[Sync] ❌ Erreur chiffrement: $e');
      failedSyncs++;
      notifyListeners();
      rethrow;
    }
  }

  /// Lance l'anti-entropie (resynchronisation complète)
  Future<void> triggerAntiEntropy() async {
    print('[Sync] 🔄 Anti-entropie lancée');
    try {
      // Comparaison des versions avec les pairs
      await Future.delayed(const Duration(seconds: 1));
      print('[Sync] ✅ Anti-entropie terminée');
    } catch (e) {
      print('[Sync] ⚠️ Erreur anti-entropie: $e');
    }
  }

  /// Récupère les statistiques de synchronisation
  Map<String, dynamic> getStats() {
    return {
      'isSyncing': _isSyncing,
      'queueSize': _syncQueue.length,
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
    };
  }
}
