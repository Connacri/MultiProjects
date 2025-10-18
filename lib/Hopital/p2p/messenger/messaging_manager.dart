import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

import '../../../objectBox/classeObjectBox.dart';
import 'messaging_entities.dart';

// ============================================================================
// MESSAGING MANAGER - Singleton pour gérer tous les messages
// ============================================================================
class MessagingManager with ChangeNotifier {
  static final MessagingManager _instance = MessagingManager._internal();

  factory MessagingManager() => _instance;

  MessagingManager._internal();

  // Référence ObjectBox (à initialiser)
  late ObjectBox _objectBox;
  late String _currentNodeId;

  // StreamControllers pour notifications
  final _messageReceivedController = StreamController<Message>.broadcast();
  final _conversationUpdateController =
      StreamController<Conversation>.broadcast();
  final _messageStatusChangeController =
      StreamController<MessageStatusUpdate>.broadcast();

  Stream<Message> get onMessageReceived => _messageReceivedController.stream;
  Stream<Conversation> get onConversationUpdate =>
      _conversationUpdateController.stream;
  Stream<MessageStatusUpdate> get onMessageStatusChange =>
      _messageStatusChangeController.stream;

  // Statistiques
  int _totalMessagesSent = 0;
  int _totalMessagesReceived = 0;
  int _totalUnreadMessages = 0;

  int get totalMessagesSent => _totalMessagesSent;
  int get totalMessagesReceived => _totalMessagesReceived;
  int get totalUnreadMessages => _totalUnreadMessages;

  /// Initialise le manager
  Future<void> initialize(ObjectBox objectBox, String currentNodeId) async {
    _objectBox = objectBox;
    _currentNodeId = currentNodeId;
    print('[MessagingManager] ✅ Initialisé (Node: $_currentNodeId)');
    _recalculateUnreadCount();
  }

  // ========================================================================
  // ENVOI DE MESSAGES
  // ========================================================================

