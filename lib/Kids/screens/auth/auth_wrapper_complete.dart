import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider_dart.dart';
import '../coach_dashboard_screen.dart';
import '../login_screen.dart';
import '../parent_dashboard_screen.dart';
import '../school_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return StreamBuilder<UserModel?>(
          stream: authProvider.streamUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const LoginScreen();
            }

            final user = snapshot.data!;

            if (!user.isActive) {
              return const DeactivatedAccountScreen();
            }

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
}

class DeactivatedAccountScreen extends StatelessWidget {
  const DeactivatedAccountScreen({super.key});

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
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.user != null) {
                    await authProvider
                        .reactivateAccount(authProvider.user!.uid);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réactiver mon compte'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.signOut();
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
