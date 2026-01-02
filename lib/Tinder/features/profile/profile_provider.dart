// features/profile/presentation/providers/profile_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  String? _error;
  bool _hasInitialized = false;

  Map<String, dynamic>? get profileData => _profileData;

  bool get loading => _loading;

  String? get error => _error;

  bool get profileCompleted => _profileData?['profile_completed'] ?? false;

  int get completionPercentage => _profileData?['completion_percentage'] ?? 0;

  // Getters sécurisés
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

  String? get country => _profileData?['country'] as String?;

  String? get gender => _profileData?['gender'] as String?;

  String? get lookingFor => _profileData?['looking_for'] as String?;

  List<String> get interests =>
      List<String>.from(_profileData?['interests'] ?? []);

  List<String> get photos => List<String>.from(_profileData?['photos'] ?? []);

  int? get heightCm => _profileData?['height_cm'] as int?;

  String? get education => _profileData?['education'] as String?;

  String? get relationshipStatus =>
      _profileData?['relationship_status'] as String?;

  String? get instagramHandle => _profileData?['instagram_handle'] as String?;

  String? get spotifyAnthem => _profileData?['spotify_anthem'] as String?;

  double? get latitude => _profileData?['latitude'] as double?;

  double? get longitude => _profileData?['longitude'] as double?;

  Future<void> init() async {
    if (_hasInitialized) return;

    _hasInitialized = true;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _error = 'Session expirée';
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        await _createProfile(user.id);
        await init();
        return;
      }

      _profileData = response;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = _getErrorMessage(e);
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _createProfile(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': _supabase.auth.currentUser?.email,
        'created_at': now,
        'updated_at': now,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadPhoto(File file, {bool isCover = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      final extension = file.path.split('.').last;
      final path = '$userId/${isCover ? 'cover' : 'photo'}.$extension';

      await _supabase.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage.from('profiles').getPublicUrl(path);

      await updateProfile(
          photoUrl: isCover ? null : url, coverUrl: isCover ? url : null);

      return url;
    } catch (e) {
      print('❌ Erreur upload photo: $e');
      rethrow;
    }
  }

  Future<String?> addPhotoToGallery(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      final extension = file.path.split('.').last;
      final path =
          '$userId/gallery/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage.from('profiles').getPublicUrl(path);

      final currentPhotos = photos..add(url);

      await updateProfile(photos: currentPhotos);

      return url;
    } catch (e) {
      print('❌ Erreur add to gallery: $e');
      rethrow;
    }
  }

  Future<void> removePhotoFromGallery(String url) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      final path = url.split('profiles/')[1];

      await _supabase.storage.from('profiles').remove([path]);

      final updatedPhotos = photos..remove(url);

      await updateProfile(photos: updatedPhotos);
    } catch (e) {
      print('❌ Erreur remove from gallery: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? occupation,
    String? city,
    String? country,
    DateTime? dateOfBirth,
    String? gender,
    String? lookingFor,
    List<String>? interests,
    int? heightCm,
    String? education,
    String? relationshipStatus,
    String? instagramHandle,
    String? spotifyAnthem,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? coverUrl,
    List<String>? photos,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        if (fullName != null) 'full_name': fullName,
        if (bio != null) 'bio': bio,
        if (occupation != null) 'occupation': occupation,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (gender != null) 'gender': gender,
        if (lookingFor != null) 'looking_for': lookingFor,
        if (interests != null) 'interests': interests,
        if (heightCm != null) 'height_cm': heightCm,
        if (education != null) 'education': education,
        if (relationshipStatus != null)
          'relationship_status': relationshipStatus,
        if (instagramHandle != null) 'instagram_handle': instagramHandle,
        if (spotifyAnthem != null) 'spotify_anthem': spotifyAnthem,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (photos != null) 'photos': photos,
      };

      await _supabase.from('profiles').update(updates).eq('id', userId);

      await init(); // Recharge

      final percentage = _calculateCompletionPercentage();
      final completed = percentage >= 80;

      await _supabase.from('profiles').update({
        'completion_percentage': percentage,
        'profile_completed': completed,
      }).eq('id', userId);

      await init();
    } catch (e) {
      _error = _getErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  int _calculateCompletionPercentage() {
    int score = 0;

    if (fullName.isNotEmpty) score += 10;
    if (_profileData?['date_of_birth'] != null) score += 10;
    if (gender != null) score += 5;
    if (lookingFor != null) score += 5;
    if (bio.isNotEmpty) score += 10;
    if (city != null) score += 5;
    if (country != null) score += 5;
    if (photoUrl != null) score += 10;
    if (coverUrl != null) score += 10;
    if (photos.length >= 2) score += 10;
    if (interests.isNotEmpty) score += 5;
    if (heightCm != null) score += 5;
    if (education != null) score += 5;
    if (relationshipStatus != null) score += 5;
    if (instagramHandle != null) score += 5;
    if (spotifyAnthem != null) score += 5;
    if (latitude != null && longitude != null) score += 5;

    return score.clamp(0, 100);
  }

  List<String> getMissingFields() {
    final missing = <String>[];

    if (fullName.isEmpty) missing.add('Nom complet');
    if (_profileData?['date_of_birth'] == null)
      missing.add('Date de naissance');
    if (gender == null) missing.add('Genre');
    if (lookingFor == null) missing.add('Recherche');
    if (bio.isEmpty) missing.add('Bio');
    if (city == null) missing.add('Ville');
    if (photoUrl == null) missing.add('Photo de profil');
    if (photos.length < 2) missing.add('Au moins 2 photos dans la galerie');

    return missing;
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _profileData = null;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    _hasInitialized = false;
    await init();
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout')) return 'Connexion trop lente';
    if (errorStr.contains('network')) return 'Pas de connexion Internet';
    if (errorStr.contains('auth')) return 'Session expirée';
    return 'Une erreur est survenue';
  }

  @override
  void dispose() {
    _hasInitialized = false;
    super.dispose();
  }
}
