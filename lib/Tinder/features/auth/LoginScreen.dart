import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _userExists = false;

  // Étape 1 : Vérifier si le mail existe
  Future<void> _checkEmail() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // On interroge ta table users/profiles
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', _emailCtrl.text.trim())
          .maybeSingle();

      setState(() {
        _userExists = res != null;
        _showPassword = true;
      });
    } catch (e) {
      _showError("Erreur de vérification");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Étape 2 : Login ou Signup
  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_userExists) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          emailRedirectTo: 'io.supabase.fluttertinder://callback',
        );
        _showSuccess("Lien de confirmation envoyé !");
      }
    } catch (e) {
      _showError("Erreur: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
              readOnly: _showPassword,
            ),
            if (_showPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _userExists
                      ? "Entrez votre mot de passe"
                      : "Créez votre mot de passe",
                ),
              ),
              if (_userExists)
                TextButton(
                  onPressed: () => Supabase.instance.client.auth
                      .resetPasswordForEmail(_emailCtrl.text.trim()),
                  child: const Text("Mot de passe oublié ?"),
                ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isLoading ? null : (_showPassword ? _submit : _checkEmail),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(_showPassword ? "Valider" : "Suivant"),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  void _showSuccess(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));
}
