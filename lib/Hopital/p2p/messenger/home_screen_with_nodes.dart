import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';
import 'nodes_horizontal_list.dart';

/// Page d'accueil avec liste horizontale des nœuds
class HomeScreenEnhanced extends StatefulWidget {
  const HomeScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<HomeScreenEnhanced> createState() => _HomeScreenEnhancedState();
}

class _HomeScreenEnhancedState extends State<HomeScreenEnhanced> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hôpital P2P - Messagerie'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Icône Messenger avec badge
          MessengerIconWithBadge(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ConversationsBottomSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Liste horizontale des nœuds (style Facebook)
            const NodesHorizontalList(),

            // Statistiques de messagerie
            _buildMessagingStatsCard(),

            // Section P2P Status
            _buildP2PStatusCard(),

            // Conversations récentes
            _buildRecentConversations(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Scroll vers les nœuds disponibles
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sélectionnez un nœud ci-dessus pour démarrer'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble),
        label: const Text('Nouvelle conversation'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildMessagingStatsCard() {
    return Consumer<MessagingManager>(
      builder: (context, messagingManager, _) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: messagingManager.totalUnreadMessages > 0
              ? Colors.orange[50]
              : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.message, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          if (messagingManager.totalUnreadMessages > 0)
                            Text(
                              '${messagingManager.totalUnreadMessages} non lus',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Envoyés',
                      messagingManager.totalMessagesSent.toString(),
                      Colors.blue,
                      Icons.send,
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatColumn(
                      'Reçus',
                      messagingManager.totalMessagesReceived.toString(),
                      Colors.green,
                      Icons.inbox,
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatColumn(
                      'Non lus',
                      messagingManager.totalUnreadMessages.toString(),
                      messagingManager.totalUnreadMessages > 0
                          ? Colors.orange
                          : Colors.grey,
                      Icons.mark_chat_unread,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildP2PStatusCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Statut P2P',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Serveur', '✅ Actif', Icons.check_circle, Colors.green),
            _buildInfoRow('Connexions', '3 voisins', Icons.people, Colors.blue),
            _buildInfoRow('Nœuds découverts', '5', Icons.radar, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentConversations() {
    return Consumer<MessagingManager>(
      builder: (context, messagingManager, _) {
        final conversations = messagingManager
            .getActiveConversations()
            .take(3)
            .toList();

        if (conversations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Conversations récentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ConversationsBottomSheet(),
                        );
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...conversations.map((conv) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[700],
                      child: Text(
                        conv.title?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      conv.title ?? 'Conversation',
                      style: TextStyle(
                        fontWeight: conv.unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      conv.lastMessagePreview ?? 'Aucun message',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: conv.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conv.unreadCount > 9
                                  ? '9+'
                                  : conv.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => ConversationDialog(
                            conversation: conv,
                          ),
                        ),
                      );
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
