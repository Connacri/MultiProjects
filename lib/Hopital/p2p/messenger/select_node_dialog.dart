import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import 'NodesManager.dart';
import 'fonctions.dart';
import 'messaging_entities.dart';
import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';

/// Wrapper pour ConversationDialog qui préserve le Provider
/// Reçoit le MessagingManager en paramètre (pas de context.read !)
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
    // Fournir le MessagingManager reçu en paramètre au nouvel écran
    // ✅ Utiliser ChangeNotifierProvider.value car MessagingManager hérite de ChangeNotifier
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNodes();
    });
    _searchController.addListener(_filterNodes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// ✅ Corrected: Use ConversationDialog instead of ConversationPage
  Future<void> _createConversation(
      BuildContext context, NetworkNode node) async {
    print('[SelectNodePage] 🔄 Création conversation avec ${node.displayName}');

    // Show loading dialog using global navigator key
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

      // Close loading dialog BEFORE navigating
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
      // Ensure dialog is always closed
      if (navigatorKey.currentContext != null &&
          Navigator.canPop(navigatorKey.currentContext!)) {
        Navigator.pop(navigatorKey.currentContext!);
      }
    }
  }

  Widget _buildNodeTile(BuildContext context, NetworkNode node) {
    return FutureBuilder<String>(
      future: getCurrentPlatform(),
      builder: (context, platformSnapshot) {
        final platform = platformSnapshot.data ?? 'Inconnu';
        final branch = getBranchForNode(node.nodeId);

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
                  const Icon(Icons.device_unknown, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    platform,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  if (branch != null) ...[
                    const Icon(Icons.account_tree, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      branch,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _createConversation(context, node),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un nœud'),
        actions: [
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
