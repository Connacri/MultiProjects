import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestPinValidation extends StatefulWidget {
  const TestPinValidation({Key? key}) : super(key: key);

  @override
  State<TestPinValidation> createState() => _TestPinValidationState();
}

class _TestPinValidationState extends State<TestPinValidation> {
  String? deviceFingerprint;
  String? deviceHashShort;
  String? generatedPin;
  bool isLoading = true;

  // Configuration du test
  String selectedLicenseType = 'demo';
  int selectedDuration = 30;

  // Résultats de validation
  Map<String, dynamic>? validationResult;

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    setState(() => isLoading = true);

    try {
      final fingerprint = await _getDeviceFingerprint();
      final hash = sha256.convert(utf8.encode(fingerprint));
      final shortHash = hash.toString().substring(0, 4);

      setState(() {
        deviceFingerprint = fingerprint;
        deviceHashShort = shortHash;
        isLoading = false;
      });

      print('✅ Test initialisé');
      print('Device ID: ${fingerprint.substring(0, 20)}...');
      print('Hash court: $shortHash');
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Erreur d\'initialisation: $e');
    }
  }

  Future<String> _getDeviceFingerprint() async {
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
    } else {
      fingerprint = 'test-${DateTime.now().millisecondsSinceEpoch}';
    }

    return fingerprint;
  }

  void _generateTestPin() {
    if (deviceHashShort == null) {
      _showError('Device hash non disponible');
      return;
    }

    final typeCode = selectedLicenseType == 'demo' ? '1' : '2';
    final durationCode = selectedLicenseType == 'demo'
        ? selectedDuration.toString().padLeft(2, '0')
        : '00';

    final baseCode = typeCode + durationCode + deviceHashShort!;
    final checksum = _calculateChecksum(baseCode);
    final pin = baseCode + checksum;

    setState(() {
      generatedPin = pin;
      validationResult = null;
    });

    print('\n📌 PIN GÉNÉRÉ:');
    print('Type: $typeCode (${selectedLicenseType})');
    print('Durée: $durationCode jours');
    print('Hash: $deviceHashShort');
    print('Checksum: $checksum');
    print('PIN complet: $pin');
  }

  String _calculateChecksum(String data) {
    final hash = sha256.convert(utf8.encode(data + 'SECRET_SALT_KEY'));
    return hash.toString().substring(0, 3);
  }

  Future<void> _validateGeneratedPin() async {
    if (generatedPin == null) {
      _showError('Générez d\'abord un PIN');
      return;
    }

    print('\n🔍 VALIDATION DU PIN: $generatedPin');

    final result = <String, dynamic>{
      'pin': generatedPin,
      'tests': <String, dynamic>{},
    };

    // Test 1: Longueur
    final lengthValid = generatedPin!.length == 10;
    result['tests']['longueur'] = {
      'valid': lengthValid,
      'expected': 10,
      'actual': generatedPin!.length,
    };
    print(
        '  ✓ Longueur: ${lengthValid ? "OK" : "ÉCHEC"} (${generatedPin!.length}/10)');

    // Test 2: Format hexadécimal
    final hexValid = RegExp(r'^[0-9a-f]+$').hasMatch(generatedPin!);
    result['tests']['format'] = {
      'valid': hexValid,
      'message':
          hexValid ? 'Hexadécimal valide' : 'Contient des caractères invalides',
    };
    print('  ✓ Format: ${hexValid ? "OK" : "ÉCHEC"}');

    // Test 3: Type de licence
    final licenseType = generatedPin!.substring(0, 1);
    final typeValid = licenseType == '1' || licenseType == '2';
    result['tests']['type'] = {
      'valid': typeValid,
      'extracted': licenseType,
      'expected': selectedLicenseType == 'demo' ? '1' : '2',
      'match': licenseType == (selectedLicenseType == 'demo' ? '1' : '2'),
    };
    print('  ✓ Type: ${typeValid ? "OK" : "ÉCHEC"} (Code: $licenseType)');

    // Test 4: Durée
    final duration = generatedPin!.substring(1, 3);
    final expectedDuration = selectedLicenseType == 'demo'
        ? selectedDuration.toString().padLeft(2, '0')
        : '00';
    final durationValid = duration == expectedDuration;
    result['tests']['duree'] = {
      'valid': durationValid,
      'extracted': duration,
      'expected': expectedDuration,
    };
    print(
        '  ✓ Durée: ${durationValid ? "OK" : "ÉCHEC"} ($duration/$expectedDuration)');

    // Test 5: Hash de l'appareil
    final deviceHash = generatedPin!.substring(3, 7);
    final hashValid = deviceHash == deviceHashShort;
    result['tests']['hash'] = {
      'valid': hashValid,
      'extracted': deviceHash,
      'expected': deviceHashShort,
    };
    print(
        '  ✓ Hash: ${hashValid ? "OK" : "ÉCHEC"} ($deviceHash/$deviceHashShort)');

    // Test 6: Checksum
    final extractedChecksum = generatedPin!.substring(7, 10);
    final baseCode = generatedPin!.substring(0, 7);
    final calculatedChecksum = _calculateChecksum(baseCode);
    final checksumValid = extractedChecksum == calculatedChecksum;
    result['tests']['checksum'] = {
      'valid': checksumValid,
      'extracted': extractedChecksum,
      'calculated': calculatedChecksum,
    };
    print(
        '  ✓ Checksum: ${checksumValid ? "OK" : "ÉCHEC"} ($extractedChecksum/$calculatedChecksum)');

    // Test 7: Validation complète (simule la validation Desktop)
    final isFullyValid = lengthValid &&
        hexValid &&
        typeValid &&
        durationValid &&
        hashValid &&
        checksumValid;
    result['isValid'] = isFullyValid;
    result['summary'] = isFullyValid
        ? '✅ PIN VALIDE - Peut être utilisé sur Desktop'
        : '❌ PIN INVALIDE - Ne fonctionnera pas sur Desktop';

    print('\n' + result['summary']);
    print('═' * 50);

    setState(() {
      validationResult = result;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test de Validation PIN')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Validation PIN'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceInfo(),
            const SizedBox(height: 24),
            _buildConfigurationPanel(),
            const SizedBox(height: 24),
            _buildGenerateButton(),
            if (generatedPin != null) ...[
              const SizedBox(height: 24),
              _buildGeneratedPinCard(),
              const SizedBox(height: 16),
              _buildValidateButton(),
            ],
            if (validationResult != null) ...[
              const SizedBox(height: 24),
              _buildValidationResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
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
                  'Informations de l\'appareil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Device ID', deviceFingerprint?.substring(0, 32) ?? ''),
            _buildInfoRow('Hash court', deviceHashShort ?? ''),
            _buildInfoRow('Plateforme', Platform.operatingSystem),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration du test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Licence DEMO'),
              value: 'demo',
              groupValue: selectedLicenseType,
              onChanged: (value) {
                setState(() {
                  selectedLicenseType = value!;
                  generatedPin = null;
                  validationResult = null;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Licence LIFETIME'),
              value: 'lifetime',
              groupValue: selectedLicenseType,
              onChanged: (value) {
                setState(() {
                  selectedLicenseType = value!;
                  generatedPin = null;
                  validationResult = null;
                });
              },
            ),
            if (selectedLicenseType == 'demo') ...[
              const SizedBox(height: 8),
              const Text('Durée (jours):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [7, 15, 30, 60, 90].map((days) {
                  return ChoiceChip(
                    label: Text('$days jours'),
                    selected: selectedDuration == days,
                    onSelected: (selected) {
                      setState(() {
                        selectedDuration = days;
                        generatedPin = null;
                        validationResult = null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton.icon(
      onPressed: _generateTestPin,
      icon: const Icon(Icons.refresh),
      label: const Text('Générer un PIN de test'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGeneratedPinCard() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'PIN Généré',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: generatedPin!.split('').map((char) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      char,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: generatedPin!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN copié dans le presse-papiers'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidateButton() {
    return ElevatedButton.icon(
      onPressed: _validateGeneratedPin,
      icon: const Icon(Icons.check_circle),
      label: const Text('Valider le PIN'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildValidationResults() {
    final isValid = validationResult!['isValid'] as bool;

    return Card(
      color: isValid ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    validationResult!['summary'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isValid ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Détails de validation:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...((validationResult!['tests'] as Map<String, dynamic>)
                .entries
                .map((entry) {
              final testResult = entry.value as Map<String, dynamic>;
              final testValid = testResult['valid'] as bool;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      testValid ? Icons.check : Icons.close,
                      color: testValid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${testResult.toString()}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }
}
