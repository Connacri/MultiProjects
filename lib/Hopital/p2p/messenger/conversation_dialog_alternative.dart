// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'messaging_manager.dart';
// import 'messaging_entities.dart';
//
// /// Version alternative du ConversationDialog qui reste un Dialog
// /// et gère mieux les erreurs de Provider
// class ConversationDialogAlternative extends StatefulWidget {
//   final Conversation conversation;
//
//   const ConversationDialogAlternative({
//     Key? key,
//     required this.conversation,
//   }) : super(key: key);
//
//   @override
//   State<ConversationDialogAlternative> createState() =>
//       _ConversationDialogAlternativeState();
// }
//
// class _ConversationDialogAlternativeState
//     extends State<ConversationDialogAlternative> {
//   late TextEditingController _messageController;
//   late ScrollController _scrollController;
//
//   @override
//   void initState() {
//     super.initState();
//     _messageController = TextEditingController();
//     _scrollController = ScrollController();
//
//     // Marquer comme lue après un délai
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         try {
//           context
//               .read<MessagingManager>()
//               .markConversationAsRead(widget.conversation.conversationId);
//         } catch (e) {
//           print('[ConversationDialog] Erreur marquage lecture: $e');
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // ✅ Wrapper avec Builder pour avoir un contexte valide
//     return Builder(
//       builder: (builderContext) {
//         return Consumer<MessagingManager>(
//           builder: (consumerContext, messagingManager, _) {
//             final messages = messagingManager.getConversationMessages(
//               widget.conversation.conversationId,
//               limit: 50,
//             );
//
//             return Dialog(
//               insetPadding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Header
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[700],
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(4),
//                         topRight: Radius.circular(4),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             widget.conversation.title ?? 'Conversation',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.info_outline,
//                               color: Colors.white),
//                           onPressed: () => _showConversationInfo(
//                               consumerContext, messagingManager),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close, color: Colors.white),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Messages list
//                   Expanded(
//                     child: messages.isEmpty
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.chat_bubble_outline,
//                                     size: 64, color: Colors.grey[400]),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   'Aucun message',
//                                   style: TextStyle(
//                                     color: Colors.grey[600],
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'Commencez la conversation !',
//                                   style: TextStyle(
//                                     color: Colors.grey[500],
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             controller: _scrollController,
//                             reverse: true,
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             itemCount: messages.length,
//                             itemBuilder: (context, index) {
//                               final message = messages[index];
//                               return _buildMessageBubble(
//                                 consumerContext,
//                                 message,
//                                 messagingManager,
//                               );
//                             },
//                           ),
//                   ),
//
//                   // Input area
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 4,
//                           offset: const Offset(0, -2),
//                         ),
//                       ],
//                     ),
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _messageController,
//                             decoration: InputDecoration(
//                               hintText: 'Votre message...',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(24),
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                             ),
//                             maxLines: 4,
//                             minLines: 1,
//                             textCapitalization: TextCapitalization.sentences,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         FloatingActionButton(
//                           mini: true,
//                           onPressed: () =>
//                               _sendMessage(consumerContext, messagingManager),
//                           child: const Icon(Icons.send),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildMessageBubble(
//     BuildContext context,
//     Message message,
//     MessagingManager messagingManager,
//   ) {
//     final isFromMe = message.fromNodeId == messagingManager.currentNodeId;
//     final timeFormat = DateFormat('HH:mm');
//     final messageTime =
//         DateTime.fromMillisecondsSinceEpoch(message.sentTimestamp);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//       child: Align(
//         alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.65,
//           ),
//           child: Column(
//             crossAxisAlignment:
//                 isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               // Message bubble
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: isFromMe ? Colors.blue[700] : Colors.grey[300],
//                   borderRadius: BorderRadius.only(
//                     topLeft: const Radius.circular(16),
//                     topRight: const Radius.circular(16),
//                     bottomLeft:
//                         Radius.circular(isFromMe ? 16 : 4),
//                     bottomRight:
//                         Radius.circular(isFromMe ? 4 : 16),
//                   ),
//                 ),
//                 child: Text(
//                   message.content,
//                   style: TextStyle(
//                     color: isFromMe ? Colors.white : Colors.black87,
//                     fontSize: 15,
//                   ),
//                 ),
//               ),
//               // Time and status
//               Padding(
//                 padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       timeFormat.format(messageTime),
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     if (isFromMe) ...[
//                       const SizedBox(width: 4),
//                       Icon(
//                         message.status == MessageStatus.read
//                             ? Icons.done_all
//                             : message.status == MessageStatus.delivered
//                                 ? Icons.done
//                                 : Icons.schedule,
//                         size: 14,
//                         color: message.status == MessageStatus.read
//                             ? Colors.blue
//                             : Colors.grey,
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _sendMessage(
//     BuildContext context,
//     MessagingManager messagingManager,
//   ) async {
//     final text = _messageController.text.trim();
//     if (text.isEmpty) return;
//
//     try {
//       await messagingManager.sendTextMessage(
//         widget.conversation.conversationId,
//         text,
//       );
//       _messageController.clear();
//
//       // Scroll to bottom
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           0,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     } catch (e) {
//       print('[ConversationDialog] Erreur envoi message: $e');
//       _showErrorDialog(context, 'Impossible d\'envoyer le message:\n$e');
//     }
//   }
//
//   void _showConversationInfo(
//     BuildContext context,
//     MessagingManager messagingManager,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Informations'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInfoRow('Titre', widget.conversation.title ?? 'N/A'),
//             const SizedBox(height: 8),
//             _buildInfoRow(
//               'Messages',
//               widget.conversation.messageCount.toString(),
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow(
//               'Non lus',
//               widget.conversation.unreadCount.toString(),
//             ),
//             const SizedBox(height: 8),
//             _buildInfoRow(
//               'Type',
//               widget.conversation.type == ConversationType.private
//                   ? 'Privée'
//                   : 'Groupe',
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Fermer'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         Text(value),
//       ],
//     );
//   }
//
//   void _showErrorDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.error_outline, color: Colors.red),
//             SizedBox(width: 8),
//             Text('Erreur'),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }
