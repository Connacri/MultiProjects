import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../activities/screens/userHomePage.dart';
import '../fonctions/AppLocalizations.dart';

class MyApp1 extends StatefulWidget {
  const MyApp1({super.key});

  @override
  State<MyApp1> createState() => _MyApp1State();
}

class _MyApp1State extends State<MyApp1> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate, // ton délégué
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''), // selon les langues que tu gères
      ],
      home: AuthScreen(), // ou ton widget principal
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // 🔄 Attente du flux d'état d'authentification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ❌ Erreur dans la connexion Firebase
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de connexion Firebase'));
        }

        // ✅ Utilisateur connecté → on affiche la page principale
        if (snapshot.hasData) {
          return HomePage();
        }

        // 👤 Aucun utilisateur connecté → on connecte anonymement
        return FutureBuilder<UserCredential>(
          future: _signInAnonymously(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (asyncSnapshot.hasError) {
              // 🔁 En cas d’erreur de connexion anonyme, tu peux rediriger vers ton Google Sign-In
              return HomePage(); //google();
            }
            // Une fois connecté anonymement → aller vers HomePage
            return HomePage();
          },
        );
      },
    );
  }

  /// 🔐 Connecte automatiquement un utilisateur anonyme
  Future<UserCredential> _signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Erreur connexion anonyme : $e');
      rethrow;
    }
  }
}
