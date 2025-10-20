// // ============================================================================
// // 1. EXTENSION - Enrichir les messages de découverte P2P
// // ============================================================================
// // À ajouter dans messaging_integration.dart ou connexion_manager_fixed.dart
//
// extension NodeMetadataDiscovery on ConnectionManager {
//   /// Envoyer les métadonnées du nœud aux voisins découverts
//   Future<void> broadcastNodeMetadata() async {
//     try {
//       final platform = await getCurrentPlatform();
//       final branch = getBranchForNode(nodeId);
//
//       final metadata = {
//         'type': 'node_metadata',
//         'nodeId': nodeId,
//         'displayName': _getDisplayName(nodeId),
//         'platform': platform,
//         'branch': branch ?? 'Unknown',
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       };
//
//       broadcastMessage(metadata);
//       print('[NodeMetadata] ✅ Métadonnées envoyées: $platform, $branch');
//     } catch (e) {
//       print('[NodeMetadata] ❌ Erreur broadcast metadata: $e');
//     }
//   }
//
//   String _getDisplayName(String nodeId) {
//     try {
//       final parts = nodeId.split('-');
//       if (parts.length >= 3) {
//         return parts.skip(2).join('-');
//       }
//       return nodeId;
//     } catch (e) {
//       return nodeId;
//     }
//   }
// }
//
// // ============================================================================
// // 2. MODIFIER NodesManager pour stocker les métadonnées
// // ============================================================================
// // Remplacer la classe NetworkNode
//
// enum NodeStatus { online, offline, idle }
//
// class NetworkNode {
//   final String nodeId;
//   final String displayName;
//   final NodeStatus status;
//   final DateTime lastSeen;
//
//   // ✅ NOUVELLES PROPRIÉTÉS
//   final String? platform;      // Platform du nœud distant
//   final String? branch;         // Branche du nœud distant
//   final int? timestamp;         // Quand les métadonnées ont été reçues
//
//   NetworkNode({
//     required this.nodeId,
//     required this.displayName,
//     required this.status,
//     required this.lastSeen,
//     this.platform,      // ✅ NOUVEAU
//     this.branch,        // ✅ NOUVEAU
//     this.timestamp,     // ✅ NOUVEAU
//   });
//
//   String get statusLabel {
//     switch (status) {
//       case NodeStatus.online:
//         return 'En ligne';
//       case NodeStatus.offline:
//         return 'Hors ligne';
//       case NodeStatus.idle:
//         return 'Inactif';
//     }
//   }
//
//   Color get statusColor {
//     switch (status) {
//       case NodeStatus.online:
//         return Colors.green;
//       case NodeStatus.offline:
//         return Colors.grey;
//       case NodeStatus.idle:
//         return Colors.orange;
//     }
//   }
// }
//
// // ============================================================================
// // 3. MODIFIER NodesManager pour recevoir et stocker les métadonnées
// // ============================================================================
//
// class NodesManager {
//   static final NodesManager _instance = NodesManager._internal();
//
//   factory NodesManager() => _instance;
//
//   NodesManager._internal();
//
//   late P2PManager _p2pManager;
//   late ConnectionManager _connectionManager;
//   List<NetworkNode> _cachedNodes = [];
//
//   // ✅ NOUVEAU: Cache des métadonnées par nodeId
//   final Map<String, Map<String, dynamic>> _nodeMetadata = {};
//
//   Future<void> initialize(
//     P2PManager p2pManager,
//     ConnectionManager connectionManager,
//   ) async {
//     _p2pManager = p2pManager;
//     _connectionManager = connectionManager;
//
//     _connectionManager.addListener(_onConnectionManagerChanged);
//
//     // ✅ NOUVEAU: Écouter les messages de métadonnées
//     _connectionManager.onMessage.listen((message) {
//       if (message['type'] == 'node_metadata') {
//         _handleNodeMetadata(message);
//       }
//     });
//
//     await refreshNodes();
//   }
//
//   // ✅ NOUVEAU: Traiter les métadonnées reçues
//   void _handleNodeMetadata(Map<String, dynamic> metadata) {
//     try {
//       final nodeId = metadata['nodeId'] as String?;
//       if (nodeId != null) {
//         _nodeMetadata[nodeId] = metadata;
//         print('[NodesManager] 📝 Métadonnées reçues pour $nodeId');
//         print('  - Platform: ${metadata['platform']}');
//         print('  - Branch: ${metadata['branch']}');
//
//         // Rafraîchir la liste pour mettre à jour l'UI
//         refreshNodes();
//       }
//     } catch (e) {
//       print('[NodesManager] ❌ Erreur traitement metadata: $e');
//     }
//   }
//
//   void _onConnectionManagerChanged() {
//     refreshNodes();
//   }
//
//   List<NetworkNode> get availableNodes => _cachedNodes;
//
//   Future<void> refreshNodes() async {
//     try {
//       print('[NodesManager] 🔄 Rafraîchissement des nœuds...');
//
//       final neighborsSet = _connectionManager.neighbors;
//
//       if (neighborsSet.isEmpty) {
//         print('[NodesManager] ⚠️ Aucun voisin découvert');
//         _cachedNodes = [];
//         return;
//       }
//
//       // ✅ MODIFIÉ: Inclure les métadonnées
//       _cachedNodes = neighborsSet.map((nodeId) {
//         final metadata = _nodeMetadata[nodeId];
//
//         return NetworkNode(
//           nodeId: nodeId,
//           displayName: metadata?['displayName'] ?? _getDisplayName(nodeId),
//           status: NodeStatus.online,
//           lastSeen: DateTime.now(),
//           platform: metadata?['platform'],      // ✅ NOUVEAU
//           branch: metadata?['branch'],          // ✅ NOUVEAU
//           timestamp: metadata?['timestamp'],    // ✅ NOUVEAU
//         );
//       }).toList();
//
//       _cachedNodes.sort((a, b) => a.displayName.compareTo(b.displayName));
//
//       print('[NodesManager] ✅ ${_cachedNodes.length} nœud(s) découvert(s)');
//       for (var node in _cachedNodes) {
//         print('[NodesManager]   - ${node.displayName}');
//         print('      Platform: ${node.platform ?? 'En attente...'}');
//         print('      Branch: ${node.branch ?? 'En attente...'}');
//       }
//     } catch (e) {
//       print('[NodesManager] ❌ Erreur rafraîchissement: $e');
//       _cachedNodes = [];
//     }
//   }
//
//   String _getDisplayName(String nodeId) {
//     try {
//       final parts = nodeId.split('-');
//       if (parts.length >= 3) {
//         return parts.skip(2).join('-');
//       }
//       return nodeId;
//     } catch (e) {
//       return nodeId;
//     }
//   }
//
//   void dispose() {
//     _connectionManager.removeListener(_onConnectionManagerChanged);
//   }
// }
//
// // ============================================================================
// // 4. MODIFIER SelectNodePage pour afficher les métadonnées du nœud distant
// // ============================================================================
//
// class SelectNodePage extends StatefulWidget {
//   const SelectNodePage({Key? key}) : super(key: key);
//
//   @override
//   State<SelectNodePage> createState() => _SelectNodePageState();
// }
//
// class _SelectNodePageState extends State<SelectNodePage> {
//   late TextEditingController _searchController;
//   List<NetworkNode> _filteredNodes = [];
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController = TextEditingController();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadInitialNodes();
//     });
//     _searchController.addListener(_filterNodes);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _loadInitialNodes() {
//     if (mounted) {
//       setState(() {
//         _filteredNodes = NodesManager().availableNodes;
//       });
//     }
//   }
//
//   void _filterNodes() {
//     final query = _searchController.text.toLowerCase();
//     if (mounted) {
//       setState(() {
//         _filteredNodes = NodesManager()
//             .availableNodes
//             .where((node) =>
//                 node.displayName.toLowerCase().contains(query) ||
//                 node.nodeId.toLowerCase().contains(query))
//             .toList();
//       });
//     }
//   }
//
//   Future<void> _refreshNodes() async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//     try {
//       await NodesManager().refreshNodes();
//       if (mounted) {
//         setState(() {
//           _filteredNodes = NodesManager().availableNodes;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         _showError('Erreur: $e');
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   void _showError(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     }
//   }
//
//   Future<void> _createConversation(
//       BuildContext context, NetworkNode node) async {
//     print('[SelectNodePage] 🔄 Création conversation avec ${node.displayName}');
//
//     showDialog(
//       context: navigatorKey.currentContext!,
//       barrierDismissible: false,
//       builder: (context) => const Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Ouverture de la conversation...'),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//
//     try {
//       final messagingManager = context.read<MessagingManager>();
//       final conversation = await messagingManager
//           .createPrivateConversation(
//             node.nodeId,
//             displayName: node.displayName,
//           )
//           .timeout(
//         const Duration(seconds: 5),
//         onTimeout: () {
//           throw TimeoutException(
//             'Timeout: la création de conversation a dépassé 5 secondes',
//           );
//         },
//       );
//
//       if (navigatorKey.currentContext != null) {
//         Navigator.pop(navigatorKey.currentContext!);
//       }
//
//       await messagingManager
//           .markConversationAsRead(conversation.conversationId);
//
//       await Navigator.of(context, rootNavigator: true).push(
//         MaterialPageRoute(
//           builder: (newContext) => ConversationDialogWithProvider(
//             conversation: conversation,
//             messagingManager: messagingManager,
//           ),
//         ),
//       );
//     } on TimeoutException catch (e) {
//       print('[SelectNodePage] ⏱️ TimeoutException: $e');
//       if (navigatorKey.currentContext != null) {
//         Navigator.pop(navigatorKey.currentContext!);
//         _showError('Timeout: la conversation a pris trop de temps à créer');
//       }
//     } catch (e, stackTrace) {
//       print('[SelectNodePage] ❌ Erreur: $e');
//       print('[SelectNodePage] Stack: $stackTrace');
//       if (navigatorKey.currentContext != null) {
//         Navigator.pop(navigatorKey.currentContext!);
//         _showError('Erreur création conversation: $e');
//       }
//     } finally {
//       if (navigatorKey.currentContext != null &&
//           Navigator.canPop(navigatorKey.currentContext!)) {
//         Navigator.pop(navigatorKey.currentContext!);
//       }
//     }
//   }
//
//   // ✅ MODIFIÉ: Afficher les données du nœud distant (pas de l'hôte local)
//   Widget _buildNodeTile(BuildContext context, NetworkNode node) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: node.statusColor.withOpacity(0.2),
//         child: Stack(
//           alignment: Alignment.bottomRight,
//           children: [
//             Center(
//               child: Text(
//                 node.displayName.isNotEmpty
//                     ? node.displayName.substring(0, 1).toUpperCase()
//                     : '?',
//                 style: TextStyle(
//                   color: node.statusColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             Positioned(
//               right: 0,
//               bottom: 0,
//               child: Container(
//                 width: 12,
//                 height: 12,
//                 decoration: BoxDecoration(
//                   color: node.statusColor,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       title: Text(node.displayName),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             node.statusLabel,
//             style: TextStyle(
//               fontSize: 11,
//               color: node.statusColor,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               const Icon(Icons.device_unknown, size: 12),
//               const SizedBox(width: 4),
//               // ✅ AFFICHER LA PLATFORM DU NŒUD DISTANT
//               Text(
//                 node.platform ?? 'En attente...',
//                 style: const TextStyle(fontSize: 11),
//               ),
//               const SizedBox(width: 8),
//               // ✅ AFFICHER LA BRANCHE DU NŒUD DISTANT
//               if (node.branch != null && node.branch != 'Unknown') ...[
//                 const Icon(Icons.account_tree, size: 12),
//                 const SizedBox(width: 4),
//                 Text(
//                   node.branch!,
//                   style: const TextStyle(fontSize: 11),
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: () => _createConversation(context, node),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sélectionner un nœud'),
//         actions: [
//           IconButton(
//             icon: _isLoading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : const Icon(Icons.refresh),
//             onPressed: _isLoading ? null : _refreshNodes,
//             tooltip: 'Rafraîchir',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Rechercher un nœud...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: _filteredNodes.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.cloud_off,
//                           size: 48,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Aucun nœud découvert',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Assurez-vous que vos appareils sont\nsur le même réseau',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[500],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('Rafraîchir'),
//                           onPressed: _refreshNodes,
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: _filteredNodes.length,
//                     itemBuilder: (context, index) {
//                       final node = _filteredNodes[index];
//                       return _buildNodeTile(context, node);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
