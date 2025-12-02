import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model_complete.dart';

enum CloudProvider { firebase, supabase }

class HybridCloudService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  CloudProvider _activeProvider = CloudProvider.firebase;
  int _firebaseOperationsToday = 0;
  DateTime _lastResetDate = DateTime.now();

  static const int maxFirebaseOperationsPerDay = 20000;
  static const int maxFirebaseWritesPerDay = 10000;
  static const String prefsKeyOperations = 'firebase_operations_count';
  static const String prefsKeyLastReset = 'firebase_last_reset';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _firebaseOperationsToday = prefs.getInt(prefsKeyOperations) ?? 0;

    final lastResetString = prefs.getString(prefsKeyLastReset);
    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);

      if (!_isSameDay(_lastResetDate, DateTime.now())) {
        await _resetDailyCounter();
      }
    }

    _checkAndSwitchProvider();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _resetDailyCounter() async {
    _firebaseOperationsToday = 0;
    _lastResetDate = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKeyOperations, 0);
    await prefs.setString(prefsKeyLastReset, _lastResetDate.toIso8601String());

    _activeProvider = CloudProvider.firebase;
  }

  Future<void> _incrementOperationCount([int count = 1]) async {
    _firebaseOperationsToday += count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKeyOperations, _firebaseOperationsToday);
    _checkAndSwitchProvider();
  }

  void _checkAndSwitchProvider() {
    if (_firebaseOperationsToday >= maxFirebaseOperationsPerDay * 0.8) {
      _activeProvider = CloudProvider.supabase;
    } else {
      _activeProvider = CloudProvider.firebase;
    }
  }

  CloudProvider get activeProvider => _activeProvider;

  bool get isUsingFirebase => _activeProvider == CloudProvider.firebase;

  bool get isUsingSupabase => _activeProvider == CloudProvider.supabase;

  int get remainingFirebaseOperations =>
      maxFirebaseOperationsPerDay - _firebaseOperationsToday;

  double get quotaUsagePercentage =>
      (_firebaseOperationsToday / maxFirebaseOperationsPerDay) * 100;

  // ========================================================================
  // CRUD Operations for Courses
  // ========================================================================

  Future<String> createCourse(CourseModel course) async {
    try {
      if (isUsingFirebase) {
        final docRef =
            await _firestore.collection('courses').add(course.toFirestore());
        await _incrementOperationCount(1);

        // Synchroniser vers Supabase en arrière-plan
        _syncToSupabase(docRef.id, course);

        return docRef.id;
      } else {
        // CORRECTION: Utiliser await directement
        final data = course.toSupabase();
        final response =
            await _supabase.from('courses').insert(data).select().single();
        return response['id'] as String;
      }
    } catch (e) {
      print('Erreur createCourse: $e');
      if (isUsingFirebase) {
        _activeProvider = CloudProvider.supabase;
        return createCourse(course);
      } else {
        _activeProvider = CloudProvider.firebase;
        return createCourse(course);
      }
    }
  }

  Future<CourseModel?> getCourse(String courseId) async {
    try {
      if (isUsingFirebase) {
        final doc = await _firestore.collection('courses').doc(courseId).get();
        await _incrementOperationCount(1);

        if (doc.exists) {
          return CourseModel.fromFirestore(doc);
        }
        return null;
      } else {
        // CORRECTION: Utiliser await directement sans stocker dans une variable intermédiaire
        final response = await _supabase
            .from('courses')
            .select()
            .eq('id', courseId)
            .maybeSingle();

        if (response != null) {
          return CourseModel.fromSupabase(response as Map<String, dynamic>);
        }
        return null;
      }
    } catch (e) {
      print('Erreur getCourse: $e');
      if (isUsingFirebase) {
        _activeProvider = CloudProvider.supabase;
        return getCourse(courseId);
      } else {
        _activeProvider = CloudProvider.firebase;
        return getCourse(courseId);
      }
    }
  }

  Future<List<CourseModel>> getCourses({
    int limit = 20,
    String? lastDocumentId,
    CourseSeason? season,
    CourseCategory? category,
    bool? isActive,
  }) async {
    try {
      if (isUsingFirebase) {
        Query query = _firestore.collection('courses');

        if (season != null) {
          query = query.where('season', isEqualTo: season.name);
        }
        if (category != null) {
          query = query.where('category', isEqualTo: category.name);
        }
        if (isActive != null) {
          query = query.where('isActive', isEqualTo: isActive);
        }

        query = query.orderBy('createdAt', descending: true).limit(limit);

        if (lastDocumentId != null) {
          final lastDoc =
              await _firestore.collection('courses').doc(lastDocumentId).get();
          if (lastDoc.exists) {
            query = query.startAfterDocument(lastDoc);
          }
        }

        final snapshot = await query.get();
        await _incrementOperationCount(snapshot.docs.length);

        return snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList();
      } else {
        // CORRECTION: Ne pas réassigner query, construire la requête complète
        var queryBuilder = _supabase.from('courses').select();

        // Appliquer les filtres
        if (season != null) {
          queryBuilder = queryBuilder.eq('season', season.name);
        }
        if (category != null) {
          queryBuilder = queryBuilder.eq('category', category.name);
        }
        if (isActive != null) {
          queryBuilder = queryBuilder.eq('is_active', isActive);
        }

        // Appliquer order et limit à la fin
        final response = await queryBuilder
            .order('created_at', ascending: false)
            .limit(limit);

        if (response is List) {
          return response
              .map((item) =>
                  CourseModel.fromSupabase(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
    } catch (e) {
      print('Erreur getCourses: $e');
      if (isUsingFirebase) {
        _activeProvider = CloudProvider.supabase;
        return getCourses(
          limit: limit,
          lastDocumentId: lastDocumentId,
          season: season,
          category: category,
          isActive: isActive,
        );
      } else {
        _activeProvider = CloudProvider.firebase;
        return getCourses(
          limit: limit,
          lastDocumentId: lastDocumentId,
          season: season,
          category: category,
          isActive: isActive,
        );
      }
    }
  }

  Future<void> updateCourse(
      String courseId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] =
          isUsingFirebase ? Timestamp.now() : DateTime.now().toIso8601String();

      if (isUsingFirebase) {
        await _firestore.collection('courses').doc(courseId).update(updates);
        await _incrementOperationCount(1);

        // Synchroniser vers Supabase
        _syncUpdateToSupabase(courseId, updates);
      } else {
        // CORRECTION: Exécuter directement avec await
        await _supabase.from('courses').update(updates).eq('id', courseId);
      }
    } catch (e) {
      print('Erreur updateCourse: $e');
      if (isUsingFirebase) {
        _activeProvider = CloudProvider.supabase;
        return updateCourse(courseId, updates);
      } else {
        _activeProvider = CloudProvider.firebase;
        return updateCourse(courseId, updates);
      }
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      if (isUsingFirebase) {
        await _firestore.collection('courses').doc(courseId).delete();
        await _incrementOperationCount(1);

        _deleteFromSupabase(courseId);
      } else {
        // CORRECTION: Exécuter directement avec await
        await _supabase.from('courses').delete().eq('id', courseId);
      }
    } catch (e) {
      print('Erreur deleteCourse: $e');
      if (isUsingFirebase) {
        _activeProvider = CloudProvider.supabase;
        return deleteCourse(courseId);
      } else {
        _activeProvider = CloudProvider.firebase;
        return deleteCourse(courseId);
      }
    }
  }

  Future<List<CourseModel>> searchCourses(String searchTerm,
      {int limit = 20}) async {
    try {
      if (isUsingFirebase) {
        final snapshot = await _firestore
            .collection('courses')
            .where('title', isGreaterThanOrEqualTo: searchTerm)
            .where('title', isLessThan: '$searchTerm\uf8ff')
            .limit(limit)
            .get();

        await _incrementOperationCount(snapshot.docs.length);
        return snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList();
      } else {
        // CORRECTION: Utiliser ilike pour la recherche insensible à la casse
        final response = await _supabase
            .from('courses')
            .select()
            .ilike('title', '%$searchTerm%')
            .limit(limit);

        if (response is List) {
          return response
              .map((item) =>
                  CourseModel.fromSupabase(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
    } catch (e) {
      print('Erreur searchCourses: $e');
      if (isUsingFirebase) {
        _activeProvider = CloudProvider.supabase;
        return searchCourses(searchTerm, limit: limit);
      } else {
        return [];
      }
    }
  }

  // ========================================================================
  // Synchronisation en arrière-plan vers Supabase
  // ========================================================================

  Future<void> _syncToSupabase(String documentId, CourseModel course) async {
    try {
      final courseData = course.toSupabase();
      courseData['id'] = documentId;
      await _supabase.from('courses').upsert(courseData);
    } catch (e) {
      print('Erreur de synchronisation vers Supabase: $e');
    }
  }

  Future<void> _syncUpdateToSupabase(
      String documentId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('courses').update(updates).eq('id', documentId);
    } catch (e) {
      print('Erreur de synchronisation de mise à jour vers Supabase: $e');
    }
  }

  Future<void> _deleteFromSupabase(String documentId) async {
    try {
      await _supabase.from('courses').delete().eq('id', documentId);
    } catch (e) {
      print('Erreur de suppression dans Supabase: $e');
    }
  }

  // ========================================================================
  // Méthodes utilitaires
  // ========================================================================

  void setProvider(CloudProvider provider) {
    _activeProvider = provider;
  }

  Map<String, dynamic> getUsageStats() {
    return {
      'activeProvider': _activeProvider.name,
      'operationsToday': _firebaseOperationsToday,
      'remainingOperations': remainingFirebaseOperations,
      'quotaUsagePercentage': quotaUsagePercentage,
      'lastResetDate': _lastResetDate.toIso8601String(),
    };
  }

  // ========================================================================
  // Statistiques
  // ========================================================================

  Future<Map<String, dynamic>> getCoursesStats() async {
    try {
      if (isUsingFirebase) {
        final snapshot = await _firestore.collection('courses').get();
        await _incrementOperationCount(snapshot.docs.length);

        final total = snapshot.docs.length;
        final active =
            snapshot.docs.where((doc) => doc.data()['isActive'] == true).length;

        return {
          'total': total,
          'active': active,
          'inactive': total - active,
        };
      } else {
        final response =
            await _supabase.from('courses').select('id, is_active');

        if (response is List) {
          final total = response.length;
          final active =
              response.where((item) => item['is_active'] == true).length;

          return {
            'total': total,
            'active': active,
            'inactive': total - active,
          };
        }
        return {'total': 0, 'active': 0, 'inactive': 0};
      }
    } catch (e) {
      print('Erreur getCoursesStats: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // ========================================================================
  // Stream pour les mises à jour en temps réel
  // ========================================================================

  Stream<List<CourseModel>> streamCourses({
    CourseSeason? season,
    CourseCategory? category,
    bool? isActive,
    int limit = 20,
  }) {
    if (isUsingFirebase) {
      Query query = _firestore.collection('courses');

      if (season != null) {
        query = query.where('season', isEqualTo: season.name);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      return query.snapshots().map((snapshot) {
        _incrementOperationCount(snapshot.docs.length);
        return snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList();
      });
    } else {
      // Supabase Realtime avec filtres appliqués au stream
      return _supabase
          .from('courses')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(limit)
          .map((data) {
            var filteredData = data;

            // Appliquer les filtres côté client pour le stream
            if (season != null) {
              filteredData = filteredData
                  .where((item) => item['season'] == season.name)
                  .toList();
            }
            if (category != null) {
              filteredData = filteredData
                  .where((item) => item['category'] == category.name)
                  .toList();
            }
            if (isActive != null) {
              filteredData = filteredData
                  .where((item) => item['is_active'] == isActive)
                  .toList();
            }

            return filteredData
                .map((item) => CourseModel.fromSupabase(item))
                .toList();
          });
    }
  }

  // ========================================================================
  // Batch operations
  // ========================================================================

  Future<void> batchCreateCourses(List<CourseModel> courses) async {
    if (isUsingFirebase) {
      final batch = _firestore.batch();

      for (var course in courses) {
        final docRef = _firestore.collection('courses').doc();
        batch.set(docRef, course.toFirestore());
      }

      await batch.commit();
      await _incrementOperationCount(courses.length);
    } else {
      final data = courses.map((course) => course.toSupabase()).toList();
      await _supabase.from('courses').insert(data);
    }
  }

  Future<void> batchUpdateCourses(
      Map<String, Map<String, dynamic>> updates) async {
    if (isUsingFirebase) {
      final batch = _firestore.batch();

      updates.forEach((courseId, updateData) {
        updateData['updatedAt'] = Timestamp.now();
        final docRef = _firestore.collection('courses').doc(courseId);
        batch.update(docRef, updateData);
      });

      await batch.commit();
      await _incrementOperationCount(updates.length);
    } else {
      // Pour Supabase, faire les updates séquentiellement
      for (var entry in updates.entries) {
        final courseId = entry.key;
        final updateData = entry.value;
        updateData['updated_at'] = DateTime.now().toIso8601String();

        await _supabase.from('courses').update(updateData).eq('id', courseId);
      }
    }
  }

  Future<void> batchDeleteCourses(List<String> courseIds) async {
    if (isUsingFirebase) {
      final batch = _firestore.batch();

      for (var courseId in courseIds) {
        final docRef = _firestore.collection('courses').doc(courseId);
        batch.delete(docRef);
      }

      await batch.commit();
      await _incrementOperationCount(courseIds.length);
    } else {
      // CORRECTION: Utiliser filter avec 'in' au lieu de in_()
      final idsString = '(${courseIds.map((id) => '"$id"').join(',')})';
      await _supabase.from('courses').delete().filter('id', 'in', idsString);
    }
  }
}
