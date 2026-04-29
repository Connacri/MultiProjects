import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Gestionnaire de découverte UDP Broadcast fonctionnel sur mobile et desktop
class DiscoveryManagerBroadcast with ChangeNotifier {
  static final DiscoveryManagerBroadcast _instance =
      DiscoveryManagerBroadcast._internal();

  factory DiscoveryManagerBroadcast() => _instance;

  DiscoveryManagerBroadcast._internal();

  // Configuration
  static const int discoveryPort = 45454;
  static const int discoveryTimeout = 10000; // 10 secondes
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

  // Tracking des nœuds découverts avec timestamp
  final Map<String, int> _nodeTimestamps = {};
  static const int nodeTimeoutDuration = 30000; // 30 secondes

  // Connectivity tracking
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;

  String? _lastKnownIP;
  List<NetworkInterface>? _networkInterfaces;

  Future<void> initialize() async {
    print('[Discovery] Initialisation de DiscoveryManagerBroadcast');
    await _detectNetworkInterfaces();
    await _setupConnectivityListener();
  }

  /// Détecte les interfaces réseau disponibles
  Future<void> _detectNetworkInterfaces() async {
    try {
      _networkInterfaces = await NetworkInterface.list();
      for (var i in _networkInterfaces!) {
        print('[Discovery] Interface: ${i.name}');
        for (var addr in i.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            print('[Discovery]   - IPv4: ${addr.address}');
            if (!addr.address.startsWith('127.')) {
              _lastKnownIP = addr.address;
            }
          }
        }
      }
    } catch (e) {
      print('[Discovery] Erreur détection interfaces: $e');
    }
  }

  /// Écoute les changements de connectivité réseau
  Future<void> _setupConnectivityListener() async {
    try {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) async {
        print('[Discovery] Changement de connectivité: $results');

        if (results.contains(ConnectivityResult.none) || results.isEmpty) {
          if (_running) {
            print('[Discovery] Réseau perdu, arrêt de la découverte');
            stop();
          }
        } else {
          // Réseau rétabli
          await _detectNetworkInterfaces();
          if (_running) {
            print('[Discovery] Réseau rétabli, redémarrage de la découverte');
            await _restartSockets();
          }
        }
      }, onError: (e) {
        print('[Discovery] Erreur flux connectivité: $e');
      });
    } catch (e) {
      print('[Discovery] Impossible d\'écouter les changements de connectivité: $e');
    }
  }

  /// Démarre la découverte et les annonces
  Future<void> start(String nodeId, int p2pPort) async {
    if (_running) {
      print('[Discovery] Découverte déjà en cours');
      return;
    }

    _running = true;

    try {
      // Vérifier la connectivité
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
        throw Exception('Pas de connexion réseau disponible');
      }

      await _detectNetworkInterfaces();

      // Créer socket pour écouter les annonces
      await _createDiscoverySocket();

      // Créer socket pour envoyer les annonces
      await _createAnnouncementSocket();

      // Écouter les annonces entrantes
      _startListening();

      // Annoncer ce nœud
      _startAnnouncements(nodeId, p2pPort);

      // Nettoyer les nœuds expirés
      _startCleanupTimer();

      print(
          '[Discovery] Découverte démarrée (port: $discoveryPort, node: $nodeId, p2p: $p2pPort)');
      notifyListeners();
    } catch (e) {
      print('[Discovery] Erreur démarrage: $e');
      _running = false;
      stop();
      rethrow;
    }
  }

  /// Crée le socket pour écouter les découvertes
  Future<void> _createDiscoverySocket() async {
    try {
      // Nettoyer l'ancien socket
      _discoverySocket?.close();

      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );

      print('[Discovery] Socket d\'écoute créé sur le port $discoveryPort');
    } catch (e) {
      print('[Discovery] Erreur création socket d\'écoute: $e');
      rethrow;
    }
  }

  /// Crée le socket pour envoyer les annonces
  Future<void> _createAnnouncementSocket() async {
    try {
      // Nettoyer l'ancien socket
      _announcementSocket?.close();

      _announcementSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Port automatique
        reuseAddress: true,
      );

      // Activer le broadcast
      _announcementSocket!.broadcastEnabled = true;

      print('[Discovery] Socket d\'annonce créé');
    } catch (e) {
      print('[Discovery] Erreur création socket d\'annonce: $e');
      rethrow;
    }
  }

  /// Lance l'écoute des annonces
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
            print('[Discovery] Erreur lecture datagram: $e');
          }
        }
      },
      onError: (error) {
        print('[Discovery] Erreur socket écoute: $error');
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
      print('[Discovery] Erreur redémarrage sockets: $e');
    }
  }

  /// Lance les annonces périodiques
  void _startAnnouncements(String nodeId, int p2pPort) {
    _announcementTimer?.cancel();

    // Annoncer immédiatement
    _announceNode(nodeId, p2pPort);

    // Puis toutes les 5 secondes
    _announcementTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _announceNode(nodeId, p2pPort);
    });
  }

  /// Envoie une annonce
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

      print('[Discovery] Annonce envoyée: $nodeId:$p2pPort');
    } catch (e) {
      print('[Discovery] Erreur envoi annonce: $e');
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
        print('[Discovery] Annonce invalide: $announcement');
        return;
      }

      final nodeKey = '$remoteNodeId@$remoteIp:$remotePort';

      // Mettre à jour le timestamp du nœud
      _nodeTimestamps[nodeKey] = DateTime.now().millisecondsSinceEpoch;

      if (!_discoveredNodes.contains(nodeKey)) {
        _discoveredNodes.add(nodeKey);
        print(
            '[Discovery] Nœud découvert: $remoteNodeId ($remoteIp:$remotePort)');
        notifyListeners();
      }
    } catch (e) {
      print('[Discovery] Erreur traitement annonce: $e');
    }
  }

  /// Lance le nettoyage des nœuds expirés
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();

    _cleanupTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _cleanupExpiredNodes();
    });
  }

  /// Supprime les nœuds qui n'ont pas communiqué depuis 30s
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
      print('[Discovery] Nœud expiré: $nodeKey');
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

  /// Arrête la découverte
  void stop() {
    _running = false;
    _announcementTimer?.cancel();
    _cleanupTimer?.cancel();
    _discoverySubscription?.cancel();
    _discoverySocket?.close();
    _announcementSocket?.close();

    _discoveredNodes.clear();
    _nodeTimestamps.clear();

    print('[Discovery] Découverte arrêtée');
    notifyListeners();
  }

  /// Nettoyage complet
  void dispose() {
    stop();
    _connectivitySubscription?.cancel();
  }
}
