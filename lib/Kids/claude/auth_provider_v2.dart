import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// 🎯 Provider d'authentification avec gestion confirmation email
class AuthProviderV2 extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ============================================================================
  // ÉTAT
  // ============================================================================

  AppAuthState _state = AppAuthState.initial;
  User? _currentUser;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  bool _needsEmailConfirmation = false;
  bool _needsProfileCompletion = false;

  // Getters
  AppAuthState get state => _state;

  User? get currentUser => _currentUser;

  Map<String, dynamic>? get userData => _userData;

  String? get errorMessage => _errorMessage;

  bool get needsEmailConfirmation => _needsEmailConfirmation;

  bool get needsProfileCompletion => _needsProfileCompletion;

  bool get isAuthenticated => _currentUser != null;

  bool get isLoading => _state == AppAuthState.loading;

  // ============================================================================
  // INITIALISATION
  // ============================================================================

  AuthProviderV2() {
    _initialize();
  }

  Future<void> _initialize() async {
    _setState(AppAuthState.loading);

    try {
      // Écouter les changements d'auth
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data);
      });

      // Récupérer la session actuelle
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        await _checkUserStatus();
      } else {
        _setState(AppAuthState.unauthenticated);
      }
    } catch (e) {
      print('[AuthProviderV2] Erreur initialisation: $e');
      _setState(AppAuthState.error);
      _errorMessage = 'Erreur d\'initialisation';
    }
  }

  /// Gère les changements d'état d'authentification
  void _handleAuthStateChange(AuthState authState) async {
    print('[AuthProviderV2] Auth event: ${authState.event}');

    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        _currentUser = authState.session?.user;
        await _checkUserStatus();
        break;

      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _userData = null;
        _needsEmailConfirmation = false;
        _needsProfileCompletion = false;
        _setState(AppAuthState.unauthenticated);
        break;

      case AuthChangeEvent.userUpdated:
        _currentUser = authState.session?.user;
        await _checkUserStatus();
        break;

      default:
        break;
    }
  }

  /// Vérifie le statut de l'utilisateur (email confirmé, profil complété)
  Future<void> _checkUserStatus() async {
    if (_currentUser == null) return;

    try {
      // 1. Vérifier si email est confirmé
      final emailConfirmed = _authService.isEmailConfirmed();
      print('[AuthProviderV2] Email confirmé: $emailConfirmed');

      if (!emailConfirmed) {
        _needsEmailConfirmation = true;
        _needsProfileCompletion = false;
        _setState(AppAuthState.needsEmailConfirmation);
        return;
      }

      // 2. Vérifier si profil existe et est complété
      _userData = await _authService.getUserData(_currentUser!.id);

      if (_userData == null) {
        // Profil pas encore créé
        _needsEmailConfirmation = false;
        _needsProfileCompletion = true;
        _setState(AppAuthState.needsProfileCompletion);
        return;
      }

      final profileCompleted = _userData!['profile_completed'] ?? false;

      if (!profileCompleted) {
        _needsEmailConfirmation = false;
        _needsProfileCompletion = true;
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        _needsEmailConfirmation = false;
        _needsProfileCompletion = false;
        _setState(AppAuthState.authenticated);
      }
    } catch (e) {
      print('[AuthProviderV2] Erreur _checkUserStatus: $e');
      _setState(AppAuthState.error);
      _errorMessage = 'Erreur de vérification du statut';
    }
  }

  // ============================================================================
  // ACTIONS D'AUTHENTIFICATION
  // ============================================================================

  /// Inscription
  Future<AuthResult> signup({
    required String email,
    required String password,
    required String role,
  }) async {
    _setState(AppAuthState.loading);
    _errorMessage = null;

    final result = await _authService.signup(
      email: email,
      password: password,
      role: role,
    );

    if (result.success) {
      _currentUser = result.user;
      _needsEmailConfirmation = result.needsEmailConfirmation;
      _needsProfileCompletion = false;

      if (_needsEmailConfirmation) {
        _setState(AppAuthState.needsEmailConfirmation);
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    notifyListeners();
    return result;
  }

  /// Connexion
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _setState(AppAuthState.loading);
    _errorMessage = null;

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result.success) {
      _currentUser = result.user;
      _needsEmailConfirmation = result.needsEmailConfirmation;
      _needsProfileCompletion = result.needsProfileCompletion;

      if (_needsEmailConfirmation) {
        _setState(AppAuthState.needsEmailConfirmation);
      } else if (_needsProfileCompletion) {
        _setState(AppAuthState.needsProfileCompletion);
      } else {
        await _checkUserStatus();
      }
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    notifyListeners();
    return result;
  }

  /// Renvoyer email de confirmation
  Future<AuthResult> resendConfirmationEmail(String email) async {
    return await _authService.resendConfirmationEmail(email);
  }

  /// Supprimer compte non confirmé
  Future<AuthResult> deleteUnconfirmedAccount() async {
    _setState(AppAuthState.loading);

    final result = await _authService.deleteUnconfirmedAccount();

    if (result.success) {
      _currentUser = null;
      _userData = null;
      _needsEmailConfirmation = false;
      _needsProfileCompletion = false;
      _setState(AppAuthState.unauthenticated);
    } else {
      _setState(AppAuthState.error);
      _errorMessage = result.message;
    }

    notifyListeners();
    return result;
  }

  /// Créer le profil utilisateur (après confirmation email)
  Future<AuthResult> createUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _setState(AppAuthState.loading);
    _errorMessage = null;

    // Récupérer le rôle depuis metadata
    final role = _authService.getUserRole() ?? 'parent';

    final result = await _authService.createUserProfile(
      userId: _currentUser!.id,
      email: _currentUser!.email!,
      role: role,
      profileData: profileData,
    );

    if (result.success) {
      _needsProfileCompletion = false;
      await _checkUserStatus();
    } else {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    }

    notifyListeners();
    return result;
  }

  /// Vérifier si un email existe déjà
  Future<bool> checkEmailExists(String email) async {
    try {
      // Utiliser une requête à la table users pour vérifier l'existence
      final response = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('[AuthProviderV2] Erreur checkEmailExists: $e');
      return false;
    }
  }

  /// Mot de passe oublié
  Future<AuthResult> sendPasswordReset(String email) async {
    _setState(AppAuthState.loading);
    _errorMessage = null;

    final result = await _authService.sendPasswordResetEmail(email);

    if (!result.success) {
      _errorMessage = result.message;
      _setState(AppAuthState.error);
    } else {
      _setState(AppAuthState.unauthenticated);
    }

    notifyListeners();
    return result;
  }

  /// Déconnexion
  Future<void> logout() async {
    _setState(AppAuthState.loading);

    await _authService.signOut();

    _currentUser = null;
    _userData = null;
    _needsEmailConfirmation = false;
    _needsProfileCompletion = false;
    _errorMessage = null;

    _setState(AppAuthState.unauthenticated);
    notifyListeners();
  }

  // ============================================================================
  // GESTION D'ÉTAT
  // ============================================================================

  void _setState(AppAuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// ============================================================================
// ÉNUMÉRATIONS
// ============================================================================

enum AppAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsEmailConfirmation,
  needsProfileCompletion,
  error,
}
