import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:url_launcher/url_launcher.dart';

import 'objectBox/MyApp.dart';

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
          windowsInfo.computerName,
          windowsInfo.numberOfCores.toString(),
          windowsInfo.systemMemoryInMegabytes.toString(),
          Platform.operatingSystemVersion,
        ];

        final bytes = utf8.encode(components.join('|'));
        final digest = sha256.convert(bytes);
        fingerprint = digest.toString();
      }

      setState(() {
        deviceFingerprint = fingerprint;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Erreur lors de la génération de l\'empreinte système');
    }
  }

  String _generateQRData() {
    if (deviceFingerprint == null) return '';

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'device_id': deviceFingerprint,
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
    } finally {
      setState(() => isValidating = false);
    }
  }

  Future<bool> _verifyLicensePin(String pin) async {
    try {
      final licenseType = pin.substring(0, 1);
      final duration = pin.substring(1, 3);
      final deviceHash = pin.substring(3, 7);
      final checksum = pin.substring(7, 10);

      final expectedHash = _getDeviceHashShort();
      if (deviceHash != expectedHash) {
        return false;
      }

      final calculatedChecksum = _calculateChecksum(pin.substring(0, 7));
      if (checksum != calculatedChecksum) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  String _getDeviceHashShort() {
    if (deviceFingerprint == null) return '0000';
    final hash = sha256.convert(utf8.encode(deviceFingerprint!));
    return hash.toString().substring(0, 4);
  }

  String _calculateChecksum(String data) {
    final hash = sha256.convert(utf8.encode(data + 'SECRET_SALT_KEY'));
    return hash.toString().substring(0, 3);
  }

  Future<void> _saveLicense(String pin) async {
    final prefs = await SharedPreferences.getInstance();

    final licenseType = pin.substring(0, 1);
    final duration = int.parse(pin.substring(1, 3));

    DateTime? expiryDate;
    if (licenseType == '1') {
      expiryDate = DateTime.now().add(Duration(days: duration));
    }

    final licenseData = {
      'pin': pin,
      'device_id': deviceFingerprint,
      'activated_at': DateTime.now().toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'type': licenseType == '1' ? 'demo' : 'lifetime',
    };

    await prefs.setString('license', jsonEncode(licenseData));
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
          onPressed: () => Navigator.of(context)
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
                keyboardType: TextInputType.number,
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                Navigator.of(context).push(MaterialPageRoute(
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
      final timestamp = data['timestamp'] as int?;
      final appVersion = data['app_version'] as String?;

      if (deviceId == null || timestamp == null) {
        _showError('QR Code invalide');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > 3600000) {
        _showError('QR Code expiré. Veuillez en générer un nouveau.');
        return;
      }

      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => LicenseGeneratorScreen(
            deviceId: deviceId,
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
  final String appVersion;

  const LicenseGeneratorScreen({
    Key? key,
    required this.deviceId,
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

    final deviceHash = _getDeviceHashShort(widget.deviceId);
    final baseCode = typeCode + durationCode + deviceHash;
    final checksum = _calculateChecksum(baseCode);
    final pin = baseCode + checksum;

    setState(() {
      generatedPin = pin;
    });
  }

  String _getDeviceHashShort(String deviceId) {
    final hash = sha256.convert(utf8.encode(deviceId));
    return hash.toString().substring(0, 4);
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
            Container(
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
      builder: (context) => AlertDialog(
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
                  MaterialPageRoute(builder: (_) => widget.activationScreen),
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
      builder: (context) => AlertDialog(
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

class MyAppBlackHole extends StatelessWidget {
  const MyAppBlackHole({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlackHole',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: LicenseProtectedApp(
        activationScreen: const LicenseActivationScreen(),
        child: const MainApp(),
      ),
    );
  }
}

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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
                          'Expire le ${_formatDate(_licenseStatus!.expiryDate!)}',
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                          '${(details['device_id'] as String).substring(0, 16)}...',
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
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
