// lib/Tinder/core/data/repositories/discovery_repository_impl.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../objectBox/Entity.dart';
import '../../../../../objectbox.g.dart';
import '../../../objectBox/classeObjectBox.dart';
import '../../core/swipe_action_enum.dart';
import 'discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final _supabase = Supabase.instance.client;
  final _swipeBox = ObjectBox().swipeQueueBox;

  /// ✅ CORRECTION: Utiliser SwipeAction au lieu de int
  @override
  Future<void> swipe({
    required String swipedId,
    required SwipeAction action,
  }) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline) {
        await _sendSwipeOnline(swipedId: swipedId, action: action);
      } else {
        _queueSwipeOffline(swipedId: swipedId, action: action);
      }
    } catch (e, stackTrace) {
      print('❌ [DiscoveryRepo] Erreur swipe: $e');
      print(stackTrace);

      // ✅ En cas d'erreur réseau, toujours queue offline
      _queueSwipeOffline(swipedId: swipedId, action: action);
    }
  }

  /// ✅ AMÉLIORATION: Gestion d'erreur et timeout
  Future<void> _sendSwipeOnline({
    required String swipedId,
    required SwipeAction action,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      await _supabase.from('swipe_actions').insert({
        'swiper_id': userId,
        'swiped_id': swipedId,
        'action': action.name, // ✅ Utiliser action.name
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Timeout lors du swipe'),
      );

      print('✅ [DiscoveryRepo] Swipe envoyé: ${action.name} sur $swipedId');
    } catch (e) {
      print('❌ [DiscoveryRepo] Erreur envoi swipe: $e');
      rethrow;
    }
  }

  /// ✅ AMÉLIORATION: Utiliser SwipeAction
  void _queueSwipeOffline({
    required String swipedId,
    required SwipeAction action,
  }) {
    try {
      final entry = SwipeQueue(
        swipedId: swipedId,
        action: action.value, // ✅ Utiliser action.value (int)
        status: 0,
        attemptCount: 0,
      );

      _swipeBox.put(entry);
      print('📦 [DiscoveryRepo] Swipe mis en queue: ${action.name}');
    } catch (e) {
      print('❌ [DiscoveryRepo] Erreur queue offline: $e');
    }
  }

  /// ✅ AMÉLIORATION: Meilleure gestion de la synchronisation
  @override
  Future<void> syncSwipes() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('⚠️ [DiscoveryRepo] Pas de connexion, sync annulée');
        return;
      }

      final pendingQuery = _swipeBox
          .query(SwipeQueue_.status.equals(0))
          .order(SwipeQueue_.createdAt)
          .build();

      final pending = pendingQuery.find();
      pendingQuery.close();

      if (pending.isEmpty) {
        print('✅ [DiscoveryRepo] Aucun swipe en attente');
        return;
      }

      print(
          '🔄 [DiscoveryRepo] Synchronisation de ${pending.length} swipes...');

      int successCount = 0;
      int failureCount = 0;

      for (final entry in pending) {
        try {
          final action = SwipeAction.fromInt(entry.action);

          await _sendSwipeOnline(
            swipedId: entry.swipedId,
            action: action,
          );

          entry.status = 1; // completed
          entry.attemptCount = 0;
          successCount++;
        } catch (e) {
          entry.attemptCount++;
          entry.status =
              entry.attemptCount >= 5 ? 2 : 0; // failed après 5 tentatives
          failureCount++;
          print('❌ [DiscoveryRepo] Échec sync swipe ${entry.swipedId}: $e');
        }

        _swipeBox.put(entry);
      }

      print(
          '✅ [DiscoveryRepo] Sync terminée: $successCount succès, $failureCount échecs');
    } catch (e, stackTrace) {
      print('❌ [DiscoveryRepo] Erreur sync globale: $e');
      print(stackTrace);
    }
  }

  /// ✅ AMÉLIORATION: Gestion d'erreur dans le stream
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
          try {
            if (response is List) {
              return response
                  .map((json) => Profile.fromMap(json as Map<String, dynamic>))
                  .toList();
            }
            return <Profile>[];
          } catch (e) {
            print('❌ [DiscoveryRepo] Erreur parsing profils: $e');
            return <Profile>[];
          }
        })
        .handleError((error) {
          print('❌ [DiscoveryRepo] Erreur stream recommendations: $error');
          return <Profile>[];
        });
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
