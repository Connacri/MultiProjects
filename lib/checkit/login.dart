import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_userId ?? 'user deconnecté'),
            ElevatedButton(
              onPressed: () async {
                const webClientId =
                    '330293988254-c3b9hgmt0hat5jfqi69j4jkn3pe6fhkv.apps.googleusercontent.com';

                /// TODO: update the iOS client ID with your own.
                ///
                /// iOS Client ID that you registered with Google Cloud.
                const iosClientId =
                    '330293988254-gfocd18j16kdnsvqhp1fk61ggr6ovp42.apps.googleusercontent.com';

                // Google sign in on Android will work without providing the Android
                // Client ID registered on Google Cloud.

                final GoogleSignIn googleSignIn = GoogleSignIn(
                  clientId: iosClientId,
                  serverClientId: webClientId,
                );
                final googleUser = await googleSignIn.signIn();
                final googleAuth = await googleUser!.authentication;
                final accessToken = googleAuth.accessToken;
                final idToken = googleAuth.idToken;

                if (accessToken == null) {
                  throw 'No Access Token found.';
                }
                if (idToken == null) {
                  throw 'No ID Token found.';
                }

                await supabase.auth.signInWithIdToken(
                  provider: OAuthProvider.google,
                  idToken: idToken,
                  accessToken: accessToken,
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
