import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'p2p_managers.dart';

class ConnectionManager with ChangeNotifier {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  ServerSocket? _server;
  final Map<String, Socket> _connections = {};
  final Map<String, String> _nodeIps = {};
  final Set<String> _neighbors = {};

  int _serverPort = 45455;
  int get serverPort => _serverPort;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _serverPort);
      _isRunning = true;

      _server!.listen(_handleConnection);
      print('🎯 Serveur P2P démarré sur le port $_serverPort');

      notifyListeners();
    } catch (e) {
      print('❌ Erreur démarrage serveur: $e');
      _isRunning = false;
    }
  }

  void _handleConnection(Socket socket) {
    final remoteAddress = socket.remoteAddress.address;
    print('🔗 Connexion entrante de $remoteAddress');

    socket.listen(
      (data) => _handleData(socket, data),
      onError: (error) => _handleError(socket, error),
      onDone: () => _handleDisconnection(socket),
    );
  }

  void _handleData(Socket socket, List<int> data) {
    try {
      final message = jsonDecode(utf8.decode(data));
      final nodeId = message['nodeId'];

      if (nodeId != null) {
        _connections[nodeId] = socket;
        _nodeIps[nodeId] = socket.remoteAddress.address;
        _neighbors.add(nodeId);

        print('📨 Message de $nodeId: ${message['type']}');
        _messageController.add(message);
      }
    } catch (e) {
      print('❌ Erreur décodage message: $e');
    }
  }

  Future<bool> connectToNode(String nodeId, String ip, int port) async {
    try {
      if (_connections.containsKey(nodeId)) {
        print('⚠️ Déjà connecté à $nodeId');
        return true;
      }

      final socket =
          await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      _connections[nodeId] = socket;
      _nodeIps[nodeId] = ip;
      _neighbors.add(nodeId);

      // Envoyer hello
      sendMessage(nodeId, {
        'type': 'hello',
        'nodeId': P2PManager().nodeId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      socket.listen(
        (data) => _handleData(socket, data),
        onError: (error) => _handleError(socket, error),
        onDone: () => _handleDisconnection(socket),
      );

      print('✅ Connecté à $nodeId ($ip:$port)');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur connexion à $nodeId: $e');
      _neighbors.remove(nodeId);
      return false;
    }
  }

  void sendMessage(String nodeId, Map<String, dynamic> message) {
    final socket = _connections[nodeId];
    if (socket != null) {
      try {
        final jsonData = jsonEncode(message);
        socket.add(utf8.encode(jsonData));
      } catch (e) {
        print('❌ Erreur envoi à $nodeId: $e');
        _handleDisconnection(socket);
      }
    }
  }

  void broadcastMessage(Map<String, dynamic> message) {
    final jsonData = jsonEncode(message);
    for (final nodeId in _connections.keys) {
      try {
        _connections[nodeId]!.add(utf8.encode(jsonData));
      } catch (e) {
        print('❌ Erreur broadcast à $nodeId: $e');
        _handleDisconnection(_connections[nodeId]!);
      }
    }
  }

  void _handleError(Socket socket, error) {
    print('❌ Erreur socket: $error');
    _handleDisconnection(socket);
  }

  void _handleDisconnection(Socket socket) {
    final nodeId = _findNodeIdBySocket(socket);
    if (nodeId != null) {
      _connections.remove(nodeId);
      _nodeIps.remove(nodeId);
      _neighbors.remove(nodeId);
      print('🔌 Déconnexion de $nodeId');
      notifyListeners();
    }
    socket.destroy();
  }

  String? _findNodeIdBySocket(Socket socket) {
    for (final entry in _connections.entries) {
      if (entry.value == socket) {
        return entry.key;
      }
    }
    return null;
  }

  Set<String> get neighbors => _neighbors;
  Map<String, String> get nodeIps => Map.from(_nodeIps);

  Future<void> stop() async {
    for (final socket in _connections.values) {
      socket.destroy();
    }
    _connections.clear();
    _neighbors.clear();
    await _server?.close();
    _isRunning = false;
    notifyListeners();
  }
}
