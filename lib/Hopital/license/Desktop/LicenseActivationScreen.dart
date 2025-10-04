import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../StorageService.dart';
import '../TestPinValidation.dart';

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
        fingerprint = 'desktop-${DateTime.now().millisecondsSinceEpoch}';
        print('✅ Empreinte fallback générée: $fingerprint');
      }

      setState(() {
        deviceFingerprint = fingerprint.trim();
        isLoading = false;
      });

      print('✅ setState terminé, deviceFingerprint disponible');
      print('✅ setState terminé');
      print('deviceFingerprint disponible: ${deviceFingerprint != null}');
      print('deviceFingerprint length: ${deviceFingerprint?.length}');
      print(
          'deviceFingerprint first 50 chars: ${deviceFingerprint?.substring(0, 50)}');
    } catch (e, stackTrace) {
      print('❌ Erreur génération empreinte: $e');
      print('Stack: $stackTrace');

      final fallback = 'fallback-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        deviceFingerprint = fallback;
        isLoading = false;
      });
      print('✅ Fallback appliqué: $fallback');
    }
  }

  String _generateQRData() {
    if (deviceFingerprint == null) return '';

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceHashShort = _getDeviceHashShort();

    final data = {
      'device_id': deviceFingerprint,
      'device_hash_short': deviceHashShort,
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

      final expectedHash = _getDeviceHashShort();
      print('Device hash attendu: $expectedHash, reçu: $deviceHash');

      if (deviceHash != expectedHash) {
        print('Hash appareil ne correspond pas');
        return false;
      }

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

      await StorageService.removeLicense(); // Nettoyer l'ancienne
      print('Anciennes données nettoyées');

      final licenseType = pin.substring(0, 1);
      final duration = int.parse(pin.substring(1, 3));
      print('Type: $licenseType, Duration: $duration jours');

      DateTime? expiryDate;
      if (licenseType == '1') {
        expiryDate = DateTime.now().add(Duration(days: duration));
        print('Date expiration: ${expiryDate.toIso8601String()}');
      }

      if (deviceFingerprint == null || deviceFingerprint!.isEmpty) {
        throw Exception('Device fingerprint non disponible');
      }

      final licenseData = {
        'pin': pin,
        'device_id': deviceFingerprint!,
        'activated_at': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'type': licenseType == '1' ? 'demo' : 'lifetime',
      };

      await StorageService.saveLicense(licenseData);

      // Vérification
      final saved = await StorageService.getLicense();
      if (saved != null) {
        print('✓ Vérification OK: Type=${saved['type']}, PIN=${saved['pin']}');
      }

      print('=== LICENCE SAUVEGARDÉE AVEC SUCCÈS ===');
    } catch (e, stackTrace) {
      print('=== ERREUR SAUVEGARDE ===');
      print('Erreur: $e');
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
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
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
                          const SizedBox(height: 30),
                          GestureDetector(
                            onDoubleTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => TestPinValidation()),
                              );
                            },
                            child: Icon(Icons.bug_report,
                                color: Colors.grey, size: 20),
                          ),
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
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
      String number, String title, List<String> points) {
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
                .map((p) => Padding(
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
