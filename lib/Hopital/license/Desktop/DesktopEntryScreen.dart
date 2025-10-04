import 'dart:io';

import 'package:flutter/material.dart';

import '../LicenseService.dart';
import 'LicenseActivationScreen.dart';
import 'MainApp.dart';

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
        // Naviguer vers MainApp
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => MainApp()),
            );
          }
        });
      } else {
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
        builder: (context) => AlertDialog(
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
        builder: (context) => AlertDialog(
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
            // Dans AdminLoginScreen.dart, ajoutez ce bouton après le container orange
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
