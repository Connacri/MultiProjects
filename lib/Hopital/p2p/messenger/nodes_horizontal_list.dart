import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'NodesManager.dart';
import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';

/// Widget affichant les nœuds disponibles en liste horizontale style Facebook
class NodesHorizontalList extends StatefulWidget {
  const NodesHorizontalList({Key? key}) : super(key: key);

  @override
  State<NodesHorizontalList> createState() => _NodesHorizontalListState();
}

class _NodesHorizontalListState extends State<NodesHorizontalList> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Rafraîchir les nœuds au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNodes();
    });
  }

  Future<void> _refreshNodes() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await NodesManager().refreshNodes();
    } catch (e) {
      print('[NodesHorizontalList] Erreur refresh: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = NodesManager().availableNodes;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Nœuds disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${nodes.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: _isRefreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue[700],
                          ),
                        )
                      : Icon(Icons.refresh, color: Colors.blue[700]),
                  onPressed: _isRefreshing ? null : _refreshNodes,
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste horizontale des nœuds
          SizedBox(
            height: 120,
            child: nodes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return _buildNodeAvatar(context, node);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Aucun nœud découvert',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Rafraîchir'),
            onPressed: _refreshNodes,
          ),
        ],
      ),
    );
  }

  Widget _buildNodeAvatar(BuildContext context, NetworkNode node) {
    // Obtenir les initiales
    final initials = node.displayName.isNotEmpty
        ? node.displayName.substring(0, 1).toUpperCase()
        : '?';

    // Couleur de fond basée sur le hash du nodeId
    final colorIndex = node.nodeId.hashCode % 10;
    final avatarColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    final avatarColor = avatarColors[colorIndex.abs()];

    return GestureDetector(
      onTap: () => _openConversation(context, node),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar avec indicateur de statut
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.status == NodeStatus.online
                          ? Colors.green
                          : Colors.grey[300]!,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: avatarColor.withOpacity(0.2),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                // Indicateur de statut (point vert/gris)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: node.statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Nom du nœud
            SizedBox(
              width: 80,
              child: Text(
                node.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openConversation(BuildContext context, NetworkNode node) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Ouverture de la conversation...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // ✅ Utiliser le context original (pas celui du loading dialog)
      final messagingManager = context.read<MessagingManager>();

      // Créer ou récupérer la conversation
      final conversation = await messagingManager.createPrivateConversation(
        node.nodeId,
        displayName: node.displayName,
      );

      if (mounted) {
        // Fermer le loading
        Navigator.pop(context);

        // Marquer comme lue
        await messagingManager
            .markConversationAsRead(conversation.conversationId);

        // Ouvrir la conversation
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (newContext) => ConversationDialog(
              conversation: conversation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fermer le loading
        Navigator.pop(context);

        // Afficher l'erreur
        showDialog(
          context: context,
          builder: (errorContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Erreur'),
              ],
            ),
            content: Text(
              'Impossible d\'ouvrir la conversation avec ${node.displayName}:\n$e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(errorContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      print('[NodesHorizontalList] Erreur ouverture conversation: $e');
    }
  }
}
