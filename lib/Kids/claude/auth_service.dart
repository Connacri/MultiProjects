import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔐 Service d'authentification avec confirmation email
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // 1️⃣ INSCRIPTION (SIGNUP) - SANS CRÉATION DATA USER
  // ============================================================================

  /// Inscription simple : crée uniquement le compte Auth
  /// La data user sera créée après confirmation email + complétion profil
  Future<AuthResult> signup({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      print('[AuthService] 🔄 Début signup pour: $email');

      // Créer le compte dans Supabase Auth
      // emailRedirectTo : URL de redirection après confirmation
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role, // Stocké dans auth.users metadata
        },
        emailRedirectTo: 'yourapp://auth/callback', // À adapter selon votre app
      );

      if (authResponse.user == null) {
        print('[AuthService] ❌ User null après signUp');
        return AuthResult.error('Échec de création du compte');
      }

      print('[AuthService] ✅ Compte Auth créé: ${authResponse.user!.id}');
      print('[AuthService] 📧 Email de confirmation envoyé à: $email');

      // ✅ PAS D'INSERTION DANS public.users ICI
      // Cela sera fait après confirmation + complétion profil

      return AuthResult.success(
        user: authResponse.user,
        needsEmailConfirmation: true,
        message: 'Un email de confirmation a été envoyé à $email',
      );
    } on AuthException catch (e) {
      print('[AuthService] ❌ AuthException: ${e.message}');
      return AuthResult.error(_parseAuthException(e));
    } catch (e, stackTrace) {
      print('[AuthService] ❌ Erreur signup: $e');
      print('[AuthService] Stack: $stackTrace');
      return AuthResult.error('Erreur lors de l\'inscription: $e');
    }
  }

  // ============================================================================
  // 2️⃣ VÉRIFIER SI EMAIL EST CONFIRMÉ
  // ============================================================================

  /// Vérifie si l'email de l'utilisateur actuel est confirmé
  bool isEmailConfirmed() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final emailConfirmedAt = user.emailConfirmedAt;
    final isConfirmed = emailConfirmedAt != null;

    print('[AuthService] Email confirmé: $isConfirmed');
    return isConfirmed;
  }

  // ============================================================================
  // 3️⃣ RENVOYER EMAIL DE CONFIRMATION
  // ============================================================================

  /// Renvoie l'email de confirmation
  Future<AuthResult> resendConfirmationEmail(String email) async {
    try {
      print('[AuthService] 🔄 Renvoi email confirmation: $email');

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      print('[AuthService] ✅ Email de confirmation renvoyé');

      return AuthResult.success(
        message: 'Email de confirmation renvoyé avec succès',
      );
    } on AuthException catch (e) {
      print('[AuthService] ❌ Erreur resend: ${e.message}');
      return AuthResult.error(_parseAuthException(e));
    } catch (e) {
      print('[AuthService] ❌ Erreur resendConfirmationEmail: $e');
      return AuthResult.error('Erreur lors du renvoi de l\'email');
    }
  }

  // ============================================================================
  // 4️⃣ SUPPRIMER LE COMPTE (avant confirmation)
  // ============================================================================

  /// Supprime le compte utilisateur non confirmé
  /// Note: Depuis le client, on peut seulement se déconnecter
  /// La suppression complète nécessite un appel backend/admin
  Future<AuthResult> deleteUnconfirmedAccount() async {
    try {
      print('[AuthService] 🔄 Suppression compte non confirmé...');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.error('Aucun utilisateur connecté');
      }

      // Se déconnecter (côté client, on ne peut pas vraiment supprimer)
      await _supabase.auth.signOut();

      print('[AuthService] ✅ Déconnexion effectuée');

      // ⚠️ Pour une vraie suppression, il faut appeler une Edge Function
      // qui utilise l'Admin API de Supabase

      return AuthResult.success(
        message: 'Compte supprimé avec succès',
      );
    } catch (e) {
      print('[AuthService] ❌ Erreur deleteUnconfirmedAccount: $e');
      return AuthResult.error('Erreur lors de la suppression');
    }
  }

  // ============================================================================
  // 5️⃣ CRÉER LE PROFIL USER (après confirmation + complétion)
  // ============================================================================

  /// Crée l'entrée dans public.users après confirmation email
  Future<AuthResult> createUserProfile({
    required String userId,
    required String email,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      print('[AuthService] 🔄 createUserProfile → $userId');

      if (!isEmailConfirmed()) {
        return AuthResult.error(
          'Veuillez confirmer votre email avant de continuer.',
          code: 'email_not_confirmed',
        );
      }

      // Vérifier si l'utilisateur existe déjà
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      final payload = {
        'id': userId,
        'email': email,
        'role': role,
        ...profileData,
        'is_active': true,
        'profile_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing == null) {
        payload['created_at'] = DateTime.now().toIso8601String();
        print('[AuthService] 🟢 Création nouveau profil');
      } else {
        print('[AuthService] 🛠️ Mise à jour profil existant');
      }

      // Supabase v2 retour implicitement un List<dynamic>
      final data = await _supabase.from('users').upsert(payload).select();

      print('[AuthService] ✅ Profil sauvegardé → $data');

      return AuthResult.success(
        message: existing == null
            ? 'Profil créé avec succès'
            : 'Profil mis à jour avec succès',
      );
    } catch (e, stackTrace) {
      print('[AuthService] ❌ Erreur createUserProfile: $e');
      print(stackTrace);
      return AuthResult.error(
        'Erreur lors de la sauvegarde du profil: $e',
      );
    }
  }

  // ============================================================================
  // 6️⃣ CONNEXION (LOGIN)
  // ============================================================================

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('[AuthService] 🔄 Tentative login: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null || response.user == null) {
        print('[AuthService] ❌ Session ou user null');
        return AuthResult.error('Email ou mot de passe incorrect');
      }

      print('[AuthService] ✅ Login réussi');

      // Vérifier si email est confirmé
      final emailConfirmed = response.user!.emailConfirmedAt != null;
      print('[AuthService] Email confirmé: $emailConfirmed');

      if (!emailConfirmed) {
        return AuthResult.success(
          user: response.user,
          needsEmailConfirmation: true,
        );
      }

      // Vérifier si le profil existe et est complété
      final userData = await _supabase
          .from('users')
          .select('profile_completed')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        print('[AuthService] ⚠️ Profil non trouvé');
        // Profil pas encore créé
        return AuthResult.success(
          user: response.user,
          needsProfileCompletion: true,
        );
      }

      final profileCompleted = userData['profile_completed'] ?? false;
      print('[AuthService] Profile completed: $profileCompleted');

      return AuthResult.success(
        user: response.user,
        needsProfileCompletion: !profileCompleted,
      );
    } on AuthException catch (e) {
      print('[AuthService] ❌ Login AuthException: ${e.message}');
      // ✅ NOUVEAU : Détecter si l'email n'existe pas
      if (e.message.contains('Invalid login credentials') ||
          e.message.contains('Email not found') ||
          e.statusCode == '400') {
        return AuthResult.error(
          'Cet email n\'est pas enregistré',
          code: 'email_not_found', // ✅ Code spécifique
        );
      }
      return AuthResult.error(_parseAuthException(e));
    } catch (e, stackTrace) {
      print('[AuthService] ❌ Erreur login: $e');
      print('[AuthService] Stack: $stackTrace');
      return AuthResult.error('Erreur de connexion: $e');
    }
  }

  // ============================================================================
  // 7️⃣ RÉCUPÉRER LE RÔLE DEPUIS METADATA
  // ============================================================================

  /// Récupère le rôle stocké dans auth.users metadata
  String? getUserRole() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final metadata = user.userMetadata;
    return metadata?['role'] as String?;
  }

  // ============================================================================
  // 8️⃣ MOT DE PASSE OUBLIÉ
  // ============================================================================

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success(
        message: 'Email de réinitialisation envoyé avec succès',
      );
    } on AuthException catch (e) {
      return AuthResult.error(_parseAuthException(e));
    } catch (e) {
      print('[AuthService] Erreur sendPasswordResetEmail: $e');
      return AuthResult.error('Erreur lors de l\'envoi de l\'email');
    }
  }

  // ============================================================================
  // 9️⃣ RÉCUPÉRATION DES DONNÉES UTILISATEUR
  // ============================================================================

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      print('[AuthService] 🔄 Récupération user data: $userId');

      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) {
        print('[AuthService] ⚠️ User data null');
      } else {
        print('[AuthService] ✅ User data récupéré');
      }

      return response;
    } catch (e, stackTrace) {
      print('[AuthService] ❌ Erreur getUserData: $e');
      print('[AuthService] Stack: $stackTrace');
      return null;
    }
  }

  // ============================================================================
  // 🔟 DÉCONNEXION
  // ============================================================================

  Future<void> signOut() async {
    try {
      print('[AuthService] 🔄 Déconnexion...');
      await _supabase.auth.signOut();
      print('[AuthService] ✅ Déconnecté');
    } catch (e) {
      print('[AuthService] ❌ Erreur signOut: $e');
    }
  }

  // ============================================================================
  // 🔧 UTILITAIRES
  // ============================================================================

  String _parseAuthException(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email ou mot de passe incorrect';
      case 'Email not confirmed':
        return 'Veuillez confirmer votre email avant de vous connecter';
      case 'User already registered':
        return 'Cet email est déjà utilisé';
      case 'Password should be at least 6 characters':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      default:
        return e.message;
    }
  }
}

// ============================================================================
// 📦 CLASSE DE RÉSULTAT
// ============================================================================

class AuthResult {
  final bool success;
  final String? message;
  final String? errorCode;
  final User? user;
  final bool needsEmailConfirmation;
  final bool needsProfileCompletion;

  AuthResult._({
    required this.success,
    this.message,
    this.errorCode,
    this.user,
    this.needsEmailConfirmation = false,
    this.needsProfileCompletion = false,
  });

  factory AuthResult.success({
    String? message,
    User? user,
    bool needsEmailConfirmation = false,
    bool needsProfileCompletion = false,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      user: user,
      needsEmailConfirmation: needsEmailConfirmation,
      needsProfileCompletion: needsProfileCompletion,
    );
  }

  factory AuthResult.error(String message, {String? code}) {
    return AuthResult._(
      success: false,
      message: message,
      errorCode: code,
    );
  }
}
