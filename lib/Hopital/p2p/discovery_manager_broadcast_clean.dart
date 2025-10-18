import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Gestionnaire de découverte UDP Broadcast - Singleton
/// Responsabilité: Découvrir les nœuds sur le réseau local via UDP
/// CETTE VERSION EST LA SEULE À UTILISER - PAS DE mDNS
class DiscoveryManager with ChangeNotifier {
  static final DiscoveryManager _instance = DiscoveryManager._internal();

  factory DiscoveryManager() => _instance;

  DiscoveryManager._internal();

  // Configuration des ports et broadcast
  static const int discoveryPort = 45454;
  static const String broadcastAddress = '255.255.255.255';

  // État
  bool _running = false;
  bool get isRunning => _running;

  final Set<String> _discoveredNodes = {};
  Set<String> get discoveredNodes => Set.from(_discoveredNodes);

  // Sockets
  RawDatagramSocket? _announcementSocket;
  RawDatagramSocket? _discoverySocket;
  Timer? _announcementTimer;
  Timer? _cleanupTimer;
  StreamSubscription? _discoverySubscription;

  // Tracking des nœuds avec timestamps pour expiration
  final Map<String, int> _nodeTimestamps = {};
  static const int nodeTimeoutDuration = 30000; // 30 secondes

  // Suivi des changements de connectivité
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;

  String? _lastKnownIP;
  List<NetworkInterface>? _networkInterfaces;

