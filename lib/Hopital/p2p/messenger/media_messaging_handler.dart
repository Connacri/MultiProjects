import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';

import '../../../objectBox/Entity.dart';
import 'messaging_manager.dart';

/// Gestionnaire des médias (photos, vidéos, fichiers) pour la messagerie
class MediaMessagingHandler {
  static final MediaMessagingHandler _instance =
      MediaMessagingHandler._internal();

  factory MediaMessagingHandler() => _instance;

  MediaMessagingHandler._internal();

  /// Limite de taille des fichiers (20 MB)
  static const int maxFileSize = 20 * 1024 * 1024;

  /// Sélectionner et envoyer une photo
  Future<void> pickAndSendPhoto(
    BuildContext context,
    MessagingManager messagingManager,
    String conversationId,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      await _sendMediaMessage(
        context,
        messagingManager,
        conversationId,
        file,
        MessageType.image,
        'Photo',
      );
    } catch (e) {
      print('[MediaHandler] Erreur sélection photo: $e');
      _showError(context, 'Erreur sélection photo: $e');
    }
  }

  /// Sélectionner et envoyer une vidéo
  Future<void> pickAndSendVideo(
    BuildContext context,
    MessagingManager messagingManager,
    String conversationId,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final videoFile = File(result.files.first.path!);

      // Vérifier la taille avant compression
      final fileSize = await videoFile.length();
      if (fileSize > maxFileSize) {
        _showError(context, 'Vidéo trop volumineux (max 20 MB)');
        return;
      }

      // Montrer un dialog de compression
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Compression vidéo...'),
            ],
          ),
        ),
      );

      // Compresser la vidéo
      final compressedFile = await _compressVideo(videoFile);

      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le dialog

      await _sendMediaMessage(
        context,
        messagingManager,
        conversationId,
        compressedFile,
        MessageType.video,
        'Vidéo',
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      print('[MediaHandler] Erreur sélection vidéo: $e');
      _showError(context, 'Erreur sélection vidéo: $e');
    }
  }

  /// Sélectionner et envoyer un fichier
  Future<void> pickAndSendFile(
    BuildContext context,
    MessagingManager messagingManager,
    String conversationId,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      await _sendMediaMessage(
        context,
        messagingManager,
        conversationId,
        file,
        MessageType.file,
        'Fichier',
      );
    } catch (e) {
      print('[MediaHandler] Erreur sélection fichier: $e');
      _showError(context, 'Erreur sélection fichier: $e');
    }
  }

  /// Envoyer un message média
  Future<void> _sendMediaMessage(
    BuildContext context,
    MessagingManager messagingManager,
    String conversationId,
    File mediaFile,
    MessageType type,
    String mediaType,
  ) async {
    try {
      // Vérifier la taille
      final fileSize = await mediaFile.length();
      if (fileSize > maxFileSize) {
        _showError(context, 'Fichier trop volumineux (max 20 MB)');
        return;
      }

      // Montrer un dialog de chargement
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Envoi du $mediaType...'),
            ],
          ),
        ),
      );

      // Envoyer via MessagingManager
      int? duration;
      if (type == MessageType.video) {
        duration = await _getVideoDuration(mediaFile);
      }

      await messagingManager.sendMediaMessage(
        conversationId,
        type,
        mediaFile,
        caption: null,
        durationSeconds: duration,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le dialog

      _showSuccess(context, '$mediaType envoyé');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      print('[MediaHandler] Erreur envoi média: $e');
      _showError(context, 'Erreur envoi: $e');
    }
  }

  /// Compresser une vidéo
  Future<File> _compressVideo(File videoFile) async {
    try {
      print('[MediaHandler] Compression de la vidéo: ${videoFile.path}');

      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null) throw Exception('Compression échouée');

      print('[MediaHandler] Vidéo compressée: ${info.path}');
      return File(info.path!);
    } catch (e) {
      print('[MediaHandler] Erreur compression: $e');
      return videoFile; // Retourner l'original en cas d'erreur
    }
  }

  /// Obtenir la durée d'une vidéo
  Future<int> _getVideoDuration(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      return (info?.duration ?? 0).toInt();
    } catch (e) {
      print('[MediaHandler] Erreur durée vidéo: $e');
      return 0;
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
