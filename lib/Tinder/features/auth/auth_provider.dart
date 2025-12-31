// features/auth/presentation/provider/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TinderAuthProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  User? get currentUser => supabase.auth.currentUser;

  TinderAuthProvider() {
    supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
