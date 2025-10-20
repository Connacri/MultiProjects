import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection_manager_fixed.dart';
import '../p2p_manager_fixed.dart';

/// Widget de debug pour voir les messages P2P en temps réel
class MessageDebugWidget extends StatefulWidget {
  const MessageDebugWidget({Key? key}) : super(key: key);

  @override
  State<MessageDebugWidget> createState() => _MessageDebugWidgetState();
}

class _MessageDebugWidgetState extends State<MessageDebugWidget> {
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    final connectionManager = context.read<ConnectionManager>();

    connectionManager.onMessage.listen((message) {
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            ...message,
            'receivedAt': DateTime.now().toIso8601String(),
          });

          // Garder seulement les 50 derniers messages
          if (_messages.length > 50) {
            _messages.removeLast();
          }
        });

        print(
            '[MessageDebug] 📩 Message reçu: ${message['type']} de ${message['nodeId']}');
      }
    });
  }

  /// Tronque une chaîne en toute sécurité
  String _truncateString(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectionManager, P2PManager>(
      builder: (context, conn, p2p, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Messages P2P (Debug)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_messages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats rapides
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      'Node',
                      _truncateString(p2p.nodeId
                          .split('-')
                          .last, 8),
                      Colors.blue,
                    ),
                    _buildStatChip(
                      'Pairs',
                      conn.neighbors.length.toString(),
                      Colors.green,
                    ),
                    _buildStatChip(
                      'Messages',
                      _messages.length.toString(),
                      Colors.purple,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Liste des messages
              SizedBox(
                height: 300,
                child: _messages.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucun message reçu',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attendez qu\'un pair envoie des données...',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageTile(msg);
                  },
                ),
              ),

              const Divider(height: 1),

              // Actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Effacer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _messages.isEmpty
                            ? null
                            : () {
                          setState(() {
                            _messages.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: conn.neighbors.isEmpty
                            ? null
                            : () {
                          _sendTestMessage(conn, p2p);
                        },
                      ),
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final nodeId = msg['nodeId'] as String?;
    final receivedAt = msg['receivedAt'] as String?;

    Color typeColor;
    IconData typeIcon;

    switch (type) {
      case 'hello':
        typeColor = Colors.blue;
        typeIcon = Icons.waving_hand;
        break;
      case 'delta':
        typeColor = Colors.purple;
        typeIcon = Icons.sync;
        break;
      case 'ack':
        typeColor = Colors.green;
        typeIcon = Icons.check;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.message;
    }

    return ListTile(
      dense: true,
      leading: Icon(typeIcon, color: typeColor, size: 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type?.toUpperCase() ?? 'UNKNOWN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'de ${_truncateString(nodeId
                  ?.split('-')
                  .last ?? 'unknown', 8)}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        receivedAt != null
            ? DateTime.parse(receivedAt).toLocal().toString().substring(11, 19)
            : 'N/A',
        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
      ),
      trailing: type == 'delta'
          ? const Icon(Icons.lock, size: 14, color: Colors.green)
          : null,
      onTap: () => _showMessageDetails(msg),
    );
  }

  void _showMessageDetails(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Message ${msg['type']?.toUpperCase() ?? 'UNKNOWN'}'),
            content: SingleChildScrollView(
              child: Text(
                msg.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _sendTestMessage(ConnectionManager conn, P2PManager p2p) {
    conn.broadcastMessage({
      'type': 'test',
      'nodeId': p2p.nodeId,
      'message': 'Test message from ${_truncateString(p2p.nodeId, 20)}',
      'timestamp': DateTime
          .now()
          .millisecondsSinceEpoch,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text('✅ Message test envoyé à ${conn.neighbors.length} pair(s)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
