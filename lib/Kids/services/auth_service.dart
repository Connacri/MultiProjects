import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user_model.dart';

class AuthService {
  // Vérifier si on doit utiliser Supabase (Windows) ou Firebase
  static bool get useSupabase {
    return !kIsWeb && Platform.isWindows;
  }

  // Vérifier si Firebase est disponible
  static bool get isFirebaseAvailable {
    if (kIsWeb) return true;
    if (Platform.isWindows) return false; // Utiliser Supabase sur Windows
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  // Vérifier si Google Sign-In est disponible
  static bool get isGoogleSignInAvailable {
    if (kIsWeb) return true;
    return !Platform.isWindows;
  }

  final FirebaseAuth? _auth =
  isFirebaseAvailable ? FirebaseAuth.instance : null;
  final FirebaseFirestore? _firestore =
  isFirebaseAvailable ? FirebaseFirestore.instance : null;
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final GoogleSignIn? _googleSignIn =
  isGoogleSignInAvailable ? GoogleSignIn.instance : null;

  bool _isInitialized = false;

  // Initialiser GoogleSignIn
  Future<void> initializeGoogleSignIn({
    String? clientId,
    String? serverClientId,
  }) async {
    if (!isGoogleSignInAvailable || _googleSignIn == null) {
      print('[AuthService] Google Sign-In non disponible sur cette plateforme');
      return;
    }

    if (_isInitialized) return;

    try {
      await _googleSignIn!.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      _isInitialized = true;

      _googleSignIn!.authenticationEvents.listen(
            (GoogleSignInAuthenticationEvent event) {
          final GoogleSignInAccount? account = switch (event) {
            GoogleSignInAuthenticationEventSignIn() => event.user,
            GoogleSignInAuthenticationEventSignOut() => null,
          };

          print(
              'Google Sign-In state changed: ${account?.email ??
                  'signed out'}');
        },
        onError: (error) {
          print('Google Sign-In authentication error: $error');
        },
      );

      _googleSignIn!.attemptLightweightAuthentication();
      print('[AuthService] ✅ Google Sign-In initialisé');
    } catch (e) {
      print('[AuthService] ❌ Erreur initialisation Google Sign-In: $e');
      rethrow;
    }
  }

  User? get currentUser {
    if (useSupabase) {
      // Pour Supabase, on retourne null car on utilise un système différent
      return null;
    }
    return _auth?.currentUser;
  }

  Stream<User?> get authStateChanges {
    if (useSupabase) {
      return Stream.value(null);
    }
    if (_auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  // ============================================================================
  // SIGN UP
  // ============================================================================
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    // WINDOWS: Utiliser Supabase
    if (useSupabase) {
      try {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'role': role.toJson(),
          },
        );

        if (response.user == null) {
          throw Exception('signup_error');
        }

        final now = DateTime.now();
        final userModel = UserModel(
          uid: response.user!.id,
          email: email,
          name: name,
          role: role,
          createdAt: now,
          updatedAt: now,
          isActive: true,
        );

        // Sauvegarder dans Supabase
        await _supabase.from('users').insert(userModel.toSupabase());

        return userModel;
      } on supabase.AuthException catch (e) {
        throw Exception(_handleSupabaseAuthException(e));
      } catch (e) {
        throw Exception('signup_error');
      }
    }

    // AUTRES PLATEFORMES: Utiliser Firebase
    if (_auth == null || _firestore == null) {
      throw Exception('Firebase non disponible sur cette plateforme');
    }

    try {
      final UserCredential userCredential =
      await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final now = DateTime.now();
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: now,
          updatedAt: now,
          isActive: true,
        );

        await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());

        try {
          await _supabase.from('users').insert(userModel.toSupabase());
        } catch (e) {
          print('Erreur synchronisation Supabase: $e');
        }

