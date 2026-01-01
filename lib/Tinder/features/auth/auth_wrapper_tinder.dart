// features/auth/presentation/widgets/auth_wrapper_tinder.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../Kids/claude/profile_completion_screen.dart';
import '../discovery/discovery_screen.dart';
import '../profile/profile_provider.dart';
import 'LoginScreen.dart';

class AuthWrapperTinder extends StatefulWidget {
  const AuthWrapperTinder({super.key});

  @override
  State<AuthWrapperTinder> createState() => _AuthWrapperTinderState();
}

class _AuthWrapperTinderState extends State<AuthWrapperTinder> {
  bool _hasInitializedProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Chargement unique du profil dès que le wrapper est monté
    if (!_hasInitializedProfile) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      // Évite les appels multiples si déjà en cours ou terminé
      if (profileProvider.profileData == null &&
          profileProvider.error == null &&
          !profileProvider.loading) {
        profileProvider.init();
      }

      _hasInitializedProfile = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        // Log utile en dev (à retirer en prod si besoin)
        print(
            '🔄 [AuthWrapper] Loading: ${profileProvider.loading}, Error: ${profileProvider.error}, Completed: ${profileProvider.profileCompleted}');

        // Chargement initial
        if (profileProvider.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Erreur auth ou profil
        if (profileProvider.error != null ||
            Supabase.instance.client.auth.currentUser == null) {
          return const LoginScreen();
        }

        // Profil incomplet → écran de complétion
        if (!profileProvider.profileCompleted) {
          return const ProfileCompletionScreen();
        }

        // Tout est OK → Discovery
        return const DiscoveryScreen();
      },
    );
  }
}
