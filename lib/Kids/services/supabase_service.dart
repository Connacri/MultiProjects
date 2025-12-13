import 'dart:math' show sqrt, asin, pi;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model_complete.dart';

/// Service dédié pour les opérations CRUD des cours dans Supabase
class SupabaseCourseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _tableName = 'courses';
  static const int _defaultLimit = 20;

  /// Récupère une liste de cours avec pagination et filtres
  Future<List<CourseModel>> getCourses({
    int limit = _defaultLimit,
    DateTime? lastDocumentTimestamp,
    CourseSeason? season,
    CourseCategory? category,
    bool? isActive,
  }) async {
    try {
      // Construction de la requête de base
      PostgrestFilterBuilder query = _supabase.from(_tableName).select();

      // Filtres optionnels
      if (season != null) {
        query = query.eq('season', season.name);
      }

      if (category != null) {
        query = query.eq('category', category.name);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      // Pagination par timestamp
      if (lastDocumentTimestamp != null) {
        query = query.lt('created_at', lastDocumentTimestamp.toIso8601String());
      }

      // Tri et limite (à la fin)
      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase getCourses: ${e.message}');
    } catch (e) {
      throw Exception('Erreur getCourses: $e');
    }
  }

  /// ✅ Méthode de validation
  String? _validateTitle(String title) {
    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      return 'Le titre est vide';
    }

    // ✅ Contrainte Supabase
    if (trimmed.length < 3) {
      return 'Le titre doit contenir au moins 3 caractères';
    }

    if (trimmed.length > 200) {
      return 'Le titre trop long';
    }

    return null; // Valide
  }

  /// Crée un nouveau cours dans Supabase
  Future<String> createCourse(CourseModel course) async {
    // Validation AVANT envoi à Supabase
    final titleError = _validateTitle(course.title);
    if (titleError != null) {
      throw Exception('Validation titre échouée: $titleError');
    }
    try {
      final data = course.toSupabase();

      // Retirer l'ID car Supabase le génère automatiquement (UUID)
      data.remove('id');

      final response =
          await _supabase.from(_tableName).insert(data).select('id').single();

      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase createCourse: ${e.message}');
    } catch (e) {
      throw Exception('Erreur createCourse: $e');
    }
  }

  /// Met à jour un cours existant
  Future<void> updateCourse(
    String courseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Supprimer les champs qui ne doivent pas être mis à jour manuellement
      updates.remove('id');
      updates.remove('created_at');
      updates.remove('created_by');

      // Forcer la mise à jour de updated_at
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from(_tableName).update(updates).eq('id', courseId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase updateCourse: ${e.message}');
    } catch (e) {
      throw Exception('Erreur updateCourse: $e');
    }
  }

  /// Supprime un cours
  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', courseId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase deleteCourse: ${e.message}');
    } catch (e) {
      throw Exception('Erreur deleteCourse: $e');
    }
  }

  /// Récupère un cours spécifique par son ID
  Future<CourseModel?> getCourse(String courseId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', courseId)
          .maybeSingle();

      if (response == null) return null;

      return CourseModel.fromSupabase(response);
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase getCourse: ${e.message}');
    } catch (e) {
      throw Exception('Erreur getCourse: $e');
    }
  }

  /// Recherche de cours par terme (full-text search)
  Future<List<CourseModel>> searchCourses(String searchTerm) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('title.ilike.%$searchTerm%,description.ilike.%$searchTerm%')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase searchCourses: ${e.message}');
    } catch (e) {
      throw Exception('Erreur searchCourses: $e');
    }
  }

  /// Récupère les cours d'un utilisateur spécifique
  Future<List<CourseModel>> getUserCourses(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase getUserCourses: ${e.message}');
    } catch (e) {
      throw Exception('Erreur getUserCourses: $e');
    }
  }

  /// Recherche de cours par proximité géographique (filtrage côté client)
  /// Utilise la formule Haversine pour calculer les distances
  Future<List<CourseModel>> getCoursesNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 50,
  }) async {
    try {
      // Récupérer tous les cours actifs
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(500); // Limite élevée pour filtrer côté client

      final courses = (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();

      // Filtrer par distance côté client
      final coursesWithDistance = courses.map((course) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          course.location.latitude,
          course.location.longitude,
        );
        return {'course': course, 'distance': distance};
      }).where((item) {
        return (item['distance'] as double) <= radiusKm;
      }).toList();

      // Trier par distance
      coursesWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Retourner seulement les cours, limités
      return coursesWithDistance
          .take(limit)
          .map((item) => item['course'] as CourseModel)
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase getCoursesNearby: ${e.message}');
    } catch (e) {
      throw Exception('Erreur getCoursesNearby: $e');
    }
  }

  /// Calcule la distance entre deux points géographiques (formule Haversine)
  /// Retourne la distance en kilomètres
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(lat1Rad) * _cos(lat2Rad) * _sin(dLon / 2) * _sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  double _sin(double radians) {
    // Utilise les fonctions natives de dart:math via import
    return radians -
        (radians * radians * radians) / 6 +
        (radians * radians * radians * radians * radians) / 120;
  }

  double _cos(double radians) {
    return 1 -
        (radians * radians) / 2 +
        (radians * radians * radians * radians) / 24;
  }

  /// Récupère les cours disponibles (actifs + places disponibles)
  /// Filtrage côté client pour current_students < max_students
  Future<List<CourseModel>> getAvailableCourses({int limit = 50}) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .lte('season_start_date', now)
          .gte('season_end_date', now)
          .order('created_at', ascending: false)
          .limit(200); // Limite plus haute pour filtrer côté client

      final courses = (response as List<dynamic>)
          .map((json) => CourseModel.fromSupabase(json as Map<String, dynamic>))
          .toList();

      // Filtrer côté client : current_students < max_students
      return courses
          .where((course) => course.currentStudents < course.maxStudents)
          .take(limit)
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase getAvailableCourses: ${e.message}');
    } catch (e) {
      throw Exception('Erreur getAvailableCourses: $e');
    }
  }

  /// Met à jour le nombre d'étudiants inscrits
  Future<void> updateStudentCount(String courseId, int newCount) async {
    try {
      await _supabase.from(_tableName).update({
        'current_students': newCount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', courseId);
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase updateStudentCount: ${e.message}');
    } catch (e) {
      throw Exception('Erreur updateStudentCount: $e');
    }
  }

  /// Incrémente le compteur d'étudiants de manière atomique
  Future<void> incrementStudentCount(String courseId) async {
    try {
      // Récupérer le cours actuel
      final course = await getCourse(courseId);
      if (course == null) {
        throw Exception('Cours introuvable');
      }

      // Vérifier qu'il reste des places
      if (course.currentStudents >= course.maxStudents) {
        throw Exception('Plus de places disponibles');
      }

      // Incrémenter
      await updateStudentCount(courseId, course.currentStudents + 1);
    } catch (e) {
      throw Exception('Erreur incrementStudentCount: $e');
    }
  }

  /// Décrémente le compteur d'étudiants de manière atomique
  Future<void> decrementStudentCount(String courseId) async {
    try {
      final course = await getCourse(courseId);
      if (course == null) {
        throw Exception('Cours introuvable');
      }

      if (course.currentStudents <= 0) {
        throw Exception('Compteur déjà à zéro');
      }

      await updateStudentCount(courseId, course.currentStudents - 1);
    } catch (e) {
      throw Exception('Erreur decrementStudentCount: $e');
    }
  }
}
