import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LicenseGeneratorScreen extends StatefulWidget {
  final String deviceId;
  final String deviceHashShort;
  final String appVersion;

  const LicenseGeneratorScreen({
    Key? key,
    required this.deviceId,
    required this.deviceHashShort,
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
