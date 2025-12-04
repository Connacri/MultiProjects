import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../models/user_model.dart';
import '../coach_dashboard_screen.dart';
import '../parent_dashboard_screen.dart';
import '../school_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Afficher le loader pendant le chargement
        if (authProvider.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Vérifier si l'utilisateur est connecté
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

        // TODO: Récupérer les données utilisateur depuis Firestore/Supabase
        // Pour l'instant, afficher un dashboard par défaut
        // Tu devras implémenter la logique de récupération du UserModel
        return FutureBuilder<UserModel?>(
          future: _fetchUserData(authProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              // Si pas de données utilisateur, déconnecter
              WidgetsBinding.instance.addPostFrameCallback((_) {
                authProvider.logout();
              });
              return const Scaffold(
                body: Center(
                  child: Text('Erreur de chargement du profil'),
                ),
              );
            }

            final user = snapshot.data!;

            // Vérifier si le compte est actif
            if (!user.isActive) {
              return DeactivatedAccountScreen(
                onReactivate: () async {
                  // TODO: Implémenter la réactivation
                  // await authProvider.reactivateAccount();
                },
                onLogout: () async {
                  await authProvider.logout();
                },
              );
            }

            // Router vers le dashboard approprié selon le rôle
            switch (user.role) {
              case UserRole.parent:
                return const ParentDashboard();
              case UserRole.school:
                return const SchoolDashboard();
              case UserRole.coach:
                return const CoachDashboard();
            }
          },
        );
      },
    );
  }

  /// Récupère les données utilisateur depuis Firestore/Supabase
  Future<UserModel?> _fetchUserData(AuthProvider authProvider) async {
    try {
      final email = authProvider.userEmail;
      if (email == null) return null;

      // TODO: Implémenter la récupération depuis Firestore/Supabase
      // Exemple pour Supabase:
      // if (authProvider.isSupabase) {
      //   final response = await Supabase.instance.client
      //       .from('users')
      //       .select()
      //       .eq('email', email)
      //       .single();
      //   return UserModel.fromJson(response);
      // }

      // Exemple pour Firebase:
      // else {
      //   final doc = await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(authProvider.firebaseUser!.uid)
      //       .get();
      //   return UserModel.fromJson(doc.data()!);
      // }

      // Pour l'instant, retourner null pour forcer l'implémentation
      return null;
    } catch (e) {
      logError('Erreur récupération user data', e);
      return null;
    }
  }
}

class DeactivatedAccountScreen extends StatelessWidget {
  final VoidCallback onReactivate;
  final VoidCallback onLogout;

  const DeactivatedAccountScreen({
    super.key,
    required this.onReactivate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte Désactivé'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Compte Désactivé',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre compte a été temporairement désactivé. Vous pouvez le réactiver dans les 60 jours suivant la désactivation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onReactivate,
                icon: const Icon(Icons.refresh),
                label: const Text('Réactiver mon compte'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onLogout,
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
