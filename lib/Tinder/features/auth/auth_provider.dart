// features/auth/presentation/provider/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TinderAuthProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  User? get currentUser => supabase.auth.currentUser;

  Session? get currentSession => supabase.auth.currentSession;

  TinderAuthProvider() {
    supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      // Optionnel : redirect après confirmation
      // emailRedirectTo: 'io.supabase.fluttertinder://login-callback',
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
