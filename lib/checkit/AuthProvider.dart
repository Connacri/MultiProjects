import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  String _contactText = '';
  String errorMessage1 = '';
  String _serverAuthCode = '';
  bool _isLoading = false;
  bool _isSigningOut = false;

  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isAuthorized => _isAuthorized;

  String get contactText => _contactText;

  String get errorMessage => errorMessage1;

  String get serverAuthCode => _serverAuthCode;

  bool get isLoading => _isLoading;

  bool get isSigningOut => _isSigningOut;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final List<String> scopes = <String>[
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  AuthNotifier() {
    _googleSignIn.authenticationEvents
        .listen(_handleAuthenticationEvent)
        .onError(_handleAuthenticationError);
    _googleSignIn.attemptLightweightAuthentication();
  }

  Future<void> _handleAuthenticationEvent(
      GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    final GoogleSignInClientAuthorization? authorization =
        await user?.authorizationClient.authorizationForScopes(scopes);

    _currentUser = user;
    _isAuthorized = authorization != null;
    errorMessage1 = '';

    if (user != null && authorization != null) {
      await handleGetContact(user);
    }

    notifyListeners();
  }

  Future<void> _handleAuthenticationError(Object e) async {
    _currentUser = null;
    _isAuthorized = false;
    errorMessage1 = e is GoogleSignInException
        ? errorMessage1FromSignInException(e)
        : 'Unknown error: $e';
    notifyListeners();
  }

  Future<void> handleGetContact(GoogleSignInAccount user) async {
    _contactText = 'Loading contact info...';
    notifyListeners();

    final Map<String, String>? headers =
        await user.authorizationClient.authorizationHeaders(scopes);
    if (headers == null) {
      _contactText = '';
      errorMessage1 = 'Failed to construct authorization headers.';
      notifyListeners();
      return;
    }

    final http.Response response = await http.get(
      Uri.parse(
          'https://people.googleapis.com/v1/people/me/connections?requestMask.includeField=person.names'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        _isAuthorized = false;
        errorMessage1 =
            'People API gave a ${response.statusCode} response. Please re-authorize access.';
      } else {
        _contactText =
            'People API gave a ${response.statusCode} response. Check logs for details.';
      }
      notifyListeners();
      return;
    }

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final String? namedContact = _pickFirstNamedContact(data);

    if (namedContact != null) {
      _contactText = 'I see you know $namedContact!';
    } else {
      _contactText = 'No contacts to display.';
    }
    notifyListeners();
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;

    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic name) =>
            (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    return null;
  }

  Future<void> handleAuthorizeScopes() async {
    if (_currentUser == null) return;

    try {
      final GoogleSignInClientAuthorization authorization =
          await _currentUser!.authorizationClient.authorizeScopes(scopes);
      authorization; // ignore: unnecessary_statements
      _isAuthorized = true;
      errorMessage1 = '';
      await handleGetContact(_currentUser!);
    } on GoogleSignInException catch (e) {
      errorMessage1 = errorMessage1FromSignInException(e);
    }
    notifyListeners();
  }

  Future<void> handleGetAuthCode() async {
    if (_currentUser == null) return;

    try {
      final GoogleSignInServerAuthorization? serverAuth =
          await _currentUser!.authorizationClient.authorizeServer(scopes);
      _serverAuthCode = serverAuth == null ? '' : serverAuth.serverAuthCode;
    } on GoogleSignInException catch (e) {
      errorMessage1 = errorMessage1FromSignInException(e);
    }
    notifyListeners();
  }

  Future<void> handleSignOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _isAuthorized = false;
    _contactText = '';
    errorMessage1 = '';
    _serverAuthCode = '';
    notifyListeners();
  }

  Future<void> handleSignOut2() async {
    _isSigningOut = true;
    notifyListeners();

    try {
      await Future.wait([
        _googleSignIn.signOut(),
        Future.delayed(const Duration(seconds: 2)),
      ]);
      _currentUser = null;
      _contactText = '';
      errorMessage1 = '';
      _serverAuthCode = '';
    } catch (e) {
      errorMessage1 = 'Erreur lors de la déconnexion: $e';
    } finally {
      _isSigningOut = false;
      notifyListeners();
    }
  }

  String errorMessage1FromSignInException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }
}
