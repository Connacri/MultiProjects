// lib/Tinder/core/data/repositories/discovery_repository.dart

import '../../../objectBox/Entity.dart';
import '../../core/swipe_action_enum.dart';

abstract class DiscoveryRepository {
  /// Enregistre une action de swipe
  ///
  /// - Si online: envoi direct à Supabase
  /// - Si offline: mise en queue ObjectBox
  Future<void> swipe({
    required String swipedId,
    required SwipeAction action,
  });

  /// Synchronise les swipes en attente avec Supabase
  Future<void> syncSwipes();

  /// Stream des profils recommandés basé sur la géolocalisation
  Stream<List<Profile>> getRecommendations({
    required String userId,
    required double userLat,
    required double userLon,
    double maxDistanceKm = 50.0,
  });
}
