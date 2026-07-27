import 'package:flutter/foundation.dart';

import '../../domain/entities/planning_snapshot.dart';
import '../../domain/services/planning_validator.dart';

/// Holds the latest validation result for the current draft.
/// Validation is pure and never persists data.
class PlanningValidationProvider extends ChangeNotifier {
  final PlanningValidator validator;

  PlanningValidationProvider({required this.validator});

  PlanningValidationResult? _result;
  String? _error;

  PlanningValidationResult? get result => _result;
  String? get error => _error;
  bool get hasResult => _result != null;
  bool get isValid => _result?.isValid ?? false;

  PlanningValidationResult validate(PlanningSnapshot snapshot) {
    try {
      _error = null;
      _result = validator.validate(snapshot);
      notifyListeners();
      return _result!;
    } catch (error) {
      _error = error.toString();
      _result = null;
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
