import 'dart:async';

import '../../objectBox/classeObjectBox.dart';
import 'delta_generator_real.dart';
import 'p2p_manager_fixed.dart';

/// 🔥 Observateur automatique de synchronisation P2P
/// CORRECTION: Évite les boucles infinies de synchronisation
class ObjectBoxSyncObserver {
  static ObjectBoxSyncObserver? _instance;

  factory ObjectBoxSyncObserver() {
    _instance ??= ObjectBoxSyncObserver._internal();
    return _instance!;
  }

  ObjectBoxSyncObserver._internal();

  final ObjectBox _objectBox = ObjectBox();
  final DeltaGenerator _deltaGenerator = DeltaGenerator();
  final P2PManager _p2pManager = P2PManager();

  // Subscriptions pour chaque entité
  StreamSubscription? _staffSubscription;
  StreamSubscription? _activiteSubscription;
  StreamSubscription? _branchSubscription;
  StreamSubscription? _timeOffSubscription;
  StreamSubscription? _planificationSubscription;
  StreamSubscription? _planningHebdoSubscription;
  StreamSubscription? _typeActiviteSubscription;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // ✅ CORRECTION: Cache robuste avec expiration automatique
  final Map<String, DateTime> _ignoreUntil = {};
  static const Duration ignoreDuration = Duration(seconds: 3);

  // ✅ CORRECTION: Throttle plus intelligent
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, List<int>> _pendingChanges = {};
  static const Duration throttleDuration = Duration(milliseconds: 800);

  // ✅ CORRECTION: Suivre l'origine des changements
  bool _isApplyingRemoteDelta = false;

