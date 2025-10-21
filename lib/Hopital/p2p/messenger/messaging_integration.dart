import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../objectBox/classeObjectBox.dart';
import '../connection_manager_fixed.dart';
import '../p2p_integration_fixed.dart';
import 'messaging_entities.dart';
import 'messaging_manager.dart';

/// ✅ Version ULTRA-SIMPLIFIÉE : événementiel pur avec filtrage des métadonnées
class MessagingP2PIntegration with ChangeNotifier {
  static MessagingP2PIntegration? _instance;

  factory MessagingP2PIntegration() {
    _instance ??= MessagingP2PIntegration._internal();
    return _instance!;
  }

  MessagingP2PIntegration._internal();

  late MessagingManager _messagingManager;
  late ConnectionManager _connectionManager;
  late ObjectBox _objectBox;

  StreamSubscription? _messageSubscription;

  bool _isRunning = false;

  int _messagesSynced = 0;
  int _messagesFailed = 0;

  bool get isRunning => _isRunning;

  int get messagesSynced => _messagesSynced;

  int get messagesFailed => _messagesFailed;

  // ✅ Getter pour accéder à ObjectBox depuis l'extérieur
  ObjectBox get objectBox => _objectBox;

  Future<void> initialize(
    MessagingManager messagingManager,
    P2PIntegration? p2pIntegration, // Nullable car plus utilisé
    ConnectionManager connectionManager,
    ObjectBox objectBox,
  ) async {
    try {
      _messagingManager = messagingManager;
      _connectionManager = connectionManager;
      _objectBox = objectBox;

      print('[MessagingP2P] ✅ Initialisé');
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur init: $e');
      rethrow;
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // ✅ CORRECTION CRITIQUE: Filtrage strict des messages de métadonnées
    _messageSubscription = _connectionManager.onMessage.listen(
      (message) {
        // 🔥 Filtrer AVANT le traitement
        final type = message['type'] as String?;

        // ✅ Ignorer explicitement les messages de métadonnées
        if (type == 'node_metadata' || type == 'metadata_request') {
          print('[MessagingP2P] 🔇 Message de métadonnée ignoré: $type');
          return; // Ne pas traiter
        }

        // ✅ Traiter uniquement les messages de messagerie
        if (type == 'message' || type == 'message_receipt') {
          _handleIncomingP2PMessage(message);
        }
      },
      onError: (e) => print('[MessagingP2P] ❌ Erreur stream: $e'),
    );

    print('[MessagingP2P] ✅ Démarré (mode événementiel avec filtrage)');
    notifyListeners();
  }

  void stop() {
    _messageSubscription?.cancel();
    _isRunning = false;
    print('[MessagingP2P] 🛑 Arrêté');
    notifyListeners();
  }

  /// ✅ Traite les messages P2P entrants IMMÉDIATEMENT (déjà filtrés)
  Future<void> _handleIncomingP2PMessage(
      Map<String, dynamic> messageData) async {
    try {
      final type = messageData['type'] as String?;

      if (type == 'message') {
        await _handleIncomingMessage(
            messageData['data'] as Map<String, dynamic>);
      } else if (type == 'message_receipt') {
        await _handleMessageReceipt(
            messageData['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur traitement: $e');
      _messagesFailed++;
      notifyListeners();
    }
  }

  Future<void> _handleIncomingMessage(Map<String, dynamic> messageData) async {
    try {
      // Recevoir directement dans MessagingManager
      await _messagingManager.receiveMessage(messageData);

      // Envoyer accusé reçu
      final messageId = messageData['messageId'] as String?;
      final conversationId = messageData['conversationId'] as String?;
      final fromNodeId = messageData['fromNodeId'] as String?;

      if (messageId != null && fromNodeId != null) {
        _sendMessageReceipt(
          messageId,
          conversationId ?? '',
          fromNodeId,
          MessageStatus.delivered,
        );
      }

      _messagesSynced++;
      notifyListeners();
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur réception: $e');
      _messagesFailed++;
      notifyListeners();
    }
  }

  Future<void> _handleMessageReceipt(Map<String, dynamic> receiptData) async {
    try {
      final messageId = receiptData['messageId'] as String?;
      final status = receiptData['status'] as int?;

      if (messageId != null &&
          status != null &&
          status < MessageStatus.values.length) {
        await _messagingManager.updateMessageStatus(
          messageId,
          MessageStatus.values[status],
        );
      }
    } catch (e) {
      print('[MessagingP2P] Erreur accusé reçu: $e');
    }
  }

  void _sendMessageReceipt(
    String messageId,
    String conversationId,
    String fromNodeId,
    MessageStatus status,
  ) {
    try {
      final payload = {
        'nodeId': _messagingManager.currentNodeId,
        'type': 'message_receipt',
        'data': {
          'messageId': messageId,
          'conversationId': conversationId,
          'recipientNodeId': _messagingManager.currentNodeId,
          'status': status.index,
          'confirmedTimestamp': DateTime.now().millisecondsSinceEpoch,
        }
      };

      _connectionManager.sendMessage(fromNodeId, payload);
    } catch (e) {
      print('[MessagingP2P] Erreur envoi accusé: $e');
    }
  }

  /// Envoyer un message (appelé depuis MessagingManager)
  Future<void> broadcastMessageToAll(
    Message message,
    List<String> targetNodeIds,
  ) async {
    try {
      // Envoyer en parallèle à tous les nœuds
      await Future.wait(
        targetNodeIds.map((nodeId) => _broadcastMessageToNode(message, nodeId)),
        eagerError: false,
      );

      _messagesSynced++;
      notifyListeners();
    } catch (e) {
      print('[MessagingP2P] Erreur broadcast: $e');
      _messagesFailed++;
      notifyListeners();
    }
  }

  Future<void> _broadcastMessageToNode(Message message, String nodeId) async {
    try {
      final payload = {
        'nodeId': _messagingManager.currentNodeId,
        'type': 'message',
        'data': {
          'messageId': message.messageId,
          'conversationId': message.conversationId,
          'fromNodeId': message.fromNodeId,
          'toNodeId': message.toNodeId,
          'typeValue': message.typeValue,
          'content': message.content,
          'sentTimestamp': message.sentTimestamp,
          'statusValue': message.statusValue,
          'mediaPath': message.mediaPath,
          'mediaSize': message.mediaSize,
          'mediaMimeType': message.mediaMimeType,
          'contentHash': message.contentHash,
        }
      };

      _connectionManager.sendMessage(nodeId, payload);
    } catch (e) {
      print('[MessagingP2P] Erreur broadcast à $nodeId: $e');
      rethrow;
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'messagesSynced': _messagesSynced,
      'messagesFailed': _messagesFailed,
      'lastSyncTimestamp': DateTime.now().millisecondsSinceEpoch,
      'lastSyncTime': DateTime.now().toString(),
    };
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

// ============================================================================
// SYNC OBSERVER - Observer ObjectBox pour synchroniser les messages P2P
// ============================================================================
class MessagingSyncObserver {
  static MessagingSyncObserver? _instance;

  factory MessagingSyncObserver() {
    _instance ??= MessagingSyncObserver._internal();
    return _instance!;
  }

  MessagingSyncObserver._internal();

  late ObjectBox _objectBox;
  late MessagingP2PIntegration _messagingP2P;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _conversationSubscription;

  Future<void> initialize(
    ObjectBox objectBox,
    MessagingP2PIntegration messagingP2P,
  ) async {
    _objectBox = objectBox;
    _messagingP2P = messagingP2P;
    print('[MessagesSyncObserver] ✅ Initialisé');
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Observer les changements de messages
    _messageSubscription = _objectBox.messageBox
        .query()
        .watch(triggerImmediately: false)
        .listen((_) {
      // Les changements de messages sont gérés par MessagingManager
    });

    // Observer les changements de conversations
    _conversationSubscription = _objectBox.conversationBox
        .query()
        .watch(triggerImmediately: false)
        .listen((_) {
      // Les changements de conversations sont gérés par MessagingManager
    });

    print('[MessagesSyncObserver] ✅ Surveillance démarrée');
  }

  void stop() {
    _messageSubscription?.cancel();
    _conversationSubscription?.cancel();
    _isRunning = false;
    print('[MessagesSyncObserver] ℹ️ Surveillance arrêtée');
  }

  void dispose() {
    stop();
  }
}
