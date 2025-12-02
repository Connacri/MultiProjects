import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase; // AJOUTER CET IMPORT

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _user!.isActive;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    // Windows: Écouter les changements d'auth Supabase
    if (!kIsWeb && Platform.isWindows) {
      supabase.Supabase.instance.client.auth.onAuthStateChange
          .listen((data) async {
        final session = data.session;
        if (session != null && session.user != null) {
          try {
            _user = await _authService.getUserData(session.user.id);
            notifyListeners();
          } catch (e) {
            _error = e.toString();
            notifyListeners();
          }
        } else {
          _user = null;
          notifyListeners();
        }
      });
      return;
    }

    // Autres plateformes: Écouter Firebase
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          _user = await _authService.getUserData(firebaseUser.uid);
          notifyListeners();
        } catch (e) {
          _error = e.toString();
          notifyListeners();
        }
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Stream<UserModel?> streamUserData() {
    // Windows: utiliser Supabase Auth
    if (!kIsWeb && Platform.isWindows) {
      final currentUser = supabase.Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        return _authService.streamUserData(currentUser.id);
      }
      return Stream.value(null);
    }

    // Autres plateformes: utiliser Firebase
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      return _authService.streamUserData(currentUser.uid);
    }
    return Stream.value(null);
  }

  // Le reste du code reste identique...
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deactivateAccount() async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await _authService.deactivateAccount(_user!.uid);
      await _authService.signOut();

      _user = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> reactivateAccount(String uid) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.reactivateAccount(uid);
      _user = await _authService.getUserData(uid);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _user = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
