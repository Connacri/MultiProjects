import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'p2p_manager_fixed.dart';

class ConnectionManager with ChangeNotifier {
  static final ConnectionManager _instance = ConnectionManager._internal();

  factory ConnectionManager() => _instance;

  ConnectionManager._internal();

  // Configuration avec fallback
  static const List<int> availablePorts = [45455, 45456, 45457, 45458, 45459];
  static const int connectionTimeout = 5;

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

  // Statistiques
  int _failedConnections = 0;
  int _successfulConnections = 0;

  int get failedConnections => _failedConnections;

  int get successfulConnections => _successfulConnections;

  /// Démarre le serveur avec retry automatique sur différents ports
  Future<void> start() async {
    if (_isRunning) {
      print('[ConnectionManager] Serveur déjà en cours d\'exécution');
      return;
    }

    print('[ConnectionManager] Démarrage du serveur P2P...');

    for (final port in availablePorts) {
      try {
        await _tryBindPort(port);
        _serverPort = port;
        _isRunning = true;
        notifyListeners();
        print('[ConnectionManager] ✅ Serveur P2P démarré sur le port $port');
        return;
      } catch (e) {
        print(
            '[ConnectionManager] Port $port indisponible: $e, essai du suivant...');
        continue;
      }
    }

    // Tous les ports ont échoué
    final error = 'Impossible de binder un port parmi: $availablePorts';
    print('[ConnectionManager] ❌ $error');
    _isRunning = false;
    notifyListeners();
    throw Exception(error);
  }

