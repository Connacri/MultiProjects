// features/auth/presentation/widgets/auth_wrapper_tinder.dart
// Version modifiée : accès app sans forcer complétion profil

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bottom_nav.dart';
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

    if (!_hasInitializedProfile) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

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
        print(
            '🔄 [AuthWrapper] Loading: ${profileProvider.loading}, Error: ${profileProvider.error}');

        // Chargement initial
        if (profileProvider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Pas authentifié → Login
        if (Supabase.instance.client.auth.currentUser == null ||
            profileProvider.error != null) {
          return const LoginScreen();
        }

        // Authentifié → direct Discovery (plus de blocage complétion)
        return const BottomNav();
      },
    );
  }
}
