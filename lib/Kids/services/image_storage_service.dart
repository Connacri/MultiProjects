import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/course_model_complete.dart';

/// Service de gestion des images via Supabase Storage
/// ✅ COMPATIBLE WINDOWS : Compression désactivée sur Desktop
class ImageStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Bucket Supabase pour les images de cours
  static const String _coursesBucket = 'courses';
  static const String _usersBucket = 'user-images';

  static const int maxImageSizeKB = 500;
  static const int imageQuality = 85;

  /// 🖥️ Détecte si on est sur Windows Desktop
  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  /// Compresse une image pour optimiser le stockage
  /// ✅ SKIP sur Windows car non supporté
  Future<File> _compressImage(File file) async {
    // 🖥️ Sur Windows : Pas de compression, retour direct
    if (_isWindowsDesktop) {
      print('🖥️ [ImageStorage] Windows détecté : Compression SKIP');
      return file;
    }

    print('📦 [ImageStorage] Compression image: ${file.path}');

    final tempDir = await getTemporaryDirectory();
    final output = '${tempDir.path}/${_uuid.v4()}.jpg';

    try {
      // Première passe de compression
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path,
        output,
        quality: imageQuality,
        minWidth: 1280,
        minHeight: 720,
      );

      if (compressed == null) {
        print(
            '⚠️ [ImageStorage] Compression échouée, utilisation fichier original');
        return file;
      }

      final compressedFile = File(compressed.path);
      final sizeKB = (await compressedFile.length()) / 1024;

      print(
          '📦 [ImageStorage] Taille après compression: ${sizeKB.toStringAsFixed(2)} KB');

      // Recompression si le fichier est trop lourd
      if (sizeKB > maxImageSizeKB) {
        print('📦 [ImageStorage] Recompression nécessaire...');
        final adjustedQuality =
            (imageQuality * (maxImageSizeKB / sizeKB)).round();

        final finalCompressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          output,
          quality: adjustedQuality,
          minWidth: 1280,
          minHeight: 720,
        );

        if (finalCompressed == null) {
          print(
              '⚠️ [ImageStorage] Recompression échouée, utilisation version 1ère compression');
          return compressedFile;
        }

        return File(finalCompressed.path);
      }

      return compressedFile;
    } catch (e) {
      print('⚠️ [ImageStorage] Erreur compression: $e');
      print('⚠️ [ImageStorage] Utilisation fichier original sans compression');
      return file;
    }
  }

  /// 🔧 Upload une image de cours dans Supabase Storage (bucket: courses)
  /// ✅ Compatible Windows Desktop (sans compression)
  Future<CourseImage> uploadCourseImage({
    required File imageFile,
    required String courseId,
  }) async {
    try {
      print('📤 [ImageStorage] Début upload image pour course: $courseId');

      // 1️⃣ Compression (skip sur Windows)
      final fileToUpload = await _compressImage(imageFile);
      final imgId = _uuid.v4();

      // 2️⃣ Structure : courses/{courseId}/{imageId}.jpg
      final filePath = '$courseId/$imgId.jpg';
      print('📤 [ImageStorage] Chemin: $filePath');

      // 3️⃣ Lecture bytes
      final Uint8List imageBytes = await fileToUpload.readAsBytes();
      final sizeKB = imageBytes.length / 1024;
      print(
          '📤 [ImageStorage] Taille: ${sizeKB.toStringAsFixed(2)} KB (${imageBytes.length} bytes)');

      // ⚠️ Avertissement si image trop lourde
      if (sizeKB > 2000) {
        print(
            '⚠️ [ImageStorage] ATTENTION: Image très lourde (${sizeKB.toStringAsFixed(0)} KB)');
        print(
            '⚠️ [ImageStorage] Recommandé: < 1 MB pour de meilleures performances');
      }

      // 4️⃣ Upload avec Uint8List
      await _supabase.storage.from(_coursesBucket).uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      print('✅ [ImageStorage] Upload réussi');

      // 5️⃣ Récupération de l'URL publique
      final publicUrl =
          _supabase.storage.from(_coursesBucket).getPublicUrl(filePath);

      print('✅ [ImageStorage] URL publique: $publicUrl');

      // 6️⃣ Nettoyage du fichier temporaire (si compression a eu lieu)
      if (fileToUpload.path != imageFile.path) {
        try {
          await fileToUpload.delete();
          print('🧹 [ImageStorage] Fichier temporaire supprimé');
        } catch (e) {
          print(
              '⚠️ [ImageStorage] Impossible de supprimer le fichier temp: $e');
        }
      }

      return CourseImage(
        id: imgId,
        supabaseUrl: publicUrl,
        localPath: imageFile.path,
        isSynced: true,
        uploadedAt: DateTime.now(),
      );
    } on StorageException catch (e) {
      print('❌ [ImageStorage] StorageException: ${e.message}');
      print('❌ [ImageStorage] StatusCode: ${e.statusCode}');
      throw Exception("Erreur upload Supabase Storage: ${e.message}");
    } catch (e, stackTrace) {
      print('❌ [ImageStorage] Erreur upload: $e');
      print('❌ [ImageStorage] StackTrace: $stackTrace');
      throw Exception("Erreur upload: $e");
    }
  }

  /// Upload multiple d'images de cours avec callback de progression
  Future<List<CourseImage>> uploadMultipleCourseImages({
    required List<File> imageFiles,
    required String courseId,
    Function(int current, int total)? onProgress,
  }) async {
    print('📤 [ImageStorage] Upload multiple: ${imageFiles.length} images');
    final results = <CourseImage>[];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        print('📤 [ImageStorage] Upload image ${i + 1}/${imageFiles.length}');
        final img = await uploadCourseImage(
          imageFile: imageFiles[i],
          courseId: courseId,
        );
        results.add(img);
        onProgress?.call(i + 1, imageFiles.length);
        print('✅ [ImageStorage] Image ${i + 1}/${imageFiles.length} uploadée');
      } catch (e) {
        print("❌ [ImageStorage] Erreur upload image ${i + 1}: $e");
        // Continue même si une image échoue
      }
    }

    print(
        '✅ [ImageStorage] Upload multiple terminé: ${results.length}/${imageFiles.length} réussis');
    return results;
  }

  /// Supprime une image de cours du bucket Supabase
  Future<void> deleteCourseImage(CourseImage img, String courseId) async {
    if (img.supabaseUrl == null || img.supabaseUrl!.isEmpty) {
      return;
    }

    // Structure du path : {courseId}/{imageId}.jpg
    final path = '$courseId/${img.id}.jpg';

    try {
      print('🗑️ [ImageStorage] Suppression: $path');
      await _supabase.storage.from(_coursesBucket).remove([path]);
      print('✅ [ImageStorage] Image supprimée');
    } on StorageException catch (e) {
      print("❌ [ImageStorage] Erreur suppression Supabase: ${e.message}");
    } catch (e) {
      print("❌ [ImageStorage] Erreur suppression: $e");
    }
  }

  /// Supprime plusieurs images d'un cours
  Future<void> deleteMultipleImages(
    List<CourseImage> images,
    String courseId,
  ) async {
    final paths = images
        .where((img) => img.supabaseUrl != null && img.supabaseUrl!.isNotEmpty)
        .map((img) => '$courseId/${img.id}.jpg')
        .toList();

    if (paths.isEmpty) return;

    try {
      print('🗑️ [ImageStorage] Suppression multiple: ${paths.length} images');
      await _supabase.storage.from(_coursesBucket).remove(paths);
      print('✅ [ImageStorage] Images supprimées');
    } on StorageException catch (e) {
      print("❌ [ImageStorage] Erreur suppression multiple: ${e.message}");
    } catch (e) {
      print("❌ [ImageStorage] Erreur suppression: $e");
    }
  }

  /// Upload d'une image de profil utilisateur
  Future<String?> uploadUserProfileImage({
    required File imageFile,
    required String userId,
    required bool isProfileImage,
  }) async {
    try {
      final fileToUpload = await _compressImage(imageFile);
      final type = isProfileImage ? 'profile' : 'cover';

      // Structure : {userId}/{type}.jpg
      final path = '$userId/$type.jpg';

      final bytes = await fileToUpload.readAsBytes();

      await _supabase.storage.from(_usersBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Nettoyage si compression
      if (fileToUpload.path != imageFile.path) {
        await fileToUpload.delete();
      }

      return _supabase.storage.from(_usersBucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw Exception("Erreur upload profil: ${e.message}");
    } catch (e) {
      throw Exception("Erreur upload: $e");
    }
  }

  /// Upload des images de profil et de couverture d'un utilisateur
  Future<Map<String, String?>> uploadUserProfileImages({
    File? profileImage,
    File? coverImage,
    required String userId,
  }) async {
    final urls = <String, String?>{};

    if (profileImage != null) {
      urls['profile'] = await uploadUserProfileImage(
        imageFile: profileImage,
        userId: userId,
        isProfileImage: true,
      );
    }

    if (coverImage != null) {
      urls['cover'] = await uploadUserProfileImage(
        imageFile: coverImage,
        userId: userId,
        isProfileImage: false,
      );
    }

    return urls;
  }

  /// Supprime toutes les images d'un cours (utile lors de la suppression complète)
  Future<void> deleteAllCourseImages(String courseId) async {
    try {
      print('🗑️ [ImageStorage] Suppression dossier: $courseId');
      final response =
          await _supabase.storage.from(_coursesBucket).list(path: courseId);

      if (response.isEmpty) {
        print('⚠️ [ImageStorage] Aucune image à supprimer');
        return;
      }

      final paths = response.map((file) => '$courseId/${file.name}').toList();

      await _supabase.storage.from(_coursesBucket).remove(paths);
      print('✅ [ImageStorage] Dossier supprimé: ${paths.length} fichiers');
    } on StorageException catch (e) {
      print("❌ [ImageStorage] Erreur suppression dossier: ${e.message}");
    } catch (e) {
      print("❌ [ImageStorage] Erreur: $e");
    }
  }
}
