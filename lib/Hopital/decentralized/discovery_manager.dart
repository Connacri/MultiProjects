import 'dart:async';

import 'package:flutter/foundation.dart';

/// Simule la découverte réseau (multicast, UDP ou LAN)
class DiscoveryManager with ChangeNotifier {
  static final DiscoveryManager _instance = DiscoveryManager._internal();
  factory DiscoveryManager() => _instance;
  DiscoveryManager._internal();

  bool _running = false;
  bool get isRunning => _running;

  Future<void> initialize() async {
    print('🔍 DiscoveryManager initialisé');
  }

  void start() {
    if (_running) return;
    _running = true;
    notifyListeners();

    print('📡 Découverte réseau démarrée (multicast simulé)...');

    // Exemple : ping toutes les 5 secondes
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_running) timer.cancel();
      print('🛰️ Recherche de pairs...');
    });
  }

  void stop() {
    _running = false;
    notifyListeners();
    print('🛑 Découverte réseau arrêtée.');
  }
}
