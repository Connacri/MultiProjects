import 'dart:async';
import 'dart:convert' show json;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Provider d’authentification Google + Firebase
class AuthService extends ChangeNotifier {
  // ---- état interne
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  String _contactText = '';
  String _errorMessage = '';
  String _serverAuthCode = '';
  bool _isLoading = false;
  bool _isSigningOut = false;

  String get errorMessage => _errorMessage;

  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isAuthorized => _isAuthorized;

  String get contactText => _contactText;

  String get serverAuthCode => _serverAuthCode;

  bool get isLoading => _isLoading;

  bool get isSigningOut => _isSigningOut;

  // ---- config Google Sign-In
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Optionnel: si tes fichiers google-services sont configurés, tu peux laisser à null.
  final String? clientId;
  final String? serverClientId;

  AuthService({
    this.clientId,
    this.serverClientId,
  }) {
    _boot();
  }

  // -----------------------------
  // Initialisation + écoute des événements d’auth
  // -----------------------------
  void _boot() {
    // Pas d’async dans le ctor: on initialise sans bloquer l’UI
    _googleSignIn
        .initialize(clientId: clientId, serverClientId: serverClientId)
        .then((_) {
      _googleSignIn.authenticationEvents
          .listen(_onAuthEvent)
          .onError(_onAuthError);

      // Tente une reconnexion “légère” (SSO) si possible.
      _googleSignIn.attemptLightweightAuthentication();
    }).catchError((e) {
      _errorMessage = 'Init error: $e';
      notifyListeners();
    });
  }

  Future<void> _onAuthEvent(GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    // Vérifie si les scopes requis sont déjà autorisés
    final GoogleSignInClientAuthorization? auth =
        await user?.authorizationClient.authorizationForScopes(_scopes);

    _currentUser = user;
    _isAuthorized = auth != null;
    _errorMessage = '';

    // Si déjà autorisé, fetch People API (exemple)
    if (user != null && auth != null) {
      unawaited(_fetchContactInfo(user));
    }
    notifyListeners();
  }

  Future<void> _onAuthError(Object e) async {
    _currentUser = null;
    _isAuthorized = false;
    _errorMessage = e is GoogleSignInException
        ? _prettySignInError(e)
        : 'Unknown error: $e';
    notifyListeners();
  }

  // -----------------------------
  // Sign-in Google interactif (+ Firebase)
  // -----------------------------
  Future<User?> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1) Lance le flux interactif si supporté (Android/iOS/macOS/Web)
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.authenticate();
      } else {
        // Sur plateformes non supportées (p.ex. Linux/Windows), gère un fallback UI.
        throw UnsupportedError(
          'Aucune méthode d’auth disponible sur cette plateforme.',
        );
      }

      // 2) À ce stade, l’évènement SignIn a été émis -> _currentUser mis à jour
      final GoogleSignInAccount? googleUser = _currentUser;
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 3) Récupère les tokens pour Firebase
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, // suffisant pour mobile
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      _isLoading = false;
      notifyListeners();
      return userCred.user;
    } catch (e) {
      _errorMessage = 'Sign-in error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // -----------------------------
  // Scopes additionnels (People API, etc.)
  // -----------------------------
  Future<void> requestScopes() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final auth = await user.authorizationClient.authorizeScopes(_scopes);
      // Les tokens reçus sont mis en cache par le client -> on rafraîchit nos flags
      _isAuthorized = auth != null;
      _errorMessage = '';
      if (_isAuthorized) {
        await _fetchContactInfo(user);
      }
    } on GoogleSignInException catch (e) {
      _errorMessage = _prettySignInError(e);
    }
    notifyListeners();
  }

  // -----------------------------
  // Server auth code (nécessite serverClientId)
  // -----------------------------
  Future<void> requestServerAuthCode() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      final GoogleSignInServerAuthorization? serverAuth =
          await user.authorizationClient.authorizeServer(_scopes);
      _serverAuthCode = serverAuth?.serverAuthCode ?? '';
    } on GoogleSignInException catch (e) {
      _errorMessage = _prettySignInError(e);
    }
    notifyListeners();
  }

  // -----------------------------
  // Déconnexion (Google + Firebase)
  // -----------------------------
  Future<void> signOut() async {
    _isSigningOut = true;
    notifyListeners();
    try {
      await Future.wait([
        GoogleSignIn.instance.disconnect(), // reset état Google
        FirebaseAuth.instance.signOut(),
      ]);
      _currentUser = null;
      _isAuthorized = false;
      _contactText = '';
      _errorMessage = '';
      _serverAuthCode = '';
    } catch (e) {
      _errorMessage = 'Sign-out error: $e';
      debugPrint('Sign out error: $e');
    } finally {
      _isSigningOut = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // Exemple d’appel People API
  // -----------------------------
  Future<void> _fetchContactInfo(GoogleSignInAccount user) async {
    _contactText = 'Loading contact info...';
    notifyListeners();

    final headers =
        await user.authorizationClient.authorizationHeaders(_scopes);
    if (headers == null) {
      _contactText = '';
      _errorMessage = 'Failed to construct authorization headers.';
      notifyListeners();
      return;
    }

    final resp = await http.get(
      Uri.parse(
        'https://people.googleapis.com/v1/people/me/connections'
        '?requestMask.includeField=person.names',
      ),
      headers: headers,
    );

    if (resp.statusCode != 200) {
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        _isAuthorized = false;
        _errorMessage =
            'People API gave a ${resp.statusCode} response. Please re-authorize access.';
      } else {
        _contactText =
            'People API gave a ${resp.statusCode} response. Check logs for details.';
      }
      notifyListeners();
      return;
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final name = _pickFirstNamedContact(data);
    _contactText =
        name != null ? 'I see you know $name!' : 'No contacts to display.';
    notifyListeners();
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic c) => (c as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic n) => (n as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      return name?['displayName'] as String?;
    }
    return null;
  }

  set errorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  // -----------------------------
  // Utils
  // -----------------------------
  String _prettySignInError(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }
}
