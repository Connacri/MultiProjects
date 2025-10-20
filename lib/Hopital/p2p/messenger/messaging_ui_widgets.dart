import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'messaging_entities.dart';
import 'messaging_manager.dart';

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
// CONVERSATIONS BOTTOM SHEET
// ============================================================================
class ConversationsBottomSheet extends StatefulWidget {
  const ConversationsBottomSheet({Key? key}) : super(key: key);

  @override
  State<ConversationsBottomSheet> createState() =>
      _ConversationsBottomSheetState();
}

class _ConversationsBottomSheetState extends State<ConversationsBottomSheet> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Widget _buildConversationTile(BuildContext context, Conversation conv) {
    final timeFormat = DateFormat('HH:mm');
    final lastTime = DateTime.fromMillisecondsSinceEpoch(
      conv.lastActivityTimestamp,
    );

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
            child: Text(
              conv.title ?? 'Conversation',
              style: TextStyle(
                fontWeight:
                    conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
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
// CONVERSATION DIALOG - Maintenant une page complète
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
  int _offset = 0;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Marquer comme lue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<MessagingManager>()
            .markConversationAsRead(widget.conversation.conversationId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.conversation.title ?? 'Conversation'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Afficher détails conversation
                },
              ),
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
}