  /// Envoie un message texte
  Future<Message> sendTextMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    return _sendMessage(
      conversationId: conversationId,
      type: MessageType.text,
      content: content,
      replyToMessageId: replyToMessageId,
    );
  }

  /// Envoie un message avec fichier (audio, vidéo, fichier)
  Future<Message> sendMediaMessage(
    String conversationId,
    MessageType type,
    File mediaFile, {
    String? caption,
    int? durationSeconds,
    String? replyToMessageId,
  }) async {
    if (!await mediaFile.exists()) {
      throw Exception('Fichier non trouvé: ${mediaFile.path}');
    }

    final fileSize = await mediaFile.length();
    if (fileSize > 20 * 1024 * 1024) {
      throw Exception('Fichier trop volumineux (max 20 MB)');
    }

    final mimeType = _getMimeType(type);
    final contentJson = {
      'caption': caption,
      'fileName': mediaFile.path.split('/').last,
    };

    final message = await _sendMessage(
      conversationId: conversationId,
      type: type,
      content: jsonEncode(contentJson),
      mediaPath: mediaFile.path,
      mediaSize: fileSize,
      mediaMimeType: mimeType,
      mediaDuration: durationSeconds,
      replyToMessageId: replyToMessageId,
    );

    return message;
  }

  /// Méthode interne pour envoyer un message
  Future<Message> _sendMessage({
    required String conversationId,
    required MessageType type,
    required String content,
    String? mediaPath,
    int? mediaSize,
    String? mediaMimeType,
    int? mediaDuration,
    String? replyToMessageId,
  }) async {
    try {
      // Créer le message
      final messageId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      Message message = Message(
        messageId: messageId,
        conversationId: conversationId,
        fromNodeId: _currentNodeId,
        typeValue: type.index,
        content: content,
        sentTimestamp: now,
        statusValue: MessageStatus.pending.index,
        mediaPath: mediaPath,
        mediaSize: mediaSize,
        mediaMimeType: mediaMimeType,
        mediaDuration: mediaDuration,
        replyToMessageId: replyToMessageId,
      );

      // Calculer hash du contenu
      message.contentHash = _calculateContentHash(message);

      // Ajouter à la base de données
      _objectBox.messageBox.put(message);

      // Mettre à jour la conversation
      await _updateConversationLastMessage(conversationId, message);

      // Ajouter à la queue de synchronisation
      _queueMessageForSync(messageId, 'send', conversationId);

      _totalMessagesSent++;
      notifyListeners();

      print('[MessagingManager] 📤 Message envoyé: $messageId');
      return message;
    } catch (e) {
      print('[MessagingManager] ❌ Erreur envoi message: $e');
      rethrow;
    }
  }

  // ========================================================================
  // RÉCEPTION DE MESSAGES
  // ========================================================================

  /// Reçoit et stocke un message entrant
  Future<void> receiveMessage(Map<String, dynamic> messageData) async {
    try {
      final messageId = messageData['messageId'] as String?;
      final conversationId = messageData['conversationId'] as String?;
      final fromNodeId = messageData['fromNodeId'] as String?;

      if (messageId == null || conversationId == null || fromNodeId == null) {
        print('[MessagingManager] ❌ Données de message invalides');
        return;
      }

      // Vérifier si le message existe déjà
      final existingMessage = _objectBox.messageBox
          .query(Message_.messageId.equals(messageId))
          .build()
          .findFirst();
      if (existingMessage != null) {
        print('[MessagingManager] ⏭️ Message déjà reçu: $messageId');
        return;
      }

      // Construire le message
      final message = Message(
        messageId: messageId,
        conversationId: conversationId,
        fromNodeId: fromNodeId,
        typeValue: messageData['type'] as int? ?? MessageType.text.index,
        content: messageData['content'] as String? ?? '',
        sentTimestamp: messageData['sentTimestamp'] as int? ??
            DateTime.now().millisecondsSinceEpoch,
        statusValue: MessageStatus.delivered.index,
        toNodeId: messageData['toNodeId'] as String?,
        mediaPath: messageData['mediaPath'] as String?,
        mediaSize: messageData['mediaSize'] as int?,
        mediaMimeType: messageData['mediaMimeType'] as String?,
        mediaDuration: messageData['mediaDuration'] as int?,
        replyToMessageId: messageData['replyToMessageId'] as String?,
        replyToContent: messageData['replyToContent'] as String?,
        replyToFromNodeId: messageData['replyToFromNodeId'] as String?,
        receivedTimestamp: DateTime.now().millisecondsSinceEpoch,
        encryptionKeyId: messageData['encryptionKeyId'] as String?,
        contentHash: messageData['contentHash'] as String?,
      );

      // Sauvegarder
      _objectBox.messageBox.put(message);

      // Mettre à jour la conversation
      await _updateConversationLastMessage(conversationId, message);

      // Envoyer une confirmation de réception
      _queueReceiptForSync(messageId, conversationId, fromNodeId);

      _totalMessagesReceived++;
      _totalUnreadMessages++;

      // Notifier
      _messageReceivedController.add(message);
      notifyListeners();

      print('[MessagingManager] 📥 Message reçu: $messageId de $fromNodeId');
    } catch (e) {
      print('[MessagingManager] ❌ Erreur réception message: $e');
    }
  }

  // ========================================================================
  // GESTION DES STATUTS
  // ========================================================================

  /// Met à jour le statut d'un message
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    try {
      final message = _objectBox.messageBox
          .query(Message_.messageId.equals(messageId))
          .build()
          .findFirst();

      if (message == null) {
        print('[MessagingManager] ❌ Message non trouvé: $messageId');
        return;
      }

      message.status = status;

      if (status == MessageStatus.read) {
        message.readTimestamp = DateTime.now().millisecondsSinceEpoch;
      } else if (status == MessageStatus.delivered) {
        message.receivedTimestamp = DateTime.now().millisecondsSinceEpoch;
      }

      _objectBox.messageBox.put(message);

      // Notifier du changement de statut
      _messageStatusChangeController.add(
        MessageStatusUpdate(
          messageId: messageId,
          status: status,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      print('[MessagingManager] ✅ Statut mis à jour: $messageId -> $status');
    } catch (e) {
      print('[MessagingManager] ❌ Erreur mise à jour statut: $e');
    }
  }

  /// Marque une conversation comme lue
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final conversation = _objectBox.conversationBox
          .query(Conversation_.conversationId.equals(conversationId))
          .build()
          .findFirst();

      if (conversation == null) return;

      // Marquer tous les messages comme lus
      final messages = _objectBox.messageBox
          .query(Message_.conversationId.equals(conversationId))
          .and(Message_.statusValue.lessThan(MessageStatus.read.index))
          .build()
          .find();

      final now = DateTime.now().millisecondsSinceEpoch;
      for (final msg in messages) {
        msg.status = MessageStatus.read;
        msg.readTimestamp = now;
      }

      _objectBox.messageBox.putMany(messages);

      // Mettre à jour le compteur
      conversation.unreadCount = 0;
      _objectBox.conversationBox.put(conversation);

      _recalculateUnreadCount();
      _conversationUpdateController.add(conversation);
      notifyListeners();

      print('[MessagingManager] ✅ Conversation marquée lue: $conversationId');
    } catch (e) {
      print('[MessagingManager] ❌ Erreur marquage lecture: $e');
    }
  }

  // ========================================================================
  // GESTION DES CONVERSATIONS
  // ========================================================================

  /// Crée une nouvelle conversation 1-à-1
  Future<Conversation> createPrivateConversation(
    String otherNodeId, {
    String? displayName,
  }) async {
    try {
      // Vérifier si conversation existe déjà
      final participants = [_currentNodeId, otherNodeId]..sort();
      final conversationId = participants.join('-');

      var existing = _objectBox.conversationBox
          .query(Conversation_.conversationId.equals(conversationId))
          .build()
          .findFirst();

      if (existing != null) {
        return existing;
      }

      // Créer nouvelle conversation
      final now = DateTime.now().millisecondsSinceEpoch;
      final conversation = Conversation(
        conversationId: conversationId,
        typeValue: ConversationType.private.index,
        participantNodeIds: participants.join(','),
        creatorNodeId: _currentNodeId,
        createdTimestamp: now,
        lastActivityTimestamp: now,
        title: displayName ?? otherNodeId,
      );

      _objectBox.conversationBox.put(conversation);

      _conversationUpdateController.add(conversation);
      notifyListeners();

      print('[MessagingManager] ✅ Conversation privée créée: $conversationId');
      return conversation;
    } catch (e) {
      print('[MessagingManager] ❌ Erreur création conversation: $e');
      rethrow;
    }
  }

  /// Crée une conversation de groupe
  Future<Conversation> createGroupConversation({
    required String title,
    required List<String> participantNodeIds,
    String? description,
    String? avatarPath,
  }) async {
    try {
      final conversationId = const Uuid().v4();
      final participants = [...participantNodeIds, _currentNodeId]..sort();

      final now = DateTime.now().millisecondsSinceEpoch;
      final conversation = Conversation(
        conversationId: conversationId,
        typeValue: ConversationType.group.index,
        title: title,
        description: description,
        avatarPath: avatarPath,
        participantNodeIds: participants.join(','),
        creatorNodeId: _currentNodeId,
        createdTimestamp: now,
        lastActivityTimestamp: now,
      );

      _objectBox.conversationBox.put(conversation);

      // Ajouter les participants
      for (final nodeId in participants) {
        final participant = ConversationParticipant(
          conversationId: conversationId,
          nodeId: nodeId,
          role: nodeId == _currentNodeId ? 'admin' : 'member',
          joinedTimestamp: now,
          displayName: null,
        );
        _objectBox.conversationParticipantBox.put(participant);
      }

      // Ajouter message système
      await _addSystemMessage(
          conversationId, 'Groupe créé par $_currentNodeId');

      _conversationUpdateController.add(conversation);
      notifyListeners();

      print('[MessagingManager] ✅ Groupe créé: $conversationId');
      return conversation;
    } catch (e) {
      print('[MessagingManager] ❌ Erreur création groupe: $e');
      rethrow;
    }
  }

  // ========================================================================
  // REQUÊTES
  // ========================================================================

  /// Récupère les conversations actives
  List<Conversation> getActiveConversations() {
    return _objectBox.conversationBox.getActiveConversations();
  }

  /// Récupère les conversations avec messages non lus
  List<Conversation> getConversationsWithUnread() {
    return _objectBox.conversationBox.getConversationsWithUnread();
  }

  /// Récupère les messages d'une conversation
  List<Message> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _objectBox.messageBox.getConversationMessages(
      conversationId,
      limit: limit,
      offset: offset,
    );
  }

  /// Récupère un message spécifique
  Message? getMessage(String messageId) {
    return _objectBox.messageBox
        .query(Message_.messageId.equals(messageId))
        .build()
        .findFirst();
  }

  /// Récupère une conversation spécifique
  Conversation? getConversation(String conversationId) {
    return _objectBox.conversationBox
        .query(Conversation_.conversationId.equals(conversationId))
        .build()
        .findFirst();
  }

  /// Recherche les messages
  List<Message> searchMessages(
    String query, {
    String? conversationId,
  }) {
    return _objectBox.messageBox
        .searchMessages(query, conversationId: conversationId);
  }

  // ========================================================================
  // HELPERS PRIVÉS
  // ========================================================================

  Future<void> _updateConversationLastMessage(
    String conversationId,
    Message message,
  ) async {
    final conversation = getConversation(conversationId);
    if (conversation == null) {
      print('[MessagingManager] ⚠️ Conversation non trouvée: $conversationId');
      return;
    }

    conversation.lastMessageId = message.messageId;
    conversation.lastMessagePreview = _getMessagePreview(message);
    conversation.lastActivityTimestamp = message.sentTimestamp;
    conversation.messageCount++;

    if (message.fromNodeId != _currentNodeId) {
      conversation.unreadCount++;
    }

    _objectBox.conversationBox.put(conversation);
    _conversationUpdateController.add(conversation);
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.audio:
        return '🎤 Message audio';
      case MessageType.video:
        return '🎥 Message vidéo';
      case MessageType.image:
        return '🖼️ Image';
      case MessageType.file:
        final data = jsonDecode(message.content) as Map<String, dynamic>;
        return '📎 ${data['fileName'] ?? 'Fichier'}';
    }
  }

  void _queueMessageForSync(
    String messageId,
    String operation,
    String conversationId,
  ) {
    try {
      final conversation = getConversation(conversationId);
      if (conversation == null) return;

      final participants = conversation.getParticipants();
      final targetNodeIds =
          participants.where((id) => id != _currentNodeId).toList();

      if (targetNodeIds.isEmpty) return;

      final syncQueue = MessageSyncQueue(
        messageId: messageId,
        operation: operation,
        targetNodeIds: jsonEncode(targetNodeIds),
        createdTimestamp: DateTime.now().millisecondsSinceEpoch,
        status: 'pending',
        priority: 5,
      );

      _objectBox.messageSyncQueueBox.put(syncQueue);
      print('[MessagingManager] 📋 Message ajouté à la queue: $messageId');
    } catch (e) {
      print('[MessagingManager] ❌ Erreur queue sync: $e');
    }
  }

  void _queueReceiptForSync(
    String messageId,
    String conversationId,
    String fromNodeId,
  ) {
    try {
      final receipt = MessageReceipt(
        messageId: messageId,
        recipientNodeId: _currentNodeId,
        statusValue: MessageStatus.delivered.index,
        confirmedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      _objectBox.messageReceiptBox.put(receipt);
      print('[MessagingManager] ✅ Reçu créé: $messageId');
    } catch (e) {
      print('[MessagingManager] ❌ Erreur création reçu: $e');
    }
  }

  Future<void> _addSystemMessage(
    String conversationId,
    String content,
  ) async {
    final messageId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      fromNodeId: 'system',
      typeValue: MessageType.text.index,
      content: content,
      sentTimestamp: now,
      statusValue: MessageStatus.delivered.index,
    );

    _objectBox.messageBox.put(message);
    await _updateConversationLastMessage(conversationId, message);
  }

  String _calculateContentHash(Message message) {
    final hashInput =
        '${message.messageId}:${message.content}:${message.sentTimestamp}';
    return sha256.convert(hashInput.codeUnits).toString();
  }

  String _getMimeType(MessageType type) {
    switch (type) {
      case MessageType.audio:
        return 'audio/mpeg';
      case MessageType.video:
        return 'video/mp4';
      case MessageType.image:
        return 'image/jpeg';
      case MessageType.file:
        return 'application/octet-stream';
      default:
        return 'text/plain';
    }
  }

  void _recalculateUnreadCount() {
    final unreadMessages = _objectBox.messageBox
        .query(Message_.statusValue.lessThan(MessageStatus.read.index))
        .and(Message_.fromNodeId.notEqual(_currentNodeId))
        .build()
        .find();

    _totalUnreadMessages = unreadMessages.length;
  }

  /// Statistiques du système de messaging
  Map<String, dynamic> getStats() {
    return {
      'totalMessagesSent': _totalMessagesSent,
      'totalMessagesReceived': _totalMessagesReceived,
      'totalUnreadMessages': _totalUnreadMessages,
      'conversationsCount': _objectBox.conversationBox.count(),
      'messagesCount': _objectBox.messageBox.count(),
    };
  }

  void dispose() {
    _messageReceivedController.close();
    _conversationUpdateController.close();
    _messageStatusChangeController.close();
  }
}

// ============================================================================
// MESSAGE STATUS UPDATE MODEL
// ============================================================================
class MessageStatusUpdate {
  final String messageId;
  final MessageStatus status;
  final int timestamp;

  MessageStatusUpdate({
    required this.messageId,
    required this.status,
    required this.timestamp,
  });
}
