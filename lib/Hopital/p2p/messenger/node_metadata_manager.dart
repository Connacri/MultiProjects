import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connection_manager_fixed.dart';
import 'fonctions.dart';

/// 🔍 Version DIAGNOSTIQUE du NodeMetadataManager
/// Avec logs détaillés pour tracer l'envoi et la réception
class NodeMetadataManager with ChangeNotifier {
  static final NodeMetadataManager _instance = NodeMetadataManager._internal();

  factory NodeMetadataManager() => _instance;

  NodeMetadataManager._internal();

  late final ConnectionManager _connectionManager;
  late final String _currentNodeId;
  bool _initialized = false;

  // Métadonnées locales
  String? _localPlatform;
  String? _localBranch;
  String? _localDisplayName;

  // Métadonnées distantes
  final Map<String, NodeMetadata> _remoteMetadata = {};

  StreamSubscription? _messageSubscription;
  Timer? _broadcastTimer;

  // 📊 DIAGNOSTICS - Compteurs
  int _messagesSent = 0;
  int _messagesReceived = 0;
  int _requestsSent = 0;
  int _requestsReceived = 0;
  final List<DiagnosticLog> _logs = [];

  Map<String, NodeMetadata> get remoteMetadata =>
      Map.unmodifiable(_remoteMetadata);

  bool get isInitialized => _initialized;

  // 📊 Getters de diagnostics
  int get messagesSent => _messagesSent;

  int get messagesReceived => _messagesReceived;

  int get requestsSent => _requestsSent;

  int get requestsReceived => _requestsReceived;

  List<DiagnosticLog> get logs => List.unmodifiable(_logs);

  /// Initialisation du gestionnaire
  Future<void> initialize(
      ConnectionManager connectionManager, String currentNodeId) async {
    if (_initialized) {
      _addLog('⚠️ INIT', 'Déjà initialisé, ignoré');
      return;
    }

    try {
      _connectionManager = connectionManager;
      _currentNodeId = currentNodeId;
      _addLog('🚀 INIT', 'Début initialisation pour $_currentNodeId');

      await _loadLocalMetadata();
      _setupMessageListener();
      _startPeriodicBroadcast();

      _addLog('📡 INIT', 'Broadcast initial...');
      await broadcastMetadata(); // Diffusion immédiate

      _initialized = true;
      _addLog('✅ INIT', 'Initialisation complète');
      print('[NodeMetadataManager] ✅ Initialisé pour $_currentNodeId');
    } catch (e, stack) {
      _addLog('❌ INIT', 'Erreur: $e');
      print('[NodeMetadataManager] ❌ Erreur initialisation: $e');
      print(stack);
      rethrow;
    }
  }

  /// Chargement des métadonnées locales
  Future<void> _loadLocalMetadata() async {
    try {
      _localPlatform = await getCurrentPlatform();
      _localBranch = getBranchForCurrentUser();
      _localDisplayName = _generateDisplayName();

      _addLog('📄 LOAD', 'Platform: $_localPlatform');
      _addLog('📄 LOAD', 'Branch: $_localBranch');
      _addLog('📄 LOAD', 'DisplayName: $_localDisplayName');

      print('[NodeMetadataManager] 📄 Métadonnées locales:');
      print('   Platform: $_localPlatform');
      print('   Branch: $_localBranch');
      print('   DisplayName: $_localDisplayName');
    } catch (e) {
      _addLog('⚠️ LOAD', 'Erreur: $e, utilisation valeurs par défaut');
      print('[NodeMetadataManager] ⚠️ Erreur chargement métadonnées: $e');
      _localPlatform ??= 'Unknown';
      _localBranch ??= 'No Branch';
      _localDisplayName ??= 'Unknown Device';
    }
  }

  /// Génère un nom d'affichage lisible depuis l'ID du nœud
  String _generateDisplayName() {
    final parts = _currentNodeId.split('-');
    return parts.length >= 3 ? parts.sublist(2).join('-') : _currentNodeId;
  }

