import 'dart:io';
import 'package:flutter/foundation.dart';

/// Gestionnaire P2P principal - Singleton
/// Responsabilité: Générer et gérer l'identité du noeud
class P2PManager with ChangeNotifier {
  static final P2PManager _instance = P2PManager._internal();

  factory P2PManager() => _instance;

  P2PManager._internal();

  String _nodeId = '';
  bool _isConnected = false;

  String get nodeId => _nodeId;
  bool get isConnected => _isConnected;

  /// Initialise le gestionnaire P2P
  /// Génère un identifiant unique pour ce noeud
  Future<void> initialize() async {
    try {
      _nodeId = _generateNodeId();
      _isConnected = true;
      notifyListeners();
      print('[P2PManager] ✅ P2PManager initialisé ($_nodeId)');
    } catch (e) {
      print('[P2PManager] ❌ Erreur initialisation: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Génère un identifiant unique basé sur le timestamp et le hostname
  String _generateNodeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hostname = Platform.localHostname;
    return 'node-$timestamp-$hostname';
  }

  /// Marque le noeud comme déconnecté
  void markDisconnected() {
    _isConnected = false;
    notifyListeners();
  }

  /// Marque le noeud comme reconnecté
  void markConnected() {
    _isConnected = true;
    notifyListeners();
  }
}