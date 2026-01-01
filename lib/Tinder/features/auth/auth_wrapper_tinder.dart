// lib/Tinder/core/auth_wrapper_tinder.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../discovery/discovery_screen.dart';
import '../profile/profile_completion_screen.dart';
import '../profile/profile_provider.dart';

/// ✅ Wrapper d'authentification avec redirection intelligente
/// - Non connecté → LoginScreen
/// - Connecté + profil incomplet → ProfileCompletionScreen
/// - Connecté + profil complet → DiscoveryScreen
class AuthWrapperTinder extends StatelessWidget {
  const AuthWrapperTinder({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        print(
            '🔄 [AuthWrapper] Rebuild - Loading: ${profileProvider.loading}, Error: ${profileProvider.error}');

        if (profileProvider.loading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Diagnostic en cours... Regardez la console'),
                ],
              ),
            ),
          );
        }

        if (profileProvider.error != null) {
          print(
              '🚩 [AuthWrapper] Affichage LoginScreen car erreur: ${profileProvider.error}');
          return const LoginScreen(); // Utilise ton LoginScreen ici
        }

        if (!profileProvider.profileCompleted) {
          print(
              '🟡 [AuthWrapper] Profil incomplet (${profileProvider.completionPercentage}%) -> CompletionScreen');
          return const ProfileCompletionScreenTinder();
        }

        print('🟢 [AuthWrapper] Tout est OK -> DiscoveryScreen');
        return const DiscoveryScreen();
      },
    );
  }
}

/// ✅ LoginScreen simple (à améliorer)
class LoginScreenBasic extends StatefulWidget {
  const LoginScreenBasic({super.key});

  @override
  State<LoginScreenBasic> createState() => _LoginScreenBasicState();
}

class _LoginScreenBasicState extends State<LoginScreenBasic> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connectez-vous pour continuer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton connexion
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton inscription
              TextButton(
                onPressed: () {
                  // TODO: Navigation vers SignupScreen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inscription à implémenter')),
                  );
                },
                child: const Text('Pas encore de compte ? S\'inscrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // TODO: Implémenter login avec TinderAuthProvider
      // await Provider.of<TinderAuthProvider>(context, listen: false).signIn(
      //   _emailController.text.trim(),
      //   _passwordController.text.trim(),
      // );

      // Après login réussi, ProfileProvider.init() sera appelé automatiquement
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
