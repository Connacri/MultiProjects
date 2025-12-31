import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/entities/profile.dart';

class DiscoveryProvider extends ChangeNotifier {
  final DiscoveryRepositoryImpl repo = DiscoveryRepositoryImpl();
  List<Profile> _profiles = [];

  List<Profile> get profiles => _profiles;
  bool loading = true;

  StreamSubscription? _sub;

  void init() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('latitude, longitude')
        .eq('id', userId)
        .single();

    final lat = profile['latitude']?.toDouble() ?? 48.8566;
    final lon = profile['longitude']?.toDouble() ?? 2.3522;

    _sub?.cancel();
    _sub = repo
        .getRecommendations(
      userId: userId,
      userLat: lat,
      userLon: lon,
    )
        .listen((data) {
      _profiles = data;
      loading = false;
      notifyListeners();
    });
  }

  Future<void> onSwipe(Profile profile, String action) async {
    await repo.swipe(profile.id, action);
    _profiles.remove(profile);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
