import 'package:flutter/material.dart';
import 'package:kenzy/objectBox/MyApp.dart';

import '../LicenseInfoPage.dart';
import '../StorageService.dart';
import 'DesktopEntryScreen.dart';
import 'LicenseActivationScreen.dart';

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  void _showLicenseManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Gestion de la Licence'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Voir les détails DesktopEntryScreen'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DesktopEntryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Voir les détails'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LicenseInfoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.orange),
              title: const Text('Changer de licence'),
              subtitle: const Text('Activer une nouvelle licence'),
              onTap: () {
                _confirmChangeLicense(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer la licence'),
              subtitle: const Text('Réinitialiser l\'application'),
              onTap: () {
                _confirmDeleteLicense(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmChangeLicense(BuildContext context) {
    Navigator.of(context).pop(); // Fermer le premier dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Changer de licence'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment changer de licence ?\n\n'
          'La licence actuelle sera supprimée et vous devrez en activer une nouvelle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _changeLicense(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLicense(BuildContext context) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Supprimer la licence actuelle
      await StorageService.removeLicense();

      // Fermer le loader
      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(); // Fermer la confirmation

        // Rediriger vers l'écran d'activation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LicenseActivationScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Licence supprimée. Veuillez en activer une nouvelle.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteLicense(BuildContext context) {
    Navigator.of(context).pop(); // Fermer le premier dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Supprimer la licence'),
          ],
        ),
        content: const Text(
          'ATTENTION: Cette action est irréversible !\n\n'
          'Voulez-vous vraiment supprimer définitivement votre licence ?\n\n'
          'Vous devrez en activer une nouvelle pour utiliser l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteLicense(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLicense(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await StorageService.removeLicense();

      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le loader
        Navigator.of(context).pop(); // Fermer la confirmation

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LicenseActivationScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licence supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gérer la licence',
            onPressed: () => _showLicenseManagementDialog(context),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LicenseInfoPage(),
                  ),
                );
              },
              icon: const Icon(Icons.info),
              label: const Text('Voir les informations de licence'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showLicenseManagementDialog(context),
              icon: const Icon(Icons.settings),
              label: const Text('Gérer la licence'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Application Activée avec Succès !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const Text(
              'Après la validation de votre licence, cliquez sur le bouton ci-dessous '
              '« Réouvrir l’application » pour démarrer votre profil et accéder à toutes les fonctionnalités.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => MyApp9()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                // 🔹 Fond sombre
                foregroundColor: Colors.white,
                // 🔹 Couleur du texte et de l’icône
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4, // optionnel : légère ombre
              ),
              icon: const Icon(Icons.open_in_browser),
              label: const Text(
                'Réouvrir l\'Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
