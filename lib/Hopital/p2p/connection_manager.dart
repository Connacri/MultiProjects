import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'p2p_manager.dart';

class ConnectionManager with ChangeNotifier {
  static final ConnectionManager _instance = ConnectionManager._internal();

  factory ConnectionManager() => _instance;

  ConnectionManager._internal();

  static const List<int> availablePorts = [45455, 45456, 45457, 45458, 45459];
  static const int connectionTimeout = 5;

  // ✅ CORRECTION: Délimiteur unique et facile à détecter
  static const String MESSAGE_DELIMITER = '\n__MSG_END__\n';

  ServerSocket? _server;
  final Map<String, Socket> _connections = {};
  final Map<String, String> _nodeIps = {};
  final Set<String> _neighbors = {};

  // ✅ Buffer amélioré avec StringBuffer
  final Map<Socket, StringBuffer> _messageBuffers = {};

  int _serverPort = 45455;

  int get serverPort => _serverPort;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  int _failedConnections = 0;
  int _successfulConnections = 0;

  int get failedConnections => _failedConnections;

  int get successfulConnections => _successfulConnections;

  Timer? _metadataBroadcastTimer;
  Map<String, dynamic>? _localMetadata;

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

        await _prepareLocalMetadata();
        await Future.delayed(Duration(milliseconds: 500));
        _broadcastNodeMetadata();
        _startPeriodicMetadataBroadcast();

