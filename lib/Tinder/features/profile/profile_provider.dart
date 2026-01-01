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

  List<String> get interests =>
      List<String>.from(_profileData?['interests'] ?? []);

  List<String> get photos => List<String>.from(_profileData?['photos'] ?? []);

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
        await init(); // Recharge après création
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
        'profile_completed': false,
        'completion_percentage': 0,
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
      final path = '$userId/${isCover ? 'cover' : 'avatar'}.$extension';

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
      print('❌ [ProfileProvider] Erreur upload: $e');
      rethrow;
    }
  }

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
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (bio != null) 'bio': bio,
        if (occupation != null && occupation.isNotEmpty)
          'occupation': occupation,
        if (city != null && city.isNotEmpty) 'city': city,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (lookingFor != null && lookingFor.isNotEmpty)
          'looking_for': lookingFor,
        if (interests != null && interests.isNotEmpty) 'interests': interests,
      };

      await _supabase.from('profiles').update(updates).eq('id', userId);

      // Recharger les données
      await init();

      // Calculer et mettre à jour la complétion
      final percentage = _calculateCompletionPercentage();
      final completed = percentage >= 90;

      await _supabase.from('profiles').update({
        'completion_percentage': percentage,
        'profile_completed': completed,
      }).eq('id', userId);

      // Recharger une dernière fois
      await init();

      _error = null;
    } catch (e) {
      _error = _getErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ✅ Ajouter une photo à la galerie
  Future<String?> addPhotoToGallery(File file) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final path = '$userId/gallery/$timestamp.$extension';

      await _supabase.storage.from('profiles').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage.from('profiles').getPublicUrl(path);

      // Récupérer la liste actuelle
      final currentPhotos = photos;

      // Ajouter la nouvelle
      final updatedPhotos = [...currentPhotos, url];

      // Mettre à jour en base
      await _supabase.from('profiles').update({
        'photos': updatedPhotos,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Recharger profil + recalcul complétion
      await init();

      return url;
    } catch (e) {
      print('❌ [ProfileProvider] Erreur addPhotoToGallery: $e');
      rethrow;
    }
  }

  // ✅ Supprimer une photo de la galerie
  Future<void> removePhotoFromGallery(String photoUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Non authentifié');

      // Extraire le path depuis l'URL publique
      final path = photoUrl.replaceFirst(
        '${_supabase.storage.from('profiles').getPublicUrl('')}/',
        '',
      );

      // Supprimer du storage
      await _supabase.storage.from('profiles').remove([path]);

      // Mettre à jour la liste en base
      final currentPhotos = photos;
      final updatedPhotos =
          currentPhotos.where((url) => url != photoUrl).toList();

      await _supabase.from('profiles').update({
        'photos': updatedPhotos,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Recharger + recalcul complétion
      await init();
    } catch (e) {
      print('❌ [ProfileProvider] Erreur removePhotoFromGallery: $e');
      rethrow;
    }
  }

  // ✅ Mise à jour du calcul de complétion (ajusté pour galerie)
  int _calculateCompletionPercentage() {
    int score = 0;

    if (fullName.isNotEmpty) score += 15;
    if (_profileData?['date_of_birth'] != null) score += 15;
    if (gender != null && gender!.isNotEmpty) score += 10;
    if (lookingFor != null && lookingFor!.isNotEmpty) score += 10;
    if (bio.length >= 20) score += 15;
    if (city != null && city!.isNotEmpty) score += 10;
    if (photoUrl != null) score += 10; // photo principale
    if (photos.length >= 2)
      score += 15; // galerie : min 2 photos supplémentaires

    return score.clamp(0, 100);
  }

  // ✅ Mise à jour getMissingFields
  List<String> getMissingFields() {
    final missing = <String>[];

    if (fullName.isEmpty) missing.add('Nom complet');
    if (_profileData?['date_of_birth'] == null)
      missing.add('Date de naissance');
    if (gender == null) missing.add('Genre');
    if (lookingFor == null) missing.add('Recherche');
    if (bio.length < 20) missing.add('Bio (min 20 caractères)');
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
      print('❌ [ProfileProvider] Erreur déconnexion: $e');
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
