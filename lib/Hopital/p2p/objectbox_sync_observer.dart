import 'dart:async';

import 'package:flutter/animation.dart';

import '../../objectBox/classeObjectBox.dart';
import 'delta_generator_real.dart';

/// 🔥 Observateur automatique avec callbacks pour rafraîchir l'UI
class ObjectBoxSyncObserver {
  static ObjectBoxSyncObserver? _instance;

  factory ObjectBoxSyncObserver() {
    _instance ??= ObjectBoxSyncObserver._internal();
    return _instance!;
  }

  ObjectBoxSyncObserver._internal();

  final ObjectBox _objectBox = ObjectBox();
  final DeltaGenerator _deltaGenerator = DeltaGenerator();

  // ========== STREAM SUBSCRIPTIONS ==========
  StreamSubscription? _staffSubscription;
  StreamSubscription? _activiteJourSubscription;
  StreamSubscription? _branchSubscription;
  StreamSubscription? _timeOffSubscription;
  StreamSubscription? _planificationSubscription;
  StreamSubscription? _planningHebdoSubscription;
  StreamSubscription? _typeActiviteSubscription;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  // ========== ✅ NOUVEAU : CALLBACKS POUR RAFRAÎCHIR L'UI ==========
  final List<VoidCallback> _onStaffChangedCallbacks = [];
  final List<VoidCallback> _onActiviteChangedCallbacks = [];
  final List<VoidCallback> _onBranchChangedCallbacks = [];
  final List<VoidCallback> _onTimeOffChangedCallbacks = [];
  final List<VoidCallback> _onPlanificationChangedCallbacks = [];

  /// ✅ Enregistrer un callback pour les changements Staff
  void addStaffChangedListener(VoidCallback callback) {
    if (!_onStaffChangedCallbacks.contains(callback)) {
      _onStaffChangedCallbacks.add(callback);
      print(
          '[SyncObserver] 🎯 Callback Staff enregistré (${_onStaffChangedCallbacks.length} total)');
    }
  }

  /// ✅ Enregistrer un callback pour les changements Activité
  void addActiviteChangedListener(VoidCallback callback) {
    if (!_onActiviteChangedCallbacks.contains(callback)) {
      _onActiviteChangedCallbacks.add(callback);
      print('[SyncObserver] 🎯 Callback Activité enregistré');
    }
  }

  /// ✅ Retirer un callback
  void removeStaffChangedListener(VoidCallback callback) {
    _onStaffChangedCallbacks.remove(callback);
  }

  void removeActiviteChangedListener(VoidCallback callback) {
    _onActiviteChangedCallbacks.remove(callback);
  }

  // ========== TRACKING DES DELTAS ==========
  final Set<String> _recentlyAppliedDeltas = {};

  // ========== THROTTLING ==========
  final Map<String, Timer> _throttleTimers = {};
  static const Duration throttleDuration = Duration(milliseconds: 500);

  // ========== FLAG DELTA DISTANT ==========
  bool _isApplyingRemoteDelta = false;