  /// Écoute des messages entrants
  void _setupMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription = _connectionManager.onMessage.listen(
      _handleIncomingMessage,
      onError: (e, _) {
        _addLog('❌ LISTEN', 'Erreur stream: $e');
        print('[NodeMetadataManager] ❌ Erreur stream: $e');
      },
      cancelOnError: false,
    );
    _addLog('👂 LISTEN', 'Écoute des messages activée');
  }

  /// Traitement des messages entrants
  void _handleIncomingMessage(Map<String, dynamic> message) {
    try {
      final type = message['type'] as String?;
      final nodeId = message['nodeId'] as String?;

      // 🔍 LOG DÉTAILLÉ de TOUS les messages reçus
      _addLog('📨 RECV', 'Type: $type, From: $nodeId');

      if (nodeId == null) {
        _addLog('⚠️ RECV', 'NodeId manquant, message ignoré');
        return;
      }

      if (nodeId == _currentNodeId) {
        _addLog('🔄 RECV', 'Message de soi-même ignoré');
        return;
      }

      switch (type) {
        case 'node_metadata':
          _addLog('✅ RECV', 'Message de métadonnées détecté');
          _handleMetadataMessage(message);
          break;
        case 'metadata_request':
          _addLog('🔍 RECV', 'Requête de métadonnées détectée');
          _requestsReceived++;
          broadcastMetadata(targetNodeId: nodeId);
          break;
        default:
          _addLog('➖ RECV', 'Type non-métadonnées ignoré: $type');
          break;
      }
    } catch (e, stack) {
      _addLog('❌ RECV', 'Erreur traitement: $e');
      print('[NodeMetadataManager] ❌ Erreur traitement message: $e');
      print(stack);
    }
  }

  /// Traitement d'un message de type "node_metadata"
  void _handleMetadataMessage(Map<String, dynamic> message) {
    try {
      final nodeId = message['nodeId'] as String;

      _addLog('🔍 PARSE', 'Parsing métadonnées de $nodeId');
      _addLog('🔍 PARSE', 'DisplayName: ${message['displayName']}');
      _addLog('🔍 PARSE', 'Platform: ${message['platform']}');
      _addLog('🔍 PARSE', 'Branch: ${message['branch']}');

      final metadata = NodeMetadata(
        nodeId: nodeId,
        displayName: message['displayName'] as String? ?? 'Unknown',
        platform: message['platform'] as String? ?? 'Unknown',
        branch: message['branch'] as String?,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(
          message['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final wasNew = !_remoteMetadata.containsKey(nodeId);
      _remoteMetadata[nodeId] = metadata;
      _messagesReceived++;

      _addLog('✅ STORE',
          '${wasNew ? "Nouveau" : "Mise à jour"} nœud: ${metadata.displayName}');
      _addLog('📊 STATS', 'Total nœuds connus: ${_remoteMetadata.length}');

      print('[NodeMetadataManager] 📥 Reçu métadonnées de $nodeId');
      print('   DisplayName: ${metadata.displayName}');
      print('   Platform: ${metadata.platform}');
      print('   Branch: ${metadata.branch ?? "N/A"}');

      notifyListeners();
    } catch (e, stack) {
      _addLog('❌ PARSE', 'Erreur parsing: $e');
      print('[NodeMetadataManager] ❌ Erreur parsing métadonnées: $e');
      print(stack);
    }
  }

  /// Diffusion des métadonnées locales
  Future<void> broadcastMetadata({String? targetNodeId}) async {
    if (!_initialized) {
      _addLog('⚠️ SEND', 'Non initialisé, broadcast ignoré');
      print('[NodeMetadataManager] ⚠️ Non initialisé, broadcast ignoré');
      return;
    }

    try {
      final payload = {
        'type': 'node_metadata',
        'nodeId': _currentNodeId,
        'displayName': _localDisplayName,
        'platform': _localPlatform,
        'branch': _localBranch,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _addLog('📦 PREPARE', 'Payload préparé:');
      _addLog('📦 PREPARE', '  NodeId: $_currentNodeId');
      _addLog('📦 PREPARE', '  DisplayName: $_localDisplayName');
      _addLog('📦 PREPARE', '  Platform: $_localPlatform');
      _addLog('📦 PREPARE', '  Branch: $_localBranch');

      if (targetNodeId != null) {
        _addLog('📤 SEND', 'Envoi ciblé vers $targetNodeId');
        _connectionManager.sendMessage(targetNodeId, payload);
        _messagesSent++;
        _addLog('✅ SEND', 'Message envoyé avec succès');
        print('[NodeMetadataManager] 📤 Métadonnées envoyées à $targetNodeId');
      } else {
        final neighbors = _connectionManager.neighbors;
        _addLog('📡 BROADCAST', 'Envoi à ${neighbors.length} voisin(s)');

        if (neighbors.isEmpty) {
          _addLog('⚠️ BROADCAST', 'Aucun voisin disponible');
          print('[NodeMetadataManager] ⚠️ Aucun voisin pour le broadcast');
          return;
        }

        for (final neighborId in neighbors) {
          _addLog('📤 SEND', 'Envoi vers $neighborId');
          _connectionManager.sendMessage(neighborId, payload);
          _messagesSent++;
        }
        _addLog('✅ BROADCAST', '${neighbors.length} message(s) envoyé(s)');
        print(
            '[NodeMetadataManager] 📡 Diffusé à ${neighbors.length} voisin(s)');
      }

      _addLog('📊 STATS', 'Total envoyés: $_messagesSent');
    } catch (e, stack) {
      _addLog('❌ SEND', 'Erreur broadcast: $e');
      print('[NodeMetadataManager] ❌ Erreur broadcast: $e');
      print(stack);
    }
  }

  /// Demande manuelle des métadonnées d'un voisin
  Future<void> requestMetadata(String targetNodeId) async {
    if (!_initialized) {
      _addLog('⚠️ REQUEST', 'Non initialisé');
      return;
    }

    try {
      final payload = {
        'type': 'metadata_request',
        'nodeId': _currentNodeId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _addLog('🔍 REQUEST', 'Demande envoyée à $targetNodeId');
      _connectionManager.sendMessage(targetNodeId, payload);
      _requestsSent++;
      _addLog('✅ REQUEST', 'Demande envoyée avec succès');
      print('[NodeMetadataManager] 🔍 Demande envoyée à $targetNodeId');
    } catch (e, stack) {
      _addLog('❌ REQUEST', 'Erreur: $e');
      print('[NodeMetadataManager] ❌ Erreur demande métadonnées: $e');
      print(stack);
    }
  }

  /// Démarre la diffusion périodique toutes les 30s
  void _startPeriodicBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_initialized) {
        _addLog('⏰ PERIODIC', 'Broadcast périodique démarré');
        await broadcastMetadata();
        cleanupStaleMetadata();
      }
    });
    _addLog('⏰ TIMER', 'Broadcast périodique activé (30s)');
  }

  /// Nettoyage des métadonnées trop anciennes
  void cleanupStaleMetadata() {
    final now = DateTime.now();
    final threshold = const Duration(minutes: 5);
    final beforeCount = _remoteMetadata.length;

    _remoteMetadata.removeWhere((nodeId, meta) {
      final stale = now.difference(meta.lastUpdate) > threshold;
      if (stale) {
        _addLog('🗑️ CLEANUP', 'Métadonnées obsolètes: $nodeId');
        print('[NodeMetadataManager] 🗑️ Supprimé métadonnées $nodeId');
      }
      return stale;
    });

    final removedCount = beforeCount - _remoteMetadata.length;
    if (removedCount > 0) {
      _addLog('🗑️ CLEANUP', '$removedCount métadonnée(s) supprimée(s)');
      notifyListeners();
    }
  }

  /// Rafraîchit manuellement toutes les métadonnées connues
  Future<void> refreshAllMetadata() async {
    if (!_initialized) return;
    try {
      final neighbors = _connectionManager.neighbors;
      _addLog(
          '🔄 REFRESH', 'Rafraîchissement de ${neighbors.length} voisin(s)');

      for (final id in neighbors) {
        await requestMetadata(id);
      }

      _addLog('✅ REFRESH', 'Rafraîchissement terminé');
      print(
          '[NodeMetadataManager] 🔄 Rafraîchissement ${neighbors.length} voisin(s)');
    } catch (e) {
      _addLog('❌ REFRESH', 'Erreur: $e');
      print('[NodeMetadataManager] ❌ Erreur refresh: $e');
    }
  }

  /// 🔍 Récupère les métadonnées d'un nœud spécifique
  NodeMetadata? getMetadata(String nodeId, {bool logIfMissing = false}) {
    if (!_initialized) {
      if (kDebugMode) {
        _addLog('⚠️ GET', 'Appel avant initialisation pour $nodeId');
      }
      return null;
    }

    final metadata = _remoteMetadata[nodeId];

    if (metadata == null) {
      if (logIfMissing) {
        _addLog('❌ GET', 'Aucune métadonnée pour $nodeId');
        print(
            '[NodeMetadataManager] ⚠️ Aucune métadonnée trouvée pour $nodeId');
      }
    } else {
      _addLog('✅ GET', 'Métadonnées trouvées pour $nodeId');
    }

    return metadata;
  }

  /// ✅ Vérifie si un nœud possède des métadonnées
  bool hasMetadata(String nodeId) {
    if (!_initialized) {
      if (kDebugMode) {
        _addLog('⚠️ HAS', 'Appel avant initialisation');
      }
      return false;
    }
    return _remoteMetadata.containsKey(nodeId);
  }

  /// Ajout d'un log de diagnostic
  void _addLog(String category, String message) {
    final log = DiagnosticLog(
      timestamp: DateTime.now(),
      category: category,
      message: message,
    );
    _logs.add(log);

    // Garder seulement les 200 derniers logs
    if (_logs.length > 200) {
      _logs.removeAt(0);
    }
  }

  /// 📊 Obtenir un rapport de diagnostics
  String getDiagnosticReport() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📊 RAPPORT DIAGNOSTIC MÉTADONNÉES P2P');
    buffer.writeln('═══════════════════════════════════════');
    buffer
        .writeln('État: ${_initialized ? "✅ Initialisé" : "❌ Non initialisé"}');
    buffer.writeln('NodeId: $_currentNodeId');
    buffer.writeln('');
    buffer.writeln('📄 MÉTADONNÉES LOCALES:');
    buffer.writeln('  Platform: $_localPlatform');
    buffer.writeln('  Branch: $_localBranch');
    buffer.writeln('  DisplayName: $_localDisplayName');
    buffer.writeln('');
    buffer.writeln('📊 STATISTIQUES:');
    buffer.writeln('  Messages envoyés: $_messagesSent');
    buffer.writeln('  Messages reçus: $_messagesReceived');
    buffer.writeln('  Requêtes envoyées: $_requestsSent');
    buffer.writeln('  Requêtes reçues: $_requestsReceived');
    buffer.writeln('  Nœuds connus: ${_remoteMetadata.length}');
    buffer.writeln('');
    buffer.writeln('👥 NŒUDS DISTANTS:');
    if (_remoteMetadata.isEmpty) {
      buffer.writeln('  (aucun)');
    } else {
      for (final metadata in _remoteMetadata.values) {
        buffer.writeln('  • ${metadata.displayName}');
        buffer.writeln('    Platform: ${metadata.platform}');
        buffer.writeln('    Branch: ${metadata.branch ?? "N/A"}');
        buffer.writeln(
            '    Maj: ${_formatDuration(DateTime.now().difference(metadata.lastUpdate))}');
      }
    }
    buffer.writeln('');
    buffer.writeln('📝 DERNIERS LOGS (${_logs.length}):');
    for (final log in _logs.reversed.take(20)) {
      buffer.writeln('  [${log.category}] ${log.message}');
    }
    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return 'il y a ${duration.inSeconds}s';
    if (duration.inMinutes < 60) return 'il y a ${duration.inMinutes}m';
    if (duration.inHours < 24) return 'il y a ${duration.inHours}h';
    return 'il y a ${duration.inDays}j';
  }

  /// Arrêt et nettoyage
  void stop() {
    _messageSubscription?.cancel();
    _broadcastTimer?.cancel();
    _remoteMetadata.clear();
    _initialized = false;
    _addLog('🛑 STOP', 'Gestionnaire arrêté');
    print('[NodeMetadataManager] 🛑 Arrêté');
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Modèle de métadonnées d'un nœud P2P
class NodeMetadata {
  final String nodeId;
  final String displayName;
  final String platform;
  final String? branch;
  final DateTime lastUpdate;

  NodeMetadata({
    required this.nodeId,
    required this.displayName,
    required this.platform,
    this.branch,
    required this.lastUpdate,
  });

  @override
  String toString() =>
      'NodeMetadata(nodeId: $nodeId, displayName: $displayName, '
      'platform: $platform, branch: ${branch ?? "N/A"}, lastUpdate: $lastUpdate)';
}

/// Modèle de log de diagnostic
class DiagnosticLog {
  final DateTime timestamp;
  final String category;
  final String message;

  DiagnosticLog({
    required this.timestamp,
    required this.category,
    required this.message,
  });

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$time] [$category] $message';
  }
}