  /// Initialise le gestionnaire
  Future<void> initialize() async {
    print('[Discovery] Initialisation');
    try {
      await _detectNetworkInterfaces();
      await _setupConnectivityListener();
      print('[Discovery] ✅ Initialisation réussie');
    } catch (e) {
      print('[Discovery] ❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  /// Détecte les interfaces réseau IPv4 disponibles
  Future<void> _detectNetworkInterfaces() async {
    try {
      _networkInterfaces = await NetworkInterface.list();
      for (var i in _networkInterfaces!) {
        print('[Discovery] Interface réseau: ${i.name}');
        for (var addr in i.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.')) {
            _lastKnownIP = addr.address;
            print('[Discovery]   └─ IPv4: ${addr.address}');
          }
        }
      }
    } catch (e) {
      print('[Discovery] ⚠️ Erreur détection interfaces: $e');
    }
  }

  /// Écoute les changements de connectivité réseau
  Future<void> _setupConnectivityListener() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      print('[Discovery] Changement de connectivité: $result');

      if (result == ConnectivityResult.none) {
        if (_running) {
          print('[Discovery] ⚠️ Réseau perdu');
          stop();
        }
      } else {
        _detectNetworkInterfaces();
        if (_running) {
          print('[Discovery] ✅ Réseau rétabli - redémarrage sockets');
          _restartSockets();
        }
      }
    });
  }

  /// Démarre la découverte: crée les sockets et lance les annonces
  Future<void> start(String nodeId, int p2pPort) async {
    if (_running) {
      print('[Discovery] ⚠️ Déjà en cours d\'exécution');
      return;
    }

    _running = true;

    try {
      // Vérifier la connectivité
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw Exception('Pas de connexion réseau disponible');
      }

      await _detectNetworkInterfaces();

      // Créer les sockets
      await _createDiscoverySocket();
      await _createAnnouncementSocket();

      // Lancer l'écoute et les annonces
      _startListening();
      _startAnnouncements(nodeId, p2pPort);
      _startCleanupTimer();

      print(
          '[Discovery] ✅ Découverte démarrée (port: $discoveryPort, IP: $_lastKnownIP)');
      notifyListeners();
    } catch (e) {
      print('[Discovery] ❌ Erreur démarrage: $e');
      _running = false;
      stop();
      rethrow;
    }
  }

  /// Crée le socket pour écouter les annonces UDP
  Future<void> _createDiscoverySocket() async {
    try {
      _discoverySocket?.close();

      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );

      print('[Discovery] Socket d\'écoute créé sur le port $discoveryPort');
    } catch (e) {
      print('[Discovery] ❌ Erreur création socket d\'écoute: $e');
      rethrow;
    }
  }

  /// Crée le socket pour envoyer les annonces UDP
  Future<void> _createAnnouncementSocket() async {
    try {
      _announcementSocket?.close();

      _announcementSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Port automatique
        reuseAddress: true,
      );

      _announcementSocket!.broadcastEnabled = true;

      print('[Discovery] Socket d\'annonce créé');
    } catch (e) {
      print('[Discovery] ❌ Erreur création socket d\'annonce: $e');
      rethrow;
    }
  }

  /// Lance l'écoute des datagrams entrants
  void _startListening() {
    _discoverySubscription?.cancel();

    _discoverySubscription = _discoverySocket!.asBroadcastStream().listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read && _running) {
          try {
            final datagram = _discoverySocket!.receive();
            if (datagram != null) {
              _handleIncomingAnnouncement(datagram);
            }
          } catch (e) {
            print('[Discovery] ⚠️ Erreur lecture datagram: $e');
          }
        }
      },
      onError: (error) {
        print('[Discovery] ❌ Erreur socket écoute: $error');
        if (_running) {
          _restartSockets();
        }
      },
      onDone: () {
        print('[Discovery] Socket d\'écoute fermé');
        if (_running) {
          _restartSockets();
        }
      },
    );
  }

  /// Redémarre les sockets en cas d'erreur
  Future<void> _restartSockets() async {
    print('[Discovery] Redémarrage des sockets');
    try {
      _discoverySubscription?.cancel();
      _discoverySocket?.close();
      _announcementSocket?.close();

      await _createDiscoverySocket();
      await _createAnnouncementSocket();
      _startListening();
    } catch (e) {
      print('[Discovery] ❌ Erreur redémarrage sockets: $e');
    }
  }

  /// Lance les annonces périodiques (toutes les 5 secondes)
  void _startAnnouncements(String nodeId, int p2pPort) {
    _announcementTimer?.cancel();

    // Annonce immédiate
    _announceNode(nodeId, p2pPort);

    // Puis toutes les 5 secondes
    _announcementTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _announceNode(nodeId, p2pPort);
    });
  }

  /// Envoie une annonce UDP avec l'identité du nœud
  void _announceNode(String nodeId, int p2pPort) {
    if (_announcementSocket == null || !_running) return;

    try {
      final announcement = {
        'nodeId': nodeId,
        'port': p2pPort,
        'ip': _lastKnownIP ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };

      final message = jsonEncode(announcement);
      final data = utf8.encode(message);

      _announcementSocket!.send(
        data,
        InternetAddress(broadcastAddress),
        discoveryPort,
      );

      print('[Discovery] 📢 Annonce envoyée: $nodeId:$p2pPort');
    } catch (e) {
      print('[Discovery] ❌ Erreur envoi annonce: $e');
    }
  }

  /// Traite les annonces reçues
  void _handleIncomingAnnouncement(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      final announcement = jsonDecode(message) as Map<String, dynamic>;

      final remoteNodeId = announcement['nodeId'] as String?;
      final remotePort = announcement['port'] as int?;
      final remoteIp =
          announcement['ip'] as String? ?? datagram.address.address;

      if (remoteNodeId == null || remotePort == null) {
        return;
      }

      final nodeKey = '$remoteNodeId@$remoteIp:$remotePort';

      // Mettre à jour le timestamp
      _nodeTimestamps[nodeKey] = DateTime.now().millisecondsSinceEpoch;

      // Si nouveau nœud, l'ajouter
      if (!_discoveredNodes.contains(nodeKey)) {
        _discoveredNodes.add(nodeKey);
        print('[Discovery] ✅ Nœud découvert: $remoteNodeId ($remoteIp:$remotePort)');
        notifyListeners();
      }
    } catch (e) {
      print('[Discovery] ⚠️ Erreur traitement annonce: $e');
    }
  }

  /// Lance le nettoyage des nœuds expirés (toutes les 5 secondes)
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();

    _cleanupTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _cleanupExpiredNodes();
    });
  }

  /// Supprime les nœuds qui n'ont pas communiqué depuis 30 secondes
  void _cleanupExpiredNodes() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final toRemove = <String>[];

    _nodeTimestamps.forEach((nodeKey, timestamp) {
      if (now - timestamp > nodeTimeoutDuration) {
        toRemove.add(nodeKey);
      }
    });

    for (final nodeKey in toRemove) {
      _discoveredNodes.remove(nodeKey);
      _nodeTimestamps.remove(nodeKey);
      print('[Discovery] ⏰ Nœud expiré: $nodeKey');
    }

    if (toRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Récupère les informations des nœuds découverts
  List<Map<String, dynamic>> getDiscoveredNodesInfo() {
    return _discoveredNodes
        .map((nodeKey) {
          final parts = nodeKey.split('@');
          if (parts.length != 2) return null;

          final nodeId = parts[0];
          final addressParts = parts[1].split(':');
          if (addressParts.length != 2) return null;

          final ip = addressParts[0];
          final port = int.tryParse(addressParts[1]) ?? discoveryPort;

          return {
            'nodeId': nodeId,
            'ip': ip,
            'port': port,
            'key': nodeKey,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Arrête la découverte (retourne void - pas de Future)
  void stop() {
    _running = false;
    _announcementTimer?.cancel();
    _cleanupTimer?.cancel();
    _discoverySubscription?.cancel();
    _discoverySocket?.close();
    _announcementSocket?.close();

    _discoveredNodes.clear();
    _nodeTimestamps.clear();

    print('[Discovery] 🛑 Découverte arrêtée');
    notifyListeners();
  }

  /// Nettoyage complet (appelle stop())
  void dispose() {
    stop();
    _connectivitySubscription?.cancel();
    print('[Discovery] 🗑️ Ressources libérées');
  }
}