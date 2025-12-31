import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../objectBox/Entity.dart';
import '../../../../../objectbox.g.dart';
import '../../../features/profile/profile.dart';
import '../../objectbox.dart';
import 'discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final _supabase = Supabase.instance.client;
  final _swipeBox = ObjectBox.store.box<SwipeQueue>();

  @override
  Future<void> swipe({
    required String swipedId,
    required int action, // 0=pass, 1=like, 2=superlike
  }) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      await _sendSwipeOnline(swipedId: swipedId, action: action);
    } else {
      _queueSwipeOffline(swipedId: swipedId, action: action);
    }
  }

  Future<void> _sendSwipeOnline({
    required String swipedId,
    required int action,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final actionString = switch (action) {
      0 => 'pass',
      1 => 'like',
      2 => 'superlike',
      _ => throw ArgumentError('Action invalide: $action'),
    };

    await _supabase.from('swipe_actions').insert({
      'swiper_id': userId,
      'swiped_id': swipedId,
      'action': actionString,
    });
  }

  void _queueSwipeOffline({
    required String swipedId,
    required int action,
  }) {
    final entry = SwipeQueue(
      swipedId: swipedId,
      action: action,
      status: 0,
      attemptCount: 0,
    );
    _swipeBox.put(entry);
  }

  @override
  Future<void> syncSwipes() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final pendingQuery = _swipeBox
        .query(SwipeQueue_.status.equals(0))
        .order(SwipeQueue_.createdAt)
        .build();

    final pending = pendingQuery.find();
    pendingQuery.close();

    if (pending.isEmpty) return;

    for (final entry in pending) {
      try {
        await _sendSwipeOnline(swipedId: entry.swipedId, action: entry.action);
        entry.status = 1; // completed
        entry.attemptCount = 0;
      } catch (e) {
        entry.attemptCount++;
        entry.status = entry.attemptCount >= 5 ? 2 : 0;
      }
      _swipeBox.put(entry);
    }
  }

  @override
  Stream<List<Profile>> getRecommendations({
    required String userId,
    required double userLat,
    required double userLon,
    double maxDistanceKm = 50.0,
  }) {
    return _supabase
        .rpc('get_recommendations', params: {
          'current_user_id': userId,
          'user_lat': userLat,
          'user_lon': userLon,
          'max_distance_km': maxDistanceKm,
        })
        .asStream()
        .asyncMap((response) async {
          if (response is List) {
            return response
                .map((json) => Profile.fromMap(json as Map<String, dynamic>))
                .toList();
          }
          return <Profile>[];
        })
        .handleError((_) => <Profile>[]);
  }
}
