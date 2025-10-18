import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../objectBox/classeObjectBox.dart';
import '../connection_manager_fixed.dart';
import '../p2p_integration_fixed.dart';
import 'messaging_integration.dart';
import 'messaging_manager.dart';
import 'messaging_ui_widgets.dart';

// ============================================================================
// EXAMPLE - Intégration Messaging dans AppBar
// ============================================================================

class HomeScreenWithMessaging extends StatefulWidget {
  const HomeScreenWithMessaging({Key? key}) : super(key: key);

  @override
  State<HomeScreenWithMessaging> createState() =>
      _HomeScreenWithMessagingState();
}

class _HomeScreenWithMessagingState extends State<HomeScreenWithMessaging> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hôpital P2P'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Icône Messenger avec badge
          MessengerIconWithBadge(
            onPressed: () {
              // Afficher bottom sheet des conversations
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const ConversationsBottomSheet(),
              );
            },
          ),
          // Autres actions (settings, etc.)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings
            },
          ),
        ],
      ),
      body: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section P2P Status
          _buildP2PStatusCard(),
          const SizedBox(height: 20),

          // Section Messaging Stats
          _buildMessagingStatsCard(),
          const SizedBox(height: 20),

          // Quick Actions
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildP2PStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
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
            const Divider(height: 20),
            _buildInfoRow('Serveur', '✅ Actif'),
            _buildInfoRow('Connexions', '3 voisins'),
            _buildInfoRow('Nœuds découverts', '5'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagingStatsCard() {
    return Consumer<MessagingManager>(
      builder: (context, messagingManager, _) {
        return Card(
          elevation: 2,
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
                    Icon(Icons.message, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
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
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Envoyés',
                      messagingManager.totalMessagesSent.toString(),
                      Colors.blue,
                    ),
                    _buildStatColumn(
                      'Reçus',
                      messagingManager.totalMessagesReceived.toString(),
                      Colors.green,
                    ),
                    _buildStatColumn(
                      'Non lus',
                      messagingManager.totalUnreadMessages.toString(),
                      messagingManager.totalUnreadMessages > 0
                          ? Colors.orange
                          : Colors.grey,
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

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_comment),
                label: const Text('Nouveau message'),
                onPressed: () {
                  // Ouvrir dialog pour créer conversation
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// ============================================================================
// MAIN - Configuration complète
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser ObjectBox
  final objectBox = ObjectBox();

  // Initialiser MessagingManager
  final messagingManager = MessagingManager();
  await messagingManager.initialize(
    objectBox,
    'node-system-hostname', // À remplacer par P2PManager().nodeId
  );

  // Initialiser MessagingP2PIntegration
  final messagingP2P = MessagingP2PIntegration();
  await messagingP2P.initialize(
    messagingManager,
    P2PIntegration(), // À initialiser
    ConnectionManager(), // À initialiser
  );
  messagingP2P.start();

  runApp(MyApp(messagingManager: messagingManager));
}

class MyApp extends StatelessWidget {
  final MessagingManager messagingManager;

  const MyApp({
    Key? key,
    required this.messagingManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MessagingManager>.value(
          value: messagingManager,
        ),
      ],
      child: MaterialApp(
        title: 'Hôpital P2P',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreenWithMessaging(),
      ),
    );
  }
}
