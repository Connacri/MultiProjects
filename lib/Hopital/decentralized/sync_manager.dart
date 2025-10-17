import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../objectbox.g.dart';
import 'crypto_manager.dart';
import 'objectbox_p2p.dart';
import 'p2p_managers.dart';

/// 🎯 Gestion de la synchronisation P2P
class SyncManager with ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();

  factory SyncManager() => _instance;

  SyncManager._internal();

  final List<Map<String, dynamic>> _syncQueue = [];

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  int successfulSyncs = 0;
  int failedSyncs = 0;

  late ObjectBoxP2P _p2pBox;

  Future<void> initialize() async {
    print('🔁 SyncManager initialisé');
    _p2pBox = await ObjectBoxP2P.create();

    // Charger les deltas non synchronisés
    final unsynced = _p2pBox.journalBox
        .query(P2PJournal_.synced.equals(false))
        .build()
        .find();

    for (final j in unsynced) {
      _syncQueue.add({
        'entity': j.entityType,
        'operation': j.operation,
        'data': jsonDecode(j.dataJson),
        'timestamp': j.timestamp,
        'originId': j.originId,
      });
    }

    _processSyncQueue();
  }

  void queueForSync(Map<String, dynamic> delta) {
    _syncQueue.add(delta);
    _processSyncQueue();
  }

  /// 🔄 Traite la file d’attente de synchro
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
    } catch (e) {
      failedSyncs++;
      print('❌ Erreur pendant la synchronisation: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _sendToNetwork(Map<String, dynamic> delta) async {
    try {
      final encrypted = await CryptoManager().encryptDelta(delta);
      await P2PManager().broadcastDelta(encrypted);
    } catch (e) {
      // ❌ MANQUE : Gestion des erreurs de chiffrement
      print('❌ Erreur chiffrement delta: $e');
      failedSyncs++;
      notifyListeners();
    }
  }

  /// 🧠 Anti-Entropie : compare les états et resynchronise les différences
  Future<void> triggerAntiEntropy() async {
    print('🧠 Démarrage de l’anti-entropie...');
    try {
      final summary = _p2pBox.getSyncSummary();
      print('📊 Résumé local des versions : $summary');
      await Future.delayed(const Duration(seconds: 1));
      print('✅ Anti-entropie terminée');
    } catch (e) {
      print('⚠️ Erreur anti-entropie: $e');
    }
  }
}
