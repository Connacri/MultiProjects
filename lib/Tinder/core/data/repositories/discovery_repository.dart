// features/discovery/domain/repositories/discovery_repository.dart

import '../../../features/profile/profile.dart';

abstract class DiscoveryRepository {
  Future<void> swipe({
    required String swipedId,
    required int action, // 0=pass, 1=like, 2=superlike
  });

  Future<void> syncSwipes();

  Stream<List<Profile>> getRecommendations({
    required String userId,
    required double userLat,
    required double userLon,
    double maxDistanceKm = 50.0,
  });
}
