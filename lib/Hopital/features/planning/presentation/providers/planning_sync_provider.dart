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
    print('[Sync] === sync() ===');
    final snapshot = planningProvider.draft ?? planningProvider.current;
    if (snapshot == null) {
      print('[Sync] ⛔ Aucun snapshot disponible');
      return;
    }
    print('[Sync] Snapshot: year=${snapshot.year}, month=${snapshot.month}, revision=${snapshot.revision}, draft=${planningProvider.draft != null}');

    _state = SyncUiState.syncing;
    _error = null;
    _conflictInfo = null;
    notifyListeners();

    try {
      final branchId = snapshot.branchId ?? 0;

      print('[Sync] Détection conflit...');
      final conflict = await _detectConflict(
        snapshot: snapshot,
        branchId: branchId,
      );
      if (conflict != null) {
        print('[Sync] ⚠ Conflit détecté: révision distante=${conflict['revision']}');
        _conflictInfo = conflict;
        _state = SyncUiState.conflict;
        notifyListeners();
        return;
      }
      print('[Sync] ✅ Pas de conflit');

      print('[Sync] Push snapshot...');
      await _pushSnapshot(snapshot: snapshot, branchId: branchId);

      _lastSyncedAt = DateTime.now().toUtc();
      _state = SyncUiState.success;
      print('[Sync] ✅ Sync réussie');
    } catch (e) {
      print('[Sync] ❌ Erreur: $e');
      _state = SyncUiState.failed;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> forceSync() async {
    print('[Sync] === forceSync() ===');
    final snapshot = planningProvider.draft ?? planningProvider.current;
    if (snapshot == null) {
      print('[Sync] ⛔ Aucun snapshot disponible');
      return;
    }
    print('[Sync] Snapshot: year=${snapshot.year}, month=${snapshot.month}, revision=${snapshot.revision}');

    _state = SyncUiState.syncing;
    _error = null;
    _conflictInfo = null;
    notifyListeners();

    try {
      final branchId = snapshot.branchId ?? 0;
      print('[Sync] Force push (ignore conflit)...');
      await _pushSnapshot(snapshot: snapshot, branchId: branchId);

      _lastSyncedAt = DateTime.now().toUtc();
      _state = SyncUiState.success;
      print('[Sync] ✅ Force sync réussie');
    } catch (e) {
      print('[Sync] ❌ Erreur: $e');
      _state = SyncUiState.failed;
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _detectConflict({
    required PlanningSnapshot snapshot,
    required int branchId,
  }) async {
    print('[Sync] Détection conflit pour branch=$branchId, year=${snapshot.year}, month=${snapshot.month}');
    final remoteInfo = await remote.fetchLatestSnapshotInfo(
      branchId: branchId,
      year: snapshot.year,
      month: snapshot.month,
    );
    if (remoteInfo == null) {
      print('[Sync] Aucune donnée distante - pas de conflit');
      return null;
    }
    print('[Sync] Données distantes: revision=${remoteInfo['revision']}, created_at=${remoteInfo['created_at']}');

    final remoteRevision = remoteInfo['revision'] as int;
    final remoteCreatedAt =
        DateTime.tryParse(remoteInfo['created_at'] as String? ?? '');

    if (remoteRevision > snapshot.revision) {
      print('[Sync] ⚠ Conflit: révision distante ($remoteRevision) > locale (${snapshot.revision})');
      return remoteInfo;
    }

    if (remoteRevision == snapshot.revision &&
        _lastSyncedAt != null &&
        remoteCreatedAt != null &&
        remoteCreatedAt.isAfter(_lastSyncedAt!)) {
      print('[Sync] ⚠ Conflit: même révision mais modifiée après dernier sync');
      return remoteInfo;
    }

    print('[Sync] ✅ Pas de conflit détecté');
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
