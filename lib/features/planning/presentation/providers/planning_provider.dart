import 'package:flutter/foundation.dart';

import '../../domain/usecases/create_planning_revision.dart';
import '../../application/usecases/load_planning.dart';
import '../../application/usecases/publish_planning.dart';
import '../../domain/entities/planning_assignment.dart';
import '../../domain/entities/planning_override.dart';
import '../../domain/entities/planning_snapshot.dart';
import '../../domain/entities/rotation_configuration.dart';
import '../../domain/entities/rotation_state_snapshot.dart';
import '../../domain/entities/staff_availability.dart';
import '../../domain/services/generate_planning.dart';
import '../../domain/usecases/save_planning_revision.dart';

/// Presentation state shared by Desktop and Mobile Planning screens.
///
/// Lifecycle:
/// load -> generate/edit draft -> persist revision -> publish.
/// Published snapshots are immutable historical facts and are never mutated
/// in place by the provider.
class PlanningProvider extends ChangeNotifier {
  final GeneratePlanning generatePlanning;
  final CreatePlanningRevision createPlanningRevision;
  final SavePlanningRevision savePlanningRevision;
  final PublishPlanning publishPlanning;
  final LoadPlanning loadPlanning;

  PlanningProvider({
    required this.generatePlanning,
    required this.createPlanningRevision,
    required this.savePlanningRevision,
    required this.publishPlanning,
    required this.loadPlanning,
  }) {
    final now = DateTime.now();
    Future.microtask(() => load(year: now.year, month: now.month));
  }

  PlanningSnapshot? _draft;
  PlanningSnapshot? _current;
  int? _loadedYear;
  int? _loadedMonth;
  int? _loadedBranchId;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  String? _error;

  PlanningSnapshot? get draft => _draft;
  PlanningSnapshot? get current => _current;
  int? get loadedYear => _loadedYear;
  int? get loadedMonth => _loadedMonth;
  int? get loadedBranchId => _loadedBranchId;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSaving => _isSaving;
  bool get isPublishing => _isPublishing;
  bool get isBusy =>
      _isLoading || _isGenerating || _isSaving || _isPublishing;
  bool get hasDraft => _draft != null;
  bool get hasCurrent => _current != null;
  String? get error => _error;

  Future<void> load({
    required int year,
    required int month,
    int? branchId,
  }) async {
    if (isBusy) return;
    _isLoading = true;
    _error = null;
    _loadedYear = year;
    _loadedMonth = month;
    _loadedBranchId = branchId;
    notifyListeners();

    try {
      _current = await loadPlanning(
        year: year,
        month: month,
        branchId: branchId,
      );
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
    _loadedYear = year;
    _loadedMonth = month;
    _loadedBranchId = branchId;
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

  /// Creates a new draft revision from the current persisted revision.
  Future<void> createRevision({
    required DateTime createdAt,
    List<PlanningAssignment>? assignments,
    DateTime? continuityDate,
    RotationStateSnapshot? rotationState,
  }) async {
    if (isBusy) return;

    final source = _current;
    if (source == null) {
      throw StateError(
        'No persisted planning snapshot is available to create a revision.',
      );
    }
    if (!source.isPublished) {
      throw StateError(
        'A revision can only be created from a persisted published snapshot.',
      );
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _draft = await createPlanningRevision(
        source: source,
        createdAt: createdAt,
        assignments: assignments,
        continuityDate: continuityDate,
        rotationState: rotationState,
      );
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Persists the current draft as an immutable, unpublished revision.
  ///
  /// The returned entity is reloaded from persistence, so the provider never
  /// assumes that a successful write implies a valid readable state.
  Future<void> saveDraft() async {
    if (isBusy) return;

    final draft = _draft;
    if (draft == null) {
      throw StateError('No planning draft is available for persistence.');
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _draft = await savePlanningRevision(snapshot: draft);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Publishes the current draft through the canonical publication pipeline.
  Future<void> publish() async {
    if (isBusy) return;

    final draft = _draft;
    if (draft == null) {
      throw StateError('No planning draft is available for publication.');
    }

    _isPublishing = true;
    _error = null;
    notifyListeners();

    try {
      final published = await publishPlanning(draft);
      _current = published;
      _draft = null;
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Replaces the in-memory draft after an external editor applies changes.
  void setDraft(PlanningSnapshot snapshot) {
    if (snapshot.isPublished) {
      throw StateError('A published snapshot cannot be assigned as a draft.');
    }
    _draft = snapshot;
    _loadedYear = snapshot.year;
    _loadedMonth = snapshot.month;
    _loadedBranchId = snapshot.branchId;
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
