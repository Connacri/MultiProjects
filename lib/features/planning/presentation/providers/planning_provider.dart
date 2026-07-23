import 'package:flutter/foundation.dart';

import '../../domain/entities/planning_override.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/staff_availability.dart';
import '../../domain/services/generate_planning.dart';
import '../../domain/services/publish_planning.dart';

class PlanningProvider extends ChangeNotifier {
  final GeneratePlanning generatePlanning;
  final PublishPlanning publishPlanning;

  PlanningProvider({
    required this.generatePlanning,
    required this.publishPlanning,
  });

  PlanningSnapshot? _draft;
  bool _isGenerating = false;
  bool _isPublishing = false;
  String? _error;

  PlanningSnapshot? get draft => _draft;
  bool get isGenerating => _isGenerating;
  bool get isPublishing => _isPublishing;
  bool get isBusy => _isGenerating || _isPublishing;
  String? get error => _error;

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
    if (_isGenerating || _isPublishing) return;

    _setBusy(generating: true);
    _error = null;

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
      _setBusy(generating: false);
    }
  }

  Future<void> publish() async {
    final draft = _draft;
    if (draft == null) {
      throw StateError('No planning draft is available for publication.');
    }
    if (_isGenerating || _isPublishing) return;

    _setBusy(publishing: true);
    _error = null;

    try {
      final publication = await publishPlanning(draft);
      _draft = publication.snapshot;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _setBusy(publishing: false);
    }
  }

  void clearDraft() {
    if (_isGenerating || _isPublishing) return;
    _draft = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _setBusy({bool? generating, bool? publishing}) {
    if (generating != null) _isGenerating = generating;
    if (publishing != null) _isPublishing = publishing;
    notifyListeners();
  }
}