  /// Démarre la surveillance automatique
  Future<void> start() async {
    if (_isRunning) {
      print('[SyncObserver] 🔄 Déjà en cours d\'exécution');
      return;
    }

    _isRunning = true;
    print('[SyncObserver] 🚀 Démarrage de la surveillance automatique');

    // Surveiller Staff
    _staffSubscription = _objectBox.staffBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handleStaffChanges();
    });

    // Surveiller ActiviteJour
    _activiteSubscription = _objectBox.activiteBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handleActiviteChanges();
    });

    // Surveiller Branch
    _branchSubscription = _objectBox.branchBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handleBranchChanges();
    });

    // Surveiller TimeOff
    _timeOffSubscription = _objectBox.timeOffBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handleTimeOffChanges();
    });

    // Surveiller Planification
    _planificationSubscription = _objectBox.planificationBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handlePlanificationChanges();
    });

    // Surveiller PlanningHebdo
    _planningHebdoSubscription = _objectBox.planningHebdoBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handlePlanningHebdoChanges();
    });

    // Surveiller TypeActivite
    _typeActiviteSubscription = _objectBox.typeActiviteBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      _handleTypeActiviteChanges();
    });

    print('[SyncObserver] ✅ Surveillance active sur toutes les entités');
  }

  /// Arrête la surveillance
  void stop() {
    _staffSubscription?.cancel();
    _activiteSubscription?.cancel();
    _branchSubscription?.cancel();
    _timeOffSubscription?.cancel();
    _planificationSubscription?.cancel();
    _planningHebdoSubscription?.cancel();
    _typeActiviteSubscription?.cancel();

    _throttleTimers.values.forEach((timer) => timer.cancel());
    _throttleTimers.clear();
    _pendingChanges.clear();
    _ignoreUntil.clear();

    _isRunning = false;
    print('[SyncObserver] 🛑 Surveillance arrêtée');
  }

  /// ✅ CORRECTION: Vérifier si on doit ignorer un changement
  bool _shouldIgnore(String entityType, int entityId) {
    // Ignorer si on applique un delta distant
    if (_isApplyingRemoteDelta) {
      print(
          '[SyncObserver] 🚫 Ignoring change (applying remote delta): $entityType-$entityId');
      return true;
    }

    final key = '$entityType-$entityId';
    final ignoreUntilTime = _ignoreUntil[key];

    if (ignoreUntilTime != null && DateTime.now().isBefore(ignoreUntilTime)) {
      print('[SyncObserver] 🚫 Ignoring change (cooldown): $key');
      return true;
    }

    // Nettoyer les entrées expirées
    _ignoreUntil.removeWhere((k, v) => DateTime.now().isAfter(v));

    return false;
  }

  /// ✅ CORRECTION: Marquer une entité comme modifiée localement
  void _markLocalChange(String entityType, int entityId) {
    final key = '$entityType-$entityId';
    _ignoreUntil[key] = DateTime.now().add(ignoreDuration);
  }

  /// Gestion des changements Staff
  void _handleStaffChanges() {
    _throttledSync('staff', () async {
      final staffs = _objectBox.staffBox.getAll();

      for (final staff in staffs) {
        if (_shouldIgnore('staff', staff.id)) continue;

        _markLocalChange('staff', staff.id);
        await _deltaGenerator.syncStaff(staff, 'update');
        print('[SyncObserver] 📤 Staff synchronisé: ${staff.nom}');
      }
    });
  }

  /// Gestion des changements ActiviteJour
  void _handleActiviteChanges() {
    _throttledSync('activite', () async {
      final activites = _objectBox.activiteBox.getAll();

      for (final activite in activites) {
        if (_shouldIgnore('activite', activite.id)) continue;

        _markLocalChange('activite', activite.id);
        await _deltaGenerator.syncActiviteJour(activite, 'update');
        print('[SyncObserver] 📤 Activité synchronisée: Jour ${activite.jour}');
      }
    });
  }

  /// Gestion des changements Branch
  void _handleBranchChanges() {
    _throttledSync('branch', () async {
      final branches = _objectBox.branchBox.getAll();

      for (final branch in branches) {
        if (_shouldIgnore('branch', branch.id)) continue;

        _markLocalChange('branch', branch.id);
        await _deltaGenerator.syncBranch(branch, 'update');
        print('[SyncObserver] 📤 Branch synchronisée: ${branch.branchNom}');
      }
    });
  }

  /// Gestion des changements TimeOff
  void _handleTimeOffChanges() {
    _throttledSync('timeoff', () async {
      final timeOffs = _objectBox.timeOffBox.getAll();

      for (final timeOff in timeOffs) {
        if (_shouldIgnore('timeoff', timeOff.id)) continue;

        _markLocalChange('timeoff', timeOff.id);
        await _deltaGenerator.syncTimeOff(timeOff, 'update');
        print('[SyncObserver] 📤 TimeOff synchronisé');
      }
    });
  }

  /// Gestion des changements Planification
  void _handlePlanificationChanges() {
    _throttledSync('planification', () async {
      final planifications = _objectBox.planificationBox.getAll();

      for (final planif in planifications) {
        if (_shouldIgnore('planification', planif.id)) continue;

        _markLocalChange('planification', planif.id);
        await _deltaGenerator.syncPlanification(planif, 'update');
        print(
            '[SyncObserver] 📤 Planification synchronisée: ${planif.mois}/${planif.annee}');
      }
    });
  }

  /// Gestion des changements PlanningHebdo
  void _handlePlanningHebdoChanges() {
    _throttledSync('planninghebdo', () async {
      final plannings = _objectBox.planningHebdoBox.getAll();

      for (final planning in plannings) {
        if (_shouldIgnore('planninghebdo', planning.id)) continue;

        _markLocalChange('planninghebdo', planning.id);
        await _deltaGenerator.syncPlanningHebdo(planning, 'update');
        print('[SyncObserver] 📤 PlanningHebdo synchronisé');
      }
    });
  }

  /// Gestion des changements TypeActivite
  void _handleTypeActiviteChanges() {
    _throttledSync('typeactivite', () async {
      final types = _objectBox.typeActiviteBox.getAll();

      for (final type in types) {
        if (_shouldIgnore('typeactivite', type.id)) continue;

        _markLocalChange('typeactivite', type.id);
        await _deltaGenerator.syncTypeActivite(type, 'update');
        print('[SyncObserver] 📤 TypeActivite synchronisé: ${type.code}');
      }
    });
  }

  /// Throttle pour éviter trop de syncs rapides
  void _throttledSync(String key, Future<void> Function() syncFunction) {
    _throttleTimers[key]?.cancel();

    _throttleTimers[key] = Timer(throttleDuration, () async {
      try {
        await syncFunction();
      } catch (e) {
        print('[SyncObserver] ❌ Erreur sync $key: $e');
      } finally {
        _throttleTimers.remove(key);
      }
    });
  }

  /// ✅ NOUVEAU: Marquer qu'on applique un delta distant
  void setApplyingRemoteDelta(bool applying) {
    _isApplyingRemoteDelta = applying;
    if (applying) {
      print('[SyncObserver] 🔒 Mode application delta distant activé');
    } else {
      print('[SyncObserver] 🔓 Mode application delta distant désactivé');
    }
  }

  /// ✅ CORRECTION AMÉLIORÉE: Ignorer les changements pour une entité
  void ignoreNextChange(String entityType, int entityId) {
    final key = '$entityType-$entityId';
    _ignoreUntil[key] = DateTime.now().add(ignoreDuration);
    print('[SyncObserver] ⏰ Ignorer $key pendant ${ignoreDuration.inSeconds}s');
  }

  /// Obtenir les statistiques
  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'activeThrottles': _throttleTimers.length,
      'ignoredEntities': _ignoreUntil.length,
      'isApplyingRemote': _isApplyingRemoteDelta,
    };
  }
}
