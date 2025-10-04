import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'StorageService.dart'; // Ajoutez cet import

class LicenseService {
  static const String _secretSalt = 'SECRET_SALT_KEY';

  static Future<LicenseStatus> checkLicense() async {
    try {
      final licenseData = await StorageService.getLicense(); // Changé

      if (licenseData == null) {
        return LicenseStatus(
          isValid: false,
          type: LicenseType.none,
          message: 'Aucune licence trouvée',
        );
      }

      // Le reste reste identique...
      final currentDeviceId = await _getDeviceFingerprint();
      final savedDeviceId = licenseData['device_id'] as String?;

      if (currentDeviceId != savedDeviceId) {
        return LicenseStatus(
          isValid: false,
          type: LicenseType.none,
          message: 'Cette licence est liée à un autre appareil',
        );
      }

      final type = licenseData['type'] as String;

      if (type == 'lifetime') {
        return LicenseStatus(
          isValid: true,
          type: LicenseType.lifetime,
          message: 'Licence LIFETIME active',
        );
      }

      if (type == 'demo') {
        final expiryStr = licenseData['expiry_date'] as String?;
        if (expiryStr == null) {
          return LicenseStatus(
            isValid: false,
            type: LicenseType.none,
            message: 'Licence corrompue',
          );
        }

        final expiryDate = DateTime.parse(expiryStr);
        final now = DateTime.now();

        if (now.isAfter(expiryDate)) {
          return LicenseStatus(
            isValid: false,
            type: LicenseType.expired,
            message:
                'Licence DEMO expirée le ${expiryDate.toString().substring(0, 10)}',
            expiryDate: expiryDate,
          );
        }

        final daysRemaining = expiryDate.difference(now).inDays;

        return LicenseStatus(
          isValid: true,
          type: LicenseType.demo,
          message: 'Licence DEMO active ($daysRemaining jours restants)',
          expiryDate: expiryDate,
          daysRemaining: daysRemaining,
        );
      }

      return LicenseStatus(
        isValid: false,
        type: LicenseType.none,
        message: 'Type de licence inconnu',
      );
    } catch (e) {
      return LicenseStatus(
        isValid: false,
        type: LicenseType.none,
        message: 'Erreur lors de la vérification: $e',
      );
    }
  }

  static Future<Map<String, dynamic>?> getLicenseDetails() async {
    return await StorageService.getLicense(); // Changé
  }

  static Future<void> removeLicense() async {
    await StorageService.removeLicense(); // Changé
  }

  // Le reste des méthodes reste identique...
  static Future<String> _getDeviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String fingerprint = '';

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      final components = [
        windowsInfo.computerName,
        windowsInfo.numberOfCores.toString(),
        windowsInfo.systemMemoryInMegabytes.toString(),
        Platform.operatingSystemVersion,
      ];
      final bytes = utf8.encode(components.join('|'));
      final digest = sha256.convert(bytes);
      fingerprint = digest.toString();
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      final components = [
        macInfo.computerName,
        macInfo.model,
        macInfo.hostName,
      ];
      final bytes = utf8.encode(components.join('|'));
      final digest = sha256.convert(bytes);
      fingerprint = digest.toString();
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      final components = [
        linuxInfo.name,
        linuxInfo.version,
        linuxInfo.id,
      ];
      final bytes = utf8.encode(components.join('|'));
      final digest = sha256.convert(bytes);
      fingerprint = digest.toString();
    }

    return fingerprint;
  }

  static String calculateChecksum(String data) {
    final hash = sha256.convert(utf8.encode(data + _secretSalt));
    return hash.toString().substring(0, 3);
  }

  static Future<String> getDeviceHashShort() async {
    final fingerprint = await _getDeviceFingerprint();
    final hash = sha256.convert(utf8.encode(fingerprint));
    return hash.toString().substring(0, 4);
  }

  static Future<bool> verifyPinIntegrity(String pin) async {
    try {
      if (pin.length != 10) return false;

      final licenseType = pin.substring(0, 1);
      final duration = pin.substring(1, 3);
      final deviceHash = pin.substring(3, 7);
      final checksum = pin.substring(7, 10);

      final expectedHash = await getDeviceHashShort();
      if (deviceHash != expectedHash) {
        return false;
      }

      final baseCode = licenseType + duration + deviceHash;
      final calculatedChecksum = calculateChecksum(baseCode);
      if (checksum != calculatedChecksum) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<LicenseStatus> checkLicenseWithIntegrity() async {
    try {
      final status = await checkLicense();

      if (!status.isValid) {
        return status;
      }

      final details = await getLicenseDetails();
      if (details != null && details['pin'] != null) {
        final pinValid = await verifyPinIntegrity(details['pin']);

        if (!pinValid) {
          return LicenseStatus(
            isValid: false,
            type: LicenseType.none,
            message: 'Licence corrompue - Intégrité du PIN invalide',
          );
        }
      }

      return status;
    } catch (e) {
      return LicenseStatus(
        isValid: false,
        type: LicenseType.none,
        message: 'Erreur lors de la vérification: $e',
      );
    }
  }
}

// Les classes LicenseStatus et LicenseType restent identiques
class LicenseStatus {
  final bool isValid;
  final LicenseType type;
  final String message;
  final DateTime? expiryDate;
  final int? daysRemaining;

  LicenseStatus({
    required this.isValid,
    required this.type,
    required this.message,
    this.expiryDate,
    this.daysRemaining,
  });
}

enum LicenseType {
  none,
  demo,
  lifetime,
  expired,
}
