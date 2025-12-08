import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/ParentDashboard.dart';
import '../screens/autresDashboard.dart';
import '../screens/coach_dashboard_screen.dart';
import '../screens/school_dashboard_screen.dart';
import 'auth_provider_v2.dart';
import 'auth_screen_unified.dart';
import 'email_confirmation_screen.dart';
import 'profile_completion_screen.dart';

/// 🎯 Wrapper intelligent avec gestion confirmation email
class AuthWrapperRefactored extends StatelessWidget {
  const AuthWrapperRefactored({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderV2>(
      builder: (context, authProvider, _) {
        // 1. État de chargement initial
        if (authProvider.state == AppAuthState.initial ||
            authProvider.state == AppAuthState.loading) {
          return const _LoadingScreen();
        }

        // 2. Non authentifié → AuthScreen
        if (authProvider.state == AppAuthState.unauthenticated) {
          return const AuthScreen();
        }

        // 3. ✅ NOUVEAU : Email non confirmé → EmailConfirmationScreen
        if (authProvider.state == AppAuthState.needsEmailConfirmation) {
          return const EmailConfirmationScreen();
        }

        // 4. Authentifié mais profil incomplet → ProfileCompletionScreen
        if (authProvider.state == AppAuthState.needsProfileCompletion) {
          return const ProfileCompletionScreen();
        }

        // 5. Authentifié avec profil complet → Vérifier les données utilisateur
        if (authProvider.state == AppAuthState.authenticated) {
          final userData = authProvider.userData;

          if (userData == null) {
            return _ErrorScreen(
              message: 'Erreur de chargement du profil',
              onRetry: () => authProvider.logout(),
            );
          }

          // Vérifier si le compte est actif
          final isActive = userData['is_active'] ?? false;
          if (!isActive) {
            return DeactivatedAccountScreen(
              onReactivate: () async {
                // TODO: Implémenter la réactivation
              },
              onLogout: () => authProvider.logout(),
            );
          }

          // Router vers le dashboard approprié selon le rôle
          final role = userData['role'] as String?;
          switch (role) {
            case 'parent':
              return const ParentDashboard(); //ParentDashboard();
            case 'coach':
              return const CoachDashboard();
            case 'school':
              return const SchoolDashboard();

            case 'autres':
              return const AutreDashboard();
            default:
              return _ErrorScreen(
                message: 'Rôle utilisateur invalide',
                onRetry: () => authProvider.logout(),
              );
          }
        }

        // 6. État d'erreur
        return _ErrorScreen(
          message: authProvider.errorMessage ?? 'Erreur inconnue',
          onRetry: () => authProvider.logout(),
        );
      },
    );
  }
}

// =============================================================================
// ÉCRANS DE CHARGEMENT ET D'ERREUR
// =============================================================================

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops !',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// COMPTE DÉSACTIVÉ
// =============================================================================

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Compte Désactivé',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Votre compte a été temporairement désactivé. '
                        'Vous pouvez le réactiver dans les 60 jours suivant la désactivation.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: onReactivate,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réactiver mon compte'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: onLogout,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