  /// Essaie de binder un port spécifique
  Future<void> _tryBindPort(int port) async {
    try {
      final server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        backlog: 100,
        shared: true,
      ).timeout(
        Duration(seconds: connectionTimeout),
        onTimeout: () {
          throw TimeoutException('Timeout bind port $port');
        },
      );

      _server = server;
      _server!.listen(
        _handleConnection,
        onError: (error) => _handleServerError(error),
        onDone: () => _handleServerDone(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Gère les nouvelles connexions entrantes
  void _handleConnection(Socket socket) {
    final remoteAddress = socket.remoteAddress.address;
    final remotePort = socket.remotePort;

    print(
        '[ConnectionManager] 🔗 Connexion entrante de $remoteAddress:$remotePort');

    socket.listen(
      (data) => _handleData(socket, data),
      onError: (error) => _handleError(socket, error),
      onDone: () => _handleDisconnection(socket),
      cancelOnError: true,
    );
  }

  /// Traite les données reçues
  void _handleData(Socket socket, List<int> data) {
    try {
      final message = jsonDecode(utf8.decode(data));
      final nodeId = message['nodeId'] as String?;

      if (nodeId == null) {
        print('[ConnectionManager] ⚠️ Message reçu sans nodeId');
        return;
      }

      // ✅ CORRECTION: Enregistrer la connexion dès le premier message
      if (!_connections.containsKey(nodeId)) {
        _connections[nodeId] = socket;
        _nodeIps[nodeId] = socket.remoteAddress.address;
        _neighbors.add(nodeId);
        print(
            '[ConnectionManager] ✅ Nouveau voisin enregistré: $nodeId (${socket.remoteAddress.address})');
        notifyListeners();
      }

      print(
          '[ConnectionManager] 📩 Message reçu de $nodeId: ${message['type']}');
      _messageController.add(message);
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur décodage message: $e');
    }
  }

  /// Se connecte à un nœud distant
  Future<bool> connectToNode(String nodeId, String ip, int port) async {
    // Ne pas se connecter à soi-même
    if (nodeId == P2PManager().nodeId) {
      print('[ConnectionManager] 🚫 Impossible de se connecter à soi-même');
      return false;
    }

    if (_connections.containsKey(nodeId)) {
      print('[ConnectionManager] ℹ️ Déjà connecté à $nodeId');
      return true;
    }

    try {
      print('[ConnectionManager] 🔄 Tentative connexion à $nodeId ($ip:$port)');

      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(seconds: connectionTimeout),
      );

      _connections[nodeId] = socket;
      _nodeIps[nodeId] = ip;
      _neighbors.add(nodeId);
      _successfulConnections++;

      // ✅ CORRECTION: Envoyer un message de présentation avec le vrai nodeId
      sendMessage(nodeId, {
        'type': 'hello',
        'nodeId': P2PManager().nodeId, // ✅ CORRECTION: Utiliser le vrai nodeId
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Écouter les messages
      socket.listen(
        (data) => _handleData(socket, data),
        onError: (error) => _handleError(socket, error),
        onDone: () => _handleDisconnection(socket),
        cancelOnError: true,
      );

      print('[ConnectionManager] ✅ Connecté à $nodeId ($ip:$port)');
      notifyListeners();
      return true;
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur connexion à $nodeId: $e');
      _failedConnections++;
      _neighbors.remove(nodeId);
      notifyListeners();
      return false;
    }
  }

  /// Envoie un message à un nœud spécifique
  void sendMessage(String nodeId, Map<String, dynamic> message) {
    final socket = _connections[nodeId];
    if (socket == null) {
      print('[ConnectionManager] ⚠️ Pas de socket pour $nodeId');
      return;
    }

    try {
      final jsonData = jsonEncode(message);
      socket.add(utf8.encode(jsonData));
      print(
          '[ConnectionManager] ✅ Message envoyé à $nodeId: ${message['type']}');
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur envoi à $nodeId: $e');
      _handleDisconnection(socket);
    }
  }

  /// Diffuse un message à tous les voisins
  void broadcastMessage(Map<String, dynamic> message) {
    final jsonData = jsonEncode(message);
    int count = 0;

    for (final nodeId in _connections.keys.toList()) {
      try {
        _connections[nodeId]!.add(utf8.encode(jsonData));
        count++;
        print('[ConnectionManager] ✅ Message envoyé à $nodeId');
      } catch (e) {
        print('[ConnectionManager] ❌ Erreur broadcast à $nodeId: $e');
        _handleDisconnection(_connections[nodeId]!);
      }
    }

    print('[ConnectionManager] 📡 Message broadcasté à $count pair(s)');
  }

  /// Gère les erreurs socket
  void _handleError(Socket socket, error) {
    print('[ConnectionManager] ⚠️ Erreur socket: $error');
    _handleDisconnection(socket);
  }

  /// Gère la déconnexion d'un socket
  void _handleDisconnection(Socket socket) {
    final nodeId = _findNodeIdBySocket(socket);
    if (nodeId != null) {
      _connections.remove(nodeId);
      _nodeIps.remove(nodeId);
      _neighbors.remove(nodeId);
      print('[ConnectionManager] 🔌 Déconnexion de $nodeId');
      notifyListeners();
    }

    try {
      socket.destroy();
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur destruction socket: $e');
    }
  }

  /// Gère les erreurs du serveur
  void _handleServerError(error) {
    print('[ConnectionManager] ❌ Erreur serveur: $error');
    _isRunning = false;
    notifyListeners();
  }

  /// Gère la fermeture du serveur
  void _handleServerDone() {
    print('[ConnectionManager] ⚠️ Serveur fermé');
    _isRunning = false;
    notifyListeners();
  }

  /// Trouve le nodeId correspondant à un socket
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

  /// Arrête le serveur
  Future<void> stop() async {
    print('[ConnectionManager] 🛑 Arrêt du serveur P2P');

    for (final socket in _connections.values) {
      try {
        socket.destroy();
      } catch (e) {
        print('[ConnectionManager] ⚠️ Erreur fermeture socket: $e');
      }
    }

    _connections.clear();
    _neighbors.clear();

    try {
      await _server?.close();
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur fermeture serveur: $e');
    }

    _isRunning = false;
    notifyListeners();
    print('[ConnectionManager] ✅ Serveur P2P arrêté');
  }

  /// Redémarre le serveur
  Future<void> restart() async {
    await stop();
    await Future.delayed(Duration(seconds: 1));
    await start();
  }

  /// Récupère les statistiques
  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'serverPort': _serverPort,
      'connectedNeighbors': _neighbors.length,
      'successfulConnections': _successfulConnections,
      'failedConnections': _failedConnections,
      'neighbors': _neighbors.toList(),
      'nodeIps': _nodeIps,
    };
  }

  void dispose() {
    stop();
  }
}
