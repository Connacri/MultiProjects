import 'package:supabase_flutter/supabase_flutter.dart';

import 'tinder_match_model.dart';

class MatchesRepositoryImpl {
  final _supabase = Supabase.instance.client;

  /// ✅ Stream de matches avec profils joints
  Stream<List<TinderMatch>> getMatchesStream() {
    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      print('❌ [MatchesRepo] Utilisateur non authentifié');
      return Stream.value([]);
    }

    // ✅ CORRECTION : Stream avec filtrage côté client
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((list) {
          try {
            // Filtrer les matches de l'utilisateur courant
            final userMatches = list.where((json) {
              final user1Id = json['user1_id'] as String?;
              final user2Id = json['user2_id'] as String?;
              return user1Id == currentUserId || user2Id == currentUserId;
            }).toList();

            // Parser en TinderMatch
            return userMatches
                .map((json) {
                  try {
                    return TinderMatch.fromMap(json, currentUserId);
                  } catch (e) {
                    print('❌ [MatchesRepo] Erreur parsing match: $e');
                    print('   JSON: $json');
                    return null;
                  }
                })
                .whereType<TinderMatch>()
                .toList();
          } catch (e) {
            print('❌ [MatchesRepo] Erreur transformation: $e');
            return <TinderMatch>[];
          }
        })
        .handleError((error) {
          print('❌ [MatchesRepo] Erreur stream: $error');
          return <TinderMatch>[];
        });
  }

  /// ✅ Récupération ponctuelle avec profils joints
  Future<List<TinderMatch>> getMatchesList({int limit = 50}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      // Deux requêtes séparées
      final user1Matches = await _supabase
          .from('matches')
          .select()
          .eq('user1_id', currentUserId)
          .order('last_message_at', ascending: false)
          .limit(limit);

      final user2Matches = await _supabase
          .from('matches')
          .select()
          .eq('user2_id', currentUserId)
          .order('last_message_at', ascending: false)
          .limit(limit);

      // Fusionner et trier
      final allMatches = [...user1Matches, ...user2Matches];
      allMatches.sort((a, b) {
        final aDate = a['last_message_at'] as String?;
        final bDate = b['last_message_at'] as String?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return allMatches
          .take(limit)
          .map((json) => TinderMatch.fromMap(json, currentUserId))
          .toList();
    } catch (e) {
      print('❌ [MatchesRepo] Erreur getMatchesList: $e');
      return [];
    }
  }

  /// ✅ Récupérer un match spécifique
  Future<TinderMatch?> getMatch(String matchId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final data =
          await _supabase.from('matches').select().eq('id', matchId).single();

      return TinderMatch.fromMap(data, currentUserId);
    } catch (e) {
      print('❌ [MatchesRepo] Erreur récupération match: $e');
      return null;
    }
  }

  /// ✅ Marquer un match comme lu
  Future<void> markMatchAsRead(String matchId) async {
    try {
      await _supabase.from('matches').update({
        'last_read_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      print('✅ [MatchesRepo] Match $matchId marqué comme lu');
    } catch (e) {
      print('❌ [MatchesRepo] Erreur mark as read: $e');
    }
  }

  /// ✅ Supprimer un match
  Future<void> deleteMatch(String matchId) async {
    try {
      await _supabase.from('matches').delete().eq('id', matchId);
      print('✅ [MatchesRepo] Match $matchId supprimé');
    } catch (e) {
      print('❌ [MatchesRepo] Erreur suppression match: $e');
      rethrow;
    }
  }

  /// ✅ Compter les matches non lus (CORRIGÉ)
  Future<int> getUnreadCount() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      // ✅ CORRECTION : Utiliser .filter() au lieu de .is_()
      // Méthode 1 : Filtrer avec .filter()
      final user1Matches = await _supabase
          .from('matches')
          .select('id')
          .eq('user1_id', currentUserId)
          .filter('last_read_at', 'is', null);

      final user2Matches = await _supabase
          .from('matches')
          .select('id')
          .eq('user2_id', currentUserId)
          .filter('last_read_at', 'is', null);

      return (user1Matches as List).length + (user2Matches as List).length;
    } catch (e) {
      print('❌ [MatchesRepo] Erreur count unread: $e');
      return 0;
    }
  }

  /// ✅ Vérifier si un like mutuel crée un match
  Future<String?> checkForMatch(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // Vérifier like mutuel
      final myLike = await _supabase
          .from('swipe_actions')
          .select('id')
          .eq('swiper_id', currentUserId)
          .eq('swiped_id', otherUserId)
          .inFilter('action', ['like', 'superlike']).maybeSingle();

      if (myLike == null) return null;

      final theirLike = await _supabase
          .from('swipe_actions')
          .select('id')
          .eq('swiper_id', otherUserId)
          .eq('swiped_id', currentUserId)
          .inFilter('action', ['like', 'superlike']).maybeSingle();

      if (theirLike == null) return null;

      // Vérifier si match existe
      final existingMatch = await _supabase
          .from('matches')
          .select('id')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .or('user1_id.eq.$otherUserId,user2_id.eq.$otherUserId')
          .maybeSingle();

      if (existingMatch != null) {
        return existingMatch['id'] as String;
      }

      // Créer nouveau match
      final newMatch = await _supabase
          .from('matches')
          .insert({
            'user1_id': currentUserId,
            'user2_id': otherUserId,
            'matched_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return newMatch['id'] as String;
    } catch (e) {
      print('❌ [MatchesRepo] Erreur check match: $e');
      return null;
    }
  }
}
