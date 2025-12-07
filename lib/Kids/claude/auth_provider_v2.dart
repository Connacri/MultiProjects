import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// 🎯 Provider d'authentification avec gestion cas edge
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

        // ✅ FIX: Détecter si l'email vient d'être confirmé
        if (_currentUser != null && _needsEmailConfirmation) {
          final isNowConfirmed = _currentUser!.emailConfirmedAt != null;
          if (isNowConfirmed) {
            print(
                '[AuthProviderV2] 🎉 Email confirmé détecté via userUpdated!');
            _needsEmailConfirmation = false;
          }
        }

        await _checkUserStatus();
        break;

      case AuthChangeEvent.tokenRefreshed:
        // ✅ NOUVEAU: Écouter aussi le refresh de token
        print('[AuthProviderV2] 🔄 Token rafraîchi, vérification statut...');
        _currentUser = authState.session?.user;
        await _checkUserStatus();
        break;

      default:
        break;
    }
  }

  /// ✨ FIX: Vérifie le statut avec gestion du cas "email confirmé mais pas de profil"
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

      // 2. Vérifier si profil existe dans public.users
      _userData = await _authService.getUserData(_currentUser!.id);

      // ⚠️ CAS EDGE: Email confirmé mais pas d'entrée dans users
      if (_userData == null) {
        print(
            '[AuthProviderV2] ⚠️ Email confirmé mais profil manquant → Création auto');

        // 🔧 OPTION A: Créer une entrée minimale automatiquement
        await _createMinimalProfile();

        // Réessayer de récupérer les données
        _userData = await _authService.getUserData(_currentUser!.id);

        // Si toujours null, forcer la complétion
        if (_userData == null) {
          print(
              '[AuthProviderV2] ❌ Échec création auto → Forcer ProfileCompletion');
          _needsEmailConfirmation = false;
          _needsProfileCompletion = true;
          _setState(AppAuthState.needsProfileCompletion);
          return;
        }
      }

      // 3. Vérifier si profil est complété
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

  /// 🔧 Crée une entrée minimale dans users (cas de récupération)
  Future<void> _createMinimalProfile() async {
    if (_currentUser == null) return;

    try {
      final role = _authService.getUserRole() ?? 'parent';

      // ✅ FIX: Ajouter tous les champs NOT NULL obligatoires
      final minimalData = {
        'id': _currentUser!.id,
        'email': _currentUser!.email!,
        'role': role,
        'name': 'À compléter', // ← Valeur temporaire pour NOT NULL constraint
        'is_active': true,
        'profile_completed': false, // ← Force ProfileCompletion
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('users').insert(minimalData);

      print('[AuthProviderV2] ✅ Profil minimal créé pour ${_currentUser!.id}');
    } catch (e) {
      print('[AuthProviderV2] ❌ Erreur _createMinimalProfile: $e');
      // Ne pas bloquer, on laisse le flow continuer vers ProfileCompletion
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

  // Dans auth_provider_v2.dart

  /// Met à jour le profil SANS déclencher _checkUserStatus
  Future<AuthResult> updateUserProfileSilent(
      Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    // ❌ NE PAS mettre _setState(AppAuthState.loading) pour éviter rebuild global
    _errorMessage = null;

    try {
      await Supabase.instance.client.from('users').update({
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUser!.id);

      // ✅ Mettre à jour UNIQUEMENT le cache local
      _userData = {
        ...(_userData ?? {}),
        ...profileData,
      };

      // ❌ NE PAS appeler _checkUserStatus() ni notifyListeners()

      return AuthResult.success(
        message: 'Profil mis à jour',
        user: _currentUser,
        needsProfileCompletion: false,
      );
    } catch (e) {
      final msg = e.toString();
      print('[AuthProviderV2] updateUserProfileSilent ERROR: $msg');
      _errorMessage = msg;
      return AuthResult.error(msg);
    }
  }

  /// Met à jour le profil utilisateur après création
  Future<AuthResult> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) {
      return AuthResult.error('Utilisateur non connecté');
    }

    _setState(AppAuthState.loading);
    _errorMessage = null;

    try {
      await Supabase.instance.client.from('users').update({
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUser!.id);

      // Mettre à jour le cache local
      _userData = {
        ...(_userData ?? {}),
        ...profileData,
      };

      _needsProfileCompletion = false;

      // Rafraîchir l'état global
      await _checkUserStatus();

      return AuthResult.success(
        message: 'Profil mis à jour',
        user: _currentUser,
        needsProfileCompletion: false,
      );
    } catch (e) {
      final msg = e.toString();
      print('[AuthProviderV2] updateUserProfile ERROR: $msg');
      _errorMessage = msg;
      _setState(AppAuthState.error);
      return AuthResult.error(msg);
    }
  }

  /// Vérifier si un email existe déjà
  Future<bool> checkEmailExists(String email) async {
    try {
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
  // VÉRIFICATION MANUELLE DE LA CONFIRMATION EMAIL
  // ============================================================================

  /// ✅ Vérifie manuellement si l'email a été confirmé (appel depuis UI)
  Future<bool> checkEmailConfirmationStatus() async {
    try {
      print('[AuthProviderV2] 🔄 Vérification manuelle confirmation email...');

      // 1. Rafraîchir la session pour obtenir les dernières infos
      final refreshResponse =
          await Supabase.instance.client.auth.refreshSession();

      if (refreshResponse.session == null) {
        print('[AuthProviderV2] ❌ Pas de session après refresh');
        return false;
      }

      // 2. Mettre à jour l'utilisateur local
      _currentUser = refreshResponse.session!.user;

      // 3. Vérifier la confirmation
      final isConfirmed = _currentUser!.emailConfirmedAt != null;
      print('[AuthProviderV2] Email confirmé: $isConfirmed');

      if (isConfirmed) {
        // 4. Email confirmé → Vérifier le statut complet
        _needsEmailConfirmation = false;
        await _checkUserStatus();
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      print('[AuthProviderV2] ❌ Erreur checkEmailConfirmationStatus: $e');
      print(stackTrace);
      return false;
    }
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
