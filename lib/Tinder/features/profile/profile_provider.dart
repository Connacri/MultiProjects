// lib/Tinder/features/profile/profile_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // État privé
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  String? _error;

  // Getters publics
  Map<String, dynamic>? get profileData => _profileData;
  bool get loading => _loading;
  String? get error => _error;

  // Données utilisateur
  String get fullName =>
      _profileData?['full_name'] as String? ?? 'Utilisateur';
  String get email => _supabase.auth.currentUser?.email ?? '';
  String? get photoUrl => _profileData?['photo_url'] as String?;
  int get age => _profileData?['age'] as int? ?? 0;
  String get bio => _profileData?['bio'] as String? ?? '';
  String? get occupation => _profileData?['occupation'] as String?;
  String? get city => _profileData?['city'] as String?;

  /// Initialisation du profil
  Future<void> init() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Récupération du profil
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Timeout profil'),
          );

      _profileData = data;
      _loading = false;
      notifyListeners();

      print('✅ [ProfileProvider] Profil chargé: ${data['full_name']}');
    } catch (e, stackTrace) {
      _error = _getErrorMessage(e);
      _loading = false;
      print('❌ [ProfileProvider] Erreur init: $e');
      print(stackTrace);
      notifyListeners();
    }
  }

  /// Mise à jour du profil
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? occupation,
    String? city,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non authentifié');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (occupation != null) updates['occupation'] = occupation;
      if (city != null) updates['city'] = city;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .timeout(const Duration(seconds: 10));

      // Recharger le profil
      await init();

      print('✅ [ProfileProvider] Profil mis à jour');
    } catch (e) {
      _error = _getErrorMessage(e);
      _loading = false;
      print('❌ [ProfileProvider] Erreur update: $e');
      notifyListeners();
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _profileData = null;
      notifyListeners();
    } catch (e) {
      print('❌ [ProfileProvider] Erreur déconnexion: $e');
      rethrow;
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return 'La connexion est trop lente.';
    }
    if (errorStr.contains('network') || errorStr.contains('socket')) {
      return 'Pas de connexion Internet.';
    }
    if (errorStr.contains('auth')) {
      return 'Session expirée. Reconnectez-vous.';
    }

    return 'Une erreur est survenue.';
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
