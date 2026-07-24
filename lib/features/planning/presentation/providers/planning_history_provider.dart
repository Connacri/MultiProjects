import 'package:flutter/foundation.dart';

import '../../domain/entities/planning_snapshot.dart';
import '../../domain/repositories/planning_repository.dart';

/// Read-only history access. Opening history never triggers generation.
class PlanningHistoryProvider extends ChangeNotifier {
  final PlanningRepository repository;

  PlanningHistoryProvider(this.repository);

  PlanningSnapshot? _planning;
  bool _isLoading = false;
  String? _error;

  PlanningSnapshot? get planning => _planning;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load({
    required int year,
    required int month,
    int? branchId,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _planning = await repository.findByMonth(
        year: year,
        month: month,
        branchId: branchId,
      );
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