        print('[ConnectionManager] ✅ Serveur P2P démarré sur le port $port');
        return;
      } catch (e) {
        print(
            '[ConnectionManager] Port $port indisponible: $e, essai du suivant...');
        continue;
      }
    }

    final error = 'Impossible de binder un port parmi: $availablePorts';
    print('[ConnectionManager] ❌ $error');
    _isRunning = false;
    notifyListeners();
    throw Exception(error);
  }

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

  Future<void> _prepareLocalMetadata() async {
    try {
      final platform = await _getCurrentPlatform();
      final branch = _getBranchForNode(P2PManager().nodeId);
      final displayName = _getDisplayName(P2PManager().nodeId);

      _localMetadata = {
        'type': 'node_metadata',
        'nodeId': P2PManager().nodeId,
        'displayName': displayName,
        'platform': platform,
        'branch': branch ?? 'Unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };

      print('[ConnectionManager] ✅ Métadonnées locales préparées:');
      print('  - Platform: $platform');
      print('  - Branch: ${branch ?? "None"}');
      print('  - Display Name: $displayName');
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur préparation métadonnées: $e');
    }
  }

  void _broadcastNodeMetadata() {
    if (_localMetadata == null) {
      print('[ConnectionManager] ⚠️ Métadonnées locales non disponibles');
      return;
    }

    try {
      for (final neighborId in _neighbors.toList()) {
        try {
          sendMessage(neighborId, _localMetadata!);
        } catch (e) {
          print(
              '[ConnectionManager] ⚠️ Erreur envoi métadonnées à $neighborId: $e');
        }
      }

      if (_neighbors.isNotEmpty) {
        print(
            '[ConnectionManager] ✅ Métadonnées broadcastées à ${_neighbors.length} voisin(s)');
      }
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur broadcast métadonnées: $e');
    }
  }

  void _startPeriodicMetadataBroadcast() {
    _metadataBroadcastTimer?.cancel();
    _metadataBroadcastTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isRunning && _neighbors.isNotEmpty) {
        _broadcastNodeMetadata();
      }
    });
    print('[ConnectionManager] ✅ Broadcast périodique de métadonnées activé');
  }

  Future<String> _getCurrentPlatform() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        return 'Web';
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          return 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          return 'iOS ${iosInfo.systemVersion}';
        } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          return 'Windows ${windowsInfo.productName}';
        } else if (Platform.isMacOS) {
          final macInfo = await deviceInfo.macOsInfo;
          return 'macOS ${macInfo.osRelease}';
        } else if (Platform.isLinux) {
          final linuxInfo = await deviceInfo.linuxInfo;
          return 'Linux ${linuxInfo.prettyName}';
        } else {
          return 'Inconnu';
        }
      }
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur récupération plateforme: $e');
      return 'Inconnu';
    }
  }

  String? _getBranchForNode(String nodeId) {
    try {
      return null;
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur récupération branche: $e');
      return null;
    }
  }

  String _getDisplayName(String nodeId) {
    try {
      final parts = nodeId.split('-');
      if (parts.length >= 3) {
        return parts.skip(2).join('-');
      }
      return nodeId;
    } catch (e) {
      return nodeId;
    }
  }

  void addNeighbor(String nodeId, String ip) {
    if (!_neighbors.contains(nodeId)) {
      _neighbors.add(nodeId);
      _nodeIps[nodeId] = ip;
      print('[ConnectionManager] ✅ Voisin ajouté: $nodeId ($ip)');
      notifyListeners();

      Future.delayed(Duration(milliseconds: 200), () {
        _broadcastNodeMetadata();
      });
    }
  }

  void removeNeighbor(String nodeId) {
    if (_neighbors.remove(nodeId)) {
      _nodeIps.remove(nodeId);
      print('[ConnectionManager] ❌ Voisin supprimé: $nodeId');
      notifyListeners();
    }
  }

  Set<String> get neighbors => _neighbors;

  Map<String, String> get nodeIps => Map.from(_nodeIps);

  void _handleConnection(Socket socket) {
    final remoteAddress = socket.remoteAddress.address;
    final remotePort = socket.remotePort;

    print(
        '[ConnectionManager] 📞 Connexion entrante de $remoteAddress:$remotePort');

    // ✅ Initialiser le buffer
    _messageBuffers[socket] = StringBuffer();

    socket.listen(
      (data) => _handleData(socket, data),
      onError: (error) => _handleError(socket, error),
      onDone: () => _handleDisconnection(socket),
      cancelOnError: true,
    );
  }

  // ✅ CORRECTION MAJEURE: Gestion robuste des messages
  void _handleData(Socket socket, List<int> data) {
    try {
      // Décoder les données reçues
      final chunk = utf8.decode(data, allowMalformed: true);

      // Ajouter au buffer
      _messageBuffers[socket]!.write(chunk);

      // Traiter tous les messages complets dans le buffer
      _processBuffer(socket);
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur traitement données: $e');
      // En cas d'erreur, nettoyer le buffer
      _messageBuffers[socket]?.clear();
    }
  }

  // ✅ NOUVEAU: Méthode dédiée au traitement du buffer
  void _processBuffer(Socket socket) {
    final buffer = _messageBuffers[socket];
    if (buffer == null) return;

    final bufferContent = buffer.toString();

    // Découper par le délimiteur
    final parts = bufferContent.split(MESSAGE_DELIMITER);

    // Le dernier élément est potentiellement incomplet, on le garde
    if (parts.isNotEmpty) {
      // Garder le dernier fragment dans le buffer
      final incompletePart = parts.last;
      buffer.clear();
      buffer.write(incompletePart);

      // Traiter tous les messages complets (sauf le dernier)
      for (int i = 0; i < parts.length - 1; i++) {
        final messagePart = parts[i].trim();
        if (messagePart.isEmpty) continue;

        _processMessage(socket, messagePart);
      }
    }
  }

  // ✅ NOUVEAU: Traitement d'un message individuel
  void _processMessage(Socket socket, String messageStr) {
    try {
      // Essayer de parser le JSON
      final message = jsonDecode(messageStr) as Map<String, dynamic>;
      final nodeId = message['nodeId'] as String?;
      final messageType = message['type'] as String?;

      if (nodeId == null) {
        print('[ConnectionManager] ⚠️ Message reçu sans nodeId');
        return;
      }

      // Enregistrer le voisin si nécessaire
      if (!_connections.containsKey(nodeId)) {
        _connections[nodeId] = socket;
        _nodeIps[nodeId] = socket.remoteAddress.address;
        _neighbors.add(nodeId);
        print(
            '[ConnectionManager] ✅ Nouveau voisin enregistré: $nodeId (${socket.remoteAddress.address})');
        notifyListeners();
      }

      print('[ConnectionManager] 📨 Message reçu de $nodeId: $messageType');

      // Émettre le message
      _messageController.add(message);
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur décodage message: $e');
      print(
          '[ConnectionManager]    Message brut (100 premiers chars): ${messageStr.substring(0, min(100, messageStr.length))}');
    }
  }

  Future<bool> connectToNode(String nodeId, String ip, int port) async {
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

      // ✅ Initialiser le buffer
      _messageBuffers[socket] = StringBuffer();

      _connections[nodeId] = socket;
      _nodeIps[nodeId] = ip;
      _neighbors.add(nodeId);
      _successfulConnections++;

      sendMessage(nodeId, {
        'type': 'hello',
        'nodeId': P2PManager().nodeId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      Future.delayed(Duration(milliseconds: 300), () {
        _broadcastNodeMetadata();
      });

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

  void sendMessage(String nodeId, Map<String, dynamic> message) {
    final socket = _connections[nodeId];
    if (socket == null) {
      print('[ConnectionManager] ⚠️ Pas de socket pour $nodeId');
      return;
    }

    try {
      final jsonData = jsonEncode(message);
      // ✅ Ajouter le délimiteur
      final dataWithDelimiter = jsonData + MESSAGE_DELIMITER;
      socket.add(utf8.encode(dataWithDelimiter));
      print(
          '[ConnectionManager] ✅ Message envoyé à $nodeId: ${message['type']}');
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur envoi à $nodeId: $e');
      _handleDisconnection(socket);
    }
  }

  void broadcastMessage(Map<String, dynamic> message) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('[ConnectionManager] 🎯 DÉBUT broadcastMessage');
    print('[ConnectionManager] Message type: ${message['type']}');
    print('[ConnectionManager] Connexions actives: ${_connections.length}');
    print('[ConnectionManager] Voisins: ${_neighbors.length}');

    final jsonData = jsonEncode(message);
    final dataWithDelimiter = jsonData + MESSAGE_DELIMITER;
    print(
        '[ConnectionManager] Message JSON: ${jsonData.substring(0, min(100, jsonData.length))}...');

    int count = 0;

    for (final nodeId in _connections.keys.toList()) {
      try {
        print('[ConnectionManager] 📤 Envoi à $nodeId...');
        _connections[nodeId]!.add(utf8.encode(dataWithDelimiter));
        count++;
        print('[ConnectionManager] ✅ Message envoyé à $nodeId');
      } catch (e) {
        print('[ConnectionManager] ❌ Erreur broadcast à $nodeId: $e');
        _handleDisconnection(_connections[nodeId]!);
      }
    }

    print('[ConnectionManager] 📡 Message broadcasté à $count pair(s)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _handleError(Socket socket, error) {
    print('[ConnectionManager] ⚠️ Erreur socket: $error');
    _handleDisconnection(socket);
  }

  void _handleDisconnection(Socket socket) {
    final nodeId = _findNodeIdBySocket(socket);
    if (nodeId != null) {
      _connections.remove(nodeId);
      _nodeIps.remove(nodeId);
      _neighbors.remove(nodeId);
      print('[ConnectionManager] 🔴 Déconnexion de $nodeId');
      notifyListeners();
    }

    // ✅ Nettoyer le buffer
    _messageBuffers.remove(socket);

    try {
      socket.destroy();
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur destruction socket: $e');
    }
  }

  void _handleServerError(error) {
    print('[ConnectionManager] ❌ Erreur serveur: $error');
    _isRunning = false;
    notifyListeners();
  }

  void _handleServerDone() {
    print('[ConnectionManager] ⚠️ Serveur fermé');
    _isRunning = false;
    notifyListeners();
  }

  String? _findNodeIdBySocket(Socket socket) {
    for (final entry in _connections.entries) {
      if (entry.value == socket) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> stop() async {
    print('[ConnectionManager] 🛑 Arrêt du serveur P2P');

    _metadataBroadcastTimer?.cancel();

    for (final socket in _connections.values) {
      try {
        socket.destroy();
      } catch (e) {
        print('[ConnectionManager] ⚠️ Erreur fermeture socket: $e');
      }
    }

    _connections.clear();
    _neighbors.clear();
    _messageBuffers.clear();

    try {
      await _server?.close();
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur fermeture serveur: $e');
    }

    _isRunning = false;
    notifyListeners();
    print('[ConnectionManager] ✅ Serveur P2P arrêté');
  }

  Future<void> restart() async {
    await stop();
    await Future.delayed(Duration(seconds: 1));
    await start();
  }

  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'serverPort': _serverPort,
      'connectedNeighbors': _neighbors.length,
      'successfulConnections': _successfulConnections,
      'failedConnections': _failedConnections,
      'neighbors': _neighbors.toList(),
      'nodeIps': _nodeIps,
      'localMetadata': _localMetadata,
    };
  }

  void dispose() {
    _metadataBroadcastTimer?.cancel();
    _messageController.close();
    stop();
  }
}
