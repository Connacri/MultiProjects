import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../connection_manager_fixed.dart';
import 'NodesManager.dart';
import 'fonctions.dart';
import 'messaging_entities.dart';
import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';

/// Wrapper pour ConversationDialog qui préserve le Provider
class ConversationDialogWithProvider extends StatelessWidget {
  final Conversation conversation;
  final MessagingManager messagingManager;

  const ConversationDialogWithProvider({
    Key? key,
    required this.conversation,
    required this.messagingManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MessagingManager>.value(
      value: messagingManager,
      child: ConversationDialog(
        conversation: conversation,
      ),
    );
  }
}

class SelectNodePage extends StatefulWidget {
  const SelectNodePage({Key? key}) : super(key: key);

  @override
  State<SelectNodePage> createState() => _SelectNodePageState();
}

class _SelectNodePageState extends State<SelectNodePage> {
  late TextEditingController _searchController;
  List<NetworkNode> _filteredNodes = [];
  bool _isLoading = false;

  // ✅ NOUVEAU: Cache des métadonnées des nœuds distants
  final Map<String, Map<String, dynamic>> _nodeMetadata = {};
  StreamSubscription? _metadataSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterNodes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNodes();
      _setupMetadataListener(); // ✅ Écouter les métadonnées
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _metadataSubscription?.cancel();
    super.dispose();
  }

  // ✅ NOUVEAU: Écouter les messages de métadonnées
  void _setupMetadataListener() {
    try {
      final connectionManager = context.read<ConnectionManager>();

      _metadataSubscription = connectionManager.onMessage.listen((message) {
        if (message['type'] == 'node_metadata') {
          final nodeId = message['nodeId'] as String?;
          if (nodeId != null && mounted) {
            setState(() {
              _nodeMetadata[nodeId] = {
                'displayName': message['displayName'] ?? 'Unknown',
                'platform': message['platform'] ?? 'Unknown',
                'branch': message['branch'] ?? 'No Branch',
                'timestamp': message['timestamp'] ?? 0,
              };
            });
            print('[SelectNodePage] 📥 Métadonnées reçues de $nodeId:');
            print('   Platform: ${message['platform']}');
            print('   Branch: ${message['branch']}');
          }
        }
      });

      print('[SelectNodePage] ✅ Listener de métadonnées configuré');
    } catch (e) {
      print('[SelectNodePage] ⚠️ Erreur setup listener: $e');
    }
  }

  void _loadInitialNodes() {
    if (mounted) {
      setState(() {
        _filteredNodes = NodesManager().availableNodes;
      });
    }
  }

  void _filterNodes() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredNodes = NodesManager()
            .availableNodes
            .where((node) =>
                node.displayName.toLowerCase().contains(query) ||
                node.nodeId.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  Future<void> _refreshNodes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await NodesManager().refreshNodes();
      if (mounted) {
        setState(() {
          _filteredNodes = NodesManager().availableNodes;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _createConversation(
      BuildContext context, NetworkNode node) async {
    print('[SelectNodePage] 🔄 Création conversation avec ${node.displayName}');

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => const Center(
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
      final messagingManager = context.read<MessagingManager>();
      print('[SelectNodePage] ✅ MessagingManager obtenu');

      final conversation = await messagingManager
          .createPrivateConversation(
        node.nodeId,
        displayName: node.displayName,
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'Timeout: la création de conversation a dépassé 5 secondes',
          );
        },
      );

      print(
          '[SelectNodePage] ✅ Conversation créée: ${conversation.conversationId}');

      if (navigatorKey.currentContext != null) {
        Navigator.pop(navigatorKey.currentContext!);
      }

      await messagingManager
          .markConversationAsRead(conversation.conversationId);

      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (newContext) => ConversationDialogWithProvider(
            conversation: conversation,
            messagingManager: messagingManager,
          ),
        ),
      );
    } on TimeoutException catch (e) {
      print('[SelectNodePage] ⏱️ TimeoutException: $e');
      if (navigatorKey.currentContext != null) {
        Navigator.pop(navigatorKey.currentContext!);
        _showError('Timeout: la conversation a pris trop de temps à créer');
      }
    } catch (e, stackTrace) {
      print('[SelectNodePage] ❌ Erreur: $e');
      print('[SelectNodePage] Stack: $stackTrace');
      if (navigatorKey.currentContext != null) {
        Navigator.pop(navigatorKey.currentContext!);
        _showError('Erreur création conversation: $e');
      }
    } finally {
      if (navigatorKey.currentContext != null &&
          Navigator.canPop(navigatorKey.currentContext!)) {
        Navigator.pop(navigatorKey.currentContext!);
      }
    }
  }

  // ✅ CORRECTION: Utiliser les métadonnées du nœud distant
  Widget _buildNodeTile(BuildContext context, NetworkNode node) {
    // Récupérer les métadonnées du nœud distant (pas du local!)
    final metadata = _nodeMetadata[node.nodeId];

    // Si métadonnées disponibles, les utiliser
    // Sinon, afficher "Détection..." en attendant
    final platform = metadata?['platform'] ?? 'Détection...';
    final branchFromMetadata = metadata?['branch'];

    // Fallback sur getBranchForNode si pas de métadonnées
    final branch = branchFromMetadata ?? getBranchForNode(node.nodeId);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: node.statusColor.withOpacity(0.2),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Center(
              child: Text(
                node.displayName.isNotEmpty
                    ? node.displayName.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: node.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: node.statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
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
            node.statusLabel,
            style: TextStyle(
              fontSize: 11,
              color: node.statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // ✅ Icône adaptée à la plateforme
              Icon(
                _getPlatformIcon(platform),
                size: 14,
                color:
                    platform == 'Détection...' ? Colors.grey : Colors.blue[700],
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  platform,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: platform != 'Détection...'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: platform == 'Détection...'
                        ? Colors.grey
                        : Colors.blue[700],
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
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _createConversation(context, node),
    );
  }

  // ✅ NOUVEAU: Icône selon la plateforme
  IconData _getPlatformIcon(String platform) {
    final platformLower = platform.toLowerCase();

    if (platformLower.contains('android')) {
      return Icons.android;
    } else if (platformLower.contains('ios')) {
      return Icons.apple;
    } else if (platformLower.contains('windows')) {
      return Icons.desktop_windows;
    } else if (platformLower.contains('macos')) {
      return Icons.laptop_mac;
    } else if (platformLower.contains('linux')) {
      return Icons.computer;
    } else if (platformLower.contains('web')) {
      return Icons.language;
    }

    return Icons.device_unknown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un nœud'),
        actions: [
          // ✅ Badge pour montrer combien de métadonnées reçues
          if (_nodeMetadata.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text(
                    '${_nodeMetadata.length}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  avatar: const Icon(Icons.info, size: 16),
                  backgroundColor: Colors.green[100],
                ),
              ),
            ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshNodes,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un nœud...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredNodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun nœud découvert',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assurez-vous que vos appareils sont\nsur le même réseau',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Rafraîchir'),
                          onPressed: _refreshNodes,
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
}
