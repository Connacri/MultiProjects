import 'dart:io';

import 'package:flutter/material.dart';

import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../services/hybrid_cloud_service.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart' show LocationService;

class CourseProvider extends ChangeNotifier {
  final HybridCloudService _cloudService = HybridCloudService();
  final ImageStorageService _imageService = ImageStorageService();
  final LocationService _locationService = LocationService();

  List<CourseModel> _courses = [];
  List<CourseModel> _userCourses = [];
  CourseModel? _selectedCourse;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreCourses = true;
  String? _lastDocumentId;

  List<CourseModel> get courses => _courses;

  List<CourseModel> get userCourses => _userCourses;

  CourseModel? get selectedCourse => _selectedCourse;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasMoreCourses => _hasMoreCourses;

  CloudProvider get activeCloudProvider => _cloudService.activeProvider;

  Map<String, dynamic> get cloudUsageStats => _cloudService.getUsageStats();

  Future<void> initialize() async {
    await _cloudService.initialize();
    notifyListeners();
  }

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
        _lastDocumentId = null;
        _hasMoreCourses = true;
      }

      final newCourses = await _cloudService.getCourses(
        limit: 20,
        lastDocumentId: _lastDocumentId,
        season: season,
        category: category,
        isActive: isActive,
      );

      if (newCourses.isEmpty) {
        _hasMoreCourses = false;
      } else {
        _courses.addAll(newCourses);
        _lastDocumentId = newCourses.last.id;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours: $e');
      _setLoading(false);
    }
  }

  Future<void> loadUserCourses(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final allCourses = await _cloudService.getCourses(limit: 100);
      // CORRECTION: Vérifier si course.createdBy n'est pas null avant la comparaison
      _userCourses =
          allCourses.where((course) => course.createdBy == userId).toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des cours utilisateur: $e');
      _setLoading(false);
    }
  }

  Future<void> loadCourseById(String courseId) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedCourse = await _cloudService.getCourse(courseId);

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement du cours: $e');
      _setLoading(false);
    }
  }

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
    required UserModel currentUser,
    int maxStudents = 30,
    List<String> tags = const [],
    Map<String, dynamic>? metadata,
    Function(int current, int total)? onImageUploadProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final tempCourseId = DateTime.now().millisecondsSinceEpoch.toString();

      final uploadedImages = await _imageService.uploadMultipleCourseImages(
        imageFiles: imageFiles,
        courseId: tempCourseId,
        syncBothClouds: true,
        onProgress: onImageUploadProgress,
      );

      if (uploadedImages.isEmpty) {
        throw Exception('Aucune image n\'a pu être uploadée');
      }

      final course = CourseModel(
        id: tempCourseId,
        title: title,
        description: description,
        category: category,
        price: price,
        currency: currency,
        season: season,
        seasonStartDate: seasonStartDate,
        seasonEndDate: seasonEndDate,
        location: location,
        images: uploadedImages,
        createdBy: currentUser.uid,
        createdByRole: currentUser.role.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        maxStudents: maxStudents,
        currentStudents: 0,
        tags: tags,
        metadata: metadata,
      );

      final courseId = await _cloudService.createCourse(course);
      final createdCourse = course.copyWith(id: courseId);

      _courses.insert(0, createdCourse);
      _userCourses.insert(0, createdCourse);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la création du cours: $e');
      _setLoading(false);
      return false;
    }
  }

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

      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.name;
      if (price != null) updates['price'] = price;
      if (currency != null) updates['currency'] = currency;
      if (season != null) updates['season'] = season.name;
      if (seasonStartDate != null) {
        updates['seasonStartDate'] = seasonStartDate;
      }
      if (seasonEndDate != null) {
        updates['seasonEndDate'] = seasonEndDate;
      }
      if (location != null) updates['location'] = location.toMap();
      if (maxStudents != null) updates['maxStudents'] = maxStudents;
      if (tags != null) updates['tags'] = tags;
      if (isActive != null) updates['isActive'] = isActive;
      if (metadata != null) updates['metadata'] = metadata;

      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final uploadedImages = await _imageService.uploadMultipleCourseImages(
          imageFiles: newImageFiles,
          courseId: courseId,
          syncBothClouds: true,
          onProgress: onImageUploadProgress,
        );

        final existingCourse = await _cloudService.getCourse(courseId);
        if (existingCourse != null) {
          final allImages = [...existingCourse.images, ...uploadedImages];
          updates['images'] = allImages.map((img) => img.toMap()).toList();
        }
      }

      await _cloudService.updateCourse(courseId, updates);

      final index = _courses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        final updatedCourse = await _cloudService.getCourse(courseId);
        if (updatedCourse != null) {
          _courses[index] = updatedCourse;
        }
      }

      final userIndex = _userCourses.indexWhere((c) => c.id == courseId);
      if (userIndex != -1) {
        final updatedCourse = await _cloudService.getCourse(courseId);
        if (updatedCourse != null) {
          _userCourses[userIndex] = updatedCourse;
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour du cours: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      _setLoading(true);
      _clearError();

      final course = await _cloudService.getCourse(courseId);
      if (course != null && course.images.isNotEmpty) {
        await _imageService.deleteCourseImages(course.images);
      }

      await _cloudService.deleteCourse(courseId);

      _courses.removeWhere((c) => c.id == courseId);
      _userCourses.removeWhere((c) => c.id == courseId);

      if (_selectedCourse?.id == courseId) {
        _selectedCourse = null;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression du cours: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeImageFromCourse(String courseId, CourseImage image) async {
    try {
      await _imageService.deleteImageFromBothClouds(image);

      final course = await _cloudService.getCourse(courseId);
      if (course != null) {
        final updatedImages =
            course.images.where((img) => img.id != image.id).toList();
        await _cloudService.updateCourse(
          courseId,
          {'images': updatedImages.map((img) => img.toMap()).toList()},
        );

        final index = _courses.indexWhere((c) => c.id == courseId);
        if (index != -1) {
          _courses[index] = course.copyWith(images: updatedImages);
        }
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }

  Future<List<CourseModel>> searchCourses(String searchTerm) async {
    try {
      return await _cloudService.searchCourses(searchTerm);
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      return [];
    }
  }

  Future<List<CourseModel>> getNearbyCourses(double radiusKm) async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception('Impossible d\'obtenir la position actuelle');
      }

      return await _locationService.filterCoursesByRadius(
        _courses,
        position.latitude,
        position.longitude,
        radiusKm,
      );
    } catch (e) {
      _setError('Erreur lors de la recherche à proximité: $e');
      return [];
    }
  }

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
    }
  }

  List<CourseModel> filterCoursesBySeason(CourseSeason season) {
    return _courses.where((course) => course.season == season).toList();
  }

  List<CourseModel> filterCoursesByCategory(CourseCategory category) {
    return _courses.where((course) => course.category == category).toList();
  }

  List<CourseModel> getAvailableCourses() {
    return _courses.where((course) => course.isAvailableNow()).toList();
  }

  void selectCourse(CourseModel? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void clearCourses() {
    _courses.clear();
    _userCourses.clear();
    _selectedCourse = null;
    _lastDocumentId = null;
    _hasMoreCourses = true;
    notifyListeners();
  }

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
}
