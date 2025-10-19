import '../../../objectBox/classeObjectBox.dart';
import '../../../objectbox.g.dart';

// ============================================================================
// ENTITIES MESSAGING P2P - À utiliser avec ObjectBox generator
// ============================================================================

/// État du message (workflow)
enum MessageStatus {
  pending, // Envoyé, en attente de confirmation
  sent, // Confirmé envoyé
  delivered, // Reçu par le destinataire
  read, // Lu par le destinataire
  failed, // Échec d'envoi
}

/// Type de message
enum MessageType {
  text, // Texte simple
  audio, // Fichier audio
  video, // Fichier vidéo
  file, // Fichier générique
  image, // Image
}

/// Type de conversation
enum ConversationType {
  private, // 1-à-1
  group, // Groupe
}

// ============================================================================
// MESSAGE ENTITY - Table principale des messages
// ============================================================================
@Entity()
class Message {
  int id = 0;

  /// Identifiant unique du message (UUID)
  @Unique()
  String messageId;

  /// ID de la conversation (conversationId)
  String conversationId;

  /// ID du nœud émetteur
  String fromNodeId;

  /// ID du nœud destinataire (NULL pour groupe)
  String? toNodeId;

  /// Type de contenu
  int typeValue; // MessageType.index

  /// Contenu (JSON pour médias, texte brut pour texte)
  String content;

  /// Chemin local du fichier (audio, vidéo, etc.)
  String? mediaPath;

  /// Taille du fichier en bytes
  int? mediaSize;

  /// MIME type du fichier
  String? mediaMimeType;

  /// Durée audio/vidéo en secondes (si applicable)
  int? mediaDuration;

  /// Timestamp d'envoi (ms depuis epoch)
  int sentTimestamp;

  /// Timestamp de réception (ms depuis epoch)
  int? receivedTimestamp;

  /// Timestamp de lecture (ms depuis epoch)
  int? readTimestamp;

  /// Statut du message
  int statusValue; // MessageStatus.index

  /// Si c'est une réponse à un autre message
  String? replyToMessageId;

  /// Contenu du message d'origine (cache pour l'affichage du thread)
  String? replyToContent;

  /// Auteur du message d'origine
  String? replyToFromNodeId;

  /// Marqué comme favori/épinglé
  bool isFavorite = false;

  /// Marqué comme supprimé (soft delete)
  bool isDeleted = false;

  /// Clé de chiffrement (pour audit)
  String? encryptionKeyId;

  /// Hash du contenu (pour vérifier l'intégrité)
  String? contentHash;

  /// Tentatives d'envoi
  int sendAttempts = 0;

  /// Dernier message d'erreur (si applicable)
  String? lastErrorMessage;

  Message({
    required this.messageId,
    required this.conversationId,
    required this.fromNodeId,
    required this.typeValue,
    required this.content,
    required this.sentTimestamp,
    required this.statusValue,
    this.toNodeId,
    this.mediaPath,
    this.mediaSize,
    this.mediaMimeType,
    this.mediaDuration,
    this.receivedTimestamp,
    this.readTimestamp,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToFromNodeId,
    this.isFavorite = false,
    this.isDeleted = false,
    this.encryptionKeyId,
    this.contentHash,
    this.sendAttempts = 0,
    this.lastErrorMessage,
  });

  MessageStatus get status => MessageStatus.values[statusValue];

  set status(MessageStatus value) => statusValue = value.index;

  MessageType get type => MessageType.values[typeValue];

  set type(MessageType value) => typeValue = value.index;
}

// ============================================================================
// CONVERSATION ENTITY - Table des conversations
// ============================================================================
@Entity()
class Conversation {
  int id = 0;

  /// Identifiant unique de la conversation (UUID)
  @Unique()
  String conversationId;

  /// Type de conversation (privée ou groupe)
  int typeValue; // ConversationType.index

  /// Titre (pour les groupes)
  String? title;

  /// Description (pour les groupes)
  String? description;

  /// Photo/avatar de la conversation
  String? avatarPath;

  /// Participants (JSON: List<String> de nodeIds)
  String participantNodeIds; // "nodeId1,nodeId2,nodeId3"

  /// Créateur de la conversation
  String creatorNodeId;

  /// Timestamp de création
  int createdTimestamp;

