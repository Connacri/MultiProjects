import 'package:flutter/foundation.dart';

import '../../data/datasources/supabase_planning_datasource.dart';
import '../../data/services/planning_sync_service.dart';
import '../../domain/entities/planning_snapshot.dart';
import 'planning_provider.dart';
import 'rotation_configuration_provider.dart';

enum SyncUiState { idle, syncing, success, failed, conflict }

class PlanningSyncProvider extends ChangeNotifier {
  final PlanningProvider planningProvider;
  final PlanningSyncService syncService;
  final RotationConfigurationProvider rotationConfigurationProvider;
  final SupabasePlanningDatasource remote;

  SyncUiState _state = SyncUiState.idle;
  String? _error;
  DateTime? _lastSyncedAt;
  Map<String, dynamic>? _conflictInfo;

  PlanningSyncProvider({
    required this.planningProvider,
    required this.syncService,
    required this.rotationConfigurationProvider,
    required this.remote,
  });

  SyncUiState get state => _state;
  String? get error => _error;
  bool get isSyncing => _state == SyncUiState.syncing;
  bool get isSynced => _state == SyncUiState.success;
  bool get hasFailed => _state == SyncUiState.failed;
  bool get hasConflict => _state == SyncUiState.conflict;
  Map<String, dynamic>? get conflictInfo => _conflictInfo;
  bool get canSync =>
      (planningProvider.hasDraft || planningProvider.hasCurrent) && !isSyncing;

  Future<void> sync() async {
    final snapshot = planningProvider.draft ?? planningProvider.current;
    if (snapshot == null) return;

    _state = SyncUiState.syncing;
    _error = null;
    _conflictInfo = null;
    notifyListeners();

    try {
      final branchId = snapshot.branchId ?? 0;

      final conflict = await _detectConflict(
        snapshot: snapshot,
        branchId: branchId,
      );
      if (conflict != null) {
        _conflictInfo = conflict;
        _state = SyncUiState.conflict;
        notifyListeners();
        return;
      }

      await _pushSnapshot(snapshot: snapshot, branchId: branchId);

      _lastSyncedAt = DateTime.now().toUtc();
      _state = SyncUiState.success;
    } catch (e) {
      _state = SyncUiState.failed;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> forceSync() async {
    final snapshot = planningProvider.draft ?? planningProvider.current;
    if (snapshot == null) return;

    _state = SyncUiState.syncing;
    _error = null;
    _conflictInfo = null;
    notifyListeners();

    try {
      final branchId = snapshot.branchId ?? 0;
      await _pushSnapshot(snapshot: snapshot, branchId: branchId);

      _lastSyncedAt = DateTime.now().toUtc();
      _state = SyncUiState.success;
    } catch (e) {
      _state = SyncUiState.failed;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _detectConflict({
    required PlanningSnapshot snapshot,
    required int branchId,
  }) async {
    final remoteInfo = await remote.fetchLatestSnapshotInfo(
      branchId: branchId,
      year: snapshot.year,
      month: snapshot.month,
    );
    if (remoteInfo == null) return null;

    final remoteRevision = remoteInfo['revision'] as int;
    final remoteCreatedAt =
        DateTime.tryParse(remoteInfo['created_at'] as String? ?? '');

    if (remoteRevision > snapshot.revision) return remoteInfo;

    if (remoteRevision == snapshot.revision &&
        _lastSyncedAt != null &&
        remoteCreatedAt != null &&
        remoteCreatedAt.isAfter(_lastSyncedAt!)) {
      return remoteInfo;
    }

    return null;
  }

  Future<void> _pushSnapshot({
    required PlanningSnapshot snapshot,
    required int branchId,
  }) async {
    final config = rotationConfigurationProvider.active;

    await syncService.pushSnapshot(
      snapshot: snapshot,
      branchId: branchId,
      configurationPayload: {
        'teamOrder': config?.teamOrder ?? [],
        'cycle': config?.cycle.map((s) => s.name).toList() ?? [],
        'policy': config?.policy.name,
        'cycleLength': config?.cycle.length ?? 4,
      },
    );
  }

  void reset() {
    _state = SyncUiState.idle;
    _error = null;
    _conflictInfo = null;
    notifyListeners();
  }
}
