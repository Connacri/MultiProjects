import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  // ✅ NOUVEAU: Timer pour broadcast périodique des métadonnées
  Timer? _metadataBroadcastTimer;

  // ✅ NOUVEAU: Cache des métadonnées du nœud local
  Map<String, dynamic>? _localMetadata;

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

        // ✅ NOUVEAU: Broadcaster les métadonnées au démarrage
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

  // ============================================================================
  // ✅ BROADCAST MÉTADONNÉES - NOUVEAU
  // ============================================================================

  /// Prépare et cache les métadonnées du nœud local
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
        'timestamp': DateTime
            .now()
            .millisecondsSinceEpoch,
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

  /// Envoie les métadonnées du nœud courant à tous les voisins
  void _broadcastNodeMetadata() {
    if (_localMetadata == null) {
      print('[ConnectionManager] ⚠️  Métadonnées locales non disponibles');
      return;
    }

    try {
      // Broadcaster à tous les voisins découverts
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
            '[ConnectionManager] ✅ Métadonnées broadcastées à ${_neighbors
                .length} voisin(s)');
      }
    } catch (e) {
      print('[ConnectionManager] ❌ Erreur broadcast métadonnées: $e');
    }
  }

  /// Republisher les métadonnées périodiquement (toutes les 30 secondes)
  void _startPeriodicMetadataBroadcast() {
    _metadataBroadcastTimer?.cancel();

    _metadataBroadcastTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isRunning && _neighbors.isNotEmpty) {
        _broadcastNodeMetadata();
      }
    });

    print('[ConnectionManager] ✅ Broadcast périodique de métadonnées activé');
  }

  // ============================================================================
  // RÉCUPÉRATION DES INFORMATIONS DU NŒUD
  // ============================================================================

  /// Récupère la plateforme de l'appareil courant
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

  /// Récupère la branche associée au nœud
  String? _getBranchForNode(String nodeId) {
    try {
      // À adapter selon votre logique métier
      // Exemple: récupérer depuis ObjectBox si vous avez une table Staff/Branch
      // final staffBox = objectBoxGlobal.store.box<Staff>();
      // final staff = staffBox.get(int.tryParse(nodeId) ?? 0);
      // return staff?.branch.target?.branchNom;

      // Pour l'instant, retourner null
      return null;
    } catch (e) {
      print('[ConnectionManager] ⚠️ Erreur récupération branche: $e');
      return null;
    }
  }

  /// Extrait le nom d'affichage du nodeId
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

  // ============================================================================
  // GESTION DES VOISINS
  // ============================================================================

  /// Ajoute un voisin et broadcaster les métadonnées
  void addNeighbor(String nodeId, String ip) {
    if (!_neighbors.contains(nodeId)) {
      _neighbors.add(nodeId);
      _nodeIps[nodeId] = ip;
      print('[ConnectionManager] ✅ Voisin ajouté: $nodeId ($ip)');
      notifyListeners();

      // ✅ NOUVEAU: Broadcaster les métadonnées quand un nouveau voisin se connecte
      Future.delayed(Duration(milliseconds: 200), () {
        _broadcastNodeMetadata();
      });
    }
  }

  /// Supprime un voisin
  void removeNeighbor(String nodeId) {
    if (_neighbors.remove(nodeId)) {
      _nodeIps.remove(nodeId);
      print('[ConnectionManager] ❌ Voisin supprimé: $nodeId');
      notifyListeners();
    }
  }

  Set<String> get neighbors => _neighbors;

  Map<String, String> get nodeIps => Map.from(_nodeIps);

  // ============================================================================
  // GESTION DES CONNEXIONS
  // ============================================================================

  /// Gère les nouvelles connexions entrantes
  void _handleConnection(Socket socket) {
    final remoteAddress = socket.remoteAddress.address;
    final remotePort = socket.remotePort;

    print(
        '[ConnectionManager] 📞 Connexion entrante de $remoteAddress:$remotePort');

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
            '[ConnectionManager] ✅ Nouveau voisin enregistré: $nodeId (${socket
                .remoteAddress.address})');
        notifyListeners();
      }

      print(
          '[ConnectionManager] 📨 Message reçu de $nodeId: ${message['type']}');
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
        'nodeId': P2PManager().nodeId,
        'timestamp': DateTime
            .now()
            .millisecondsSinceEpoch,
      });

      // ✅ NOUVEAU: Broadcaster les métadonnées après connexion
      Future.delayed(Duration(milliseconds: 300), () {
        _broadcastNodeMetadata();
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
      print('[ConnectionManager] 📴 Déconnexion de $nodeId');
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

  /// Arrête le serveur
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
      'localMetadata': _localMetadata,
    };
  }

  void dispose() {
    _metadataBroadcastTimer?.cancel();
    _messageController.close();
    stop();
  }
}