  /// ✅ Démarrer la surveillance automatique
  Future<void> start() async {
    if (_isRunning) {
      print('[SyncObserver] 🔄 Déjà en cours d\'exécution');
      return;
    }

    _isRunning = true;
    print('[SyncObserver] 🚀 Démarrage de la surveillance automatique');
    print('[SyncObserver] ⚡ Throttle: ${throttleDuration.inMilliseconds}ms');

    // ========== SURVEILLER STAFF ==========
    _staffSubscription = _objectBox.staffBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 Staff modifié détecté');
        _handleStaffChanges();
      } else {
        print(
            '[SyncObserver] 🔒 Changement Staff ignoré (delta distant en cours)');
      }
    });

    // ========== SURVEILLER ACTIVITEJOUR ==========
    _activiteJourSubscription = _objectBox.activiteBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 ActiviteJour modifiée détectée');
        _handleActiviteJourChanges();
      }
    });

    // ========== SURVEILLER BRANCH ==========
    _branchSubscription = _objectBox.branchBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 Branch modifiée détectée');
        _handleBranchChanges();
      }
    });

    // ========== SURVEILLER TIMEOFF ==========
    _timeOffSubscription = _objectBox.timeOffBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 TimeOff modifié détecté');
        _handleTimeOffChanges();
      }
    });

    // ========== SURVEILLER PLANIFICATION ==========
    _planificationSubscription = _objectBox.planificationBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 Planification modifiée détectée');
        _handlePlanificationChanges();
      }
    });

    // ========== SURVEILLER PLANNINGHEBDO ==========
    _planningHebdoSubscription = _objectBox.planningHebdoBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 PlanningHebdo modifié détecté');
        _handlePlanningHebdoChanges();
      }
    });

    // ========== SURVEILLER TYPEACTIVITE ==========
    _typeActiviteSubscription = _objectBox.typeActiviteBox
        .query()
        .watch(triggerImmediately: false)
        .listen((query) {
      if (!_isApplyingRemoteDelta) {
        print('[SyncObserver] 📊 TypeActivite modifié détecté');
        _handleTypeActiviteChanges();
      }
    });

    print('[SyncObserver] ✅ Surveillance active sur 7 entités');
  }

  /// Arrêter la surveillance
  void stop() {
    _staffSubscription?.cancel();
    _activiteJourSubscription?.cancel();
    _branchSubscription?.cancel();
    _timeOffSubscription?.cancel();
    _planificationSubscription?.cancel();
    _planningHebdoSubscription?.cancel();
    _typeActiviteSubscription?.cancel();

    _throttleTimers.values.forEach((timer) => timer.cancel());
    _throttleTimers.clear();
    _recentlyAppliedDeltas.clear();

    _isRunning = false;
    print('[SyncObserver] 🛑 Surveillance arrêtée');
  }

  // ========================================================================
  // HANDLERS POUR CHAQUE ENTITÉ
  // ========================================================================

  /// ✅ Gestion des changements Staff
  void _handleStaffChanges() {
    _throttledSync('staff', () async {
      final staffs = _objectBox.staffBox.getAll();

      for (final staff in staffs) {
        final changeSignature = 'Staff-${staff.id}-${staff.nom}-${staff.grade}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip Staff ${staff.id} (vient d\'un delta distant)');
          // ✅ NOUVEAU : Notifier les listeners même pour les changements distants
          _notifyStaffListeners();
          continue;
        }

        await _deltaGenerator.syncStaff(staff, 'update');
        print(
            '[SyncObserver] 📤 Staff synchronisé: ${staff.nom} (ID: ${staff.id})');
      }

      // ✅ NOUVEAU : Notifier tous les listeners
      _notifyStaffListeners();
    });
  }

  /// ✅ Gestion des changements ActiviteJour
  void _handleActiviteJourChanges() {
    _throttledSync('activiteJour', () async {
      final activites = _objectBox.activiteBox.getAll();

      for (final activite in activites) {
        final changeSignature =
            'ActiviteJour-${activite.id}-${activite.jour}-${activite.statut}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip ActiviteJour ${activite.id} (vient d\'un delta distant)');
          _notifyActiviteListeners();
          continue;
        }

        await _deltaGenerator.syncActiviteJour(activite, 'update');
        print('[SyncObserver] 📤 ActiviteJour synchronisée: ${activite.id}');
      }

      _notifyActiviteListeners();
    });
  }

  /// ✅ Gestion des changements Branch
  void _handleBranchChanges() {
    _throttledSync('branch', () async {
      final branches = _objectBox.branchBox.getAll();

      for (final branch in branches) {
        final changeSignature = 'Branch-${branch.id}-${branch.branchNom}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip Branch ${branch.id} (vient d\'un delta distant)');
          _notifyBranchListeners();
          continue;
        }

        await _deltaGenerator.syncBranch(branch, 'update');
        print('[SyncObserver] 📤 Branch synchronisée: ${branch.branchNom}');
      }

      _notifyBranchListeners();
    });
  }

  /// ✅ Gestion des changements TimeOff
  void _handleTimeOffChanges() {
    _throttledSync('timeOff', () async {
      final timeOffs = _objectBox.timeOffBox.getAll();

      for (final timeOff in timeOffs) {
        final changeSignature =
            'TimeOff-${timeOff.id}-${timeOff.debut}-${timeOff.fin}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip TimeOff ${timeOff.id} (vient d\'un delta distant)');
          _notifyTimeOffListeners();
          continue;
        }

        await _deltaGenerator.syncTimeOff(timeOff, 'update');
        print('[SyncObserver] 📤 TimeOff synchronisé: ${timeOff.id}');
      }

      _notifyTimeOffListeners();
    });
  }

  /// ✅ Gestion des changements Planification
  void _handlePlanificationChanges() {
    _throttledSync('planification', () async {
      final planifications = _objectBox.planificationBox.getAll();

      for (final planif in planifications) {
        final changeSignature =
            'Planification-${planif.id}-${planif.mois}-${planif.annee}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip Planification ${planif.id} (vient d\'un delta distant)');
          _notifyPlanificationListeners();
          continue;
        }

        await _deltaGenerator.syncPlanification(planif, 'update');
        print('[SyncObserver] 📤 Planification synchronisée: ${planif.id}');
      }

      _notifyPlanificationListeners();
    });
  }

  /// ✅ Gestion des changements PlanningHebdo
  void _handlePlanningHebdoChanges() {
    _throttledSync('planningHebdo', () async {
      final plannings = _objectBox.planningHebdoBox.getAll();

      for (final planning in plannings) {
        final changeSignature =
            'PlanningHebdo-${planning.id}-${planning.dimanche}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip PlanningHebdo ${planning.id} (vient d\'un delta distant)');
          continue;
        }

        await _deltaGenerator.syncPlanningHebdo(planning, 'update');
        print('[SyncObserver] 📤 PlanningHebdo synchronisé: ${planning.id}');
      }
    });
  }

  /// ✅ Gestion des changements TypeActivite
  void _handleTypeActiviteChanges() {
    _throttledSync('typeActivite', () async {
      final types = _objectBox.typeActiviteBox.getAll();

      for (final type in types) {
        final changeSignature = 'TypeActivite-${type.id}-${type.code}';

        if (_recentlyAppliedDeltas.contains(changeSignature)) {
          print(
              '[SyncObserver] ⭐ Skip TypeActivite ${type.id} (vient d\'un delta distant)');
          continue;
        }

        await _deltaGenerator.syncTypeActivite(type, 'update');
        print('[SyncObserver] 📤 TypeActivite synchronisé: ${type.code}');
      }
    });
  }

  // ========================================================================
  // ✅ NOUVEAU : MÉTHODES POUR NOTIFIER LES LISTENERS
  // ========================================================================

  void _notifyStaffListeners() {
    print(
        '[SyncObserver] 🔔 Notification de ${_onStaffChangedCallbacks.length} listeners Staff');
    for (final callback in _onStaffChangedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('[SyncObserver] ❌ Erreur callback Staff: $e');
      }
    }
  }

  void _notifyActiviteListeners() {
    print(
        '[SyncObserver] 🔔 Notification de ${_onActiviteChangedCallbacks.length} listeners Activité');
    for (final callback in _onActiviteChangedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('[SyncObserver] ❌ Erreur callback Activité: $e');
      }
    }
  }

  void _notifyBranchListeners() {
    for (final callback in _onBranchChangedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('[SyncObserver] ❌ Erreur callback Branch: $e');
      }
    }
  }

  void _notifyTimeOffListeners() {
    for (final callback in _onTimeOffChangedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('[SyncObserver] ❌ Erreur callback TimeOff: $e');
      }
    }
  }

  void _notifyPlanificationListeners() {
    for (final callback in _onPlanificationChangedCallbacks) {
      try {
        callback();
      } catch (e) {
        print('[SyncObserver] ❌ Erreur callback Planification: $e');
      }
    }
  }

  // ========================================================================
  // MÉTHODES UTILITAIRES
  // ========================================================================

  /// ✅ Throttle pour éviter trop de syncs rapides
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

  /// ✅ Marquer un delta comme récemment appliqué
  void markDeltaAsApplied(String entityType, Map<String, dynamic> data) {
    String signature = '';

    switch (entityType) {
      case 'Staff':
        signature = 'Staff-${data['id']}-${data['nom']}-${data['grade']}';
        break;
      case 'ActiviteJour':
        signature =
            'ActiviteJour-${data['id']}-${data['jour']}-${data['statut']}';
        break;
      case 'Branch':
        signature = 'Branch-${data['id']}-${data['branchNom']}';
        break;
      case 'TimeOff':
        signature = 'TimeOff-${data['id']}-${data['debut']}-${data['fin']}';
        break;
      case 'Planification':
        signature =
            'Planification-${data['id']}-${data['mois']}-${data['annee']}';
        break;
      case 'PlanningHebdo':
        signature = 'PlanningHebdo-${data['id']}-${data['dimanche']}';
        break;
      case 'TypeActivite':
        signature = 'TypeActivite-${data['id']}-${data['code']}';
        break;
    }

    _recentlyAppliedDeltas.add(signature);
    print('[SyncObserver] 🏷️ Delta marqué: $signature');

    // Nettoyer après 5 secondes
    Future.delayed(Duration(seconds: 5), () {
      _recentlyAppliedDeltas.remove(signature);
      print('[SyncObserver] 🧹 Delta signature nettoyée: $signature');
    });
  }

  /// ✅ Marquer qu'on applique un delta distant
  void setApplyingRemoteDelta(bool applying) {
    _isApplyingRemoteDelta = applying;
    if (applying) {
      print('[SyncObserver] 🔒 Mode application delta distant activé');
    } else {
      print('[SyncObserver] 🔓 Mode application delta distant désactivé');
    }
  }

  /// Statistiques de l'observer
  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'activeThrottles': _throttleTimers.length,
      'recentlyAppliedDeltas': _recentlyAppliedDeltas.length,
      'isApplyingRemote': _isApplyingRemoteDelta,
      'throttleDurationMs': throttleDuration.inMilliseconds,
      'staffListeners': _onStaffChangedCallbacks.length,
      'activiteListeners': _onActiviteChangedCallbacks.length,
    };
  }

  /// Nettoyer toutes les signatures trackées
  void clearAllTracking() {
    _recentlyAppliedDeltas.clear();
    print('[SyncObserver] 🧹 Tous les trackings nettoyés');
  }

  /// Nettoyer tous les callbacks
  void dispose() {
    _onStaffChangedCallbacks.clear();
    _onActiviteChangedCallbacks.clear();
    _onBranchChangedCallbacks.clear();
    _onTimeOffChangedCallbacks.clear();
    _onPlanificationChangedCallbacks.clear();
    stop();
  }
}
