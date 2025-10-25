import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../objectBox/Entity.dart';
import '../../../objectBox/classeObjectBox.dart';
import '../../../objectbox.g.dart';

/// 📱 MessagingProvider - Singleton avec ChangeNotifier
class MessagingProvider with ChangeNotifier {
  late final ObjectBox _objectBox;
  late String _currentNodeId;
  bool _initialized = false;

  // Statistiques
  int _totalMessagesSent = 0;
  int _totalMessagesReceived = 0;
  int _totalUnreadMessages = 0;

  // Getters
  bool get initialized => _initialized;

  int get totalMessagesSent => _totalMessagesSent;

  int get totalMessagesReceived => _totalMessagesReceived;

  int get totalUnreadMessages => _totalUnreadMessages;

  // StreamControllers pour notifications
  final _messageReceivedController = StreamController<Message>.broadcast();
  final _conversationUpdateController =
      StreamController<Conversation>.broadcast();

  Stream<Message> get onMessageReceived => _messageReceivedController.stream;

  Stream<Conversation> get onConversationUpdate =>
      _conversationUpdateController.stream;

  MessagingProvider() {
    _initObjectBox();
  }

  /// Initialisation ObjectBox
  Future<void> _initObjectBox() async {
    try {
      _objectBox = ObjectBox();
      _initialized = true;
      notifyListeners();
      print('[MessagingProvider] ✅ Initialisé');
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur initialisation: $e');
    }
  }

  /// Initialise le provider avec le nodeId courant
  Future<void> initialize(String nodeId) async {
    try {
      _currentNodeId = nodeId;
      _recalculateUnreadCount();
      print('[MessagingProvider] ✅ Initialisé avec nodeId: $_currentNodeId');
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur: $e');
    }
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

  /// Envoie un message avec fichier
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

    return _sendMessage(
      conversationId: conversationId,
      type: type,
      content: jsonEncode(contentJson),
      mediaPath: mediaFile.path,
      mediaSize: fileSize,
      mediaMimeType: mimeType,
      mediaDuration: durationSeconds,
      replyToMessageId: replyToMessageId,
    );
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
      final messageId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      final message = Message(
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

      message.contentHash = _calculateContentHash(message);
      _objectBox.messageBox.put(message);

      await _updateConversationLastMessage(conversationId, message);
      _queueMessageForSync(messageId, 'send', conversationId);

      _totalMessagesSent++;
      notifyListeners();

      print('[MessagingProvider] 📤 Message envoyé: $messageId');
      return message;
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur envoi: $e');
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
        return;
      }

      // Vérifier si existe déjà
      final existing = _objectBox.messageBox
          .query(Message_.messageId.equals(messageId))
          .build()
          .findFirst();
      if (existing != null) return;

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
      );

      _objectBox.messageBox.put(message);
      await _updateConversationLastMessage(conversationId, message);
      _queueReceiptForSync(messageId, conversationId, fromNodeId);

      _totalMessagesReceived++;
      _totalUnreadMessages++;

      _messageReceivedController.add(message);
      notifyListeners();

      print('[MessagingProvider] 📥 Message reçu: $messageId');
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur réception: $e');
    }
  }

  // ========================================================================
  // GESTION DES CONVERSATIONS
  // ========================================================================

  /// Crée une conversation privée 1-à-1
  Future<Conversation> createPrivateConversation(
    String otherNodeId, {
    String? displayName,
  }) async {
    try {
      final participants = [_currentNodeId, otherNodeId]..sort();
      final conversationId = participants.join('-');

      var existing = _objectBox.conversationBox
          .query(Conversation_.conversationId.equals(conversationId))
          .build()
          .findFirst();

      if (existing != null) return existing;

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

      print('[MessagingProvider] ✅ Conversation privée créée: $conversationId');
      return conversation;
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur création conversation: $e');
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

      for (final nodeId in participants) {
        final participant = ConversationParticipant(
          conversationId: conversationId,
          nodeId: nodeId,
          role: nodeId == _currentNodeId ? 'admin' : 'member',
          joinedTimestamp: now,
        );
        _objectBox.conversationParticipantBox.put(participant);
      }

      _conversationUpdateController.add(conversation);
      notifyListeners();

      print('[MessagingProvider] ✅ Groupe créé: $conversationId');
      return conversation;
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur création groupe: $e');
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
  List<Message> searchMessages(String query, {String? conversationId}) {
    return _objectBox.messageBox
        .searchMessages(query, conversationId: conversationId);
  }

  /// Marque une conversation comme lue
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final conversation = getConversation(conversationId);
      if (conversation == null) return;

      final msgQuery = _objectBox.messageBox
          .query(Message_.conversationId.equals(conversationId) &
              Message_.statusValue.lessThan(MessageStatus.read.index))
          .build();

      final messages = msgQuery.find();
      msgQuery.close(); // ⚡ Important : toujours fermer la query

      final now = DateTime.now().millisecondsSinceEpoch;
      for (final msg in messages) {
        msg.status = MessageStatus.read;
        msg.readTimestamp = now;
      }

      _objectBox.messageBox.putMany(messages);

      conversation.unreadCount = 0;
      _objectBox.conversationBox.put(conversation);

      _recalculateUnreadCount();
      _conversationUpdateController.add(conversation);
      notifyListeners();

      print('[MessagingProvider] ✅ Conversation marquée lue: $conversationId');
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur marquage lecture: $e');
    }
  }

  // ========================================================================
  // HELPERS PRIVÉS
  // ========================================================================

  Future<void> _updateConversationLastMessage(
    String conversationId,
    Message message,
  ) async {
    final conversation = getConversation(conversationId);
    if (conversation == null) return;

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
      print('[MessagingProvider] 📋 Message ajouté à la queue: $messageId');
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur queue sync: $e');
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
    } catch (e) {
      print('[MessagingProvider] ❌ Erreur création reçu: $e');
    }
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
    final query = _objectBox.messageBox
        .query(Message_.statusValue.lessThan(MessageStatus.read.index) &
                Message_.fromNodeId
                    .notEquals(_currentNodeId) // ✅ notEquals avec 's'
            )
        .build();

    final unreadMessages = query.find();
    query.close(); // ⚡ Important : toujours fermer la query

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

  @override
  void dispose() {
    _messageReceivedController.close();
    _conversationUpdateController.close();
    super.dispose();
  }
}
