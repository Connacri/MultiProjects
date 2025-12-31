// lib/Tinder/features/matches/matches_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'matches_provider.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchesProvider>(
      builder: (context, provider, _) {
        // ✅ Gestion d'erreur
        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: provider.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Loading
        if (provider.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ✅ État vide
        if (provider.matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun match pour le moment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commencez à swiper pour trouver des matchs !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Filtrer les matches par recherche
        final filteredMatches = _searchQuery.isEmpty
            ? provider.matches
            : provider.searchMatches(_searchQuery);

        return Column(
          children: [
            // ✅ Barre de recherche
            _buildSearchBar(),

            // ✅ Liste des matches
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.refresh,
                child: filteredMatches.isEmpty
                    ? _buildEmptySearch()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          final match = filteredMatches[index];

                          return Dismissible(
                            key: Key(match.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await _confirmDelete(context);
                            },
                            onDismissed: (direction) {
                              provider.deleteMatch(match.id);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Match avec ${match.otherUserName} supprimé',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Annuler',
                                    onPressed: provider.refresh,
                                  ),
                                ),
                              );
                            },
                            child: _buildMatchTile(context, match, provider),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un match...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// ✅ État vide de recherche
  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Tile de match
  Widget _buildMatchTile(
    BuildContext context,
    match,
    MatchesProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              match.lastMessagePreview != null
                  ? match.lastMessagePreview!
                  : 'Match ! Commencez la conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: match.lastMessagePreview != null
                    ? Colors.grey[700]
                    : Colors.blue,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(match.lastMessageAt ?? match.matchedAt),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            // ✅ Badge "nouveau" si pas de message
            if (match.lastMessagePreview == null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'NOUVEAU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // ✅ Marquer comme lu
          provider.markAsRead(match.id);

          // TODO: Navigator.push vers ChatScreen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat avec ${match.otherUserName} (à implémenter)'),
            ),
          );
        },
      ),
    );
  }

  /// ✅ Dialogue de confirmation de suppression
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer ce match ?'),
          content: const Text(
            'Cette action est irréversible. Vous ne pourrez plus discuter avec cette personne.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';

    return 'Maintenant';
  }
}
