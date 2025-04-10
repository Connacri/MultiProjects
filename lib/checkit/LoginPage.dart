import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Oauth/Ogoogle/googleSignInProvider.dart';
import 'AuthProvider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<googleSignInProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Image.asset('assets/google_logo.png', height: 24), // optionnel
          label: const Text('Se connecter avec Google'),
          onPressed: () async {
            await auth.googleLogin();
            if (auth.user != null) {
              Navigator.pop(context, true); // retourne à HomePage
            }
          },
        ),
      ),
    );
  }
}
