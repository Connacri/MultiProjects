import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/course_model_complete.dart';

class ImageStorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  static const int maxImageSizeKB = 500; // Limite de taille après compression
  static const int imageQuality = 85; // Qualité de compression

  Future<File> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: imageQuality,
      minWidth: 1920,
      minHeight: 1080,
    );

    if (result == null) {
      throw Exception('Erreur lors de la compression de l\'image');
    }

    final compressedFile = File(result.path);
    final fileSizeKB = await compressedFile.length() / 1024;

    if (fileSizeKB > maxImageSizeKB) {
      final adjustedQuality =
          (imageQuality * (maxImageSizeKB / fileSizeKB)).round();
      final finalResult = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: adjustedQuality,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (finalResult == null) {
        throw Exception('Erreur lors de la recompression de l\'image');
      }
      return File(finalResult.path);
    }

    return compressedFile;
  }

  Future<CourseImage> uploadCourseImage({
    required File imageFile,
    required String courseId,
    bool syncBothClouds = true,
  }) async {
    try {
      final compressedImage = await _compressImage(imageFile);
      final imageId = _uuid.v4();
      final fileName = '$courseId/$imageId.jpg';

      String? firebaseUrl;
      String? supabaseUrl;

      try {
        final firebaseRef = _firebaseStorage.ref().child('courses/$fileName');
        final uploadTask = await firebaseRef.putFile(compressedImage);
        firebaseUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Erreur upload Firebase: $e');
      }

      if (syncBothClouds || firebaseUrl == null) {
        try {
          final bytes = await compressedImage.readAsBytes();
          final supabasePath = 'courses/$fileName';

          await _supabase.storage.from('course-images').uploadBinary(
                supabasePath,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );

          supabaseUrl = _supabase.storage
              .from('course-images')
              .getPublicUrl(supabasePath);
        } catch (e) {
          print('Erreur upload Supabase: $e');
          if (firebaseUrl == null) {
            rethrow;
          }
        }
      }

      await compressedImage.delete();

      if (firebaseUrl == null && supabaseUrl == null) {
        throw Exception('Échec de l\'upload sur les deux plateformes');
      }

      return CourseImage(
        id: imageId,
        firebaseUrl: firebaseUrl ?? '',
        supabaseUrl: supabaseUrl,
        localPath: imageFile.path,
        isSynced: firebaseUrl != null && supabaseUrl != null,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  Future<List<CourseImage>> uploadMultipleCourseImages({
    required List<File> imageFiles,
    required String courseId,
    bool syncBothClouds = true,
    Function(int current, int total)? onProgress,
  }) async {
    final List<CourseImage> uploadedImages = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final courseImage = await uploadCourseImage(
          imageFile: imageFiles[i],
          courseId: courseId,
          syncBothClouds: syncBothClouds,
        );
        uploadedImages.add(courseImage);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        print('Erreur upload image ${i + 1}: $e');
      }
    }

    return uploadedImages;
  }

  Future<void> deleteImageFromBothClouds(CourseImage image) async {
    final List<Future> deleteTasks = [];

    if (image.firebaseUrl.isNotEmpty) {
      try {
        final ref = _firebaseStorage.refFromURL(image.firebaseUrl);
        deleteTasks.add(ref.delete());
      } catch (e) {
        print('Erreur suppression Firebase: $e');
      }
    }

    if (image.supabaseUrl != null && image.supabaseUrl!.isNotEmpty) {
      try {
        final fileName = image.supabaseUrl!.split('/').last;
        deleteTasks.add(
          _supabase.storage.from('course-images').remove(['courses/$fileName']),
        );
      } catch (e) {
        print('Erreur suppression Supabase: $e');
      }
    }

    await Future.wait(deleteTasks);
  }

  Future<void> deleteCourseImages(List<CourseImage> images) async {
    final deleteTasks = images.map((image) => deleteImageFromBothClouds(image));
    await Future.wait(deleteTasks);
  }

  Future<String?> uploadProfileImage({
    required File imageFile,
    required String userId,
    bool isProfileImage = true,
  }) async {
    try {
      final compressedImage = await _compressImage(imageFile);
      final imageType = isProfileImage ? 'profile' : 'cover';
      final fileName = '$userId/$imageType.jpg';

      String? url;

      try {
        final firebaseRef = _firebaseStorage.ref().child('users/$fileName');
        final uploadTask = await firebaseRef.putFile(compressedImage);
        url = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Erreur upload profil Firebase: $e');

        final bytes = await compressedImage.readAsBytes();
        final supabasePath = 'users/$fileName';

        await _supabase.storage.from('user-images').uploadBinary(
              supabasePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        url = _supabase.storage.from('user-images').getPublicUrl(supabasePath);
      }

      await compressedImage.delete();
      return url;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image de profil: $e');
    }
  }

  Future<Map<String, String?>> uploadUserProfileImages({
    File? profileImage,
    File? coverImage,
    required String userId,
  }) async {
    final Map<String, String?> urls = {};

    if (profileImage != null) {
      urls['profile'] = await uploadProfileImage(
        imageFile: profileImage,
        userId: userId,
        isProfileImage: true,
      );
    }

    if (coverImage != null) {
      urls['cover'] = await uploadProfileImage(
        imageFile: coverImage,
        userId: userId,
        isProfileImage: false,
      );
    }

    return urls;
  }

  Future<void> syncImageToSupabase(CourseImage image, String courseId) async {
    if (image.supabaseUrl != null && image.supabaseUrl!.isNotEmpty) {
      return;
    }

    try {
      if (image.firebaseUrl.isEmpty) {
        throw Exception('URL Firebase manquante pour la synchronisation');
      }

      final response = await _supabase.storage
          .from('course-images')
          .createSignedUrl('courses/$courseId/${image.id}.jpg', 3600);

      if (response.isNotEmpty) {
        print('Image synchronisée vers Supabase: ${image.id}');
      }
    } catch (e) {
      print('Erreur synchronisation image vers Supabase: $e');
    }
  }

  Future<void> syncAllImagesToSupabase(
      List<CourseImage> images, String courseId) async {
    final syncTasks = images
        .where((img) => img.supabaseUrl == null || img.supabaseUrl!.isEmpty)
        .map((img) => syncImageToSupabase(img, courseId));

    await Future.wait(syncTasks);
  }

  Future<int> calculateStorageUsage(String userId) async {
    int totalSize = 0;

    try {
      final firebaseRef = _firebaseStorage.ref().child('users/$userId');
      final listResult = await firebaseRef.listAll();

      for (var item in listResult.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }
    } catch (e) {
      print('Erreur calcul usage stockage: $e');
    }

    return totalSize;
  }

  String formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
