// features/matches/presentation/matches_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'matches_provider.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchesProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.matches.isEmpty) {
          return const Center(
            child: Text(
              'Aucun match pour le moment',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.matches.length,
          itemBuilder: (context, index) {
            final match = provider.matches[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: match.otherUserPhoto != null
                    ? CachedNetworkImageProvider(match.otherUserPhoto!)
                    : null,
                child: match.otherUserPhoto == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              title: Text(
                match.otherUserName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: match.lastMessagePreview != null
                  ? Text(match.lastMessagePreview!,
                      maxLines: 1, overflow: TextOverflow.ellipsis)
                  : const Text('Match ! Commencez la conversation'),
              trailing: Text(
                _formatDate(match.lastMessageAt ?? match.matchedAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                // TODO: Navigator.push ChatScreen(matchId: match.id)
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}
