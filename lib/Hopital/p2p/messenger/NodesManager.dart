import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'messaging_entities.dart';
import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';

// ============================================================================
// NOEUDS MANAGER - Gère la liste des nœuds découverts
// ============================================================================
class NodesManager {
  static final NodesManager _instance = NodesManager._internal();

  factory NodesManager() => _instance;

  NodesManager._internal();

  // Liste des nœuds disponibles sur le réseau
  final List<NetworkNode> _availableNodes = [
    NetworkNode(
      nodeId: 'node-001-hospital-paris',
      displayName: 'Hopital Paris Central',
      status: NodeStatus.online,
      lastSeen: DateTime.now(),
    ),
    NetworkNode(
      nodeId: 'node-002-clinic-lyon',
      displayName: 'Clinic Lyon',
      status: NodeStatus.online,
      lastSeen: DateTime.now(),
    ),
    NetworkNode(
      nodeId: 'node-003-medical-marseille',
      displayName: 'Medical Center Marseille',
      status: NodeStatus.offline,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NetworkNode(
      nodeId: 'node-004-clinic-toulouse',
      displayName: 'Clinic Toulouse',
      status: NodeStatus.online,
      lastSeen: DateTime.now(),
    ),
  ];

  List<NetworkNode> get availableNodes => _availableNodes;

// Dans une app réelle, cette liste viendrait du ConnectionManager
// ou du P2PIntegration qui découvre les nœuds sur le réseau
}

// ============================================================================
// NETWORK NODE MODEL
// ============================================================================
enum NodeStatus { online, offline, idle }

class NetworkNode {
  final String nodeId;
  final String displayName;
  final NodeStatus status;
  final DateTime lastSeen;
  final String? avatarUrl;

  NetworkNode({
    required this.nodeId,
    required this.displayName,
    required this.status,
    required this.lastSeen,
    this.avatarUrl,
  });

  String get statusLabel {
    switch (status) {
      case NodeStatus.online:
        return 'En ligne';
      case NodeStatus.offline:
        return 'Hors ligne';
      case NodeStatus.idle:
        return 'Inactif';
    }
  }

  Color get statusColor {
    switch (status) {
      case NodeStatus.online:
        return Colors.green;
      case NodeStatus.offline:
        return Colors.grey;
      case NodeStatus.idle:
        return Colors.orange;
    }
  }
}

// ============================================================================
// SELECT NODE DIALOG - Afficher liste des nœuds disponibles
// ============================================================================
class SelectNodeDialog extends StatefulWidget {
  const SelectNodeDialog({Key? key}) : super(key: key);

  @override
  State<SelectNodeDialog> createState() => _SelectNodeDialogState();
}

class _SelectNodeDialogState extends State<SelectNodeDialog> {
  late TextEditingController _searchController;
  List<NetworkNode> _filteredNodes = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredNodes = NodesManager().availableNodes;
    _searchController.addListener(_filterNodes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterNodes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNodes = NodesManager()
          .availableNodes
          .where((node) =>
              node.displayName.toLowerCase().contains(query) ||
              node.nodeId.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    const Text(
                      'Sélectionner un nœud',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un nœud...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterNodes();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Liste des nœuds
          Expanded(
            child: _filteredNodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun nœud trouvé',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredNodes.length,
                    itemBuilder: (context, index) {
                      final node = _filteredNodes[index];
                      return _buildNodeTile(context, node);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeTile(BuildContext context, NetworkNode node) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: node.statusColor.withOpacity(0.2),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Text(
              node.displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: node.statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: node.statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      ),
      title: Text(node.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node.nodeId,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            node.statusLabel,
            style: TextStyle(
              fontSize: 11,
              color: node.statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: node.status == NodeStatus.online
          ? () => _createConversation(context, node)
          : null,
      enabled: node.status == NodeStatus.online,
    );
  }

  Future<void> _createConversation(
    BuildContext context,
    NetworkNode node,
  ) async {
    try {
      // Créer une conversation privée avec le nœud
      final conversation =
          await context.read<MessagingManager>().createPrivateConversation(
                node.nodeId,
                displayName: node.displayName,
              );

      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialog de sélection
        // Ouvrir la conversation
        _showConversationDialog(context, conversation);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showConversationDialog(
      BuildContext context, Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => ConversationDialog(conversation: conversation),
    );
  }
}

// ============================================================================
// NODES LIST SCREEN - Affichage des nœuds connus
// ============================================================================
class NodesListScreen extends StatefulWidget {
  const NodesListScreen({Key? key}) : super(key: key);

  @override
  State<NodesListScreen> createState() => _NodesListScreenState();
}

class _NodesListScreenState extends State<NodesListScreen> {
  late TextEditingController _searchController;
  List<NetworkNode> _filteredNodes = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredNodes = NodesManager().availableNodes;
    _searchController.addListener(_filterNodes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterNodes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNodes = NodesManager()
          .availableNodes
          .where((node) =>
              node.displayName.toLowerCase().contains(query) ||
              node.nodeId.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineNodes =
        _filteredNodes.where((n) => n.status == NodeStatus.online).toList();
    final offlineNodes =
        _filteredNodes.where((n) => n.status != NodeStatus.online).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nœuds du réseau'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un nœud...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterNodes();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Liste des nœuds
          Expanded(
            child: ListView(
              children: [
                // Nœuds en ligne
                if (onlineNodes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'En ligne (${onlineNodes.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ...onlineNodes.map((node) => _buildNodeTile(context, node)),
                // Nœuds hors ligne
                if (offlineNodes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      'Hors ligne (${offlineNodes.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ...offlineNodes.map((node) => _buildNodeTile(context, node)),
                if (_filteredNodes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun nœud trouvé',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeTile(BuildContext context, NetworkNode node) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: node.statusColor.withOpacity(0.2),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Text(
              node.displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: node.statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: node.statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      ),
      title: Text(node.displayName),
      subtitle: Text(
        node.statusLabel,
        style: TextStyle(
          fontSize: 12,
          color: node.statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: node.status == NodeStatus.online
          ? ElevatedButton.icon(
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Écrire'),
              onPressed: () => _startConversation(context, node),
            )
          : Icon(Icons.circle, size: 8, color: node.statusColor),
    );
  }

  Future<void> _startConversation(
    BuildContext context,
    NetworkNode node,
  ) async {
    try {
      final conversation =
          await context.read<MessagingManager>().createPrivateConversation(
                node.nodeId,
                displayName: node.displayName,
              );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ConversationDialog(conversation: conversation),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
