// import 'package:flutter/material.dart';
//
// import '../../../objectbox.g.dart';
// import 'messaging_entities.dart';
//
// class ConversationPage extends StatefulWidget {
//   final Conversation conversation;
//
//   const ConversationPage({Key? key, required this.conversation})
//       : super(key: key);
//
//   @override
//   State<ConversationPage> createState() => _ConversationPageState();
// }
//
// class _ConversationPageState extends State<ConversationPage> {
//   late TextEditingController _messageController;
//   final Box<Message> _messageBox = objectBoxGlobal.store.box<Message>();
//   List<Message> _messages = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _messageController = TextEditingController();
//     _loadMessages();
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }
//
//   void _loadMessages() {
//     setState(() {
//       _messages = _messageBox
//           .getConversationMessages(widget.conversation.conversationId);
//     });
//   }
//
//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
//
//     final newMessage = Message(
//       messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
//       conversationId: widget.conversation.conversationId,
//       fromNodeId: 'current_node_id', // À remplacer par l'ID du nœud actuel
//       typeValue: MessageType.text.index,
//       content: _messageController.text.trim(),
//       sentTimestamp: DateTime.now().millisecondsSinceEpoch,
//       statusValue: MessageStatus.pending.index,
//     );
//
//     _messageBox.put(newMessage);
//     _messageController.clear();
//     _loadMessages();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.conversation.title ??
//             widget.conversation.participantNodeIds),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: true,
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[index];
//                 return ListTile(
//                   title: Text(message.fromNodeId),
//                   subtitle: Text(message.content),
//                   trailing: Text(
//                     DateTime.fromMillisecondsSinceEpoch(message.sentTimestamp)
//                         .toLocal()
//                         .toString(),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Envoyer un message...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
