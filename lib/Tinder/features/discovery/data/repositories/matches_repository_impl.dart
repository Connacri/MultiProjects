// features/matches/data/repositories/matches_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/match.dart';

class MatchesRepositoryImpl {
  final _supabase = Supabase.instance.client;

  Stream<List<Match>> getMatchesStream() {
    final currentUserId = _supabase.auth.currentUser!.id;

    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .order('last_message_at', ascending: false)
        .map((list) => list.map(Match.fromMap).toList());
  }
}
