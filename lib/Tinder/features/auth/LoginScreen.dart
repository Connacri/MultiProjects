// features/auth/presentation/widgets/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUp = false; // toggle entre login / signup

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider =
        Provider.of<TinderAuthProvider>(context, listen: false);

    try {
      if (_isSignUp) {
        // SignUp avec password + confirmation email
        await authProvider.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lien de confirmation envoyé à votre email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await authProvider.signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }
    } on AuthException catch (e) {
      String message;
      switch (e.message) {
        case 'Invalid credentials':
          message = 'Email ou mot de passe incorrect';
          break;
        case 'Email not confirmed':
          message = 'Veuillez confirmer votre email';
          break;
        default:
          message = e.message ?? 'Erreur inconnue';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(Icons.favorite, size: 80, color: colorScheme.primary),
                const SizedBox(height: 32),

                Text(
                  _isSignUp ? 'Créer un compte' : 'Bienvenue',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 48),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Email requis' : null,
                ),
                const SizedBox(height: 16),

                // Password (seulement si signup ou login)
                if (_isSignUp || !_isSignUp)
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isSignUp
                          ? 'Choisir un mot de passe'
                          : 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Mot de passe requis';
                      if (_isSignUp && (v!.length < 6)) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),

                if (!_isSignUp) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (_emailCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saisissez votre email')),
                          );
                          return;
                        }
                        await Supabase.instance.client.auth
                            .resetPasswordForEmail(
                          _emailCtrl.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Email de réinitialisation envoyé')),
                          );
                        }
                      },
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Bouton principal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isSignUp ? 'S\'inscrire' : 'Se connecter'),
                  ),
                ),

                const SizedBox(height: 16),

                // Toggle mode
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Déjà un compte ? Se connecter'
                        : 'Pas de compte ? S\'inscrire',
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