  /// Timestamp de la dernière activité
  int lastActivityTimestamp;

  /// ID du dernier message (pour aperçu)
  String? lastMessageId;

  /// Contenu du dernier message (cache pour liste)
  String? lastMessagePreview;

  /// Nombre total de messages non lus
  int unreadCount = 0;

  /// Nombre total de messages
  int messageCount = 0;

  /// Conversation archivée
  bool isArchived = false;

  /// Conversation supprimée (soft delete)
  bool isDeleted = false;

  /// Conversation épinglée
  bool isPinned = false;

  /// Notification désactivée
  bool isMuted = false;

  /// Dernière synchronisation (timestamp)
  int lastSyncTimestamp = 0;

  /// Métadonnées (JSON)
  String? metadata;

  Conversation({
    required this.conversationId,
    required this.typeValue,
    required this.participantNodeIds,
    required this.creatorNodeId,
    required this.createdTimestamp,
    required this.lastActivityTimestamp,
    this.title,
    this.description,
    this.avatarPath,
    this.lastMessageId,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.messageCount = 0,
    this.isArchived = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.isMuted = false,
    this.lastSyncTimestamp = 0,
    this.metadata,
  });

  ConversationType get type => ConversationType.values[typeValue];

  set type(ConversationType value) => typeValue = value.index;

  List<String> getParticipants() =>
      participantNodeIds.split(',').where((p) => p.isNotEmpty).toList();

  void setParticipants(List<String> participants) {
    participantNodeIds = participants.join(',');
  }
}

// ============================================================================
// MESSAGE RECEIPT ENTITY - Suivre les confirmations de réception
// ============================================================================
@Entity()
class MessageReceipt {
  int id = 0;

  /// ID du message
  String messageId;

  /// ID du nœud destinataire
  String recipientNodeId;

  /// Statut de la confirmation
  int statusValue; // MessageStatus.index (delivered, read)

  /// Timestamp de confirmation
  int confirmedTimestamp;

  /// Hash du message (pour vérifier l'intégrité)
  String? messageHash;

  MessageReceipt({
    required this.messageId,
    required this.recipientNodeId,
    required this.statusValue,
    required this.confirmedTimestamp,
    this.messageHash,
  });

  MessageStatus get status => MessageStatus.values[statusValue];

  set status(MessageStatus value) => statusValue = value.index;
}

// ============================================================================
// CONVERSATION PARTICIPANT ENTITY - Détails des participants
// ============================================================================
@Entity()
class ConversationParticipant {
  int id = 0;

  /// ID de la conversation
  String conversationId;

  /// ID du nœud participant
  String nodeId;

  /// Nom d'affichage du participant
  String? displayName;

  /// Rôle du participant (admin, member)
  String role; // 'admin', 'member'

  /// Timestamp d'ajout à la conversation
  int joinedTimestamp;

  /// Timestamp de départ (NULL si toujours membre)
  int? leftTimestamp;

  /// Notifications activées pour ce participant
  bool notificationsEnabled = true;

  /// Dernier message lu par ce participant
  String? lastReadMessageId;

  /// Timestamp du dernier accès
  int? lastAccessTimestamp;

  ConversationParticipant({
    required this.conversationId,
    required this.nodeId,
    required this.role,
    required this.joinedTimestamp,
    this.displayName,
    this.leftTimestamp,
    this.notificationsEnabled = true,
    this.lastReadMessageId,
    this.lastAccessTimestamp,
  });
}

// ============================================================================
// MESSAGE SYNC QUEUE ENTITY - Queue pour synchronisation
// ============================================================================
@Entity()
class MessageSyncQueue {
  int id = 0;

  /// ID du message à synchroniser
  String messageId;

  /// Type d'opération (send, resend, delete)
  String operation; // 'send', 'resend', 'delete', 'sync'

  /// Destinataires (JSON List<String>)
  String targetNodeIds;

  /// Nombre de tentatives
  int attemptCount = 0;

  /// Timestamp de création
  int createdTimestamp;

  /// Timestamp de la prochaine tentative
  int? nextRetryTimestamp;

  /// Statut de la queue
  String status; // 'pending', 'in_progress', 'completed', 'failed'

  /// Message d'erreur
  String? errorMessage;

  /// Priorité (1-10, 10 = plus haute)
  int priority = 5;

