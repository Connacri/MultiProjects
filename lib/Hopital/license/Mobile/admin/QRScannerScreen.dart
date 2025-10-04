import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'LicenseGeneratorScreen.dart';

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
      final deviceHashShort = data['device_hash_short'] as String?;
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
            deviceHashShort: deviceHashShort ?? '',
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
