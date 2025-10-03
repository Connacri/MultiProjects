import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:url_launcher/url_launcher.dart';

import 'objectBox/MyApp.dart';

// ============================================================================
// POINT D'ENTRÉE PRINCIPAL - À UTILISER DANS main.dart
// ============================================================================

class MyAppBlackHole extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform = Platform.isAndroid || Platform.isIOS;
    if (isMobilePlatform) {
      return MobileEntryScreen(); // ❌ PAS DE WRAPPER DE LICENCE
    } else {
      return DesktopEntryScreen(); // ✅ AVEC WRAPPER DE LICENCE
    }

    return PlatformAwareEntryPoint(); // ⚠️ Cette ligne n'est JAMAIS atteinte
  }
}

// ============================================================================
// DÉTECTION DE PLATEFORME ET ROUTAGE
// ============================================================================

class PlatformAwareEntryPoint extends StatelessWidget {
  const PlatformAwareEntryPoint({Key? key}) : super(key: key);

  bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  bool get isDesktopPlatform =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement pendant la détection
    return FutureBuilder<Widget>(
      future: _determineEntryPoint(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        return snapshot.data ?? UnsupportedPlatformScreen();
      },
    );
  }

  Future<Widget> _determineEntryPoint() async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulation chargement

    if (isMobilePlatform) {
      return MobileEntryScreen();
    }

    if (isDesktopPlatform) {
      return DesktopEntryScreen();
    }

    return UnsupportedPlatformScreen();
  }
}

// ============================================================================
// ÉCRAN D'ENTRÉE MOBILE (Android/iOS)
// ============================================================================

class MobileEntryScreen extends StatelessWidget {
  const MobileEntryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade700],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icône
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 40),

                  Text(
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'Choisissez votre mode d\'accès',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 60),

                  // Bouton Utilisateur
                  _buildMobileButton(
                    context: context,
                    icon: Icons.person,
                    label: 'Mode Utilisateur',
                    subtitle: 'Accéder à l\'application',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => CardSelectionScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 24),

                  // Bouton Admin
                  _buildMobileButton(
                    context: context,
                    icon: Icons.admin_panel_settings,
                    label: 'Mode Admin',
                    subtitle: 'Scanner QR Code pour licences',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminLicenseApp(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 60),

                  // Info plateforme
                  _buildPlatformInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.transparent,
          foregroundColor: isPrimary ? Colors.blue.shade700 : Colors.white,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.white, width: 2),
          ),
          elevation: isPrimary ? 8 : 0,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.blue.shade700.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isPrimary
                          ? Colors.blue.shade700.withOpacity(0.7)
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    String platformName = Platform.isAndroid ? 'Android' : 'iOS';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Platform.isAndroid ? Icons.android : Icons.apple,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Plateforme: $platformName',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ÉCRAN D'ENTRÉE DESKTOP (Windows/macOS/Linux)
// ============================================================================

class DesktopEntryScreen extends StatefulWidget {
  const DesktopEntryScreen({Key? key}) : super(key: key);

  @override
  State<DesktopEntryScreen> createState() => _DesktopEntryScreenState();
}

class _DesktopEntryScreenState extends State<DesktopEntryScreen> {
  bool _isChecking = true;
  bool _isLicenseValid = false;
  String _statusMessage = 'Vérification de la licence...';

  @override
  void initState() {
    super.initState();
    _checkLicense();
  }

  Future<void> _checkLicense() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Vérification de la licence...';
    });

    try {
      final status = await LicenseService.checkLicenseWithIntegrity();

      setState(() {
        _isLicenseValid = status.isValid;
        _statusMessage = status.message;
        _isChecking = false;
      });

      if (status.isValid) {
        // Licence valide, naviguer vers MainApp
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => MainApp()),
            );
          }
        });
      } else {
        // Licence invalide, afficher les détails
        if (status.type == LicenseType.expired) {
          _showExpiredDialog(status.message);
        } else if (status.message.contains('corrompue')) {
          _showCorruptedDialog(status.message);
        }
      }
    } catch (e) {
      setState(() {
        _isLicenseValid = false;
        _statusMessage = 'Erreur: $e';
        _isChecking = false;
      });
    }
  }

  void _showExpiredDialog(String message) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Licence Expirée'),
                ],
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToActivation();
                  },
                  child: Text('Renouveler'),
                ),
              ],
            ),
      );
    });
  }

  void _showCorruptedDialog(String message) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Licence Corrompue'),
                ],
              ),
              content: Text('$message\n\nVeuillez réactiver votre licence.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await LicenseService.removeLicense();
                    if (mounted) {
                      Navigator.of(context).pop();
                      _navigateToActivation();
                    }
                  },
                  child: Text('Réactiver'),
                ),
              ],
            ),
      );
    });
  }

  void _navigateToActivation() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LicenseActivationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                _statusMessage,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Plateforme: ${_getPlatformName()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLicenseValid) {
      return LicenseActivationScreen();
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Licence valide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Chargement de l\'application...'),
          ],
        ),
      ),
    );
  }

  String _getPlatformName() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

