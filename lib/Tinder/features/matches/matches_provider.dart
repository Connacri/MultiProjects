// features/matches/presentation/provider/matches_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/repositories/matches_repository_impl.dart';

class MatchesProvider extends ChangeNotifier {
  final MatchesRepositoryImpl repo = MatchesRepositoryImpl();

  List<Match> _matches = [];

  List<Match> get matches => _matches;

  bool loading = true;

  StreamSubscription? _subscription;

  MatchesProvider() {
    _loadMatches();
  }

  void _loadMatches() {
    _subscription?.cancel();
    _subscription = repo.getMatchesStream().listen((newMatches) {
      _matches = newMatches;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
