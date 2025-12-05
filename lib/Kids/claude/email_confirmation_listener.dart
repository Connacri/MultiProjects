import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🎧 Listener automatique de confirmation email
/// Utilise un polling intelligent pour détecter la confirmation
class EmailConfirmationListener {
  static final EmailConfirmationListener _instance =
      EmailConfirmationListener._internal();
  factory EmailConfirmationListener() => _instance;
  EmailConfirmationListener._internal();

  Timer? _pollingTimer;
  bool _isListening = false;
  VoidCallback? _onConfirmed;
  VoidCallback? _onError;

  // Configuration du polling
  final Duration _pollingInterval = const Duration(seconds: 3);
  final int _maxAttempts = 100; // 5 minutes max (100 * 3s)
  int _attemptCount = 0;

  /// Démarre l'écoute automatique de la confirmation
  void startListening({
    required VoidCallback onConfirmed,
    VoidCallback? onError,
  }) {
    if (_isListening) {
      print('[EmailListener] ⚠️ Listener déjà actif');
      return;
    }

    print('[EmailListener] 🎧 Démarrage listener confirmation email...');
    print('[EmailListener] 🔄 Polling toutes les ${_pollingInterval.inSeconds}s');

    _isListening = true;
    _onConfirmed = onConfirmed;
    _onError = onError;
    _attemptCount = 0;

    // Vérification immédiate
    _checkEmailConfirmation();

    // Démarrer le polling
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkEmailConfirmation();
    });
  }

  /// Vérifie si l'email a été confirmé
  Future<void> _checkEmailConfirmation() async {
    if (!_isListening) return;

    _attemptCount++;
    print('[EmailListener] 🔍 Vérification #$_attemptCount...');

    try {
      // Rafraîchir la session pour obtenir les dernières infos
      final refreshResponse =
          await Supabase.instance.client.auth.refreshSession();

      if (refreshResponse.session == null) {
        print('[EmailListener] ⚠️ Pas de session');
        return;
      }

      final user = refreshResponse.session!.user;
      final isConfirmed = user.emailConfirmedAt != null;

      print('[EmailListener] Email confirmé: $isConfirmed');
      print('[EmailListener] emailConfirmedAt: ${user.emailConfirmedAt}');

      if (isConfirmed) {
        print('[EmailListener] 🎉 EMAIL CONFIRMÉ DÉTECTÉ!');
        stopListening();
        _onConfirmed?.call();
        return;
      }

      // Arrêter après le nombre max de tentatives
      if (_attemptCount >= _maxAttempts) {
        print('[EmailListener] ⏱️ Timeout: nombre max de tentatives atteint');
        stopListening();
        _onError?.call();
      }
    } catch (e, stackTrace) {
      print('[EmailListener] ❌ Erreur vérification: $e');
      print(stackTrace);

      // En cas d'erreur, continuer à essayer
      if (_attemptCount >= _maxAttempts) {
        stopListening();
        _onError?.call();
      }
    }
  }

  /// Arrête l'écoute
  void stopListening() {
    if (!_isListening) return;

    print('[EmailListener] 🛑 Arrêt du listener');
    _isListening = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _attemptCount = 0;
  }

  /// Vérifie immédiatement (appelé depuis UI)
  Future<bool> checkNow() async {
    print('[EmailListener] ⚡ Vérification immédiate forcée');

    try {
      final refreshResponse =
          await Supabase.instance.client.auth.refreshSession();

      if (refreshResponse.session == null) {
        return false;
      }

      final user = refreshResponse.session!.user;
      final isConfirmed = user.emailConfirmedAt != null;

      if (isConfirmed) {
        print('[EmailListener] 🎉 EMAIL CONFIRMÉ!');
        stopListening();
        _onConfirmed?.call();
      }

      return isConfirmed;
    } catch (e) {
      print('[EmailListener] ❌ Erreur checkNow: $e');
      return false;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    stopListening();
  }

  bool get isListening => _isListening;
  int get attemptCount => _attemptCount;
  int get maxAttempts => _maxAttempts;
}

/// 🪟 Listener de focus de fenêtre (détecte quand user revient à l'app)
class WindowFocusListener extends WidgetsBindingObserver {
  final VoidCallback onWindowFocused;

  WindowFocusListener({required this.onWindowFocused});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print('[WindowFocus] 🪟 Fenêtre focus - Vérification confirmation...');
      onWindowFocused();
    }
  }
}
