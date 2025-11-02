import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../checkit/AuthProvider.dart';

class SignInDemo extends StatelessWidget {
  const SignInDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In')),
      body: Consumer<AuthService>(
        builder: (context, auth, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (auth.isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Authentification en cours...'),
                ] else if (auth.currentUser != null)
                  ..._buildAuthenticatedWidgets(context, auth)
                else
                  ..._buildUnauthenticatedWidgets(context, auth),
                if (auth.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // ✅ Widgets affichés si l'utilisateur est connecté
  // =====================================================
  List<Widget> _buildAuthenticatedWidgets(
      BuildContext context, AuthService auth) {
    final GoogleSignInAccount user = auth.currentUser!;

    return [
      ListTile(
        leading: GoogleUserCircleAvatar(identity: user),
        title: Text(user.displayName ?? ''),
        subtitle: Text(user.email),
      ),
      const SizedBox(height: 16),
      const Text('✅ Connecté avec succès !'),
      if (auth.isAuthorized) ...[
        if (auth.contactText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(auth.contactText),
          ),
        ElevatedButton(
          onPressed: () => auth.requestScopes(),
          child: const Text('ACTUALISER CONTACTS'),
        ),
        if (auth.serverAuthCode.isEmpty)
          ElevatedButton(
            onPressed: auth.requestServerAuthCode,
            child: const Text('OBTENIR SERVER AUTH CODE'),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Server Auth Code:\n${auth.serverAuthCode}',
              textAlign: TextAlign.center,
            ),
          ),
      ] else ...[
        const Text('🔒 Autorisation requise pour lire vos contacts.'),
        ElevatedButton(
          onPressed: auth.requestScopes,
          child: const Text('DEMANDER LES PERMISSIONS'),
        ),
      ],
      const SizedBox(height: 20),
      ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        onPressed: auth.signOut,
        label: const Text('SE DÉCONNECTER'),
      ),
    ];
  }

  // =====================================================
  // 🚀 Widgets affichés si l'utilisateur N’EST PAS connecté
  // =====================================================
  List<Widget> _buildUnauthenticatedWidgets(
      BuildContext context, AuthService auth) {
    return [
      const Text(
        'Vous n’êtes pas connecté.',
        style: TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 20),
      if (GoogleSignIn.instance.supportsAuthenticate())
        ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('SE CONNECTER AVEC GOOGLE'),
          onPressed: () async {
            try {
              await auth.signInWithGoogle();
            } catch (error) {
              auth
                ..errorMessage = error.toString()
                ..notifyListeners();
            }
          },
        )
      else ...[
        if (kIsWeb)
          const Text(
              'Ce flux d’authentification n’est pas supporté sur le Web (utilisez FirebaseAuth directement).')
        else
          const Text(
            '⚠️ Cette plateforme ne prend pas en charge Google Sign-In interactif.',
            textAlign: TextAlign.center,
          ),
      ],
    ];
  }
}
