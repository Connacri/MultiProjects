// lib/Tinder/features/matches/matches_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../objectBox/Entity.dart';
import '../../core/data/repositories/matches_repository_impl.dart';

class MatchesProvider extends ChangeNotifier {
  final MatchesRepositoryImpl repo = MatchesRepositoryImpl();

  // ✅ État privé
  List<Match> _matches = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;
  StreamSubscription? _subscription;

  // ✅ Getters publics
  List<Match> get matches => List.unmodifiable(_matches);

  bool get loading => _loading;

  String? get error => _error;

  int get unreadCount => _unreadCount;

  bool get hasMatches => _matches.isNotEmpty;

  MatchesProvider() {
    _loadMatches();
    _loadUnreadCount();
  }

  /// ✅ AMÉLIORATION: Chargement avec gestion d'erreur
  void _loadMatches() {
    _subscription?.cancel();

    _subscription = repo.getMatchesStream().listen(
      (newMatches) {
        _matches = newMatches;
        _loading = false;
        _error = null;
        print('✅ [MatchesProvider] ${newMatches.length} matches reçus');
        notifyListeners();
      },
      onError: (e) {
        _error = _getErrorMessage(e);
        _loading = false;
        print('❌ [MatchesProvider] Erreur stream: $e');
        notifyListeners();
      },
    );
  }

  /// ✅ NOUVEAU: Charger le nombre de matches non lus
  Future<void> _loadUnreadCount() async {
    try {
      _unreadCount = await repo.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('❌ [MatchesProvider] Erreur count unread: $e');
    }
  }

  /// ✅ NOUVEAU: Marquer un match comme lu
  Future<void> markAsRead(String matchId) async {
    try {
      await repo.markMatchAsRead(matchId);
      await _loadUnreadCount(); // Rafraîchir le compteur
    } catch (e) {
      print('❌ [MatchesProvider] Erreur mark as read: $e');
    }
  }

  /// ✅ NOUVEAU: Supprimer un match
  Future<bool> deleteMatch(String matchId) async {
    try {
      // ✅ Optimistic update
      final index = _matches.indexWhere((m) => m.id == matchId);
      if (index == -1) return false;

      final removedMatch = _matches[index];
      _matches = List.from(_matches)..removeAt(index);
      notifyListeners();

      // ✅ Suppression API
      await repo.deleteMatch(matchId);
      print('✅ [MatchesProvider] Match supprimé');
      return true;
    } catch (e) {
      print('❌ [MatchesProvider] Erreur suppression: $e');

      // ✅ Rollback si échec
      _loading = true;
      notifyListeners();
      _loadMatches();

      return false;
    }
  }

  /// ✅ NOUVEAU: Rafraîchir manuellement
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    _loadMatches();
    await _loadUnreadCount();
  }

  /// ✅ NOUVEAU: Filtrer les matches par recherche
  List<Match> searchMatches(String query) {
    if (query.isEmpty) return _matches;

    final lowerQuery = query.toLowerCase();

    return _matches.where((match) {
      return match.otherUserName.toLowerCase().contains(lowerQuery) ||
          (match.lastMessagePreview?.toLowerCase().contains(lowerQuery) ??
              false);
    }).toList();
  }

  /// ✅ Messages d'erreur utilisateur-friendly
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return 'La connexion est trop lente';
    }
    if (errorStr.contains('network')) {
      return 'Pas de connexion Internet';
    }
    if (errorStr.contains('auth')) {
      return 'Session expirée';
    }

    return 'Une erreur est survenue';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
