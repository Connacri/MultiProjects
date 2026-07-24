import 'package:flutter/foundation.dart';

import '../../application/usecases/load_planning.dart';
import '../../application/usecases/publish_planning.dart';
import '../../domain/entities/planning_override.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/staff_availability.dart';
import '../../domain/services/generate_planning.dart';

/// Presentation state shared by Desktop and Mobile Planning screens.
class PlanningProvider extends ChangeNotifier {
  final GeneratePlanning generatePlanning;
  final PublishPlanning publishPlanning;
  final LoadPlanning loadPlanning;

  PlanningProvider({
    required this.generatePlanning,
    required this.publishPlanning,
    required this.loadPlanning,
  });

  PlanningSnapshot? _draft;
  PlanningSnapshot? _current;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isPublishing = false;
  String? _error;

  PlanningSnapshot? get draft => _draft;
  PlanningSnapshot? get current => _current;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isPublishing => _isPublishing;
  bool get isBusy => _isLoading || _isGenerating || _isPublishing;
  String? get error => _error;

  Future<void> load({required int year, required int month, int? branchId}) async {
    if (isBusy) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _current = await loadPlanning(year: year, month: month, branchId: branchId);
      _draft = null;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generate({
    required int year,
    required int month,
    required RotationConfiguration configuration,
    required List<int> staffIds,
    required Map<int, String> staffTeams,
    List<StaffAvailability> availability = const [],
    List<PlanningOverride> overrides = const [],
    int? branchId,
  }) async {
    if (isBusy) return;
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      _draft = await generatePlanning(
        year: year,
        month: month,
        configuration: configuration,
        staffIds: staffIds,
        staffTeams: staffTeams,
        availability: availability,
        overrides: overrides,
        branchId: branchId,
      );
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> publish() async {
    final draft = _draft;
    if (draft == null) {
      throw StateError('No planning draft is available for publication.');
    }
    if (isBusy) return;
    _isPublishing = true;
    _error = null;
    notifyListeners();
    try {
      _current = await publishPlanning(draft);
      _draft = null;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  void setDraft(PlanningSnapshot snapshot) {
    _draft = snapshot;
    notifyListeners();
  }

  void clearDraft() {
    _draft = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
