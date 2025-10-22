import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../../objectBox/Entity.dart';
import '../../widgets.dart';
import '../connection_manager_fixed.dart';
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
  bool _metadataInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterNodes);
    _metadataManager = NodeMetadataManager();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔥 Nettoyer AVANT de charger
      print('[SelectNodePage] 🧹 Nettoyage initial...');
      NodesManager().cleanupDisconnectedNodes();

      _initializeMetadataManager();
      _loadInitialNodes();

      // 🔥 Rafraîchir automatiquement après 500ms pour s'assurer d'avoir les bons nœuds
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _refreshNodes();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _metadataManager.removeListener(_onMetadataChanged);
    super.dispose();
  }

  /// ✅ CORRECTION CRITIQUE : Initialiser le gestionnaire de métadonnées avec ConnectionManager
  Future<void> _initializeMetadataManager() async {
    try {
      // Récupérer le MessagingManager depuis le Provider
      final messagingManager = context.read<MessagingManager>();

      // Récupérer le ConnectionManager depuis votre app
      // ⚠️ IMPORTANT : Vous devez avoir accès au ConnectionManager
      // Option 1 : Via un Provider
      final connectionManager = context.read<ConnectionManager>();

      // ✅ INITIALISER avec les bonnes dépendances
      await _metadataManager.initialize(
        connectionManager,
        messagingManager.currentNodeId,
      );

      // Écouter les changements
      _metadataManager.addListener(_onMetadataChanged);

      setState(() {
        _metadataInitialized = true;
      });

      print('[SelectNodePage] ✅ Gestionnaire de métadonnées initialisé');
      print('[SelectNodePage] 📡 NodeId: ${messagingManager.currentNodeId}');
    } catch (e, stack) {
      print('[SelectNodePage] ❌ Erreur initialisation metadata manager: $e');
      print(stack);

      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur initialisation métadonnées: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      print('[SelectNodePage] 🧹 Début refresh avec nettoyage complet...');

      // 🔥 ÉTAPE 1: Nettoyer le cache local immédiatement
      setState(() {
        _filteredNodes.clear();
      });

      // 🔥 ÉTAPE 2: Nettoyer les métadonnées obsolètes
      if (_metadataInitialized) {
        _metadataManager.cleanupStaleMetadata();
        print('[SelectNodePage] 🗑️ Métadonnées nettoyées');
      }

      // 🔥 ÉTAPE 3: Nettoyer NodesManager
      NodesManager().cleanupDisconnectedNodes();
      print('[SelectNodePage] 🗑️ NodesManager nettoyé');

      // 🔥 ÉTAPE 4: Rafraîchir la liste depuis les voisins actifs
      await NodesManager().refreshNodes();

      // 🔥 ÉTAPE 5: Demander les métadonnées des nouveaux nœuds
      if (_metadataInitialized) {
        await _metadataManager.refreshAllMetadata();
      }

      // 🔥 ÉTAPE 6: Mettre à jour l'UI
      if (mounted) {
        setState(() {
          _filteredNodes = NodesManager().availableNodes;
        });
        print('[SelectNodePage] ✅ ${_filteredNodes.length} nœud(s) actif(s)');
      }
    } catch (e) {
      print('[SelectNodePage] ❌ Erreur refresh: $e');
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

  IconData getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.apple;
      case 'windows':
        return Icons.window;
      case 'linux':
        return Icons.laptop;
      default:
        return Icons.device_unknown;
    }
  }

  /// ✅ Construction du tile avec métadonnées du gestionnaire
  Widget _buildNodeTile(BuildContext context, NetworkNode node) {
    // ✅ Récupérer les métadonnées depuis le gestionnaire
    final metadata =
        _metadataInitialized ? _metadataManager.getMetadata(node.nodeId) : null;

    // Si métadonnées disponibles, les utiliser
    final platform = metadata?.platform ?? 'Détection...';
    final branch = metadata?.branch ?? getBranchForNode(node.nodeId);
    final hasMetadata = metadata != null;

    // ✅ Si pas de métadonnées ET initialisé, demander
    if (!hasMetadata && _metadataInitialized && !_isLoading) {
      _metadataManager.requestMetadata(node.nodeId);
    }
    final Color baseColor = node.statusColor;
    final Color bgColor = baseColor.withOpacity(0.08);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _createConversation(context, node),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ Avatar avec badge de statut
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: bgColor,
                  child: Text(
                    node.displayName.isNotEmpty
                        ? node.displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: baseColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // ✅ Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne principale : nom + badge branche
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          node.displayName.isNotEmpty
                              ? node.displayName
                              : 'Nœud inconnu',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (branch != null && branch != 'No Branch') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 0.8),
                          ),
                          child: Text(
                            branch!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ✅ Plateforme et métadonnées
                  Row(
                    children: [
                      Icon(
                        getPlatformIcon(platform),
                        size: 14,
                        color: hasMetadata
                            ? Colors.blueAccent
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        platform,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasMetadata
                              ? Colors.blueAccent
                              : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        node.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: baseColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ✅ Métadonnées
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: hasMetadata
                        ? Text(
                            '✓ Métadonnées synchronisées',
                            key: const ValueKey('meta_ok'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : _metadataInitialized
                            ? Text(
                                '⏳ En attente de métadonnées...',
                                key: const ValueKey('meta_wait'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
    // return ListTile(
    //   leading: CircleAvatar(
    //     backgroundColor: node.statusColor.withOpacity(0.2),
    //     child: Stack(
    //       alignment: Alignment.bottomRight,
    //       children: [
    //         Center(
    //           child: Text(
    //             node.displayName.isNotEmpty
    //                 ? node.displayName.substring(0, 1).toUpperCase()
    //                 : '?',
    //             style: TextStyle(
    //               color: node.statusColor,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ),
    //         Positioned(
    //           right: 0,
    //           bottom: 0,
    //           child: Container(
    //             width: 12,
    //             height: 12,
    //             decoration: BoxDecoration(
    //               color: node.statusColor,
    //               shape: BoxShape.circle,
    //               border: Border.all(color: Colors.white, width: 2),
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    //   title: Row(
    //     children: [
    //       Icon(
    //         getPlatformIcon(platform),
    //         size: 16,
    //         color: hasMetadata ? Colors.blue[700] : Colors.grey,
    //       ),
    //       SizedBox(
    //         width: 4,
    //       ),
    //       // Text(node.displayName),
    //       if (branch != null && branch != 'No Branch') ...[
    //         Flexible(
    //           child: Text(
    //             branch,
    //             style: const TextStyle(
    //               fontSize: 13,
    //               fontWeight: FontWeight.bold,
    //               color: Colors.green,
    //             ),
    //             overflow: TextOverflow.ellipsis,
    //           ),
    //         ),
    //       ],
    //       SizedBox(
    //         width: 4,
    //       ),
    //       if (hasMetadata) Icon(Icons.verified),
    //       SizedBox(
    //         width: 4,
    //       ),
    //       Text(
    //         node.statusLabel,
    //         style: TextStyle(
    //           fontSize: 11,
    //           color: node.statusColor,
    //           fontWeight: FontWeight.w500,
    //         ),
    //       ),
    //
    //       const SizedBox(height: 4),
    //     ],
    //   ),
    //   subtitle: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Row(
    //         children: [
    //           // ✅ Icône adaptée à la plateforme
    //           Icon(
    //             getPlatformIcon(platform),
    //             size: 14,
    //             color: hasMetadata ? Colors.blue[700] : Colors.grey,
    //           ),
    //           const SizedBox(width: 4),
    //           Flexible(
    //             child: Text(
    //               platform,
    //               style: TextStyle(
    //                 fontSize: 11,
    //                 fontWeight:
    //                     hasMetadata ? FontWeight.bold : FontWeight.normal,
    //                 color: hasMetadata ? Colors.blue[700] : Colors.grey,
    //               ),
    //               overflow: TextOverflow.ellipsis,
    //             ),
    //           ),
    //           // const SizedBox(width: 8),
    //           // if (branch != null && branch != 'No Branch') ...[
    //           //   const Icon(Icons.business, size: 12, color: Colors.green),
    //           //   const SizedBox(width: 4),
    //           //   Flexible(
    //           //     child: Text(
    //           //       branch,
    //           //       style: const TextStyle(
    //           //         fontSize: 11,
    //           //         fontWeight: FontWeight.bold,
    //           //         color: Colors.green,
    //           //       ),
    //           //       overflow: TextOverflow.ellipsis,
    //           //     ),
    //           //   ),
    //           // ],
    //         ],
    //       ),
    //       // ✅ Indicateur de métadonnées
    //       if (hasMetadata)
    //         Padding(
    //           padding: const EdgeInsets.only(top: 2),
    //           child: Text(
    //             '✓ Métadonnées synchronisées',
    //             style: TextStyle(
    //               fontSize: 10,
    //               color: Colors.green[600],
    //               fontStyle: FontStyle.italic,
    //             ),
    //           ),
    //         )
    //       else if (_metadataInitialized)
    //         Padding(
    //           padding: const EdgeInsets.only(top: 2),
    //           child: Text(
    //             '⏳ En attente de métadonnées...',
    //             style: TextStyle(
    //               fontSize: 10,
    //               color: Colors.orange[600],
    //               fontStyle: FontStyle.italic,
    //             ),
    //           ),
    //         ),
    //     ],
    //   ),
    //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    //   onTap: () => _createConversation(context, node),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un nœud'),
        actions: [
          // Ajoutez ce bouton dans l'AppBar de SelectNodePage, juste avant le bouton refresh
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () async {
              if (!mounted) return;

              // Montrer un dialog de confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.cleaning_services, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Nettoyage complet'),
                    ],
                  ),
                  content: const Text(
                    'Cela va supprimer tous les nœuds déconnectés '
                    'et rafraîchir complètement la liste.\n\n'
                    'Continuer ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Nettoyer'),
                    ),
                  ],
                ),
              );

              if (confirm != true || !mounted) return;

              setState(() => _isLoading = true);

              try {
                print('[SelectNodePage] 🧹🔥 NETTOYAGE FORCÉ TOTAL');

                // 1. Vider complètement le cache local
                _filteredNodes.clear();
                NodesManager().availableNodes.clear();

                // 2. Nettoyer les métadonnées
                if (_metadataInitialized) {
                  _metadataManager.cleanupStaleMetadata();
                }

                // 3. Attendre 1 seconde pour laisser le réseau se stabiliser
                await Future.delayed(const Duration(seconds: 1));

                // 4. Rafraîchir complètement
                await _refreshNodes();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Nettoyage complet effectué'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('[SelectNodePage] ❌ Erreur nettoyage forcé: $e');
                if (mounted) {
                  _showError('Erreur nettoyage: $e');
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            tooltip: 'Nettoyage forcé',
          ),
          // ✅ Indicateur d'état du gestionnaire de métadonnées
          if (!_metadataInitialized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange[300]!,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Init...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            count: _metadataInitialized
                ? _metadataManager.remoteMetadata.length
                : 0,
            onPressed: () {
              if (!_metadataInitialized) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gestionnaire de métadonnées non initialisé'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

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
                        if (_metadataManager.remoteMetadata.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Aucune métadonnée reçue pour le moment',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
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
                                        Icon(getPlatformIcon(metadata.platform),
                                            size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            metadata.platform,
                                            style:
                                                const TextStyle(fontSize: 11),
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
            tooltip: _metadataInitialized
                ? 'Métadonnées (${_metadataManager.remoteMetadata.length})'
                : 'Non initialisé',
            badgeColor: _metadataInitialized ? Colors.green : Colors.grey,
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
