import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _licenseFileName = 'license.json';

  /// Récupère le chemin du fichier de licence
  static Future<String> _getLicenseFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_licenseFileName';
  }

  /// Sauvegarde les données de licence
  static Future<void> saveLicense(Map<String, dynamic> data) async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);

      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      print('Licence sauvegardée: $filePath');
    } catch (e) {
      print('Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// Récupère les données de licence
  static Future<Map<String, dynamic>?> getLicense() async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        print('Aucun fichier de licence trouvé');
        return null;
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      return data;
    } catch (e) {
      print('Erreur lecture: $e');
      return null;
    }
  }

  /// Supprime la licence
  static Future<void> removeLicense() async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('Licence supprimée');
      }
    } catch (e) {
      print('Erreur suppression: $e');
      rethrow;
    }
  }

  /// Vérifie si une licence existe
  static Future<bool> licenseExists() async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
