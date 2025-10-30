import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../objectBox/Entity.dart';
import 'fonctions.dart';
import 'messaging_manager.dart';
import 'node_metadata_manager.dart';

// ============================================================================
// MESSENGER ICON WITH BADGE - AppBar Icon
// ============================================================================
class MessengerIconWithBadge extends StatelessWidget {
  final VoidCallback onPressed;

  const MessengerIconWithBadge({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingManager>(
      builder: (context, messagingManager, _) {
        final unreadCount = messagingManager.totalUnreadMessages;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.messenger_outlined),
              onPressed: onPressed,
              tooltip: 'Messages',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// CONVERSATIONS BOTTOM SHEET - CORRIGÉ
// ============================================================================
class ConversationsBottomSheet extends StatefulWidget {
  const ConversationsBottomSheet({Key? key}) : super(key: key);

  @override
  State<ConversationsBottomSheet> createState() =>
      _ConversationsBottomSheetState();
}

class _ConversationsBottomSheetState extends State<ConversationsBottomSheet> {
  late TextEditingController _searchController;
  late NodeMetadataManager _metadataManager;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _metadataManager = NodeMetadataManager();

    // ✅ Écouter les changements de métadonnées pour rebuild
    _metadataManager.addListener(_onMetadataChanged);
  }

  @override
  void dispose() {
    _metadataManager.removeListener(_onMetadataChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onMetadataChanged() {
    if (mounted) {
      setState(() {}); // Rebuild pour afficher les nouvelles métadonnées
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingManager>(
      builder: (context, messagingManager, _) {
        final conversationsWithUnread =
            messagingManager.getConversationsWithUnread();
        final allConversations = messagingManager.getActiveConversations();

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Messages',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher conversations...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Conversations list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Non-lues en premier
                        if (conversationsWithUnread.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              'Non lues (${conversationsWithUnread.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ...conversationsWithUnread.map(
                          (conv) => _buildConversationTile(context, conv),
                        ),
                        // Autres conversations
                        if (allConversations.length >
                            conversationsWithUnread.length)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Autres conversations',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ...allConversations
                            .where((conv) =>
                                !conversationsWithUnread.contains(conv))
                            .map(
                              (conv) => _buildConversationTile(context, conv),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ CORRIGÉ: Utilise NodeMetadataManager pour obtenir les vraies métadonnées du participant
  Widget _buildConversationTile(BuildContext context, Conversation conv) {
    final timeFormat = DateFormat('HH:mm');
    final lastTime = DateTime.fromMillisecondsSinceEpoch(
      conv.lastActivityTimestamp,
    );

    // ✅ Récupérer le participant (excluant l'utilisateur courant)
    final messagingManager = context.read<MessagingManager>();
    final participants = conv.getParticipants();
    final otherParticipants = participants
        .where((id) => id != messagingManager.currentNodeId)
        .toList();

    final participantId = otherParticipants.isNotEmpty
        ? otherParticipants.first
        : participants.first;

    // ✅ CORRECTION MAJEURE: Utiliser NodeMetadataManager pour les métadonnées distantes
    final metadata = _metadataManager.getMetadata(participantId);
    final hasMetadata = metadata != null;

    // ✅ Si métadonnées disponibles, les utiliser. Sinon, fallback
    final platform = metadata?.platform ?? 'Détection...';
    final branch = metadata?.branch ?? getBranchForNode(participantId);

    // ✅ Si pas de métadonnées, demander
    if (!hasMetadata) {
      _metadataManager.requestMetadata(participantId);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[700],
        child: Text(
          conv.title?.substring(0, 1).toUpperCase() ?? '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.title ?? 'Conversation',
                  style: TextStyle(
                    fontWeight: conv.unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      getPlatformIcon(platform),
                      size: 12,
                      color: hasMetadata ? Colors.blue[700] : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        platform,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              hasMetadata ? FontWeight.bold : FontWeight.normal,
                          color: hasMetadata ? Colors.blue[700] : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (branch != null && branch != 'No Branch') ...[
                      const Icon(Icons.business, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          branch,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                // ✅ Indicateur de métadonnées
                if (hasMetadata)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '✓ Métadonnées synchronisées',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (conv.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conv.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        conv.lastMessagePreview ?? 'Aucun message',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey,
          fontWeight:
              conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Text(
        timeFormat.format(lastTime),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.pop(context);
        _openConversationDialog(context, conv);
      },
    );
  }

  void _openConversationDialog(
      BuildContext context, Conversation conversation) {
    // ✅ Marquer comme lue avant d'ouvrir
    context
        .read<MessagingManager>()
        .markConversationAsRead(conversation.conversationId);

    // ✅ Utiliser Navigator.push avec MaterialPageRoute pour conserver le Provider
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (newContext) => ConversationDialog(conversation: conversation),
      ),
    );
  }
}

// ============================================================================
// CONVERSATION DIALOG - CORRIGÉ - Maintenant une page complète
// ============================================================================
class ConversationDialog extends StatefulWidget {
  final Conversation conversation;

  const ConversationDialog({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  State<ConversationDialog> createState() => _ConversationDialogState();
}

class _ConversationDialogState extends State<ConversationDialog> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  late NodeMetadataManager _metadataManager;
  int _offset = 0;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _metadataManager = NodeMetadataManager();

    // ✅ Écouter les changements de métadonnées
    _metadataManager.addListener(_onMetadataChanged);

    // Marquer comme lue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<MessagingManager>()
            .markConversationAsRead(widget.conversation.conversationId);

        // ✅ Demander les métadonnées du participant
        _requestParticipantMetadata();
      }
    });
  }

  @override
  void dispose() {
    _metadataManager.removeListener(_onMetadataChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMetadataChanged() {
    if (mounted) {
      setState(() {}); // Rebuild pour afficher les nouvelles métadonnées
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    setState(() {
      _offset += _pageSize;
    });
  }

  /// ✅ Demander les métadonnées du participant
  void _requestParticipantMetadata() {
    try {
      final messagingManager = context.read<MessagingManager>();
      final participants = widget.conversation.getParticipants();
      final otherParticipants = participants
          .where((id) => id != messagingManager.currentNodeId)
          .toList();

      if (otherParticipants.isNotEmpty) {
        final participantId = otherParticipants.first;
        if (!_metadataManager.hasMetadata(participantId)) {
          _metadataManager.requestMetadata(participantId);
        }
      }
    } catch (e) {
      print('[ConversationDialog] ⚠️ Erreur demande métadonnées: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Utiliser Consumer pour accéder au Provider de manière sûre
    return Consumer<MessagingManager>(
      builder: (context, messagingManager, _) {
        final messages = messagingManager.getConversationMessages(
          widget.conversation.conversationId,
          limit: _pageSize,
          offset: _offset,
        );

        // ✅ CORRECTION MAJEURE: Récupérer les métadonnées du participant distant
        final participants = widget.conversation.getParticipants();
        final otherParticipants = participants
            .where((id) => id != messagingManager.currentNodeId)
            .toList();

        final participantId = otherParticipants.isNotEmpty
            ? otherParticipants.first
            : participants.first;

        // ✅ Utiliser NodeMetadataManager pour les métadonnées distantes
        final metadata = _metadataManager.getMetadata(participantId);
        final hasMetadata = metadata != null;

        final platform = metadata?.platform ?? 'Détection...';
        final branch = metadata?.branch ?? getBranchForNode(participantId);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.title ?? 'Conversation'),
                FittedBox(
                  child: Row(
                    children: [
                      Icon(
                        getPlatformIcon(platform),
                        size: 12,
                        color: hasMetadata ? Colors.white : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        platform,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              hasMetadata ? FontWeight.bold : FontWeight.normal,
                          color: hasMetadata ? Colors.white : Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (branch != null && branch != 'No Branch') ...[
                        const Icon(Icons.business,
                            size: 12, color: Colors.greenAccent),
                        const SizedBox(width: 4),
                        Text(
                          branch,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // ✅ Bouton pour forcer le rafraîchissement des métadonnées
              IconButton(
                icon: Icon(
                  hasMetadata ? Icons.verified : Icons.sync,
                  color: hasMetadata ? Colors.greenAccent : Colors.white60,
                ),
                onPressed: () {
                  _metadataManager.requestMetadata(participantId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demande de métadonnées envoyée'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip:
                    hasMetadata ? 'Métadonnées OK' : 'Rafraîchir métadonnées',
              ),
              // IconButton(
              //   icon: const Icon(Icons.info_outline),
              //   onPressed: () {
              //     _showConversationInfo(context, participantId);
              //   },
              // ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Commencez la conversation !',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(
                              context, message, messagingManager);
                        },
                      ),
              ),
              // Input area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Votre message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: PopupMenuButton(
                            icon: const Icon(Icons.add),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.image),
                                    SizedBox(width: 12),
                                    Text('Image'),
                                  ],
                                ),
                                onTap: () => _attachImage(context),
                              ),
                              PopupMenuItem(
                                child: const Row(
                                  children: [
                                    Icon(Icons.mic),
                                    SizedBox(width: 12),
                                    Text('Audio'),
                                  ],
                                ),
                                onTap: () => _attachAudio(context),
                              ),
                            ],
                          ),
                        ),
                        maxLines: 4,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    FloatingActionButton(
                      mini: true,
                      onPressed: () => _sendMessage(context, messagingManager),
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Afficher les infos détaillées de la conversation
  void _showConversationInfo(BuildContext context, String participantId) {
    final metadata = _metadataManager.getMetadata(participantId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Informations'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('NodeId', participantId),
            const Divider(),
            if (metadata != null) ...[
              _buildInfoRow('Nom', metadata.displayName),
              _buildInfoRow('Plateforme', metadata.platform),
              if (metadata.branch != null)
                _buildInfoRow('Branche', metadata.branch!),
              _buildInfoRow('Dernière mise à jour',
                  _formatTimestamp(metadata.lastUpdate)),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Métadonnées synchronisées',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Métadonnées en cours de récupération...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (metadata == null)
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Demander métadonnées'),
              onPressed: () {
                _metadataManager.requestMetadata(participantId);
                Navigator.pop(context);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Message message,
    MessagingManager messagingManager,
  ) {
    final isFromMe = message.fromNodeId == messagingManager.currentNodeId;
    final timeFormat = DateFormat('HH:mm');
    final messageTime =
        DateTime.fromMillisecondsSinceEpoch(message.sentTimestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Align(
        alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(context, message),
          child: Column(
            crossAxisAlignment:
                isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: isFromMe ? Colors.blue[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isFromMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeFormat.format(messageTime),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    if (isFromMe)
                      Icon(
                        message.status == MessageStatus.read
                            ? Icons.done_all
                            : message.status == MessageStatus.delivered
                                ? Icons.done
                                : Icons.schedule,
                        size: 12,
                        color: message.status == MessageStatus.read
                            ? Colors.blue
                            : Colors.grey,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(
      BuildContext context, MessagingManager messagingManager) async {
    if (_messageController.text.isEmpty) return;

    try {
      await messagingManager.sendTextMessage(
        widget.conversation.conversationId,
        _messageController.text,
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier'),
              onTap: () {
                Navigator.pop(context);
                // Copier texte
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Supprimer message
              },
            ),
          ],
        ),
      ),
    );
  }

  void _attachImage(BuildContext context) {
    // Implémenter attachement image
  }

  void _attachAudio(BuildContext context) {
    // Implémenter enregistrement audio
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'il y a ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'il y a ${diff.inDays}j';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'il y a ${weeks} sem.';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return 'il y a ${months} mois';
    } else {
      final years = (diff.inDays / 365).floor();
      return 'il y a ${years} an${years > 1 ? 's' : ''}';
    }
  }
}
