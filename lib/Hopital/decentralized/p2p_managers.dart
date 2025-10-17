import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'crypto_manager.dart';
import 'objectbox_p2p.dart';

/// 🎯 MANAGER PRINCIPAL DU RÉSEAU P2P
class P2PManager with ChangeNotifier {
  static final P2PManager _instance = P2PManager._internal();

  factory P2PManager() => _instance;

  P2PManager._internal();

  String _nodeId = '';

  String get nodeId => _nodeId;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  final Map<String, Socket> _connections = {};

  Future<void> initialize() async {
    _nodeId = _generateNodeId();
    _isConnected = true;
    notifyListeners();
    print('🟢 P2PManager initialisé ($_nodeId)');
  }

  String _generateNodeId() {
    return 'node-${DateTime.now().millisecondsSinceEpoch}-${Platform.localHostname}';
  }

  /// 📤 Diffuse un delta chiffré à tous les pairs connus
  Future<void> broadcastDelta(Map<String, dynamic> encryptedDelta) async {
    if (_connections.isEmpty) {
      print('⚠️ Aucun pair connecté, diffusion ignorée');
      return;
    }

    for (final entry in _connections.entries) {
      final nodeId = entry.key;
      await sendMessage(nodeId, {
        'type': 'delta',
        'payload': encryptedDelta,
        'origin': _nodeId,
      });
    }

    print('📡 Delta diffusé à ${_connections.length} pairs');
  }

  /// 📩 Envoie un message JSON à un pair spécifique
  Future<void> sendMessage(String nodeId, Map<String, dynamic> message) async {
    final socket = _connections[nodeId];
    if (socket == null) {
      print('⚠️ Aucun socket pour $nodeId');
      return;
    }

    final encoded = utf8.encode(jsonEncode(message));
    socket.add(encoded);
    await socket.flush();
  }

  /// 🛰️ Gère les connexions entrantes depuis ConnectionManager
  void registerConnection(String nodeId, Socket socket) {
    _connections[nodeId] = socket;
    _isConnected = true;
    notifyListeners();
    print('🔗 Connecté à $nodeId');
  }

  /// 🔄 Traite les messages entrants
  Future<void> handleIncomingData(Socket socket, List<int> rawData) async {
    try {
      final message = jsonDecode(utf8.decode(rawData));
      final type = message['type'];

      if (type == 'delta') {
        final encrypted = Map<String, dynamic>.from(message['payload']);
        final delta = await CryptoManager().decryptDelta(encrypted);

        print('📥 Delta reçu et déchiffré : ${delta['entity']}');

        // Application locale du delta
        final ob = await ObjectBoxP2P.create();
        ob.applyDelta(delta);
      }
    } catch (e) {
      print('❌ Erreur traitement message entrant: $e');
    }
  }
}
