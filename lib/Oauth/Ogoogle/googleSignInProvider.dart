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
      appBar: AppBar(
        title: const Text('Google Sign In'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Consumer<AuthService>(
          builder: (context, authNotifier, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                if (authNotifier.currentUser != null)
                  ..._buildAuthenticatedWidgets(context, authNotifier)
                else
                  ..._buildUnauthenticatedWidgets(context, authNotifier),
                if (authNotifier.errorMessage.isNotEmpty)
                  Text(authNotifier.errorMessage),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAuthenticatedWidgets(
      BuildContext context, AuthService authNotifier) {
    final GoogleSignInAccount user = authNotifier.currentUser!;
    return <Widget>[
      ListTile(
        leading: GoogleUserCircleAvatar(
          identity: user,
        ),
        title: Text(user.displayName ?? ''),
        subtitle: Text(user.email),
      ),
      const Text('Signed in successfully.'),
      if (authNotifier.isAuthorized) ...<Widget>[
        if (authNotifier.contactText.isNotEmpty) Text(authNotifier.contactText),
        ElevatedButton(
          child: const Text('REFRESH'),
          onPressed: () => authNotifier.handleGetContact(user),
        ),
        if (authNotifier.serverAuthCode.isEmpty)
          ElevatedButton(
            child: const Text('REQUEST SERVER CODE'),
            onPressed: authNotifier.handleGetAuthCode,
          )
        else
          Text('Server auth code:\n${authNotifier.serverAuthCode}'),
      ] else ...<Widget>[
        const Text('Authorization needed to read your contacts.'),
        ElevatedButton(
          onPressed: authNotifier.handleAuthorizeScopes,
          child: const Text('REQUEST PERMISSIONS'),
        ),
      ],
      ElevatedButton(
        onPressed: authNotifier.handleSignOut,
        child: const Text('SIGN OUT'),
      ),
    ];
  }

  List<Widget> _buildUnauthenticatedWidgets(
      BuildContext context, AuthService authNotifier) {
    return <Widget>[
      const Text('You are not currently signed in.'),
      if (GoogleSignIn.instance.supportsAuthenticate())
        ElevatedButton(
          onPressed: () async {
            try {
              await GoogleSignIn.instance.authenticate();
            } catch (error) {
              authNotifier.errorMessage1 = error.toString();
              authNotifier.notifyListeners();
            }
          },
          child: const Text('SIGN IN'),
        )
      else ...<Widget>[
        if (kIsWeb)
          const SizedBox.shrink()
        else
          const Text(
              'This platform does not have a known authentication method')
      ]
    ];
  }
}
