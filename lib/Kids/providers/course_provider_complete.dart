import 'dart:io';

import 'package:flutter/material.dart';

import '../models/course_model_complete.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart' show LocationService;
import '../services/supabase_service.dart';

/// Provider complet pour la gestion des cours avec Supabase
class CourseProvider extends ChangeNotifier {
  final SupabaseCourseService _courseService = SupabaseCourseService();
  final ImageStorageService _imageService = ImageStorageService();
  final LocationService _locationService = LocationService();

  List<CourseModel> _courses = [];
  List<CourseModel> _userCourses = [];
  CourseModel? _selectedCourse;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreCourses = true;
  DateTime? _lastDocumentTimestamp;

  final ValueNotifier<double> uploadProgressNotifier =
      ValueNotifier<double>(0.0);

  // Getters
  List<CourseModel> get courses => _courses;

  List<CourseModel> get userCourses => _userCourses;

  CourseModel? get selectedCourse => _selectedCourse;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasMoreCourses => _hasMoreCourses;

  double get uploadProgress => uploadProgressNotifier.value;

  @override
  void dispose() {
    uploadProgressNotifier.dispose();
    super.dispose();
  }

  /// Charge une liste de cours avec pagination et filtres
  Future<void> loadCourses({
    bool refresh = false,
    CourseSeason? season,
    CourseCategory? category,
    bool? isActive = true,
  }) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _courses.clear();
        _lastDocumentTimestamp = null;
        _hasMoreCourses = true;
      }

      final newCourses = await _courseService.getCourses(
        limit: 20,
        lastDocumentTimestamp: _lastDocumentTimestamp,
        season: season,
        category: category,
        isActive: isActive,
      );

      if (newCourses.isEmpty) {
        _hasMoreCourses = false;
      } else {
        _courses.addAll(newCourses);
        _lastDocumentTimestamp = newCourses.last.createdAt;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours: $e');
      print(e);
      _setLoading(false);
    }
  }

  /// 🔧 FIX : Crée un nouveau cours dans Supabase
  /// ✅ STRATÉGIE CORRECTE : Créer le cours D'ABORD, puis uploader les images avec le vrai ID
  Future<bool> createCourse({
    required String title,
    required String description,
    required CourseCategory category,
    double? price,
    String currency = 'EUR',
    required CourseSeason season,
    required DateTime seasonStartDate,
    required DateTime seasonEndDate,
    required CourseLocation location,
    required List<File> imageFiles,
    required String currentUserId,
    required String currentUserRole,
    int maxStudents = 30,
    List<String> tags = const [],
    Map<String, dynamic>? metadata,
    Function(int current, int total)? onImageUploadProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _setUploadProgress(0.0);

      print(
          '╔═══════════════════════════════════════════════════════════════════');
      print('🔵 [CourseProvider] Création cours - DÉBUT');
      print(
          '╚═══════════════════════════════════════════════════════════════════');

      // 🎯 ÉTAPE 1 : Créer le cours SANS images pour obtenir l'ID réel de Supabase
      print('📝 [CourseProvider] ÉTAPE 1/3 : Création cours (sans images)...');

      final newCourse = CourseModel(
        id: '',
        // ✅ Vide, Supabase va générer l'UUID
        title: title,
        description: description,
        category: category,
        price: price,
        currency: currency,
        season: season,
        seasonStartDate: seasonStartDate,
        seasonEndDate: seasonEndDate,
        location: location,
        images: [],
        // ✅ Vide au départ
        createdBy: currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        maxStudents: maxStudents,
        currentStudents: 0,
        tags: tags,
        metadata: metadata,
      );

      final courseId = await _courseService.createCourse(newCourse);
      print('✅ [CourseProvider] Cours créé avec ID: $courseId');

      // 🎯 ÉTAPE 2 : Upload des images avec le VRAI courseId
      List<CourseImage> uploadedImages = [];
      if (imageFiles.isNotEmpty) {
        print(
            '📤 [CourseProvider] ÉTAPE 2/3 : Upload ${imageFiles.length} images...');

        uploadedImages = await _imageService.uploadMultipleCourseImages(
          imageFiles: imageFiles,
          courseId: courseId, // ✅ Utilise le vrai ID de Supabase
          onProgress: (current, total) {
            _setUploadProgress(current / total);
            onImageUploadProgress?.call(current, total);
            print('📤 [CourseProvider] Progression upload: $current/$total');
          },
        );

        print('✅ [CourseProvider] ${uploadedImages.length} images uploadées');
      } else {
        print('⚠️ [CourseProvider] Aucune image à uploader');
      }

      // 🎯 ÉTAPE 3 : Mettre à jour le cours avec les URLs des images
      if (uploadedImages.isNotEmpty) {
        print(
            '📝 [CourseProvider] ÉTAPE 3/3 : Mise à jour cours avec images...');

        await _courseService.updateCourse(
          courseId,
          {
            'images': uploadedImages.map((img) => img.toMap()).toList(),
          },
        );

        print(
            '✅ [CourseProvider] Cours mis à jour avec ${uploadedImages.length} images');
      }

      // 🎯 ÉTAPE 4 : Re-fetch pour avoir les données complètes
      print('🔄 [CourseProvider] ÉTAPE 4/4 : Récupération cours complet...');

      final createdCourse = await _courseService.getCourse(courseId);
      if (createdCourse != null) {
        _courses.insert(0, createdCourse);
        _userCourses.insert(0, createdCourse);
        print('✅ [CourseProvider] Cours ajouté aux listes locales');
      } else {
        print('⚠️ [CourseProvider] Impossible de récupérer le cours créé');
      }

      _setLoading(false);
      _setUploadProgress(0.0);

      print(
          '╔═══════════════════════════════════════════════════════════════════');
      print('✅ [CourseProvider] Création cours - SUCCÈS');
      print(
          '╚═══════════════════════════════════════════════════════════════════');

      return true;
    } catch (e, stackTrace) {
      print(
          '╔═══════════════════════════════════════════════════════════════════');
      print('❌ [CourseProvider] ERREUR création cours: $e');
      print('❌ [CourseProvider] StackTrace: $stackTrace');
      print(
          '╚═══════════════════════════════════════════════════════════════════');

      _setError('Erreur lors de la création du cours: $e');
      _setLoading(false);
      _setUploadProgress(0.0);
      return false;
    }
  }

  /// Met à jour un cours existant
  Future<bool> updateCourse({
    required String courseId,
    String? title,
    String? description,
    CourseCategory? category,
    double? price,
    String? currency,
    CourseSeason? season,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    CourseLocation? location,
    List<File>? newImageFiles,
    int? maxStudents,
    List<String>? tags,
    bool? isActive,
    Map<String, dynamic>? metadata,
    Function(int current, int total)? onImageUploadProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _setUploadProgress(0.0);

      print('🔵 [CourseProvider] Mise à jour cours: $courseId');

      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.name;
      if (price != null) updates['price'] = price;
      if (currency != null) updates['currency'] = currency;
      if (season != null) updates['season'] = season.name;
      if (seasonStartDate != null) {
        updates['season_start_date'] = seasonStartDate.toIso8601String();
      }
      if (seasonEndDate != null) {
        updates['season_end_date'] = seasonEndDate.toIso8601String();
      }
      if (location != null) updates['location'] = location.toMap();
      if (maxStudents != null) updates['max_students'] = maxStudents;
      if (tags != null) updates['tags'] = tags;
      if (isActive != null) updates['is_active'] = isActive;
      if (metadata != null) updates['metadata'] = metadata;

      // Upload des nouvelles images
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        print(
            '📤 [CourseProvider] Upload ${newImageFiles.length} nouvelles images...');

        final uploadedImages = await _imageService.uploadMultipleCourseImages(
          imageFiles: newImageFiles,
          courseId: courseId,
          onProgress: (current, total) {
            _setUploadProgress(current / total);
            onImageUploadProgress?.call(current, total);
          },
        );

        final existingCourse = await _courseService.getCourse(courseId);
        if (existingCourse != null) {
          final allImages = [...existingCourse.images, ...uploadedImages];
          updates['images'] = allImages.map((img) => img.toMap()).toList();
          print('✅ [CourseProvider] Total images: ${allImages.length}');
        }
      }

      // Mettre à jour dans Supabase
      await _courseService.updateCourse(courseId, updates);

      // Re-fetch pour avoir les données à jour
      final updatedCourse = await _courseService.getCourse(courseId);
      if (updatedCourse != null) {
        _updateLocalCourse(updatedCourse);
      }

      _setLoading(false);
      _setUploadProgress(0.0);
      notifyListeners();

      print('✅ [CourseProvider] Cours mis à jour avec succès');
      return true;
    } catch (e, stackTrace) {
      print('❌ [CourseProvider] Erreur mise à jour: $e');
      print('❌ [CourseProvider] StackTrace: $stackTrace');

      _setError('Erreur lors de la mise à jour: $e');
      _setLoading(false);
      _setUploadProgress(0.0);
      return false;
    }
  }

  /// Supprime un cours
  Future<bool> deleteCourse(String courseId) async {
    try {
      _setLoading(true);
      _clearError();

      print('🗑️ [CourseProvider] Suppression cours: $courseId');

      // Récupérer le cours pour supprimer les images
      final course = await _courseService.getCourse(courseId);

      if (course != null && course.images.isNotEmpty) {
        print(
            '🗑️ [CourseProvider] Suppression ${course.images.length} images...');
        await _imageService.deleteMultipleImages(course.images, courseId);
      }

      // Supprimer de Supabase
      await _courseService.deleteCourse(courseId);

      // Retirer localement
      _courses.removeWhere((c) => c.id == courseId);
      _userCourses.removeWhere((c) => c.id == courseId);

      if (_selectedCourse?.id == courseId) {
        _selectedCourse = null;
      }

      _setLoading(false);
      notifyListeners();

      print('✅ [CourseProvider] Cours supprimé avec succès');
      return true;
    } catch (e, stackTrace) {
      print('❌ [CourseProvider] Erreur suppression: $e');
      print('❌ [CourseProvider] StackTrace: $stackTrace');

      _setError('Erreur lors de la suppression: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Charge les cours d'un utilisateur
  Future<void> loadUserCourses(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      _userCourses = await _courseService.getUserCourses(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours utilisateur: $e');
      print(e);
      _setLoading(false);
    }
  }

  /// Charge un cours spécifique
  Future<void> loadCourseById(String courseId) async {
    try {
      _setLoading(true);
      _clearError();
      _selectedCourse = await _courseService.getCourse(courseId);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement du cours: $e');
      print(e);
      _setLoading(false);
    }
  }

  /// Supprime une image d'un cours
  Future<bool> removeImageFromCourse(String courseId, CourseImage image) async {
    try {
      await _imageService.deleteCourseImage(image, courseId);

      final course = await _courseService.getCourse(courseId);
      if (course != null) {
        final updatedImages =
            course.images.where((img) => img.id != image.id).toList();
        await _courseService.updateCourse(
          courseId,
          {'images': updatedImages.map((img) => img.toMap()).toList()},
        );
        _updateLocalCourse(course.copyWith(images: updatedImages));
      }
      return true;
    } catch (e) {
      _setError("Erreur lors de la suppression de l'image: $e");
      print(e);
      return false;
    }
  }

  /// Recherche de cours
  Future<List<CourseModel>> searchCourses(String searchTerm) async {
    try {
      return await _courseService.searchCourses(searchTerm);
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      print(e);
      return [];
    }
  }

  /// Tri par distance géographique
  Future<void> sortCoursesByDistance() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) return;

      _courses = await _locationService.sortCoursesByDistance(
        _courses,
        position.latitude,
        position.longitude,
      );
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du tri par distance: $e');
      print(e);
    }
  }

  /// Charge les cours à proximité
  Future<void> loadCoursesNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _courses = await _courseService.getCoursesNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours à proximité: $e');
      print(e);
      _setLoading(false);
    }
  }

  /// Filtres locaux
  List<CourseModel> filterCoursesBySeason(CourseSeason season) {
    return _courses.where((course) => course.season == season).toList();
  }

  List<CourseModel> filterCoursesByCategory(CourseCategory category) {
    return _courses.where((course) => course.category == category).toList();
  }

  List<CourseModel> getAvailableCourses() {
    return _courses.where((course) => course.isAvailableNow()).toList();
  }

  /// Sélectionne un cours
  void selectCourse(CourseModel? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  /// Vide les listes locales
  void clearCourses() {
    _courses.clear();
    _userCourses.clear();
    _selectedCourse = null;
    _lastDocumentTimestamp = null;
    _hasMoreCourses = true;
    notifyListeners();
  }

  // === Méthodes privées ===

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setUploadProgress(double progress) {
    uploadProgressNotifier.value = progress;
  }

  void _updateLocalCourse(CourseModel updatedCourse) {
    final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) {
      _courses[index] = updatedCourse;
    }

    final userIndex = _userCourses.indexWhere((c) => c.id == updatedCourse.id);
    if (userIndex != -1) {
      _userCourses[userIndex] = updatedCourse;
    }
  }
}