  MessageSyncQueue({
    required this.messageId,
    required this.operation,
    required this.targetNodeIds,
    required this.createdTimestamp,
    this.attemptCount = 0,
    this.nextRetryTimestamp,
    this.status = 'pending',
    this.errorMessage,
    this.priority = 5,
  });
}

// ============================================================================
// MESSAGE SEARCH INDEX ENTITY - Indexation pour recherche rapide
// ============================================================================
@Entity()
class MessageSearchIndex {
  int id = 0;

  /// ID du message original
  String messageId;

  /// Conversation ID
  String conversationId;

  /// Contenu indexé (tokenisé)
  String searchContent;

  /// Timestamp du message
  int messageTimestamp;

  /// Type de contenu
  int typeValue; // MessageType.index

  MessageSearchIndex({
    required this.messageId,
    required this.conversationId,
    required this.searchContent,
    required this.messageTimestamp,
    required this.typeValue,
  });
}

// ============================================================================
// QUERIES HELPER - Requêtes courantes optimisées
// ============================================================================
extension MessageQueries on Box<Message> {
  /// Récupère les messages d'une conversation (paginé)
  List<Message> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) {
    final query = this
        .query(Message_.conversationId.equals(conversationId))
        .order(Message_.sentTimestamp, flags: Order.descending)
        .build();

    query.offset = offset;
    query.limit = limit;

    final results = query.find();
    query.close();
    return results;
  }

  /// Récupère les messages non lus d'une conversation
  List<Message> getUnreadMessages(String conversationId) {
    final query = this
        .query(Message_.conversationId.equals(conversationId) &
            Message_.statusValue.lessThan(MessageStatus.read.index))
        .order(Message_.sentTimestamp)
        .build();

    final results = query.find();
    query.close();
    return results;
  }

  /// Récupère les messages d'un nœud spécifique
  List<Message> getMessagesFromNode(String nodeId) {
    final query = this
        .query(Message_.fromNodeId.equals(nodeId))
        .order(Message_.sentTimestamp, flags: Order.descending)
        .build();

    final results = query.find();
    query.close();
    return results;
  }

  /// Récupère les messages en attente de confirmation
  List<Message> getPendingMessages() {
    final query = this
        .query(Message_.statusValue.equals(MessageStatus.pending.index))
        .order(Message_.sentTimestamp)
        .build();

    final results = query.find();
    query.close();
    return results;
  }

  /// Recherche par contenu
  List<Message> searchMessages(String searchQuery, {String? conversationId}) {
    Condition<Message> condition =
        Message_.content.contains(searchQuery, caseSensitive: false);

    if (conversationId != null) {
      condition = condition & Message_.conversationId.equals(conversationId);
    }

    final query = this
        .query(condition)
        .order(Message_.sentTimestamp, flags: Order.descending)
        .build();

    final results = query.find();
    query.close();
    return results;
  }
}

extension ConversationQueries on Box<Conversation> {
  /// Récupère les conversations triées par activité
  List<Conversation> getActiveConversations() {
    final query = this
        .query(Conversation_.isDeleted.equals(false))
        .order(Conversation_.lastActivityTimestamp, flags: Order.descending)
        .build();

    final results = query.find();
    query.close();
    return results;
  }

  /// Récupère les conversations non archivées avec messages non lus
  List<Conversation> getConversationsWithUnread() {
    final query = this
        .query(Conversation_.unreadCount.greaterThan(0) &
            Conversation_.isArchived.equals(false))
        .order(Conversation_.lastActivityTimestamp, flags: Order.descending)
        .build();

    final results = query.find();
    query.close();
    return results;
  }

  /// Récupère une conversation par participants (1-à-1)
  Conversation? getPrivateConversation(String nodeId1, String nodeId2) {
    final participants = [nodeId1, nodeId2]..sort();
    final participantStr = participants.join(',');

    final query = this
        .query(Conversation_.participantNodeIds.equals(participantStr) &
            Conversation_.typeValue.equals(ConversationType.private.index))
        .build();

    final result = query.findFirst();
    query.close();
    return result;
  }
}

// ============================================================================
// OBJECTBOX REFERENCE - À ajouter globalement
// ============================================================================
late ObjectBox _objectBoxInstance;

ObjectBox get objectBoxGlobal => _objectBoxInstance;
