// lib/Tinder/features/profile/profile_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? get profileData => _profileData;

  bool get loading => _loading;

  String? get error => _error;

  // ✅ Getters sécurisés
  String get fullName => _profileData?['full_name'] as String? ?? '';

  String get email => _supabase.auth.currentUser?.email ?? '';

  String? get photoUrl => _profileData?['photo_url'] as String?;

  String? get coverUrl => _profileData?['cover_url'] as String?;

  int get age {
    final dob = _profileData?['date_of_birth'];
    if (dob == null) return 0;
    try {
      final birthDate = DateTime.parse(dob.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String get bio => _profileData?['bio'] as String? ?? '';

  String? get occupation => _profileData?['occupation'] as String?;

  String? get city => _profileData?['city'] as String?;

  String? get gender => _profileData?['gender'] as String?;

  String? get lookingFor => _profileData?['looking_for'] as String?;

  bool get profileCompleted =>
      _profileData?['profile_completed'] as bool? ?? false;

  int get completionPercentage =>
      _profileData?['completion_percentage'] as int? ?? 0;

  List<String> get photos {
    final photosJson = _profileData?['photos'];
    if (photosJson is List) {
      return photosJson.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get interests {
    final interestsData = _profileData?['interests'];
    if (interestsData is List) {
      return List<String>.from(interestsData);
    }
    return [];
  }

  /// ✅ CORRECTION : Gestion du cas "profile inexistant"
// lib/Tinder/features/profile/profile_provider.dart

// lib/Tinder/features/profile/profile_provider.dart

  Future<void> init() async {
    print('🚀 [ProfileProvider] DÉBUT INIT');
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('ℹ️ [ProfileProvider] Aucun utilisateur connecté');
        _loading = false;
        _error = "Utilisateur non authentifié";
        notifyListeners();
        return;
      }

      print('👤 [ProfileProvider] User ID: ${user.id}');
      print('📧 [ProfileProvider] Email: ${user.email}');

      // Tentative de lecture
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        print('⚠️ [ProfileProvider] Profil inexistant en base, création...');
        await _createProfile(user.id);
        // Récupération après création
        _profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        print('✅ [ProfileProvider] Profil créé et récupéré');
      } else {
        _profileData = data;
        print('✅ [ProfileProvider] Profil chargé avec succès');
        print('📊 [ProfileProvider] Complétion: ${completionPercentage}%');
      }
    } catch (e, stacktrace) {
      print('❌ [ProfileProvider] ERREUR CRITIQUE: $e');
      print('📜 [ProfileProvider] STACKTRACE: $stacktrace');
      _error = e.toString();
    } finally {
      _loading = false;
      print(
          '🏁 [ProfileProvider] FIN INIT - Loading: $_loading, Error: $_error');
      notifyListeners();
    }
  }

  /// ✅ Créer un profile vide si inexistant
  Future<void> _createProfile(String userId) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': _supabase.auth.currentUser?.email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('✅ [ProfileProvider] Profile créé');
    } catch (e) {
      print('❌ [ProfileProvider] Erreur création profile: $e');
      rethrow;
    }
  }

  /// ✅ Mise à jour du profil
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? occupation,
    String? city,
    String? photoUrl,
    String? coverUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? lookingFor,
    List<String>? interests,
    double? latitude,
    double? longitude,
    String? education,
    int? heightCm,
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
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (coverUrl != null) updates['cover_url'] = coverUrl;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
      }
      if (gender != null) updates['gender'] = gender;
      if (lookingFor != null) updates['looking_for'] = lookingFor;
      if (interests != null) updates['interests'] = interests;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (education != null) updates['education'] = education;
      if (heightCm != null) updates['height_cm'] = heightCm;

      await _supabase.from('profiles').update(updates).eq('id', userId);

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

  /// ✅ Upload photo de profil ou cover
  Future<String?> uploadPhoto(File file, {bool isCover = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName =
          '${userId}/${isCover ? 'cover' : 'avatar'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucket = isCover ? 'covers' : 'avatars';

      await _supabase.storage.from(bucket).upload(fileName, file);

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(fileName);

      // Mettre à jour le profil
      await updateProfile(
        photoUrl: isCover ? null : publicUrl,
        coverUrl: isCover ? publicUrl : null,
      );

      print('✅ [ProfileProvider] Photo uploadée: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ [ProfileProvider] Erreur upload photo: $e');
      return null;
    }
  }

  /// ✅ Ajouter une photo au carousel (max 6)
  Future<bool> addPhotoToGallery(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Limite de 6 photos
      if (photos.length >= 6) {
        _error = 'Maximum 6 photos atteint';
        notifyListeners();
        return false;
      }

      final fileName =
          '${userId}/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('gallery').upload(fileName, file);

      final publicUrl =
          _supabase.storage.from('gallery').getPublicUrl(fileName);

      // Ajouter à l'array photos
      final currentPhotos = List<String>.from(photos);
      currentPhotos.add(publicUrl);

      await _supabase
          .from('profiles')
          .update({'photos': currentPhotos}).eq('id', userId);

      await init();
      print('✅ [ProfileProvider] Photo ajoutée à la galerie');
      return true;
    } catch (e) {
      print('❌ [ProfileProvider] Erreur ajout photo: $e');
      _error = 'Erreur lors de l\'ajout de la photo';
      notifyListeners();
      return false;
    }
  }

  /// ✅ Supprimer une photo de la galerie
  Future<bool> removePhotoFromGallery(String photoUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Retirer de l'array
      final currentPhotos = List<String>.from(photos);
      currentPhotos.remove(photoUrl);

      await _supabase
          .from('profiles')
          .update({'photos': currentPhotos}).eq('id', userId);

      // Supprimer du storage
      try {
        final fileName = photoUrl.split('/').last;
        await _supabase.storage.from('gallery').remove(['${userId}/$fileName']);
      } catch (e) {
        print('⚠️ [ProfileProvider] Erreur suppression storage: $e');
      }

      await init();
      return true;
    } catch (e) {
      print('❌ [ProfileProvider] Erreur suppression photo: $e');
      return false;
    }
  }

  /// ✅ Obtenir les champs manquants pour compléter le profil
  List<String> getMissingFields() {
    final missing = <String>[];

    if (fullName.isEmpty) missing.add('Nom complet');
    if (_profileData?['date_of_birth'] == null)
      missing.add('Date de naissance');
    if (gender == null) missing.add('Genre');
    if (lookingFor == null) missing.add('Recherche');
    if (bio.length < 20) missing.add('Bio (min 20 caractères)');
    if (city == null) missing.add('Ville');
    if (occupation == null) missing.add('Profession');
    if (photoUrl == null) missing.add('Photo de profil');
    if (photos.length < 2) missing.add('Photos (min 2)');
    if (interests.length < 3) missing.add('Centres d\'intérêt (min 3)');

    return missing;
  }

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

  Future<void> refresh() async {
    await init();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout')) return 'Connexion trop lente';
    if (errorStr.contains('network')) return 'Pas de connexion Internet';
    if (errorStr.contains('auth')) return 'Session expirée';
    return 'Une erreur est survenue';
  }
}