// ============================================================================
// ÉCRAN POUR PLATEFORMES NON SUPPORTÉES
// ============================================================================

class UnsupportedPlatformScreen extends StatelessWidget {
  const UnsupportedPlatformScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                'Plateforme non supportée',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Cette application est disponible uniquement sur:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildPlatformItem(Icons.phone_android, 'Android'),
                    _buildPlatformItem(Icons.apple, 'iOS'),
                    _buildPlatformItem(Icons.laptop_windows, 'Windows'),
                    _buildPlatformItem(Icons.laptop_mac, 'macOS'),
                    _buildPlatformItem(Icons.laptop, 'Linux'),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Plateforme détectée: ${Platform.operatingSystem}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformItem(IconData icon, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLACEHOLDER POUR CardSelectionScreen (Si inexistant)
// ============================================================================

class CardSelectionScreen extends StatelessWidget {
  const CardSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélection'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard,
                size: 100,
                color: Colors.blue.shade700,
              ),
              SizedBox(height: 32),
              Text(
                'Bienvenue dans l\'application',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Sélectionnez une option ci-dessous',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              _buildOptionCard(
                context,
                icon: Icons.store,
                title: 'Point de Vente',
                subtitle: 'Accéder au POS',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MainApp()),
                  );
                },
              ),
              SizedBox(height: 16),
              _buildOptionCard(
                context,
                icon: Icons.hotel,
                title: 'Hôtel',
                subtitle: 'Gestion hôtelière',
                color: Colors.orange,
                onTap: () {
                  // Navigation vers module hôtel
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Module Hôtel en développement')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({Key? key}) : super(key: key);

  @override
  State<LicenseActivationScreen> createState() =>
      _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  String? deviceFingerprint;
  List<TextEditingController> pinControllers =
  List.generate(10, (_) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(10, (_) => FocusNode());
  bool isLoading = true;
  bool isValidating = false;

  @override
  void initState() {
    super.initState();
    _generateDeviceFingerprint();
  }

  @override
  void dispose() {
    for (var controller in pinControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _generateDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String fingerprint = '';

      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;

        final components = [
          windowsInfo.computerName ?? 'UnknownPC',
          windowsInfo.numberOfCores.toString(),
          windowsInfo.systemMemoryInMegabytes?.toString() ?? '0',
          Platform.operatingSystemVersion,
        ];

        final bytes = utf8.encode(components.join('|'));
        final digest = sha256.convert(bytes);
        fingerprint = digest.toString();

        print('✅ Empreinte générée: ${fingerprint.substring(0, 16)}...');
      } else {
        fingerprint = 'desktop-${DateTime
            .now()
            .millisecondsSinceEpoch}';
        print('✅ Empreinte fallback générée: $fingerprint');
      }

      setState(() {
        deviceFingerprint = fingerprint;
        isLoading = false;
      });

      print('✅ setState terminé, deviceFingerprint disponible');
    } catch (e, stackTrace) {
      print('❌ Erreur génération empreinte: $e');
      print('Stack: $stackTrace');

      // Fallback GARANTI
      final fallback = 'fallback-${DateTime
          .now()
          .millisecondsSinceEpoch}';
      setState(() {
        deviceFingerprint = fallback;
        isLoading = false;
      });
      print('✅ Fallback appliqué: $fallback');
    }
  }

  String _generateQRData() {
    if (deviceFingerprint == null) return '';

    final timestamp = DateTime
        .now()
        .millisecondsSinceEpoch;

    // AJOUT: Calculer le hash court directement ici
    final deviceHashShort = _getDeviceHashShort();

    final data = {
      'device_id': deviceFingerprint,
      'device_hash_short': deviceHashShort, // NOUVEAU: inclure le hash court
      'timestamp': timestamp,
      'app_version': '1.0.0',
    };

    return jsonEncode(data);
  }

  Future<void> _validateLicense() async {
    setState(() => isValidating = true);

    try {
      final pin = pinControllers.map((c) => c.text).join('');

      if (pin.length != 10) {
        _showError('Le code PIN doit contenir 10 chiffres');
        setState(() => isValidating = false);
        return;
      }

      final isValid = await _verifyLicensePin(pin);

      if (isValid) {
        await _saveLicense(pin);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainAppScreen()),
          );
        }
      } else {
        _showError('Code PIN invalide');
      }
    } catch (e) {
      _showError('Erreur lors de la validation: $e');
      print('Erreur lors de la validation: $e');
    } finally {
      setState(() => isValidating = false);
    }
  }

  Future<bool> _verifyLicensePin(String pin) async {
    try {
      if (!RegExp(r'^[0-9a-f]+$').hasMatch(pin)) {
        // Autoriser les caractères hexadécimaux
        print('PIN contient des caractères invalides: $pin');
        return false;
      }

      if (pin.length != 10) {
        print('PIN doit contenir 10 caractères, reçu: ${pin.length}');
        return false;
      }

      final licenseType = pin.substring(0, 1);
      final duration = pin.substring(1, 3);
      final deviceHash = pin.substring(3, 7);
      final checksum = pin.substring(7, 10);

      // Vérifier le hash de l'appareil
      final expectedHash = _getDeviceHashShort();
      print('Device hash attendu: $expectedHash, reçu: $deviceHash');

      if (deviceHash != expectedHash) {
        print('Hash appareil ne correspond pas');
        return false;
      }

      // Vérifier le checksum
      final baseCode = licenseType + duration + deviceHash;
      final calculatedChecksum = _calculateChecksum(baseCode);
      print('Checksum calculé: $calculatedChecksum, reçu: $checksum');

      if (checksum != calculatedChecksum) {
        print('Checksum ne correspond pas');
        return false;
      }

      print('PIN validé avec succès');
      return true;
    } catch (e, stackTrace) {
      print('Erreur lors de la vérification du PIN: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  String _getDeviceHashShort() {
    if (deviceFingerprint == null) {
      print('deviceFingerprint est null');
      return '0000';
    }
    final hash = sha256.convert(utf8.encode(deviceFingerprint!));
    final shortHash = hash.toString().substring(0, 4);
    print('Device fingerprint: ${deviceFingerprint!.substring(0, 16)}...');
    print('Device hash court généré: $shortHash');
    return shortHash;
  }

  String _calculateChecksum(String data) {
    try {
      final hash = sha256.convert(utf8.encode(data + 'SECRET_SALT_KEY'));
      final checksum = hash.toString().substring(0, 3);
      print('Checksum calculé pour "$data": $checksum');
      return checksum;
    } catch (e) {
      print('Erreur calcul checksum: $e');
      return '000';
    }
  }

  Future<void> _saveLicense(String pin) async {
    try {
      print('=== DÉBUT SAUVEGARDE LICENCE ===');
      print('PIN: $pin');

      final prefs = await SharedPreferences.getInstance();

      // NETTOYER toute donnée corrompue existante
      await prefs.remove('license');
      print('Anciennes données nettoyées');

      final licenseType = pin.substring(0, 1);
      final duration = int.parse(pin.substring(1, 3));
      print('Type: $licenseType, Duration: $duration jours');

      DateTime? expiryDate;
      if (licenseType == '1') {
        expiryDate = DateTime.now().add(Duration(days: duration));
        print('Date expiration: ${expiryDate.toIso8601String()}');
      }

      // ⚠️ CORRECTION CRITIQUE ICI
      if (deviceFingerprint == null || deviceFingerprint!.isEmpty) {
        print('❌ ERREUR: deviceFingerprint est null ou vide');
        throw Exception('Device fingerprint non disponible');
      }

      print(
          'Device fingerprint valide: ${deviceFingerprint!.substring(
              0, 16)}...');

      final licenseData = {
        'pin': pin,
        'device_id': deviceFingerprint!, // ✅ Maintenant garanti non-null
        'activated_at': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'type': licenseType == '1' ? 'demo' : 'lifetime',
      };

      print('Données de licence préparées');

      final jsonString = jsonEncode(licenseData);
      print('JSON créé (${jsonString.length} caractères)');
      print(
          'Aperçu: ${jsonString.substring(0, min(100, jsonString.length))}...');

      final success = await prefs.setString('license', jsonString);
      print('Sauvegarde réussie: $success');

      // VÉRIFICATION: Relire immédiatement
      final saved = prefs.getString('license');
      if (saved != null) {
        final decoded = jsonDecode(saved);
        print(
            '✅ Vérification OK: Type=${decoded['type']}, PIN=${decoded['pin']}');
      }

      print('=== LICENCE SAUVEGARDÉE AVEC SUCCÈS ===');
    } catch (e, stackTrace) {
      print('=== ERREUR SAUVEGARDE ===');
      print('Erreur: $e');
      print('Type erreur: ${e.runtimeType}');
      print('deviceFingerprint: ${deviceFingerprint ?? "NULL"}');
      print('Stack trace:');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> _sendEmailRequest() async {
    final qrData = _generateQRData();
    final email = 'ramzi.guedouar@gmail.com';
    final subject = 'Demande d\'activation de licence';
    final body = '''
Bonjour,

Je souhaite activer une licence pour votre application.

Données du système:
$qrData

Merci de me fournir un code PIN d'activation.

Cordialement
''';

    final emailUrl = Uri(
      scheme: 'mailto',
      path: email,
      query:
      'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(
          body)}',
    );

    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl);
    } else {
      _showError('Impossible d\'ouvrir le client email');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade700],
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            elevation: 8,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.all(40),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildInstructions(),
                    const SizedBox(height: 30),
                    _buildQRSection(),
                    const SizedBox(height: 30),
                    _buildPinSection(),
                    const SizedBox(height: 30),
                    _buildButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.security, size: 64, color: Colors.blue.shade700),
        const SizedBox(height: 16),
        const Text(
          'Activation de la Licence',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenue ! Activez votre application',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (ctx) => AdminLicenseApp())),
          child: Text(
            'Je suis Admin',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        )
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Comment activer votre licence ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionStep('1', 'Choisissez votre type de licence', [
            '• Licence DEMO: Durée limitée (7, 15, 30 jours...)',
            '• Licence LIFETIME: Accès permanent sans expiration',
          ]),
          const Divider(height: 24),
          _buildInstructionStep('2', 'Scannez le QR Code ci-dessous', [
            '• Utilisez l\'application Admin Android',
            '• Ou envoyez une demande par email avec le bouton "Demander par Email"',
          ]),
          const Divider(height: 24),
          _buildInstructionStep('3', 'Recevez et entrez votre code PIN', [
            '• Vous recevrez un code PIN de 10 chiffres',
            '• Entrez-le dans les champs ci-dessous',
            '• Cliquez sur "Valider" pour activer',
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Le code PIN est unique pour cet ordinateur et ne peut pas être utilisé sur un autre appareil.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title,
      List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points
                .map((p) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(p,
                      style: TextStyle(color: Colors.grey.shade700)),
                ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQRSection() {
    return Column(
      children: [
        const Text(
          'Scannez ce QR Code',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: SizedBox(
            width: 250,
            height: 250,
            child: SfBarcodeGenerator(
              value: _generateQRData(),
              symbology: QRCode(),
              showValue: false,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ID Appareil: ${deviceFingerprint?.substring(0, 16)}...',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'monospace'),
        ),
        SelectableText(deviceFingerprint.toString()),
      ],
    );
  }

  Widget _buildPinSection() {
    return Column(
      children: [
        const Text(
          'Entrez votre code PIN d\'activation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(10, (index) {
            return Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: pinControllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                //keyboardType: TextInputType.number,
                maxLength: 1,
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: Colors.blue.shade700, width: 3),
                  ),
                ),
                //  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty && index < 9) {
                    focusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isValidating ? null : _validateLicense,
            icon: isValidating
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.check_circle),
            label: Text(
              isValidating ? 'Validation en cours...' : 'Valider la Licence',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _sendEmailRequest,
            icon: const Icon(Icons.email),
            label: const Text(
              'Demander par Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade700, width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Activée')),
      body: const Center(
          child: Text('Bienvenue ! Votre application est activée.')),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////

class AdminLicenseApp extends StatelessWidget {
  const AdminLicenseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin License Generator',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: const AdminLoginScreen(),
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // CHANGEMENT CLÉ 1: Stockage du mot de passe en clair.
  static const String _adminPassword = 'Admin@2024';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // CHANGEMENT CLÉ 2: Suppression de la fonction _hashPassword.

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      // CHANGEMENT CLÉ 3: Comparaison directe du mot de passe entré.
      if (_passwordController.text == _adminPassword) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QRScannerScreen()),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe incorrect'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        _passwordController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... Le reste du code de l'interface utilisateur (UI) reste inchangé
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade700,
                Colors.deepPurple.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 64,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Admin License',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Générateur de Licences',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe administrateur',
                              hintText: 'Entrez votre mot de passe',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Mot de passe trop court';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Accès réservé aux administrateurs uniquement',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onDoubleTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (ctx) => MyApp9()));
                                  },
                                  child: Icon(
                                    Icons.info,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool hasScanned = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!hasScanned && capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null) {
        setState(() => hasScanned = true);
        _processQRData(barcode.rawValue!);
      }
    }
  }

  void _processQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      final deviceId = data['device_id'] as String?;
      final deviceHashShort = data['device_hash_short'] as String?; // NOUVEAU
      final timestamp = data['timestamp'] as int?;
      final appVersion = data['app_version'] as String?;

      if (deviceId == null || timestamp == null) {
        _showError('QR Code invalide');
        return;
      }

      final now = DateTime
          .now()
          .millisecondsSinceEpoch;
      if (now - timestamp > 3600000) {
        _showError('QR Code expiré. Veuillez en générer un nouveau.');
        return;
      }

      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) =>
              LicenseGeneratorScreen(
                deviceId: deviceId,
                deviceHashShort:
                deviceHashShort ?? '', // NOUVEAU: passer le hash court
                appVersion: appVersion ?? 'Unknown',
              ),
        ),
      )
          .then((_) {
        setState(() => hasScanned = false);
      });
    } catch (e) {
      _showError('Erreur lors du scan: $e');
      setState(() => hasScanned = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.deepPurple.shade50,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner,
                        size: 48, color: Colors.deepPurple.shade700),
                    const SizedBox(height: 8),
                    const Text(
                      'Scannez le QR Code de l\'application Windows',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseGeneratorScreen extends StatefulWidget {
  final String deviceId;
  final String deviceHashShort; // NOUVEAU
  final String appVersion;

  const LicenseGeneratorScreen({
    Key? key,
    required this.deviceId,
    required this.deviceHashShort, // NOUVEAU
    required this.appVersion,
  }) : super(key: key);

  @override
  State<LicenseGeneratorScreen> createState() => _LicenseGeneratorScreenState();
}

class _LicenseGeneratorScreenState extends State<LicenseGeneratorScreen> {
  String? selectedLicenseType;
  int? selectedDuration;
  String? generatedPin;

  final Map<String, String> licenseTypes = {
    'demo': 'Licence DEMO (Durée limitée)',
    'lifetime': 'Licence LIFETIME (Permanent)',
  };

  final List<int> demoDurations = [7, 15, 30, 60, 90];

  void _generatePin() {
    if (selectedLicenseType == null) {
      _showError('Veuillez sélectionner un type de licence');
      return;
    }

    if (selectedLicenseType == 'demo' && selectedDuration == null) {
      _showError('Veuillez sélectionner une durée pour la licence DEMO');
      return;
    }

    final typeCode = selectedLicenseType == 'demo' ? '1' : '2';
    final durationCode = selectedLicenseType == 'demo'
        ? selectedDuration.toString().padLeft(2, '0')
        : '00';

    // MODIFICATION: Utiliser directement le hash court reçu du QR code
    final deviceHash = widget.deviceHashShort;

    final baseCode = typeCode + durationCode + deviceHash;
    final checksum = _calculateChecksum(baseCode);
    final pin = baseCode + checksum;

    setState(() {
      generatedPin = pin;
    });

    print('PIN généré: $pin');
    print(
        'Type: $typeCode, Durée: $durationCode, Hash: $deviceHash, Checksum: $checksum');
  }

  String _calculateChecksum(String data) {
    final hash = sha256.convert(utf8.encode(data + 'SECRET_SALT_KEY'));
    return hash.toString().substring(0, 3);
  }

  void _copyToClipboard() {
    if (generatedPin != null) {
      Clipboard.setData(ClipboardData(text: generatedPin!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code PIN copié dans le presse-papiers'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générer une Licence'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceInfo(),
            const SizedBox(height: 24),
            _buildLicenseTypeSelector(),
            if (selectedLicenseType == 'demo') ...[
              const SizedBox(height: 24),
              _buildDurationSelector(),
            ],
            const SizedBox(height: 32),
            _buildGenerateButton(),
            if (generatedPin != null) ...[
              const SizedBox(height: 32),
              _buildGeneratedPin(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.computer, color: Colors.deepPurple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Informations de l\'appareil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
                'ID Appareil', widget.deviceId.substring(0, 16) + '...'),
            _buildInfoRow('Version App', widget.appVersion),
            _buildInfoRow(
                'Date de scan', DateTime.now().toString().substring(0, 19)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: Colors.grey.shade700, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTypeSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Colors.deepPurple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Type de licence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...licenseTypes.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                subtitle: Text(
                  entry.key == 'demo'
                      ? 'Accès temporaire avec date d\'expiration'
                      : 'Accès illimité sans expiration',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: entry.key,
                groupValue: selectedLicenseType,
                activeColor: Colors.deepPurple.shade700,
                onChanged: (value) {
                  setState(() {
                    selectedLicenseType = value;
                    selectedDuration = null;
                    generatedPin = null;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.deepPurple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Durée de la licence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: demoDurations.map((days) {
                final isSelected = selectedDuration == days;
                return ChoiceChip(
                  label: Text('$days jours'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedDuration = selected ? days : null;
                      generatedPin = null;
                    });
                  },
                  selectedColor: Colors.deepPurple.shade700,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: _generatePin,
      icon: const Icon(Icons.vpn_key, size: 28),
      label: const Text(
        'Générer le Code PIN',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Widget _buildGeneratedPin() {
    return Card(
      elevation: 8,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 32),
                const SizedBox(width: 8),
                const Text(
                  'Code PIN Généré',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FittedBox(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: generatedPin!.split('').map((digit) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple.shade300),
                      ),
                      child: Text(
                        digit,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text('Copier le Code PIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Détails de la licence',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLicenseDetail(
                    'Type',
                    selectedLicenseType == 'demo' ? 'DEMO' : 'LIFETIME',
                  ),
                  if (selectedLicenseType == 'demo')
                    _buildLicenseDetail('Durée', '$selectedDuration jours'),
                  _buildLicenseDetail(
                    'Expiration',
                    selectedLicenseType == 'demo'
                        ? DateTime.now()
                        .add(Duration(days: selectedDuration!))
                        .toString()
                        .substring(0, 10)
                        : 'Jamais',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////

class LicenseService {
  static const String _licenseKey = 'license';
  static const String _secretSalt = 'SECRET_SALT_KEY';

  /// Vérifie si l'application possède une licence valide
  static Future<LicenseStatus> checkLicense() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final licenseData = prefs.getString(_licenseKey);

      if (licenseData == null) {
        return LicenseStatus(
          isValid: false,
          type: LicenseType.none,
          message: 'Aucune licence trouvée',
        );
      }

      final license = jsonDecode(licenseData);

      // Vérifier l'intégrité de l'appareil
      final currentDeviceId = await _getDeviceFingerprint();
      final savedDeviceId = license['device_id'] as String?;

      if (currentDeviceId != savedDeviceId) {
        return LicenseStatus(
          isValid: false,
          type: LicenseType.none,
          message: 'Cette licence est liée à un autre appareil',
        );
      }

      // Vérifier le type de licence
      final type = license['type'] as String;

      if (type == 'lifetime') {
        return LicenseStatus(
          isValid: true,
          type: LicenseType.lifetime,
          message: 'Licence LIFETIME active',
        );
      }

      if (type == 'demo') {
        final expiryStr = license['expiry_date'] as String?;
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

        final daysRemaining = expiryDate
            .difference(now)
            .inDays;

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

  /// Obtient les détails de la licence
  static Future<Map<String, dynamic>?> getLicenseDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final licenseData = prefs.getString(_licenseKey);

    if (licenseData == null) return null;

    return jsonDecode(licenseData);
  }

  /// Supprime la licence
  static Future<void> removeLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
  }

  /// Génère l'empreinte unique de l'appareil
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
    }

    return fingerprint;
  }

  /// Vérifie périodiquement la validité de la licence
  static Future<bool> validateLicenseIntegrity() async {
    final status = await checkLicense();
    return status.isValid;
  }

  /// Calcule le checksum avec le sel secret (pour validation du PIN)
  static String calculateChecksum(String data) {
    final hash = sha256.convert(utf8.encode(data + _secretSalt));
    return hash.toString().substring(0, 3);
  }

  /// Obtient le hash court de l'appareil (pour validation du PIN)
  static Future<String> getDeviceHashShort() async {
    final fingerprint = await _getDeviceFingerprint();
    final hash = sha256.convert(utf8.encode(fingerprint));
    return hash.toString().substring(0, 4);
  }

  /// Vérifie l'intégrité complète du PIN avec le sel
  static Future<bool> verifyPinIntegrity(String pin) async {
    try {
      if (pin.length != 10) return false;

      final licenseType = pin.substring(0, 1);
      final duration = pin.substring(1, 3);
      final deviceHash = pin.substring(3, 7);
      final checksum = pin.substring(7, 10);

      // Vérifier le hash de l'appareil
      final expectedHash = await getDeviceHashShort();
      if (deviceHash != expectedHash) {
        return false;
      }

      // Vérifier le checksum avec le sel
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

  /// Vérification complète incluant l'intégrité du PIN stocké
  static Future<LicenseStatus> checkLicenseWithIntegrity() async {
    try {
      // Vérifier la licence normalement
      final status = await checkLicense();

      if (!status.isValid) {
        return status;
      }

      // Vérification supplémentaire : intégrité du PIN
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

/// Statut de la licence
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

/// Types de licence
enum LicenseType {
  none,
  demo,
  lifetime,
  expired,
}

/// Widget wrapper pour protéger l'application
class LicenseProtectedApp extends StatefulWidget {
  final Widget child;
  final Widget activationScreen;

  const LicenseProtectedApp({
    Key? key,
    required this.child,
    required this.activationScreen,
  }) : super(key: key);

  @override
  State<LicenseProtectedApp> createState() => _LicenseProtectedAppState();
}

class _LicenseProtectedAppState extends State<LicenseProtectedApp> {
  bool _isChecking = true;
  bool _isLicenseValid = false;

  @override
  void initState() {
    super.initState();
    _checkLicense();
    _startPeriodicCheck();
  }

  Future<void> _checkLicense() async {
    // Utilise la vérification renforcée avec intégrité du PIN
    final status = await LicenseService.checkLicenseWithIntegrity();

    setState(() {
      _isLicenseValid = status.isValid;
      _isChecking = false;
    });

    if (!status.isValid && status.type == LicenseType.expired) {
      _showExpiredDialog(status.message);
    } else if (!status.isValid && status.message.contains('corrompue')) {
      _showCorruptedDialog(status.message);
    }
  }

  void _showCorruptedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Licence Corrompue'),
              ],
            ),
            content: Text(
                '$message\n\nVeuillez contacter le support pour obtenir une nouvelle licence.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await LicenseService.removeLicense();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => widget.activationScreen),
                    );
                  }
                },
                child: const Text('Réactiver'),
              ),
            ],
          ),
    );
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _checkLicense();
        _startPeriodicCheck();
      }
    });
  }

  void _showExpiredDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Licence Expirée'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => widget.activationScreen),
                  );
                },
                child: const Text('Renouveler la Licence'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Vérification de la licence...'),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLicenseValid) {
      return MaterialApp(
        home: widget.activationScreen,
      );
    }

    return widget.child;
  }
}

/// Widget pour afficher les infos de licence
class LicenseInfoWidget extends StatefulWidget {
  const LicenseInfoWidget({Key? key}) : super(key: key);

  @override
  State<LicenseInfoWidget> createState() => _LicenseInfoWidgetState();
}

class _LicenseInfoWidgetState extends State<LicenseInfoWidget> {
  LicenseStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await LicenseService.checkLicense();
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const CircularProgressIndicator();
    }

    Color statusColor = _status!.isValid ? Colors.green : Colors.red;
    IconData statusIcon = _status!.isValid ? Icons.check_circle : Icons.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Statut de la Licence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Type', _getLicenseTypeLabel(_status!.type)),
            _buildInfoRow('Statut', _status!.message),
            if (_status!.expiryDate != null)
              _buildInfoRow(
                'Expiration',
                _status!.expiryDate!.toString().substring(0, 10),
              ),
            if (_status!.daysRemaining != null)
              _buildInfoRow(
                'Jours restants',
                _status!.daysRemaining.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getLicenseTypeLabel(LicenseType type) {
    switch (type) {
      case LicenseType.demo:
        return 'DEMO';
      case LicenseType.lifetime:
        return 'LIFETIME';
      case LicenseType.expired:
        return 'EXPIRÉE';
      case LicenseType.none:
        return 'AUCUNE';
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Application'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LicenseInfoPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Application Activée avec Succès !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LicenseInfoPage(),
                  ),
                );
              },
              child: const Text('Voir les informations de licence'),
            ),
          ],
        ),
      ),
    );
  }
}

