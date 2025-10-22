import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../../objectBox/Entity.dart';
import '../../widgets.dart';
import 'NodesManager.dart';
import 'fonctions.dart';
import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';
import 'metadata_diagnostic_ui.dart';
import 'node_metadata_manager.dart';

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
  late NodeMetadataManager _metadataManager;

  List<NetworkNode> _filteredNodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterNodes);
    _metadataManager = NodeMetadataManager();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNodes();
      _setupMetadataManager();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ Configuration du gestionnaire de métadonnées
  void _setupMetadataManager() {
    try {
      // Écouter les changements de métadonnées
      _metadataManager.addListener(_onMetadataChanged);

      print('[SelectNodePage] ✅ Gestionnaire de métadonnées configuré');
    } catch (e) {
      print('[SelectNodePage] ⚠️ Erreur setup metadata manager: $e');
    }
  }

  /// ✅ Callback quand les métadonnées changent
  void _onMetadataChanged() {
    if (mounted) {
      setState(() {
        // Force le rebuild pour afficher les nouvelles métadonnées
      });
      print('[SelectNodePage] 🔄 Métadonnées mises à jour, rebuild UI');
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

      // ✅ Demander les métadonnées de tous les nouveaux nœuds
      await _metadataManager.refreshAllMetadata();

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
    print('[SelectNodePage] 💬 Création conversation avec ${node.displayName}');

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

  /// ✅ Construction du tile avec métadonnées du gestionnaire
  Widget _buildNodeTile(BuildContext context, NetworkNode node) {
    // ✅ Récupérer les métadonnées depuis le gestionnaire
    final metadata = _metadataManager.getMetadata(node.nodeId);

    // Si métadonnées disponibles, les utiliser
    final platform = metadata?.platform ?? 'Détection...';
    final branch = metadata?.branch ?? getBranchForNode(node.nodeId);
    final hasMetadata = metadata != null;

    // ✅ Si pas de métadonnées, demander
    if (!hasMetadata && !_isLoading) {
      _metadataManager.requestMetadata(node.nodeId);
    }

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
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _createConversation(context, node),
    );
  }

  /// ✅ Icône selon la plateforme
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
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MetadataDiagnosticPage(),
                ),
              );
            },
            tooltip: 'Diagnostic Métadonnées',
          ),
          // ✅ Badge des messages non lus
          Consumer<MessagingManager>(
            builder: (context, messagingManager, _) {
              return BadgeIcon(
                icon: Icons.message,
                count: messagingManager.totalUnreadCount,
                onPressed: () => Navigator.pop(context),
                tooltip:
                    'Messages (${messagingManager.totalUnreadCount} non lus)',
                badgeColor: Colors.red,
              );
            },
          ),
          const SizedBox(width: 8),
          // ✅ Badge des métadonnées reçues
          BadgeIcon(
            icon: Icons.info_outline,
            count: _metadataManager.remoteMetadata.length,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Métadonnées P2P'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nœuds avec métadonnées: ${_metadataManager.remoteMetadata.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(),
                        ..._metadataManager.remoteMetadata.values
                            .map((metadata) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    metadata.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(_getPlatformIcon(metadata.platform),
                                          size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          metadata.platform,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (metadata.branch != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.business,
                                            size: 12, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            metadata.branch!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    'Maj: ${_formatTimestamp(metadata.lastUpdate)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _metadataManager.cleanupStaleMetadata();
                        Navigator.pop(context);
                      },
                      child: const Text('Nettoyer'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Métadonnées (${_metadataManager.remoteMetadata.length})',
            badgeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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

  /// ✅ Formater le timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'il y a ${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes}m';
    } else {
      return 'il y a ${diff.inHours}h';
    }
  }
}
