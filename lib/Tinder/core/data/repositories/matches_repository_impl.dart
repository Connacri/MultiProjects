// lib/Tinder/core/data/repositories/matches_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../objectBox/Entity.dart';

class MatchesRepositoryImpl {
  final _supabase = Supabase.instance.client;

  /// ✅ SOLUTION 1: Stream avec filtrage côté client (Simple et fiable)
  Stream<List<Match>> getMatchesStream() {
    final currentUserId = _supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      print('❌ [MatchesRepo] Utilisateur non authentifié');
      return Stream.value([]);
    }

    // ✅ Stream sans filtre, on filtre côté client
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((list) {
          try {
            // ✅ Filtrer les matches de l'utilisateur courant
            final userMatches = list.where((json) {
              final user1Id = json['user1_id'] as String?;
              final user2Id = json['user2_id'] as String?;
              return user1Id == currentUserId || user2Id == currentUserId;
            });

            // ✅ Parser en objets Match
            return userMatches
                .map((json) {
                  try {
                    return Match.fromMap(json);
                  } catch (e) {
                    print('❌ [MatchesRepo] Erreur parsing match: $e');
                    print('   JSON: $json');
                    return null;
                  }
                })
                .whereType<Match>()
                .toList();
          } catch (e) {
            print('❌ [MatchesRepo] Erreur transformation: $e');
            return <Match>[];
          }
        })
        .handleError((error) {
          print('❌ [MatchesRepo] Erreur stream: $error');
          return <Match>[];
        });
  }

  /// ✅ SOLUTION 2: Récupération ponctuelle avec RPC (Performant)
  /// Utilise la fonction RPC Supabase si disponible
  Future<List<Match>> getMatchesList({int limit = 50, int offset = 0}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      // ✅ Essayer d'abord avec RPC (optimal)
      try {
        final response = await _supabase.rpc(
          'get_user_matches',
          params: {
            'p_user_id': currentUserId,
            'p_limit': limit,
            'p_offset': offset,
          },
        );

        if (response is List) {
          return response
              .map((json) => Match.fromMap(json as Map<String, dynamic>))
              .toList();
        }
      } catch (rpcError) {
        print('⚠️ [MatchesRepo] RPC non disponible, fallback query normale');
      }

      // ✅ Fallback: Query classique avec deux requêtes
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

      // ✅ Fusionner et trier
      final allMatches = [...user1Matches, ...user2Matches];
      allMatches.sort((a, b) {
        final aDate = a['last_message_at'] as String?;
        final bDate = b['last_message_at'] as String?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return allMatches.take(limit).map((json) => Match.fromMap(json)).toList();
    } catch (e) {
      print('❌ [MatchesRepo] Erreur getMatchesList: $e');
      return [];
    }
  }

  /// ✅ Récupérer un match spécifique
  Future<Match?> getMatch(String matchId) async {
    try {
      final data =
          await _supabase.from('matches').select().eq('id', matchId).single();

      return Match.fromMap(data);
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

  /// ✅ Supprimer un match (unmatch)
  Future<void> deleteMatch(String matchId) async {
    try {
      await _supabase.from('matches').delete().eq('id', matchId);

      print('✅ [MatchesRepo] Match $matchId supprimé');
    } catch (e) {
      print('❌ [MatchesRepo] Erreur suppression match: $e');
      rethrow;
    }
  }

  /// ✅ Compter les matches non lus
  Future<int> getUnreadCount() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      // ✅ Essayer avec RPC d'abord
      try {
        final result = await _supabase.rpc(
          'count_unread_matches',
          params: {'p_user_id': currentUserId},
        );

        return result as int? ?? 0;
      } catch (rpcError) {
        print('⚠️ [MatchesRepo] RPC count non disponible, fallback');
      }

      // ✅ Fallback: Deux requêtes séparées
      final user1Response = await _supabase
          .from('matches')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user1_id', currentUserId)
          .isNull('last_read_at');

      final user2Response = await _supabase
          .from('matches')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user2_id', currentUserId)
          .isNull('last_read_at');

      return (user1Response.count ?? 0) + (user2Response.count ?? 0);
    } catch (e) {
      print('❌ [MatchesRepo] Erreur count unread: $e');
      return 0;
    }
  }

  /// ✅ NOUVEAU: Vérifier si un like mutuel crée un match
  Future<String?> checkForMatch(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      // ✅ Essayer avec RPC
      try {
        final result = await _supabase.rpc(
          'check_mutual_like',
          params: {
            'user1': currentUserId,
            'user2': otherUserId,
          },
        ).single();

        if (result['is_match'] == true) {
          return result['match_id'] as String?;
        }
        return null;
      } catch (rpcError) {
        print('⚠️ [MatchesRepo] RPC check_mutual_like non disponible');
      }

      // ✅ Fallback: Vérification manuelle
      // Vérifier si current user a liké other user
      final myLike = await _supabase
          .from('swipe_actions')
          .select('id')
          .eq('swiper_id', currentUserId)
          .eq('swiped_id', otherUserId)
          .inFilter('action', ['like', 'superlike']).maybeSingle();

      if (myLike == null) return null;

      // Vérifier si other user a liké current user
      final theirLike = await _supabase
          .from('swipe_actions')
          .select('id')
          .eq('swiper_id', otherUserId)
          .eq('swiped_id', currentUserId)
          .inFilter('action', ['like', 'superlike']).maybeSingle();

      if (theirLike == null) return null;

      // ✅ Match mutuel détecté, créer le match
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
