import 'package:flutter/foundation.dart';

import '../../domain/entities/rotation_configuration.dart';
import '../../domain/repositories/rotation_configuration_repository.dart';

/// Manages the active versioned rotation configuration for the planning UI.
///
/// Changing `teamOrder` creates a new persisted configuration version. The
/// provider never mutates a published snapshot or historical configuration.
class RotationConfigurationProvider extends ChangeNotifier {
  final RotationConfigurationRepository repository;

  RotationConfiguration? _active;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  RotationConfigurationProvider({required this.repository});

  RotationConfiguration? get active => _active;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isLoading || _isSaving;
  String? get error => _error;

  Future<void> loadActive() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _active = await repository.findActive();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a new configuration version and makes it active in memory.
  Future<RotationConfiguration> saveVersion(
    RotationConfiguration configuration,
  ) async {
    if (_isSaving) {
      throw StateError('A rotation configuration save is already in progress.');
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await repository.saveVersion(configuration: configuration);
      _active = saved;
      return saved;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<RotationConfiguration> reorderTeams(
    List<String> teamOrder,
  ) async {
    final current = _active;
    if (current == null) {
      throw StateError('No active rotation configuration is loaded.');
    }

    final normalized = teamOrder
        .map((team) => team.trim())
        .where((team) => team.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalized.length != current.teamOrder.length ||
        normalized.toSet().length != current.teamOrder.toSet().length) {
      throw ArgumentError(
        'The new team order must contain exactly the configured teams.',
      );
    }

    return saveVersion(current.copyWith(teamOrder: normalized));
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
