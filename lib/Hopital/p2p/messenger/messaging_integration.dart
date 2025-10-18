import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'messaging_manager.dart';
import 'messaging_entities.dart';
import 'p2p_integration_fixed.dart';
import 'connection_manager_fixed.dart';

// ============================================================================
// MESSAGING P2P INTEGRATION - Synchronisation P2P des messages
// ============================================================================
class MessagingP2PIntegration with ChangeNotifier {
  static MessagingP2PIntegration? _instance;

  factory MessagingP2PIntegration() {
    _instance ??= MessagingP2PIntegration._internal();
    return _instance!;
  }

  MessagingP2PIntegration._internal();

  late MessagingManager _messagingManager;
  late P2PIntegration _p2pIntegration;
  late ConnectionManager _connectionManager;

  Timer? _syncTimer;
  Timer? _retryTimer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // Statistiques
  int _messagesSynced = 0;
  int _messagesFailed = 0;
  int _lastSyncTimestamp = 0;

  int get messagesSynced => _messagesSynced;
  int get messagesFailed => _messagesFailed;
  int get lastSyncTimestamp => _lastSyncTimestamp;

  static const int syncInterval = 5; // secondes
  static const int maxRetries = 3;

  /// Initialise l'intégration P2P de messaging
  Future<void> initialize(
    MessagingManager messagingManager,
    P2PIntegration p2pIntegration,
    ConnectionManager connectionManager,
  ) async {
    try {
      _messagingManager = messagingManager;
      _p2pIntegration = p2pIntegration;
      _connectionManager = connectionManager;

      // Écouter les messages P2P entrants
      _connectionManager.onMessage.listen((message) {
        _handleIncomingP2PMessage(message);
      });

      print('[MessagingP2P] ✅ Intégration P2P initialisée');
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  /// Démarre la synchronisation des messages
  void start() {
    if (_isRunning) {
      print('[MessagingP2P] ⚠️ Synchronisation déjà en cours');
      return;
    }

    _isRunning = true;

    // Première sync immédiate
    _processSyncQueue();

    // Puis toutes les 5 secondes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: syncInterval), (_) {
      _processSyncQueue();
    });

    // Retry des messages échoués
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _retryFailedMessages();
    });

    print('[MessagingP2P] ✅ Synchronisation démarrée');
    notifyListeners();
  }

  /// Arrête la synchronisation
  void stop() {
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _isRunning = false;
    print('[MessagingP2P] ⏹️ Synchronisation arrêtée');
    notifyListeners();
  }

  // ========================================================================
  // SYNCHRONISATION MESSAGES
  // ========================================================================

  /// Traite la queue de synchronisation
  Future<void> _processSyncQueue() async {
    try {
      // Récupérer les messages en attente de sync
      final pendingQueue = _messagingManager._objectBox.messageSyncQueueBox
          .query(MessageSyncQueue_.status.equals('pending'))
          .order(MessageSyncQueue_.priority, flags: Order.descending)
          .build()
          .find();

      if (pendingQueue.isEmpty) {
        return;
      }

      print(
          '[MessagingP2P] 📋 Processing ${pendingQueue.length} messages from queue');

      for (final syncItem in pendingQueue) {
        await _processSyncItem(syncItem);
      }

      _lastSyncTimestamp = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur traitement queue: $e');
    }
  }

  /// Traite un élément de la queue
  Future<void> _processSyncItem(MessageSyncQueue syncItem) async {
    try {
      final message = _messagingManager.getMessage(syncItem.messageId);
      if (message == null) {
        _objectBox.messageSyncQueueBox.remove(syncItem.id);
        return;
      }

      final targetNodeIds =
          (jsonDecode(syncItem.targetNodeIds) as List<dynamic>)
              .cast<String>();

      // Broadcaster le message à tous les nœuds cibles
      for (final nodeId in targetNodeIds) {
        await _broadcastMessageToNode(message, nodeId);
      }

      // Marquer comme complété
      syncItem.status = 'completed';
      _objectBox.messageSyncQueueBox.put(syncItem);
      _messagesSynced++;

      print('[MessagingP2P] ✅ Sync complétée: ${syncItem.messageId}');
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur sync item: $e');
      syncItem.attemptCount++;
      syncItem.errorMessage = e.toString();

      if (syncItem.attemptCount >= maxRetries) {
        syncItem.status = 'failed';
        _messagesFailed++;
      } else {
        syncItem.status = 'pending';
        syncItem.nextRetryTimestamp =
            DateTime.now().millisecondsSinceEpoch + (30 * 1000); // 30s
      }

      _objectBox.messageSyncQueueBox.put(syncItem);
    }
  }

  /// Broadcaster un message à un nœud spécifique
  Future<void> _broadcastMessageToNode(Message message, String nodeId) async {
    try {
      final payload = {
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
          'mediaDuration': message.mediaDuration,
          'replyToMessageId': message.replyToMessageId,
          'replyToContent': message.replyToContent,
          'replyToFromNodeId': message.replyToFromNodeId,
          'contentHash': message.contentHash,
        }
      };

      // Envoyer via ConnectionManager
      _connectionManager.sendMessage(nodeId, payload);

      print('[MessagingP2P] 📤 Message envoyé à $nodeId');
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur broadcast à $nodeId: $e');
      rethrow;
    }
  }

  /// Réessaye les messages échoués
  Future<void> _retryFailedMessages() async {
    try {
      final failedQueue = _objectBox.messageSyncQueueBox
          .query(MessageSyncQueue_.status.equals('pending'))
          .and(MessageSyncQueue_.nextRetryTimestamp
              .lessOrEqual(DateTime.now().millisecondsSinceEpoch))
          .build()
          .find();

      if (failedQueue.isEmpty) return;

      print('[MessagingP2P] 🔄 Retry de ${failedQueue.length} messages');

      for (final item in failedQueue) {
        await _processSyncItem(item);
      }
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur retry: $e');
    }
  }

  // ========================================================================
  // RÉCEPTION DE MESSAGES P2P
  // ========================================================================

  /// Traite les messages P2P entrants
  Future<void> _handleIncomingP2PMessage(
      Map<String, dynamic> messageData) async {
    try {
      final type = messageData['type'] as String?;

      if (type == 'message') {
        await _handleIncomingMessage(messageData['data'] as Map<String, dynamic>);
      } else if (type == 'message_receipt') {
        await _handleMessageReceipt(messageData['data'] as Map<String, dynamic>);
      } else if (type == 'sync_request') {
        await _handleSyncRequest(messageData['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur traitement message P2P: $e');
    }
  }

  /// Traite un message entrant
  Future<void> _handleIncomingMessage(
      Map<String, dynamic> messageData) async {
    try {
      await _messagingManager.receiveMessage(messageData);

      // Envoyer une confirmation de réception
      _sendMessageReceipt(
        messageData['messageId'] as String,
        messageData['conversationId'] as String,
        messageData['fromNodeId'] as String,
        MessageStatus.delivered,
      );
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur traitement message entrant: $e');
    }
  }

  /// Traite une confirmation de réception
  Future<void> _handleMessageReceipt(
      Map<String, dynamic> receiptData) async {
    try {
      final messageId = receiptData['messageId'] as String?;
      final status = receiptData['status'] as int?;

      if (messageId == null || status == null) return;

      await _messagingManager.updateMessageStatus(
        messageId,
        MessageStatus.values[status],
      );
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur traitement reçu: $e');
    }
  }

  /// Traite une demande de synchronisation
  Future<void> _handleSyncRequest(Map<String, dynamic> syncData) async {
    try {
      final conversationId = syncData['conversationId'] as String?;
      final fromTimestamp = syncData['fromTimestamp'] as int?;

      if (conversationId == null) return;

      // Récupérer les messages depuis le timestamp
      final messages = _objectBox.messageBox
          .query(Message_.conversationId.equals(conversationId))
          .and(Message_.sentTimestamp.greaterOrEqual(fromTimestamp ?? 0))
          .order(Message_.sentTimestamp)
          .build()
          .find();

      // Envoyer les messages
      for (final message in messages) {
        // Broadcaster via P2PIntegration
      }
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur traitement sync request: $e');
    }
  }

  /// Envoie une confirmation de réception
  Future<void> _sendMessageReceipt(
    String messageId,
    String conversationId,
    String fromNodeId,
    MessageStatus status,
  ) async {
    try {
      final payload = {
        'type': 'message_receipt',
        'data': {
          'messageId': messageId,
          'conversationId': conversationId,
          'recipientNodeId': _messagingManager._currentNodeId,
          'status': status.index,
          'confirmedTimestamp': DateTime.now().millisecondsSinceEpoch,
        }
      };

      _connectionManager.sendMessage(fromNodeId, payload);
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur envoi reçu: $e');
    }
  }

  // ========================================================================
  // REQUÊTES MULTI-NŒUDS (Anti-Entropy)
  // ========================================================================

  /// Déclenche la synchronisation anti-entropie
  Future<void> triggerAntiEntropy() async {
    try {
      print('[MessagingP2P] 🔄 Anti-entropie lancée');

      final conversations = _messagingManager.getActiveConversations();

      for (final conversation in conversations) {
        final lastSync = conversation.lastSyncTimestamp;

        // Demander les messages depuis la dernière sync
        final payload = {
          'type': 'sync_request',
          'data': {
            'conversationId': conversation.conversationId,
            'fromTimestamp': lastSync,
          }
        };

        // Broadcaster à tous les participants
        for (final nodeId in conversation.getParticipants()) {
          if (nodeId != _messagingManager._currentNodeId) {
            _connectionManager.sendMessage(nodeId, payload);
          }
        }
      }

      print('[MessagingP2P] ✅ Anti-entropie complétée');
    } catch (e) {
      print('[MessagingP2P] ❌ Erreur anti-entropie: $e');
    }
  }

  // ========================================================================
  // STATISTIQUES
  // ========================================================================

  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'messagesSynced': _messagesSynced,
      'messagesFailed': _messagesFailed,
      'lastSyncTimestamp': _lastSyncTimestamp,
      'lastSyncTime': _lastSyncTimestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(_lastSyncTimestamp).toString()
          : 'Jamais',
    };
  }

  void dispose() {
    stop();
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
    print('[MessagesSyncObserver] ⏹️ Surveillance arrêtée');
  }

  void dispose() {
    stop();
  }
}