        await userCredential.user!.updateDisplayName(name);

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('signup_error');
    }
  }

  // ============================================================================
  // SIGN IN
  // ============================================================================
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    // WINDOWS: Utiliser Supabase
    if (useSupabase) {
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw Exception('user_not_found');
        }

        // Récupérer les données utilisateur depuis Supabase
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        final userModel = UserModel.fromSupabase(userData);

        if (!userModel.isActive) {
          if (userModel.canReactivate()) {
            throw Exception('account_deactivated_can_reactivate');
          } else {
            await deleteUserCompletely(response.user!.id);
            throw Exception('account_deleted_permanently');
          }
        }

        return userModel;
      } on supabase.AuthException catch (e) {
        throw Exception(_handleSupabaseAuthException(e));
      } catch (e) {
        rethrow;
      }
    }

    // AUTRES PLATEFORMES: Utiliser Firebase
    if (_auth == null || _firestore == null) {
      throw Exception('Firebase non disponible sur cette plateforme');
    }

    try {
      final UserCredential userCredential =
      await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userDoc = await _firestore!
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('user_not_found');
        }

        final userModel = UserModel.fromFirestore(userDoc);

        if (!userModel.isActive) {
          if (userModel.canReactivate()) {
            throw Exception('account_deactivated_can_reactivate');
          } else {
            await deleteUserCompletely(userCredential.user!.uid);
            throw Exception('account_deleted_permanently');
          }
        }

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // GET USER DATA
  // ============================================================================
  Future<UserModel?> getUserData(String uid) async {
    // WINDOWS: Utiliser Supabase
    if (useSupabase) {
      try {
        final userData =
        await _supabase.from('users').select().eq('id', uid).single();
        return UserModel.fromSupabase(userData);
      } catch (e) {
        throw Exception('fetch_user_error');
      }
    }

    // AUTRES PLATEFORMES: Utiliser Firebase
    if (_firestore == null) {
      throw Exception('Firebase non disponible sur cette plateforme');
    }

    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('fetch_user_error');
    }
  }

  // ============================================================================
  // STREAM USER DATA
  // ============================================================================
  Stream<UserModel?> streamUserData(String uid) {
    // WINDOWS: Utiliser Supabase
    if (useSupabase) {
      return _supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', uid)
          .map((data) {
        if (data.isEmpty) return null;
        return UserModel.fromSupabase(data.first);
      });
    }

    // AUTRES PLATEFORMES: Utiliser Firebase
    if (_firestore == null) {
      return Stream.value(null);
    }

    return _firestore!.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ============================================================================
  // RESET PASSWORD
  // ============================================================================
  Future<void> resetPassword(String email) async {
    // WINDOWS: Utiliser Supabase
    if (useSupabase) {
      try {
        await _supabase.auth.resetPasswordForEmail(email);
      } on supabase.AuthException catch (e) {
        throw Exception(_handleSupabaseAuthException(e));
      } catch (e) {
        throw Exception('reset_password_error');
      }
      return;
    }

    // AUTRES PLATEFORMES: Utiliser Firebase
    if (_auth == null) {
      throw Exception('Firebase non disponible sur cette plateforme');
    }

    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('reset_password_error');
    }
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================
  Future<void> signOut() async {
    try {
      // WINDOWS: Utiliser Supabase
      if (useSupabase) {
        await _supabase.auth.signOut();
        return;
      }

      // AUTRES PLATEFORMES
      if (isGoogleSignInAvailable && _googleSignIn != null && _isInitialized) {
        await _googleSignIn!.disconnect();
      }

      if (isFirebaseAvailable && _auth != null) {
        await _auth!.signOut();
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      throw Exception('signout_error');
    }
  }

  // ============================================================================
  // DEACTIVATE ACCOUNT
  // ============================================================================
  Future<void> deactivateAccount(String uid) async {
    try {
      final now = DateTime.now();
      final scheduledDeletion = now.add(const Duration(days: 60));

      // Mise à jour Supabase (toujours)
      await _supabase.from('users').update({
        'is_active': false,
        'deactivated_at': now.toIso8601String(),
        'scheduled_deletion_date': scheduledDeletion.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', uid);

      // Mise à jour Firebase (si disponible)
      if (!useSupabase && _firestore != null) {
        await _firestore!.collection('users').doc(uid).update({
          'isActive': false,
          'deactivatedAt': Timestamp.fromDate(now),
          'scheduledDeletionDate': Timestamp.fromDate(scheduledDeletion),
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      throw Exception('deactivate_account_error');
    }
  }

  // ============================================================================
  // REACTIVATE ACCOUNT
  // ============================================================================
  Future<void> reactivateAccount(String uid) async {
    try {
      // Vérifier si le compte peut être réactivé
      final userModel = await getUserData(uid);
      if (userModel == null) {
        throw Exception('user_not_found');
      }

      if (!userModel.canReactivate()) {
        throw Exception('reactivation_period_expired');
      }

      // Réactivation Supabase (toujours)
      await _supabase.from('users').update({
        'is_active': true,
        'deactivated_at': null,
        'scheduled_deletion_date': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);

      // Réactivation Firebase (si disponible)
      if (!useSupabase && _firestore != null) {
        await _firestore!.collection('users').doc(uid).update({
          'isActive': true,
          'deactivatedAt': null,
          'scheduledDeletionDate': null,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // DELETE USER COMPLETELY
  // ============================================================================
  Future<void> deleteUserCompletely(String uid) async {
    try {
      // Suppression Supabase (toujours)
      await _supabase.from('users').delete().eq('id', uid);

      // Suppression Firebase (si disponible)
      if (!useSupabase && _firestore != null && _auth != null) {
        await _firestore!.collection('users').doc(uid).delete();

        final user = _auth!.currentUser;
        if (user != null && user.uid == uid) {
          await user.delete();
        }
      }
    } catch (e) {
      throw Exception('delete_account_error');
    }
  }

  // ============================================================================
  // GOOGLE SIGN IN (pas disponible sur Windows)
  // ============================================================================
  Future<UserModel?> signInWithGoogle() async {
    if (useSupabase) {
      throw Exception('Google Sign-In non disponible sur Windows');
    }

    // Le reste du code existant pour les autres plateformes...
    // (garder votre code actuel)
  }

  // ============================================================================
  // UPDATE USER PROFILE
  // ============================================================================
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? bio,
    String? phoneNumber,
    UserRole? role,
    AppLocation? location,
    UserProfileImages? profileImages,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (role != null) updates['role'] = role.toJson();
      if (location != null) updates['location'] = location.toMap();
      if (profileImages != null)
        updates['profile_images'] = profileImages.toMap();
      if (metadata != null) updates['metadata'] = metadata;

      // Mise à jour Supabase (toujours)
      await _supabase.from('users').update(updates).eq('id', uid);

      // Mise à jour Firebase (si disponible)
      if (!useSupabase && _firestore != null) {
        final firebaseUpdates = <String, dynamic>{
          'updatedAt': Timestamp.now(),
        };

        if (name != null) firebaseUpdates['name'] = name;
        if (bio != null) firebaseUpdates['bio'] = bio;
        if (phoneNumber != null) firebaseUpdates['phoneNumber'] = phoneNumber;
        if (role != null) firebaseUpdates['role'] = role.toJson();
        if (location != null) firebaseUpdates['location'] = location.toMap();
        if (profileImages != null)
          firebaseUpdates['profileImages'] = profileImages.toMap();
        if (metadata != null) firebaseUpdates['metadata'] = metadata;

        await _firestore!.collection('users').doc(uid).update(firebaseUpdates);
      }
    } catch (e) {
      throw Exception('update_profile_error');
    }
  }

  // ============================================================================
  // ERROR HANDLERS
  // ============================================================================
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'weak_password';
      case 'email-already-in-use':
        return 'email_already_in_use';
      case 'invalid-email':
        return 'invalid_email';
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
        return 'wrong_password';
      case 'user-disabled':
        return 'user_disabled';
      case 'too-many-requests':
        return 'too_many_requests';
      case 'operation-not-allowed':
        return 'operation_not_allowed';
      case 'network-request-failed':
        return 'network_error';
      default:
        return 'auth_error';
    }
  }

  String _handleSupabaseAuthException(supabase.AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login')) return 'wrong_password';
    if (message.contains('user not found')) return 'user_not_found';
    if (message.contains('email not confirmed')) return 'email_not_confirmed';
    if (message.contains('invalid email')) return 'invalid_email';
    if (message.contains('password')) return 'weak_password';
    if (message.contains('already registered')) return 'email_already_in_use';

    return 'auth_error';
  }
}