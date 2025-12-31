// lib/Tinder/features/discovery/discovery_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/repositories/discovery_repository_impl.dart';
import '../../core/swipe_action_enum.dart';
import '../profile/profile.dart';

class DiscoveryProvider extends ChangeNotifier {
  final DiscoveryRepositoryImpl repo = DiscoveryRepositoryImpl();

  // ✅ État privé
  List<Profile> _profiles = [];
  bool _loading = true;
  String? _error;
  StreamSubscription? _sub;

  // ✅ Getters publics
  List<Profile> get profiles => List.unmodifiable(_profiles);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasProfiles => _profiles.isNotEmpty;

  /// ✅ AMÉLIORATION: Initialisation avec gestion d'erreur
  Future<void> init() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Récupération des coordonnées utilisateur
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('latitude, longitude')
          .eq('id', userId)
          .single()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout coordonnées'),
          );

      final lat = (profile['latitude'] as num?)?.toDouble() ?? 48.8566;
      final lon = (profile['longitude'] as num?)?.toDouble() ?? 2.3522;

      print('📍 [DiscoveryProvider] Position: ($lat, $lon)');

      // Annuler l'ancien stream
      await _sub?.cancel();

      // ✅ Écoute du stream de recommandations
      _sub = repo
          .getRecommendations(
        userId: userId,
        userLat: lat,
        userLon: lon,
      )
          .listen(
        (data) {
          _profiles = data;
          _loading = false;
          _error = null;
          print('✅ [DiscoveryProvider] ${data.length} profils reçus');
          notifyListeners();
        },
        onError: (e) {
          _error = _getErrorMessage(e);
          _loading = false;
          print('❌ [DiscoveryProvider] Erreur stream: $e');
          notifyListeners();
        },
      );

      // ✅ Synchroniser les swipes en attente
      await repo.syncSwipes();
    } catch (e, stackTrace) {
      _error = _getErrorMessage(e);
      _loading = false;
      print('❌ [DiscoveryProvider] Erreur init: $e');
      print(stackTrace);
      notifyListeners();
    }
  }

  /// ✅ AMÉLIORATION: Swipe avec animation optimiste + rollback
  Future<void> onSwipe(Profile profile, SwipeAction action) async {
    // ✅ Optimistic update: retirer le profil immédiatement
    final index = _profiles.indexWhere((p) => p.id == profile.id);

    if (index == -1) {
      print('⚠️ [DiscoveryProvider] Profil déjà retiré');
      return;
    }

    final removedProfile = _profiles[index];
    _profiles = List.from(_profiles)..removeAt(index);
    notifyListeners();

    try {
      // ✅ Envoi du swipe
      await repo.swipe(
        swipedId: profile.id,
        action: action,
      );

      print(
          '✅ [DiscoveryProvider] Swipe ${action.name} sur ${profile.fullName}');

      // ✅ Vérifier si c'est un match (si like ou superlike)
      if (action == SwipeAction.like || action == SwipeAction.superlike) {
        await _checkForMatch(profile.id);
      }
    } catch (e) {
      // ✅ Rollback: remettre le profil en cas d'erreur critique
      print('❌ [DiscoveryProvider] Erreur swipe, rollback: $e');

      _profiles = List.from(_profiles)..insert(index, removedProfile);
      _error = _getErrorMessage(e);
      notifyListeners();
    }
  }

  /// ✅ NOUVEAU: Vérifier si un match s'est créé
  Future<void> _checkForMatch(String swipedId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final result =
          await Supabase.instance.client.rpc('check_mutual_like', params: {
        'user1': userId,
        'user2': swipedId,
      }).single();

      if (result['is_match'] == true) {
        print('🎉 [DiscoveryProvider] MATCH avec $swipedId !');
        // TODO: Déclencher animation match
      }
    } catch (e) {
      print('⚠️ [DiscoveryProvider] Erreur check match: $e');
    }
  }

  /// ✅ NOUVEAU: Recharger les profils
  Future<void> refresh() async {
    await init();
  }

  /// ✅ AMÉLIORATION: Messages d'erreur utilisateur-friendly
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return 'La connexion est trop lente. Vérifiez votre réseau.';
    }
    if (errorStr.contains('network') || errorStr.contains('socket')) {
      return 'Pas de connexion Internet. Vérifiez votre Wi-Fi ou vos données mobiles.';
    }
    if (errorStr.contains('auth')) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    if (errorStr.contains('permission')) {
      return 'Permissions insuffisantes. Contactez le support.';
    }

    return 'Une erreur est survenue. Réessayez plus tard.';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