class LicenseInfoPage extends StatelessWidget {
  const LicenseInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations de Licence'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LicenseInfoWidget(),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>?>(
              future: LicenseService.getLicenseDetails(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final details = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails Techniques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Code PIN',
                          details['pin'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Date d\'activation',
                          _formatDate(details['activated_at']),
                        ),
                        _buildDetailRow(
                          'ID Appareil',
                          (details['device_id'] as String?)?.substring(0, 16) ??
                              'N/A',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute
          .toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
/////////////////////////////////////////////////////////////////////////////////

/// Page de paramètres avec informations de licence
/// À intégrer dans votre menu de navigation
class SettingsPageWithLicense extends StatefulWidget {
  const SettingsPageWithLicense({Key? key}) : super(key: key);

  @override
  State<SettingsPageWithLicense> createState() =>
      _SettingsPageWithLicenseState();
}

class _SettingsPageWithLicenseState extends State<SettingsPageWithLicense> {
  LicenseStatus? _licenseStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenseStatus();
  }

  Future<void> _loadLicenseStatus() async {
    final status = await LicenseService.checkLicense();
    setState(() {
      _licenseStatus = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Section Licence
          _buildSectionHeader('Licence'),
          _buildLicenseCard(),

          const Divider(height: 32),

          // Vos autres sections de paramètres
          _buildSectionHeader('Application'),
          _buildSettingTile(
            icon: Icons.palette,
            title: 'Thème',
            subtitle: 'Clair / Sombre',
            onTap: () {
              // Votre logique de changement de thème
            },
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {
              // Votre logique de changement de langue
            },
          ),

          const Divider(height: 32),

          _buildSectionHeader('Données'),
          _buildSettingTile(
            icon: Icons.backup,
            title: 'Sauvegarde',
            subtitle: 'Sauvegarder les données',
            onTap: () {
              // Votre logique de sauvegarde
            },
          ),
          _buildSettingTile(
            icon: Icons.restore,
            title: 'Restauration',
            subtitle: 'Restaurer depuis une sauvegarde',
            onTap: () {
              // Votre logique de restauration
            },
          ),

          const Divider(height: 32),

          _buildSectionHeader('À propos'),
          _buildSettingTile(
            icon: Icons.info,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLicenseCard() {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_licenseStatus == null) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: Icon(Icons.error, color: Colors.red),
          title: Text('Erreur de licence'),
          subtitle: Text('Impossible de charger les informations'),
        ),
      );
    }

    final isValid = _licenseStatus!.isValid;
    final type = _licenseStatus!.type;

    Color statusColor = isValid ? Colors.green : Colors.red;
    IconData statusIcon = isValid ? Icons.verified : Icons.error;

    String statusText = '';
    String detailText = '';

    switch (type) {
      case LicenseType.lifetime:
        statusText = 'Licence LIFETIME';
        detailText = 'Accès permanent';
        break;
      case LicenseType.demo:
        statusText = 'Licence DEMO';
        detailText = '${_licenseStatus!.daysRemaining} jours restants';
        if (_licenseStatus!.daysRemaining! <= 7) {
          statusColor = Colors.orange;
        }
        break;
      case LicenseType.expired:
        statusText = 'Licence expirée';
        detailText = 'Renouvellement requis';
        break;
      case LicenseType.none:
        statusText = 'Aucune licence';
        detailText = 'Activation requise';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LicenseDetailsPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (type == LicenseType.demo &&
                        _licenseStatus!.expiryDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Expire le ${_formatDate(_licenseStatus!
                              .expiryDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month
        .toString()
        .padLeft(2, '0')}/${date.year}';
  }
}

/// Page détaillée des informations de licence
class LicenseDetailsPage extends StatelessWidget {
  const LicenseDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Licence'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LicenseInfoWidget(),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>?>(
              future: LicenseService.getLicenseDetails(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final details = snapshot.data;
                if (details == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune licence trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const LicenseActivationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.vpn_key),
                            label: const Text('Activer une licence'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations Techniques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Code PIN',
                          details['pin'] ?? 'N/A',
                          Icons.vpn_key,
                        ),
                        _buildInfoRow(
                          'Type de licence',
                          (details['type'] as String).toUpperCase(),
                          Icons.card_membership,
                        ),
                        _buildInfoRow(
                          'Date d\'activation',
                          _formatDateTime(details['activated_at']),
                          Icons.event,
                        ),
                        if (details['expiry_date'] != null)
                          _buildInfoRow(
                            'Date d\'expiration',
                            _formatDateTime(details['expiry_date']),
                            Icons.event_busy,
                          ),
                        _buildInfoRow(
                          'ID Appareil',
                          '${(details['device_id'] as String).substring(
                              0, 16)}...',
                          Icons.computer,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Informations importantes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoPoint(
                        'Cette licence est unique et liée à cet appareil'),
                    _buildInfoPoint(
                        'Elle ne peut pas être transférée vers un autre PC'),
                    _buildInfoPoint(
                        'Pour renouveler, contactez votre administrateur'),
                    _buildInfoPoint('En cas de problème, notez votre code PIN'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month
          .toString()
          .padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(
          2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
