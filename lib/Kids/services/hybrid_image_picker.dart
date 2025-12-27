import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

/// 🎯 Service hybride d'image picking optimisé par plateforme
/// 
/// **Architecture :**
/// - Windows Desktop → `file_picker` (non-bloquant, natif)
/// - Android/iOS → `image_picker` (optimisé mobile avec compression intégrée)
/// - Web → `file_picker` (compatible navigateurs)
/// 
/// **Avantages :**
/// ✅ Aucun blocage de l'UI sur Windows
/// ✅ UX mobile optimale avec preview et compression
/// ✅ Validation automatique des types de fichiers
/// ✅ API unifiée pour toutes les plateformes
class HybridImagePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// 🖥️ Détecte si on est sur Windows Desktop
  static bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  /// 📱 Détecte si on est sur mobile (Android/iOS)
  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 🌐 Détecte si on est sur Web
  static bool get _isWeb => kIsWeb;

  // ============================================================================
  // MÉTHODES PUBLIQUES
  // ============================================================================

  /// 📸 Pick une image unique (méthode principale)
  /// 
  /// **Paramètres :**
  /// - [maxWidth], [maxHeight] : Dimensions max (utilisé seulement sur mobile)
  /// - [imageQuality] : Qualité 0-100 (utilisé seulement sur mobile)
  /// - [allowedExtensions] : Extensions autorisées (par défaut: jpg, jpeg, png)
  /// 
  /// **Retour :**
  /// - `File?` : Le fichier image sélectionné ou null si annulé
  static Future<File?> pickImage({
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
    List<String> allowedExtensions = const ['jpg', 'jpeg', 'png'],
  }) async {
    try {
      print('🖼️ [HybridPicker] Début picking...');
      print('🖼️ [HybridPicker] Platform: ${_getPlatformName()}');

      // Sélection du picker selon la plateforme
      if (_isWindowsDesktop || _isWeb) {
        return await _pickImageWithFilePicker(allowedExtensions);
      } else if (_isMobile) {
        return await _pickImageWithImagePicker(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
      } else {
        // Fallback pour autres plateformes (macOS, Linux)
        return await _pickImageWithFilePicker(allowedExtensions);
      }
    } catch (e, stackTrace) {
      print('❌ [HybridPicker] Erreur picking: $e');
      print('❌ [HybridPicker] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 📸 Pick une image de profil (optimisé pour avatars)
  static Future<File?> pickProfileImage() async {
    return await pickImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
  }

  /// 📸 Pick une image de couverture (optimisé pour headers)
  static Future<File?> pickCoverImage() async {
    return await pickImage(
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );
  }

  /// 📸 Pick plusieurs images
  /// 
  /// ⚠️ Sur Windows/Web, utilise `file_picker` (multi-sélection native)
  /// ⚠️ Sur mobile, utilise `image_picker` (avec preview)
  static Future<List<File>> pickMultipleImages({
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
    List<String> allowedExtensions = const ['jpg', 'jpeg', 'png'],
  }) async {
    try {
      print('🖼️ [HybridPicker] Début picking multiple...');

      if (_isWindowsDesktop || _isWeb) {
        return await _pickMultipleImagesWithFilePicker(allowedExtensions);
      } else if (_isMobile) {
        return await _pickMultipleImagesWithImagePicker(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
      } else {
        return await _pickMultipleImagesWithFilePicker(allowedExtensions);
      }
    } catch (e, stackTrace) {
      print('❌ [HybridPicker] Erreur picking multiple: $e');
      print('❌ [HybridPicker] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // IMPLÉMENTATIONS SPÉCIFIQUES : FILE_PICKER (Windows/Web)
  // ============================================================================

  /// 🖥️ Pick avec file_picker (Windows, Web, macOS, Linux)
  /// ✅ Non-bloquant sur Windows
  static Future<File?> _pickImageWithFilePicker(
    List<String> allowedExtensions,
  ) async {
    try {
      print('🖥️ [HybridPicker] Utilisation de file_picker');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: false, // Important: ne charge pas les données en mémoire
        withReadStream: false,
        dialogTitle: 'Sélectionner une image',
      );

      if (result == null || result.files.isEmpty) {
        print('🖼️ [HybridPicker] Picking annulé par l\'utilisateur');
        return null;
      }

      final filePath = result.files.single.path;

      if (filePath == null) {
        print('❌ [HybridPicker] Chemin du fichier null');
        return null;
      }

      final file = File(filePath);

      // Validation du fichier
      if (!await file.exists()) {
        print('❌ [HybridPicker] Fichier n\'existe pas: $filePath');
        return null;
      }

      final sizeKB = (await file.length()) / 1024;
      final extension = filePath.split('.').last.toLowerCase();

      print('✅ [HybridPicker] Image sélectionnée: $filePath');
      print('✅ [HybridPicker] Extension: $extension');
      print('✅ [HybridPicker] Taille: ${sizeKB.toStringAsFixed(2)} KB');

      // Validation du type de fichier
      if (!allowedExtensions.contains(extension)) {
        print('❌ [HybridPicker] Extension non autorisée: $extension');
        throw Exception(
          'Type de fichier non supporté. Extensions autorisées: ${allowedExtensions.join(", ")}',
        );
      }

      // Avertissement si le fichier est très lourd
      if (sizeKB > 5000) {
        print(
          '⚠️ [HybridPicker] Fichier lourd: ${sizeKB.toStringAsFixed(0)} KB',
        );
        print('⚠️ [HybridPicker] Recommandation: < 2 MB pour de meilleures performances');
      }

      return file;
    } catch (e, stackTrace) {
      print('❌ [HybridPicker] Erreur file_picker: $e');
      print('❌ [HybridPicker] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 🖥️ Pick multiple avec file_picker
  static Future<List<File>> _pickMultipleImagesWithFilePicker(
    List<String> allowedExtensions,
  ) async {
    try {
      print('🖥️ [HybridPicker] Picking multiple avec file_picker');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
        dialogTitle: 'Sélectionner des images',
      );

      if (result == null || result.files.isEmpty) {
        print('🖼️ [HybridPicker] Aucune image sélectionnée');
        return [];
      }

      final files = <File>[];

      for (final platformFile in result.files) {
        if (platformFile.path != null) {
          final file = File(platformFile.path!);
          if (await file.exists()) {
            files.add(file);
          }
        }
      }

      print('✅ [HybridPicker] ${files.length} images sélectionnées');
      return files;
    } catch (e, stackTrace) {
      print('❌ [HybridPicker] Erreur picking multiple: $e');
      print('❌ [HybridPicker] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // IMPLÉMENTATIONS SPÉCIFIQUES : IMAGE_PICKER (Mobile)
  // ============================================================================

  /// 📱 Pick avec image_picker (Android/iOS)
  /// ✅ Compression et resize intégrés
  static Future<File?> _pickImageWithImagePicker({
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      print('📱 [HybridPicker] Utilisation de image_picker');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: true,
      );

      if (image == null) {
        print('🖼️ [HybridPicker] Picking annulé par l\'utilisateur');
        return null;
      }

      final file = File(image.path);
      final sizeKB = (await file.length()) / 1024;

      print('✅ [HybridPicker] Image sélectionnée: ${file.path}');
      print('✅ [HybridPicker] Taille: ${sizeKB.toStringAsFixed(2)} KB');

      return file;
    } catch (e, stackTrace) {
      print('❌ [HybridPicker] Erreur image_picker: $e');
      print('❌ [HybridPicker] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 📱 Pick multiple avec image_picker
  static Future<List<File>> _pickMultipleImagesWithImagePicker({
    double? maxWidth,
    double? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      print('📱 [HybridPicker] Picking multiple avec image_picker');

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        requestFullMetadata: true,
      );

      if (images.isEmpty) {
        print('🖼️ [HybridPicker] Aucune image sélectionnée');
        return [];
      }

      print('✅ [HybridPicker] ${images.length} images sélectionnées');
      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e, stackTrace) {
      print('❌ [HybridPicker] Erreur picking multiple: $e');
      print('❌ [HybridPicker] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ============================================================================
  // UTILITAIRES
  // ============================================================================

  /// 🔍 Retourne le nom de la plateforme actuelle
  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows Desktop';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// 📊 Valide si un fichier est une image valide
  static bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// 📊 Obtient la taille d'un fichier en KB
  static Future<double> getFileSizeKB(File file) async {
    final bytes = await file.length();
    return bytes / 1024;
  }

  /// 📊 Obtient l'extension d'un fichier
  static String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }
}
