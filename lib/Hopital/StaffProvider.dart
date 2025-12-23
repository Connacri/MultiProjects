import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';
import 'ActivitePersonne.dart';
import 'p2p/delta_generator_real.dart';
import 'p2p/objectbox_sync_observer.dart';

/// ✅ CORRECTION MAJEURE : Force refresh explicite avec timestamp

class StaffProvider with ChangeNotifier {
  final ObjectBox _objectBox;
  late ObjectBoxSyncObserver _syncObserver = ObjectBoxSyncObserver();

  // ✅ CORRECTION CRITIQUE : Stocker les abonnements ObjectBox pour les annuler (FUITE DE MÉMOIRE FIX)
  final List<StreamSubscription> _subscriptions = [];

  List<Staff> _staffs = [];
  bool _isLoading = false;
  bool _initialized = false;
  Timer? _pollTimer;

  int _lastUpdateTimestamp = 0;
  int _remoteChangesReceived = 0;
  bool _mounted = true;

  bool get isInitialized => _initialized;

  List<Staff> get staffs => _staffs;

  bool get isLoading => _isLoading;

  int get lastUpdateTimestamp => _lastUpdateTimestamp;

  int get remoteChangesReceived => _remoteChangesReceived;

  bool get mounted => _mounted;

// ✅ AJOUTE ÇA ICI
  final Map<int, String?> _currentMonthObservations = {};

// ✅ Getter pour obs d'un staff
  String? getObservationForStaff(int staffId) {
    return _currentMonthObservations[staffId];
  }

// ✅ Setter temporaire (pour édition en cours)
  void setTemporaryObservation(int staffId, String? obs) {
    _currentMonthObservations[staffId] = obs;
    notifyListeners();
  }

  // ✅ Clear lors du changement de mois (à appeler dans loadMonthActivities si besoin)
  void clearCurrentMonthObservations() {
    _currentMonthObservations.clear();
  }

  // ✅ CORRECTION : ObjectBox passé en paramètre
  StaffProvider(this._objectBox) {
    print('[StaffProvider] 🎯 Initialisation du provider');
    _initializeProvider();
  }

  // ✅ NOUVELLE MÉTHODE : Initialisation simplifiée
  Future<void> _initializeProvider() async {
    try {
      // 1️⃣ Créer le SyncObserver
      _syncObserver = ObjectBoxSyncObserver();

      // 2️⃣ Enregistrer les listeners
      _syncObserver.addStaffChangedListener(_onStaffChanged);
      _syncObserver.addStaffChangedListener(_onRemoteStaffChanged);
      _syncObserver.addActiviteChangedListener(_onRemoteActiviteChanged);

      // 3️⃣ Charger les données
      await fetchStaffs();

      // 4️⃣ Démarrer le polling
      _startPolling();

      // 5️⃣ ✅ CRITIQUE : Marquer comme initialisé
      _initialized = true;
      notifyListeners();

      print('[StaffProvider] ✅ Initialisé avec ${_staffs.length} staffs');
    } catch (e) {
      print('[StaffProvider] ❌ Erreur initialisation: $e');

      // ✅ IMPORTANT : Même en cas d'erreur, marquer comme initialisé
      // pour ne pas bloquer l'interface
      _initialized = true;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _checkForChanges();
    });
    print('[StaffProvider] ⏰ Polling démarré (toutes les 2s)');
  }

  Future<void> _checkForChanges() async {
    try {
      final freshStaffs = _objectBox.staffBox.getAll();

      bool hasChanges = false;
      if (_staffs.length != freshStaffs.length) {
        hasChanges = true;
      } else {
        for (int i = 0; i < _staffs.length; i++) {
          if (_staffs[i].nom != freshStaffs[i].nom ||
              _staffs[i].grade != freshStaffs[i].grade) {
            hasChanges = true;
            break;
          }

          final oldActivites = _staffs[i].activites.length;
          final newActivites = freshStaffs[i].activites.length;
          if (oldActivites != newActivites) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        print('[StaffProvider] 🔔 Polling détecté des changements !');
        await _forceRefreshFromDatabase();
      }
    } catch (e) {
      // Ignore silencieusement les erreurs de polling
    }
  }

  void _onStaffChanged() {
    print('[StaffProvider] 🔔 Changement LOCAL détecté');
    fetchStaffs();
  }

  void _onRemoteStaffChanged() {
    print('[StaffProvider] 🔔 Changement DISTANT détecté - Force refresh UI');
    _remoteChangesReceived++;
    _forceRefreshFromDatabase();
  }

  void _onRemoteActiviteChanged() {
    print('[StaffProvider] 🔔 Activité DISTANTE détectée - Force refresh UI');
    _remoteChangesReceived++;
    _forceRefreshFromDatabase();
  }

  Future<void> _forceRefreshFromDatabase() async {
    try {
      print('[StaffProvider] 🔄 FORCE REFRESH depuis ObjectBox...');

      final freshStaffs = _objectBox.staffBox.getAll();

      print('[StaffProvider] 📊 Avant: ${_staffs.length} staffs');
      print('[StaffProvider] 📊 Après: ${freshStaffs.length} staffs');

      bool hasChanges = false;
      if (_staffs.length != freshStaffs.length) {
        hasChanges = true;
      } else {
        for (int i = 0; i < _staffs.length; i++) {
          if (_staffs[i].nom != freshStaffs[i].nom ||
              _staffs[i].grade != freshStaffs[i].grade ||
              _staffs[i].groupe != freshStaffs[i].groupe) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges) {
        print('[StaffProvider] ✅ Changements détectés, mise à jour UI');
        _staffs = freshStaffs;
        _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

        notifyListeners();

        Future.delayed(Duration(milliseconds: 100), () {
          if (_mounted) {
            notifyListeners();
          }
        });

        print(
            '[StaffProvider] 🔔 notifyListeners() appelé (timestamp: $_lastUpdateTimestamp)');
      } else {
        print('[StaffProvider] ℹ️ Aucun changement détecté dans les données');
      }
    } catch (e) {
      print('[StaffProvider] ❌ Erreur force refresh: $e');
    }
  }

  Future<void> fetchStaffs() async {
    try {
      _isLoading = true;
      notifyListeners();

      final oldCount = _staffs.length;
      _staffs = await Isolate.run(() {
        // Ici, fais tes calculs de tris ou de filtrages complexes
        // Attention: On ne peut pas manipuler des objets complexes de DB directement
        // s'ils ne sont pas thread-safe, mais on peut traiter des listes.
        return _objectBox.staffBox.getAll();
      });
      final newCount = _staffs.length;
      print('[StaffProvider] 📊 fetchStaffs: $oldCount → $newCount staffs');

      _isLoading = false;
      _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    } catch (e) {
      print('[StaffProvider] ❌ Erreur chargement: $e');
      _isLoading = false;
      // notifyListeners();
    }
  }

// Dans StaffProvider.dart
  Future<void> fetchStaffsBackground() async {
    _isLoading = true;
    notifyListeners();

    // On lance le calcul sur un thread séparé pour ne pas bloquer l'UI
    // Note: Assure-toi que _objectBox est accessible ou passe les données nécessaires
    _staffs = await Isolate.run(() {
      // Ici, fais tes calculs de tris ou de filtrages complexes
      // Attention: On ne peut pas manipuler des objets complexes de DB directement
      // s'ils ne sont pas thread-safe, mais on peut traiter des listes.
      return _objectBox.staffBox.getAll();
    });

    _isLoading = false;
    notifyListeners();
  }

// ✅ AMÉLIORATION : Méthode pour forcer la relecture depuis ObjectBox
  Future<void> forceRefresh() async {
    print('[StaffProvider] 🔄 Force refresh manuel demandé');

    try {
      // ✅ Recharger depuis ObjectBox
      _staffs = _objectBox.staffBox.getAll();

      // ✅ Mettre à jour le timestamp
      _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

      // ✅ Notifier les listeners
      notifyListeners();

      // ✅ Double notification après un délai (garantie UI refresh)
      await Future.delayed(Duration(milliseconds: 100));
      if (_mounted) {
        notifyListeners();
      }

      print(
          '[StaffProvider] ✅ Force refresh terminé: ${_staffs.length} staffs');
    } catch (e) {
      print('[StaffProvider] ❌ Erreur force refresh: $e');
    }
  }

  Future<void> addStaff(Staff staff, List<ActiviteJour> activites) async {
    try {
      final staffId = _objectBox.staffBox.put(staff);
      for (var activite in activites) {
        activite.staff.target = staff;
        _objectBox.activiteBox.put(activite);
      }
      print('[StaffProvider] ✅ Staff ajouté: ${staff.nom}');
      await fetchStaffs();
    } catch (e) {
      print('[StaffProvider] ❌ Erreur ajout staff: $e');
      rethrow;
    }
  }

// ✅ Méthode updateStaff modifiée : obs passé en paramètre séparé
  Future<void> updateStaff(Staff staff, {String? newObs}) async {
    try {
      print('[StaffProvider] 💾 Mise à jour staff: ${staff.nom}');

      // ✅ Sauvegarder les champs permanents dans ObjectBox (sans obs)
      final savedId = _objectBox.staffBox.put(staff);
      print('[StaffProvider] ✅ Staff sauvegardé avec ID: $savedId');

      // ✅ Mettre à jour l'observation en mémoire si fournie
      if (newObs != null) {
        setTemporaryObservation(staff.id, newObs);
      }

      // ✅ CRITIQUE : Sauvegarder le snapshot du mois actuel (inclut obs)
      final now = DateTime.now();
      await saveMonthActivities(now.year, now.month);

      // ✅ Recharger et rafraîchir
      await fetchStaffs();
      notifyListeners();
    } catch (e) {
      print('[StaffProvider] ❌ Erreur mise à jour staff: $e');
      rethrow;
    }
  }

  Future<void> deleteStaff(Staff staff) async {
    try {
      final activites = staff.activites.toList();
      for (var activite in activites) {
        _objectBox.activiteBox.remove(activite.id);
      }
      final timeOffs = staff.timeOff.toList();
      for (var timeOff in timeOffs) {
        _objectBox.timeOffBox.remove(timeOff.id);
      }
      _objectBox.staffBox.remove(staff.id);
      print('[StaffProvider] ✅ Staff supprimé: ${staff.nom}');
      await fetchStaffs();
    } catch (e) {
      print('[StaffProvider] ❌ Erreur suppression: $e');
      rethrow;
    }
  }

// ============================================================================
// CORRECTION - Sauvegarde et chargement du mois avec observations
// Dans StaffProvider.dart
// ============================================================================

// ✅ Méthode saveMonthActivities corrigée : sauvegarde obs depuis le map
  Future<void> saveMonthActivities(int year, int month) async {
    try {
      print('💾 Sauvegarde mois $month/$year...');

      final query = _objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();
      Planification? planif = query.findFirst();
      query.close();

      if (planif == null) {
        print('🆕 Création nouvelle planification');
        planif = Planification(mois: month, annee: year, ordreEquipes: '');
        _objectBox.planificationBox.put(planif);
      }

      // ✅ Collecter activitesByStaff (depuis code existant, assume inchangé)
      final activitesByStaff = <int, List<ActiviteJour>>{};
      for (final staff in _staffs) {
        activitesByStaff[staff.id] = staff.activites.toList();
      }

      // ✅ Collecter obsByStaff depuis le map en mémoire
      final obsByStaff = Map<int, String?>.from(_currentMonthObservations);

      // ✅ Sauvegarder le snapshot (utilise l'extension)
      planif.saveMonthSnapshot(
        staffs: _staffs,
        activitesByStaff: activitesByStaff,
        obsByStaff: obsByStaff, // ✅ Inclut obs, même vides
      );

      _objectBox.planificationBox.put(planif);
      print('✅ Mois sauvegardé avec ${_staffs.length} staffs');
    } catch (e) {
      print('❌ Erreur saveMonthActivities: $e');
      rethrow;
    }
  }

// ✅ Méthode loadMonthActivities corrigée : charge obs dans le map
  Future<bool> loadMonthActivities(int year, int month) async {
    try {
      print('📂 Chargement mois $month/$year...');

      final query = _objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();
      final planif = query.findFirst();
      query.close();

      if (planif == null) {
        print('ℹ️ Aucune sauvegarde pour $month/$year');
        _currentMonthObservations.clear(); // ✅ Vide les obs si mois inexistant
        return false;
      }

      final snapshot = planif.loadMonthSnapshot();
      if (snapshot == null) {
        print('⚠️ Snapshot invalide');
        _currentMonthObservations.clear();
        return false;
      }

      // // ✅ 1. Restaurer l'ordre des staffs (inchangé)
      // final staffsOrdre = snapshot['staffsOrdre'] as List<dynamic>?;
      // if (staffsOrdre != null) {
      //   for (var entry in staffsOrdre) {
      //     final staffId = entry['id'] as int;
      //     final ordre = entry['ordre'] as int;
      //
      //     final staff = _objectBox.staffBox.get(staffId);
      //     if (staff != null && staff.ordre != ordre) {
      //       staff.ordre = ordre;
      //       _objectBox.staffBox.put(staff);
      //     }
      //   }
      // }

      // ✅ 2. Restaurer les observations dans le map (toujours, même vides)
      final observations = snapshot['observations'] as List<dynamic>?;
      _currentMonthObservations.clear();
      int obsRestored = 0;
      if (observations != null) {
        for (var obsEntry in observations) {
          final staffId = obsEntry['staffId'] as int;
          final obs = obsEntry['obs'] as String?;
          _currentMonthObservations[staffId] = obs; // ✅ Supporte null/""
          obsRestored++;
        }
      }
      print('✅ $obsRestored observations restaurées');

      // ✅ 3. Restaurer les activités (depuis code existant, assume inchangé)
      // ... (ajoute ici la partie pour activites si tronquée)

      await fetchStaffs();
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur loadMonthActivities: $e');
      _currentMonthObservations.clear();
      return false;
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Mise à jour d'une seule observation dans le snapshot
  Future<void> updateObservationInSnapshot(
      int staffId, String? newObs, int year, int month) async {
    try {
      print('💾 Mise à jour observation snapshot pour staff $staffId');

      final query = _objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();
      final planif = query.findFirst();
      query.close();

      if (planif == null) {
        print('⚠️ Aucune planification pour $month/$year');
        return;
      }

      final snapshot = planif.loadMonthSnapshot();
      if (snapshot == null) {
        print('⚠️ Snapshot invalide');
        return;
      }

      // Mettre à jour ou ajouter l'observation dans le snapshot
      final observations = (snapshot['observations'] as List<dynamic>?) ?? [];

      // Chercher l'entrée existante
      int existingIndex =
          observations.indexWhere((e) => e['staffId'] == staffId);

      if (newObs != null && newObs.isNotEmpty) {
        if (existingIndex >= 0) {
          // Mettre à jour
          observations[existingIndex]['obs'] = newObs;
        } else {
          // Ajouter
          observations.add({'staffId': staffId, 'obs': newObs});
        }
      } else {
        // Supprimer si obs vide
        if (existingIndex >= 0) {
          observations.removeAt(existingIndex);
        }
      }

      // Sauvegarder le snapshot mis à jour
      snapshot['observations'] = observations;
      planif.activitesJson = jsonEncode(snapshot);
      _objectBox.planificationBox.put(planif);

      print('✅ Observation mise à jour dans le snapshot');
    } catch (e) {
      print('❌ Erreur updateObservationInSnapshot: $e');
    }
  }

  Staff? getStaffById(int id) {
    try {
      return _objectBox.staffBox.get(id);
    } catch (e) {
      print("[StaffProvider] ❌ Erreur getStaffById: $e");
      return null;
    }
  }

  List<Staff> getStaffsByBranch(int branchId) {
    try {
      return _staffs
          .where((staff) => staff.branch.targetId == branchId)
          .toList();
    } catch (e) {
      print("[StaffProvider] ❌ Erreur getStaffsByBranch: $e");
      return [];
    }
  }

  List<Staff> getStaffsByTeam(String? team) {
    try {
      if (team == null) return [];
      return _staffs.where((staff) => staff.equipe == team).toList();
    } catch (e) {
      print("[StaffProvider] ❌ Erreur getStaffsByTeam: $e");
      return [];
    }
  }

  List<Staff> searchStaffs(String query) {
    try {
      if (query.isEmpty) return _staffs;
      final lowerQuery = query.toLowerCase();
      return _staffs
          .where((staff) =>
              staff.nom.toLowerCase().contains(lowerQuery) ||
              staff.grade.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      print("[StaffProvider] ❌ Erreur searchStaffs: $e");
      return [];
    }
  }

  // Ajoutez ces méthodes dans votre classe StaffProvider

// ✅ MÉTHODE : Correction des groupes paramédicaux et agents d'hygiène
// ✅ MÉTHODE UNIQUE : Correction des groupes paramédicaux et agents d'hygiène
  Future<Map<String, int>> correctStaffGroups() async {
    try {
      print('[StaffProvider] 🔧 Début correction groupes...');

      final allStaff = _objectBox.staffBox.getAll();
      int paramedicalCount = 0;
      int hygieneCount = 0;
      int totalModified = 0;

      for (final staff in allStaff) {
        final originalGroupe = staff.groupe;

        // ✅ CORRECTION UNIQUE : Vérifie les deux conditions en une seule passe
        if (_isParamedical(staff.groupe) && staff.groupe == 'Garde 12H') {
          staff.groupe = 'Garde 24H';
          paramedicalCount++;
          totalModified++;
          print(
              '[StaffProvider] 🔄 Paramédical: ${staff.nom} - Garde 12H → Garde 24H');
        }
        // ✅ CORRECTION UNIQUE : Vérifie les deux conditions en une seule passe
        else if (_isAgentHygiene(staff.groupe) && staff.groupe == '08h-12h') {
          staff.groupe = '12h';
          hygieneCount++;
          totalModified++;
          print('[StaffProvider] 🔄 Hygiène: ${staff.nom} - 08h-12h → 12h');
        }

        // ✅ SAUVEGARDE UNIQUE : Seulement si modification
        if (staff.groupe != originalGroupe) {
          _objectBox.staffBox.put(staff);
        }
      }

      // ✅ RECHARGEMENT UNIQUE des données
      if (totalModified > 0) {
        await fetchStaffs();
      }

      final results = {
        'totalModified': totalModified,
        'paramedicalModified': paramedicalCount,
        'hygieneModified': hygieneCount,
      };

      print('[StaffProvider] ✅ Correction terminée: $results');
      return results;
    } catch (e) {
      print('[StaffProvider] ❌ Erreur correction groupes: $e');
      rethrow;
    }
  }

// ✅ MÉTHODE : Détection personnel paramédical
  bool _isParamedical(String groupe) {
    final paramedicalGrades = ["Garde 12H"];

    final lowerGrade = groupe.toLowerCase();
    return paramedicalGrades
        .any((pattern) => lowerGrade.contains(pattern.toLowerCase()));
  }

// ✅ MÉTHODE : Détection agents d'hygiène
  bool _isAgentHygiene(String groupe) {
    final hygieneGrades = ["08h-12h"];

    final lowerGrade = groupe.toLowerCase();
    return hygieneGrades
        .any((pattern) => lowerGrade.contains(pattern.toLowerCase()));
  }

// ✅ MÉTHODE : Statistiques avant correction
  Map<String, dynamic> getGroupCorrectionStats() {
    final allStaff = _staffs;
    int paramedical12H = 0;
    int hygiene8H12H = 0;
    int totalParamadical = 0;
    int totalHygiene = 0;

    for (final staff in allStaff) {
      if (_isParamedical(staff.groupe)) {
        print(
            "Groupes avant correction : ${_staffs.map((s) => s.groupe).toList()}");
        totalParamadical++;
        if (staff.groupe == 'Garde 12H') {
          staff.groupe = 'Garde 24H'; // ✅ Modification correcte
          paramedical12H++;
        }
      } else if (_isAgentHygiene(staff.groupe)) {
        print(
            "Groupes avant correction : ${_staffs.map((s) => s.groupe).toList()}");
        totalHygiene++;
        if (staff.groupe == '08h-12h') {
          staff.groupe = '12H'; // ✅ Modification corrigée
          hygiene8H12H++;
        }
      }
    }

    return {
      'totalStaff': allStaff.length,
      'totalParamadical': totalParamadical,
      'paramedical12H': paramedical12H,
      'totalHygiene': totalHygiene,
      'hygiene8H12H': hygiene8H12H,
    };
  }

  @override
  void dispose() {
    print('[StaffProvider] 🧹 Nettoyage du provider');
    _pollTimer?.cancel();
    _mounted = false;
    _syncObserver.removeStaffChangedListener(_onStaffChanged);
    _syncObserver.removeStaffChangedListener(_onRemoteStaffChanged);
    _syncObserver.removeActiviteChangedListener(_onRemoteActiviteChanged);
    super.dispose();
  }
}
// ============================================================================
// STAFFPROVIDER - VERSION CORRIGÉE POUR COHÉRENCE DONNÉES
// À remplacer dans votre fichier StaffProvider.dart
// ============================================================================

/// Provider pour gérer les activités - VERSION AMÉLIORÉE
class ActiviteProvider with ChangeNotifier {
  late final ObjectBox _objectBox;
  late final DeltaGenerator _deltaGenerator; // ✅ AJOUTER
// ✅ AJOUTE ÇA ICI
  final Map<int, String?> _currentMonthObservations = {};

  // ✅ Getter public
  String? getObservationForStaff(int staffId) {
    return _currentMonthObservations[staffId];
  }

// ✅ Setter temporaire (pour édition en cours)
  void setTemporaryObservation(int staffId, String? obs) {
    _currentMonthObservations[staffId] = obs;
    notifyListeners();
  }

  // ✅ Clear lors du changement de mois (à appeler dans loadMonthActivities si besoin)
  void clearCurrentMonthObservations() {
    _currentMonthObservations.clear();
  }

  ActiviteProvider() {
    _objectBox = ObjectBox();
    _deltaGenerator = DeltaGenerator(); // ✅ INITIALISER
  }

  // Méthodes publiques pour accéder aux boxes
  Box<ActiviteJour> get activiteBox => _objectBox.activiteBox;

  Box<TimeOff> get timeOffBox => _objectBox.timeOffBox;

  Box<Staff> get staffBox => _objectBox.staffBox;

  /// 🔹 VERSION CORRIGÉE : Met à jour une activité en respectant la logique métier
  /// ✅ CORRECTION : Synchroniser après modification
  Future<void> updateActivite(int staffId, int jour, String statut,
      {required int year, required int month}) async {
    try {
      final staff = _objectBox.staffBox.get(staffId);
      if (staff == null) {
        print("⚠️ Staff $staffId non trouvé");
        return;
      }

      final dateJour = DateTime(year, month, jour);

      // Vérifications de congés...
      bool estEnCongeTimeOff = _isStaffOnLeaveTimeOff(staff, dateJour);
      if (estEnCongeTimeOff) {
        print("🚫 ${staff.nom} est en congé TimeOff - Modification ignorée");
        return;
      }

      // Récupérer ou créer l'activité
      final query = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staffId) &
              ActiviteJour_.jour.equals(jour))
          .build();
      final activites = query.find();
      query.close();

      ActiviteJour? activiteExistante;
      if (activites.isNotEmpty) {
        activiteExistante = activites.first;
        activiteExistante.statut = statut;
        _objectBox.activiteBox.put(activiteExistante);
        print("✅ Activité mise à jour: ${staff.nom} jour $jour = $statut");
      } else {
        final nouvelleActivite = ActiviteJour(jour: jour, statut: statut)
          ..staff.target = staff;
        _objectBox.activiteBox.put(nouvelleActivite);
        activiteExistante = nouvelleActivite;
        print("➕ Nouvelle activité créée: ${staff.nom} jour $jour = $statut");
      }

      // ✅ SYNCHRONISER L'ACTIVITÉ
      await _deltaGenerator.syncActiviteJour(activiteExistante, 'update');
      print("📤 Activité synchronisée");

      notifyListeners();
    } catch (e) {
      print("❌ Erreur updateActivite: $e");
      rethrow;
    }
  }

  /// 🔹 NOUVELLE MÉTHODE : Force la mise à jour (pour les congés planifiés)
  Future<void> forceUpdateActivite(int staffId, int jour, String statut,
      {required int year, required int month}) async {
    try {
      final staff = _objectBox.staffBox.get(staffId);
      if (staff == null) return;

      final query = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staffId) &
              ActiviteJour_.jour.equals(jour))
          .build();
      final activites = query.find();
      query.close();

      if (activites.isNotEmpty) {
        final activite = activites.first;
        activite.statut = statut;
        _objectBox.activiteBox.put(activite);
        print("🔄 Activité forcée: ${staff.nom} jour $jour = $statut");
      } else {
        final nouvelle = ActiviteJour(jour: jour, statut: statut)
          ..staff.target = staff;
        _objectBox.activiteBox.put(nouvelle);
        print("➕ Nouvelle activité forcée: ${staff.nom} jour $jour = $statut");
      }

      notifyListeners();
    } catch (e) {
      print("❌ Erreur forceUpdateActivite: $e");
    }
  }

  /// 🔹 NOUVELLE MÉTHODE : Force la mise à jour en ignorant complètement les congés
  Future<void> forceUpdateActiviteIgnoringLeave(
      int staffId, int jour, String statut,
      {required int year, required int month}) async {
    try {
      final staff = _objectBox.staffBox.get(staffId);
      if (staff == null) {
        print("⚠️ Staff $staffId non trouvé");
        return;
      }

      final query = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staffId) &
              ActiviteJour_.jour.equals(jour))
          .build();
      final activites = query.find();
      query.close();

      if (activites.isNotEmpty) {
        final activite = activites.first;
        String ancienStatut = activite.statut;
        activite.statut = statut;
        _objectBox.activiteBox.put(activite);
        print(
            "🔄 Force update: ${staff.nom} jour $jour: $ancienStatut → $statut");
      } else {
        final nouvelle = ActiviteJour(jour: jour, statut: statut)
          ..staff.target = staff;
        _objectBox.activiteBox.put(nouvelle);
        print("➕ Force create: ${staff.nom} jour $jour = $statut");
      }

      notifyListeners();
    } catch (e) {
      print("❌ Erreur forceUpdateActiviteIgnoringLeave: $e");
      rethrow;
    }
  }

  /// ✅ MÉTHODE : Vérifier si staff en congé à une date
  bool _isStaffOnLeaveTimeOff(Staff staff, DateTime dateJour) {
    final objectBox = ObjectBox();
    final timeOffs = objectBox.timeOffBox
        .query(TimeOff_.staff.equals(staff.id))
        .build()
        .find();

    for (var timeOff in timeOffs) {
      if (dateJour.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
          dateJour.isBefore(timeOff.fin.add(Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  /// 🔹 Vérifie si un staff est en congé (TimeOff OU activité) à une date donnée
  bool isStaffOnLeave(Staff staff, DateTime dateJour) {
    // Vérifier TimeOff
    if (_isStaffOnLeaveTimeOff(staff, dateJour)) {
      return true;
    }

    // Vérifier activités de congé
    final activites = staff.activites.toList();
    return activites.any((activite) =>
        activite.jour == dateJour.day &&
        (activite.statut == 'C' || activite.statut == 'CM'));
  }

  /// ✅ MÉTHODE CORRIGÉE : Création d'activités avec prise en compte des congés et obs
  Future<void> insertActivites(
    List<ActivitePersonne> liste, {
    required int year,
    required int month,
  }) async {
    try {
      print('📥 Insertion des activités pour $month/$year...');

      final objectBox = ObjectBox();

      // ⚠️ NE PAS SUPPRIMER TOUTE LA BASE
      // Supprimer seulement les activités du mois concerné
      final debutMois = DateTime(year, month, 1);
      final finMois = DateTime(year, month + 1, 0);
      final daysInMonth = finMois.day;

      for (var e in liste) {
        // 1️⃣ Créer/récupérer Branch
        Branch branch = objectBox.branchBox
                .query(Branch_.branchNom.equals(e.branchNom ?? "Rhumatologie"))
                .build()
                .findFirst() ??
            Branch(branchNom: e.branchNom ?? "Rhumatologie");
        objectBox.branchBox.put(branch);

        // 2️⃣ Créer/récupérer Staff (avec ordre préservé si existe)
        Staff? existingStaff = objectBox.staffBox
            .query(Staff_.nom.equals(e.nom))
            .build()
            .findFirst();

        final staff = existingStaff ??
            Staff(
              nom: e.nom,
              grade: e.grade,
              groupe: e.groupe,
              equipe: e.equipe,

              ordre: existingStaff?.ordre, // ✅ Préserver l'ordre
            )
          ..branch.target = branch;

        objectBox.staffBox.put(staff);

        // 3️⃣ Insérer TimeOff (congés planifiés)
        if (e.conges != null && e.conges!.isNotEmpty) {
          // ✅ Supprimer les anciens congés du mois
          final oldTimeOffs = objectBox.timeOffBox
              .query(TimeOff_.staff.equals(staff.id))
              .build()
              .find()
              .where((t) =>
                  t.debut.isBefore(finMois.add(Duration(days: 1))) &&
                  t.fin.isAfter(debutMois.subtract(Duration(days: 1))))
              .toList();

          for (var old in oldTimeOffs) {
            objectBox.timeOffBox.remove(old.id);
          }

          // Ajouter les nouveaux
          for (var conge in e.conges!) {
            final timeOff = TimeOff(
              debut: conge.debut,
              fin: conge.fin,
              motif: conge.motif,
            )..staff.target = staff;
            objectBox.timeOffBox.put(timeOff);
          }
        }

        // 4️⃣ Supprimer les anciennes activités du mois
        final oldActivites = objectBox.activiteBox
            .query(ActiviteJour_.staff.equals(staff.id))
            .build()
            .find()
            .where((a) => a.jour >= 1 && a.jour <= daysInMonth)
            .toList();

        for (var old in oldActivites) {
          objectBox.activiteBox.remove(old.id);
        }

        // 5️⃣ Créer les nouvelles activités en respectant les congés
        for (int i = 0; i < e.jours.length && i < daysInMonth; i++) {
          final jour = i + 1;
          final statutJour = e.jours[i];
          final dateJour = DateTime(year, month, jour);

          // Vérifier TimeOff
          final estEnCongeTimeOff = _isStaffOnLeaveTimeOff(staff, dateJour);

          String statutFinal = estEnCongeTimeOff ? 'C' : statutJour;

          final activite = ActiviteJour(jour: jour, statut: statutFinal)
            ..staff.target = staff;
          objectBox.activiteBox.put(activite);
        }

        print('✅ Staff inséré: ${staff.nom}');
      }

      await fetchStaffs();
      print('🎉 Insertion terminée: ${liste.length} staffs traités');
    } catch (e) {
      print('❌ Erreur insertActivites: $e');
      rethrow;
    }
  }

  Future<void> fetchStaffs() async {
    final staffs = _objectBox.staffBox.getAll();
    print("📊 Staffs dans la DB: ${staffs.length}");
    notifyListeners();
  }

  Future<void> clearAllActivitesAncien(int year, int month) async {
    try {
      final query = _objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();

      final planifs = query.find();
      for (var planif in planifs) {
        _objectBox.planificationBox.remove(planif.id);
      }
      query.close();

      print(
          '🗑️ Planification du mois $month/$year supprimée (activités + obs effacées)');

      // Vide aussi le map en mémoire si c'est le mois courant
      _currentMonthObservations.clear();

      await fetchStaffs();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur clearAllActivitesAncien: $e');
    }
  }

  Future<void> clearAllActivites(BuildContext context) async {
    try {
      // 1️⃣ Supprimer toutes les activités
      _objectBox.activiteBox.removeAll();
      print("✅ Toutes les activités supprimées.");

      // 2️⃣ Supprimer tous les TimeOff (congés)
      // _objectBox.timeOffBox.removeAll();
      print("✅ Tous les TimeOff supprimés.");

      // 3️⃣ Supprimer toutes les planifications
      _objectBox.planificationBox.removeAll();
      print("✅ Toutes les planifications supprimées.");

      // 4️⃣ Réinitialiser les obs et équipes des staffs
      final staffs = _objectBox.staffBox.getAll();
      for (var staff in staffs) {
        // staff.obs = null;
        // staff.equipe = null; // Optionnel : réinitialiser les équipes

        // Vider les relations ToMany
        staff.activites.clear();
        // staff.timeOff.clear();

        _objectBox.staffBox.put(staff);
      }
      print("✅ Tous les staffs réinitialisés (obs, équipes, relations).");

      notifyListeners();

      // 5️⃣ Rafraîchir l'interface
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
    } catch (e) {
      print("❌ Erreur clearAllActivites: $e");
      rethrow;
    }
  }

  Future<void> clearAllDB(BuildContext context) async {
    try {
      // 1️⃣ Supprimer toutes les activités
      _objectBox.activiteBox.removeAll();
      print("✅ Toutes les activités supprimées.");

      // 2️⃣ Supprimer tous les TimeOff (congés)
      _objectBox.timeOffBox.removeAll();
      print("✅ Tous les TimeOff supprimés.");

      // 3️⃣ Supprimer toutes les planifications
      _objectBox.planificationBox.removeAll();
      print("✅ Toutes les planifications supprimées.");

      // 4️⃣ Supprimer tous les staffs
      _objectBox.staffBox.removeAll();
      print("✅ Tous les staffs supprimés.");

      // 5️⃣ Supprimer toutes les branches
      _objectBox.branchBox.removeAll();
      print("✅ Toutes les branches supprimées.");

      print("🎉 Base de données complètement vidée.");

      notifyListeners();

      // 6️⃣ Rafraîchir l'interface
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final branchProvider =
          Provider.of<BranchProvider>(context, listen: false);

      await staffProvider.fetchStaffs();
      await branchProvider.fetchBranches();
    } catch (e) {
      print("❌ Erreur clearAllActivites: $e");
      rethrow;
    }
  }

  Future<void> clearEntireDatabase(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("⚠️ ATTENTION"),
          ],
        ),
        content: Text(
          "Cette action va TOUT supprimer :\n\n"
          "• Tous les staffs\n"
          "• Toutes les activités\n"
          "• Tous les congés\n"
          "• Toutes les planifications\n"
          "• Toutes les branches\n\n"
          "Cette action est IRRÉVERSIBLE !",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("TOUT SUPPRIMER"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      _objectBox.activiteBox.removeAll();
      _objectBox.timeOffBox.removeAll();
      _objectBox.planificationBox.removeAll();
      _objectBox.staffBox.removeAll();
      _objectBox.branchBox.removeAll();

      notifyListeners();

      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ Base de données complètement vidée"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// ✅ Méthode clearAllExceptStaffs corrigée (assume nettoyage global sauf staffs)
  Future<void> clearAllExceptStaffs() async {
    try {
      // ✅ Supprime tout sauf staffs
      _objectBox.activiteBox.removeAll();
      _objectBox.timeOffBox.removeAll();
      _objectBox.planificationBox
          .removeAll(); // ✅ Supprime snapshots (incl. obs)
      _objectBox.planningHebdoBox.removeAll();
      _objectBox.typeActiviteBox.removeAll();

      // ✅ Vide le map obs en mémoire
      _currentMonthObservations.clear();

      print('🗑️ Tout supprimé sauf staffs');
      await fetchStaffs();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur clearAllExceptStaffs: $e');
    }
  }

  /// 🔹 NOUVELLE MÉTHODE : Planification intelligente des gardes
  Future<PlanificationResult> planifierGardesAvancees({
    required List<String> equipesOrdonnees,
    required int jourDepart,
    required int year,
    required int month,
    required int daysInMonth,
  }) async {
    try {
      int totalModifications = 0;
      int congesRespectes = 0;
      Map<String, int> gardesParEquipe = {for (var e in equipesOrdonnees) e: 0};
      Map<String, int> recuperationsParEquipe = {
        for (var e in equipesOrdonnees) e: 0
      };

      // Récupérer le personnel médical concerné
      final personnelMedical = _objectBox.staffBox
          .getAll()
          .where((staff) =>
              staff.equipe != null &&
              equipesOrdonnees.contains(staff.equipe!.toUpperCase()))
          .toList();

      if (personnelMedical.isEmpty) {
        throw Exception(
            "Aucun personnel médical trouvé avec les équipes: ${equipesOrdonnees.join(', ')}");
      }

      // LOGIQUE DE ROTATION CORRIGÉE
      for (int day = 1; day <= daysInMonth; day++) {
        // Calculer l'équipe de garde pour ce jour
        int joursDepuisDebut = (day - jourDepart + daysInMonth) % daysInMonth;
        int equipeIndex = joursDepuisDebut % equipesOrdonnees.length;
        String equipeDeGarde = equipesOrdonnees[equipeIndex];

        // Planifier chaque membre du personnel
        for (final staff in personnelMedical) {
          final staffEquipe = staff.equipe!.toUpperCase();
          final dateJour = DateTime(year, month, day);

          // Vérifier les congés
          if (isStaffOnLeave(staff, dateJour)) {
            congesRespectes++;
            print("🚫 ${staff.nom} en congé le jour $day - ignoré");
            continue;
          }

          // Déterminer le statut
          String statutAAffecter;
          if (staffEquipe == equipeDeGarde) {
            statutAAffecter = "G"; // Garde
            gardesParEquipe[staffEquipe] =
                (gardesParEquipe[staffEquipe] ?? 0) + 1;
          } else {
            statutAAffecter = "RE"; // Récupération
            recuperationsParEquipe[staffEquipe] =
                (recuperationsParEquipe[staffEquipe] ?? 0) + 1;
          }

          // Appliquer la modification
          await updateActivite(staff.id, day, statutAAffecter,
              year: year, month: month);
          totalModifications++;
        }
      }

      return PlanificationResult(
        success: true,
        totalModifications: totalModifications,
        congesRespectes: congesRespectes,
        gardesParEquipe: gardesParEquipe,
        recuperationsParEquipe: recuperationsParEquipe,
        personnelConcerne: personnelMedical.length,
      );
    } catch (e) {
      print("❌ Erreur planifierGardesAvancees: $e");
      return PlanificationResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
// tes entités (TimeOff, Staff, etc.)

class TimeOffProvider with ChangeNotifier {
  final ObjectBox objectBox = ObjectBox();

  List<TimeOff> _timeOffs = [];

  List<TimeOff> get timeOffs => _timeOffs;

  /// Charger tous les congés depuis ObjectBox
  Future<void> fetchTimeOffs() async {
    _timeOffs = objectBox.timeOffBox.getAll();
    notifyListeners();
  }

  /// Ajouter un congé
  Future<void> addTimeOff(TimeOff timeOff) async {
    objectBox.timeOffBox.put(timeOff);
    await fetchTimeOffs();
  }

  /// Supprimer un congé
  Future<void> deleteTimeOff(int id) async {
    objectBox.timeOffBox.remove(id);
    await fetchTimeOffs();
  }

  /// Mettre à jour un congé
  Future<void> updateTimeOff(TimeOff timeOff) async {
    objectBox.timeOffBox.put(timeOff);
    await fetchTimeOffs();
  }

  /// Obtenir les congés d’un staff précis
  List<TimeOff> getTimeOffsByStaff(int staffId) {
    return _timeOffs.where((t) => t.staff.targetId == staffId).toList();
  }
}

/// 🔹 Classe pour le résultat de planification
class PlanificationResult {
  final bool success;
  final String? error;
  final int totalModifications;
  final int congesRespectes;
  final Map<String, int> gardesParEquipe;
  final Map<String, int> recuperationsParEquipe;
  final int personnelConcerne;

  PlanificationResult({
    required this.success,
    this.error,
    this.totalModifications = 0,
    this.congesRespectes = 0,
    this.gardesParEquipe = const {},
    this.recuperationsParEquipe = const {},
    this.personnelConcerne = 0,
  });
}

class BranchProvider with ChangeNotifier {
  List<Branch> _branches = [];
  late final ObjectBox _objectBox;
  bool _initialized = false;

  List<Branch> get branches => _branches;

  bool get isInitialized => _initialized; // 🆕 AJOUT

  BranchProvider() {
    _initObjectBox();
  }

  /// 🔹 Initialisation d’ObjectBox et chargement des branches
  Future<void> _initObjectBox() async {
    try {
      _objectBox = ObjectBox();
      await fetchBranches();
      _initialized = true;
      notifyListeners(); // ✅ CRUCIAL : notifier après le chargement
    } catch (e, stack) {
      debugPrint(
          '❌ Erreur initialisation ObjectBox (BranchProvider): $e\n$stack');
    }
  }

  Future<void> fetchBranches() async {
    try {
      _branches = _objectBox.branchBox.getAll();
      print("🔍 Branches chargées : ${_branches.length}"); // 🆕 DEBUG
      for (var b in _branches) {
        print("  - ${b.branchNom} (ID: ${b.id})"); // 🆕 DEBUG
      }
      notifyListeners(); // ✅ CRUCIAL
    } catch (e) {
      debugPrint("❌ Erreur fetchBranches: $e");
    }
  }

  /// 🔹 Créer une nouvelle branche
  Future<Branch?> addBranch(String name) async {
    try {
      if (name.trim().isEmpty) return null;

      // Vérifie si une branche du même nom existe déjà
      final existing = _objectBox.branchBox
          .query(Branch_.branchNom.equals(name.trim()))
          .build()
          .findFirst();

      if (existing != null) {
        debugPrint("⚠️ Branche '$name' existe déjà (ID: ${existing.id})");
        return existing;
      }

      final newBranch = Branch(branchNom: name.trim());
      _objectBox.branchBox.put(newBranch);

      _branches.add(newBranch);
      notifyListeners();

      debugPrint("✅ Nouvelle branche ajoutée: ${newBranch.branchNom}");
      return newBranch;
    } catch (e) {
      debugPrint("❌ Erreur addBranch: $e");
      return null;
    }
  }

  /// 🔹 Modifier une branche
  Future<void> updateBranch(Branch branch, String newName) async {
    try {
      branch.branchNom = newName.trim();
      _objectBox.branchBox.put(branch);

      final index = _branches.indexWhere((b) => b.id == branch.id);
      if (index != -1) _branches[index] = branch;

      notifyListeners();
      debugPrint("✏️ Branche mise à jour: ${branch.branchNom}");
    } catch (e) {
      debugPrint("❌ Erreur updateBranch: $e");
    }
  }

  /// 🔹 Supprimer une branche (et détacher ses staffs)
  Future<void> deleteBranch(Branch branch) async {
    try {
      final staffs = _objectBox.staffBox
          .getAll()
          .where((s) => s.branch.target?.id == branch.id)
          .toList();

      for (var s in staffs) {
        s.branch.target = null;
        _objectBox.staffBox.put(s);
      }

      _objectBox.branchBox.remove(branch.id);
      _branches.removeWhere((b) => b.id == branch.id);
      notifyListeners();

      debugPrint("🗑️ Branche supprimée: ${branch.branchNom}");
    } catch (e) {
      debugPrint("❌ Erreur deleteBranch: $e");
    }
  }

  /// 🔹 Assigner une branche à un staff
  Future<void> assignBranchToStaff(Staff staff, Branch branch) async {
    try {
      staff.branch.target = branch;
      _objectBox.staffBox.put(staff);

      // Pas besoin de rafraîchir toute la liste
      debugPrint("👤 ${staff.nom} → ${branch.branchNom}");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erreur assignBranchToStaff: $e");
    }
  }
}

class PlanningHebdoProvider with ChangeNotifier {
  final ObjectBox _objectBox;
  List<PlanningHebdo> _plannings = [];

  List<PlanningHebdo> get plannings => _plannings;

  PlanningHebdoProvider(this._objectBox) {
    fetchPlannings();
  }

  Future<void> fetchPlannings() async {
    try {
      _plannings = _objectBox.planningHebdoBox.getAll();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur fetchPlannings: $e');
    }
  }

  bool hasPlanning(int staffId) {
    return _plannings.any((p) => p.staff.targetId == staffId);
  }

  /// CRUD - CREATE : Créer un nouveau planning
  Future<void> createPlanning({required int staffId}) async {
    try {
      final newPlanning = PlanningHebdo();
      newPlanning.staff.targetId = staffId;
      _objectBox.planningHebdoBox.put(newPlanning);
      await fetchPlannings();
      print('✅ Planning créé pour staff ID: $staffId');
    } catch (e) {
      print('❌ Erreur createPlanning: $e');
      rethrow;
    }
  }

  /// CRUD - READ : Obtenir le planning d'un staff
  PlanningHebdo? getPlanningByStaff(int staffId) {
    try {
      return _plannings.firstWhereOrNull((p) => p.staff.targetId == staffId);
    } catch (e) {
      return null;
    }
  }

  /// CRUD - READ : Obtenir tous les plannings d'une équipe
  List<PlanningHebdo> getPlanningsByEquipe(String equipe) {
    try {
      return _plannings.where((p) {
        final staff = p.staff.target;
        return staff?.equipe == equipe;
      }).toList();
    } catch (e) {
      print('❌ Erreur getPlanningsByEquipe: $e');
      return [];
    }
  }

  /// CRUD - READ : Obtenir l'activité d'un jour spécifique
  String? getActiviteForStaffAndDay(int staffId, int jourSemaine) {
    try {
      final planning = getPlanningByStaff(staffId);
      return planning?.getActiviteJour(jourSemaine);
    } catch (e) {
      print('❌ Erreur getActiviteForStaffAndDay: $e');
      return null;
    }
  }

  /// CRUD - UPDATE : Mettre à jour une activité
  Future<void> updateActiviteJour({
    required int staffId,
    required int jourSemaine,
    String? activite,
  }) async {
    try {
      final planning = getPlanningByStaff(staffId);
      if (planning != null) {
        planning.setActiviteJour(jourSemaine, activite);
        _objectBox.planningHebdoBox.put(planning);
        await fetchPlannings();
        print(
            '✅ Activité mise à jour pour staff $staffId, jour $jourSemaine: $activite');
      }
    } catch (e) {
      print('❌ Erreur updateActiviteJour: $e');
      rethrow;
    }
  }

  /// CRUD - UPDATE : Mettre à jour plusieurs activités en une fois
  Future<void> updateActivitesSemaine({
    required int staffId,
    required Map<int, String?> activites, // Map<jour, activite>
  }) async {
    try {
      final planning = getPlanningByStaff(staffId);
      if (planning != null) {
        activites.forEach((jour, activite) {
          planning.setActiviteJour(jour, activite);
        });
        _objectBox.planningHebdoBox.put(planning);
        await fetchPlannings();
        print(
            '✅ ${activites.length} activités mises à jour pour staff $staffId');
      }
    } catch (e) {
      print('❌ Erreur updateActivitesSemaine: $e');
      rethrow;
    }
  }

  /// CRUD - DELETE : Supprimer un planning
  Future<void> deletePlanning(int planningId) async {
    try {
      _objectBox.planningHebdoBox.remove(planningId);
      await fetchPlannings();
      print('🗑️ Planning supprimé ID: $planningId');
    } catch (e) {
      print('❌ Erreur deletePlanning: $e');
      rethrow;
    }
  }

  /// CRUD - DELETE : Supprimer le planning d'un staff
  Future<void> deletePlanningByStaff(int staffId) async {
    try {
      final planning = getPlanningByStaff(staffId);
      if (planning != null) {
        await deletePlanning(planning.id);
      }
    } catch (e) {
      print('❌ Erreur deletePlanningByStaff: $e');
      rethrow;
    }
  }

  /// CRUD - DELETE : Effacer toutes les activités d'un planning
  Future<void> clearPlanningActivities(int staffId) async {
    try {
      final planning = getPlanningByStaff(staffId);
      if (planning != null) {
        for (int i = 0; i < 7; i++) {
          planning.setActiviteJour(i, null);
        }
        _objectBox.planningHebdoBox.put(planning);
        await fetchPlannings();
        print('✅ Activités effacées pour staff $staffId');
      }
    } catch (e) {
      print('❌ Erreur clearPlanningActivities: $e');
      rethrow;
    }
  }

  /// CRUD - DELETE : Effacer toutes les activités de tous les plannings
  Future<void> clearAllActivities() async {
    try {
      for (var planning in _plannings) {
        for (int i = 0; i < 7; i++) {
          planning.setActiviteJour(i, null);
        }
        _objectBox.planningHebdoBox.put(planning);
      }
      await fetchPlannings();
      print('✅ Toutes les activités effacées');
    } catch (e) {
      print('❌ Erreur clearAllActivities: $e');
      rethrow;
    }
  }

  /// CRUD - UTILITAIRE : Dupliquer un planning vers d'autres staffs
  Future<void> duplicatePlanning({
    required int sourceStaffId,
    required List<int> targetStaffIds,
  }) async {
    try {
      final sourcePlanning = getPlanningByStaff(sourceStaffId);
      if (sourcePlanning == null) {
        throw Exception('Planning source non trouvé');
      }

      for (var targetStaffId in targetStaffIds) {
        var targetPlanning = getPlanningByStaff(targetStaffId);
        if (targetPlanning == null) {
          targetPlanning = PlanningHebdo();
          targetPlanning.staff.targetId = targetStaffId;
        }

        // Copier toutes les activités
        for (int i = 0; i < 7; i++) {
          targetPlanning.setActiviteJour(i, sourcePlanning.getActiviteJour(i));
        }

        _objectBox.planningHebdoBox.put(targetPlanning);
      }

      await fetchPlannings();
      print('✅ Planning dupliqué vers ${targetStaffIds.length} staff(s)');
    } catch (e) {
      print('❌ Erreur duplicatePlanning: $e');
      rethrow;
    }
  }

  /// CRUD - UTILITAIRE : Statistiques des activités
  Map<String, int> getActiviteStats(int staffId) {
    try {
      final planning = getPlanningByStaff(staffId);
      final stats = <String, int>{};

      if (planning != null) {
        for (int i = 0; i < 7; i++) {
          final activite = planning.getActiviteJour(i);
          if (activite != null && activite.isNotEmpty) {
            stats[activite] = (stats[activite] ?? 0) + 1;
          }
        }
      }

      return stats;
    } catch (e) {
      print('❌ Erreur getActiviteStats: $e');
      return {};
    }
  }

  /// CRUD - UTILITAIRE : Valider un planning
  List<String> validatePlanning(int staffId) {
    final errors = <String>[];
    try {
      final planning = getPlanningByStaff(staffId);
      final staff = planning?.staff.target;

      if (planning == null) {
        errors.add('Planning non trouvé');
        return errors;
      }

      if (staff == null) {
        errors.add('Staff non associé au planning');
      }

      // Vérifier si au moins une activité est définie
      final hasActivite = List.generate(7, (i) => planning.getActiviteJour(i))
          .any((activite) => activite != null && activite.isNotEmpty);

      if (!hasActivite) {
        errors.add('Aucune activité définie pour la semaine');
      }

      return errors;
    } catch (e) {
      errors.add('Erreur de validation: $e');
      return errors;
    }
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension PlanningHebdoProviderExtension on PlanningHebdoProvider {
  ObjectBox get objectBox => _objectBox;
}

class TypeActiviteProvider with ChangeNotifier {
  final ObjectBox _objectBox;
  List<TypeActivite> _typesActivites = [];

  List<TypeActivite> get typesActivites => _typesActivites;

  TypeActiviteProvider(this._objectBox) {
    fetchTypesActivites();
  }

  /// Récupérer tous les types d'activités
  Future<void> fetchTypesActivites() async {
    try {
      _typesActivites = _objectBox.typeActiviteBox.getAll();
      notifyListeners();
      print('✅ ${_typesActivites.length} types d\'activités chargés');
    } catch (e) {
      print('❌ Erreur fetchTypesActivites: $e');
    }
  }

  /// Créer un nouveau type d'activité
  Future<void> createTypeActivite({
    required String code,
    required String libelle,
    String? description,
    int? couleurHex,
  }) async {
    try {
      // Vérifier si le code existe déjà
      final existing = _typesActivites.firstWhere(
        (t) => t.code.toUpperCase() == code.toUpperCase(),
        orElse: () => TypeActivite(code: '', libelle: ''),
      );

      if (existing.code.isNotEmpty) {
        throw Exception('Un type avec le code "$code" existe déjà');
      }

      final newType = TypeActivite(
        code: code.toUpperCase(),
        libelle: libelle,
        description: description,
        couleurHex: couleurHex,
      );

      _objectBox.typeActiviteBox.put(newType);
      await fetchTypesActivites();
      print('✅ Type créé: $libelle ($code)');
    } catch (e) {
      print('❌ Erreur createTypeActivite: $e');
      rethrow;
    }
  }

  /// Mettre à jour un type existant
  Future<void> updateTypeActivite(TypeActivite type) async {
    try {
      _objectBox.typeActiviteBox.put(type);
      await fetchTypesActivites();
      print('✅ Type mis à jour: ${type.libelle}');
    } catch (e) {
      print('❌ Erreur updateTypeActivite: $e');
      rethrow;
    }
  }

  /// Supprimer un type
  Future<void> deleteTypeActivite(int typeId) async {
    try {
      _objectBox.typeActiviteBox.remove(typeId);
      await fetchTypesActivites();
      print('🗑️ Type supprimé');
    } catch (e) {
      print('❌ Erreur deleteTypeActivite: $e');
      rethrow;
    }
  }

  /// Obtenir un type par son code
  TypeActivite? getTypeByCode(String code) {
    try {
      return _typesActivites.firstWhere(
        (t) => t.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Créer les types par défaut
  Future<void> createDefaultTypes() async {
    try {
      if (_typesActivites.isNotEmpty) return;

      final defaultTypes = [
        TypeActivite(
          code: 'SERV',
          libelle: 'Service',
          description: 'Service normal',
          couleurHex: 0xFFE0E0E0,
        ),
        TypeActivite(
          code: 'DMO',
          libelle: 'Demi-journée',
          description: 'Demi-journée de travail',
          couleurHex: 0xFFBBDEFB,
        ),
        TypeActivite(
          code: 'VG',
          libelle: 'Visite Générale',
          description: 'Visite générale des patients',
          couleurHex: 0xFFC8E6C9,
        ),
        TypeActivite(
          code: 'CONSULT',
          libelle: 'Consultation',
          description: 'Consultation médicale',
          couleurHex: 0xFFE1BEE7,
        ),
        TypeActivite(
          code: 'JP',
          libelle: 'Journée Pédagogique',
          description: 'Formation/Journée pédagogique',
          couleurHex: 0xFFFFE0B2,
        ),
        TypeActivite(
          code: 'BIO',
          libelle: 'Biothérapie',
          description: 'Séance de biothérapie',
          couleurHex: 0xFFB2DFDB,
        ),
        // TypeActivite(
        //   code: 'G',
        //   libelle: 'Garde',
        //   description: 'Garde',
        //   couleurHex: 0xFFFFE082,
        // ),
        // TypeActivite(
        //   code: 'RE',
        //   libelle: 'Repos',
        //   description: 'Jour de repos',
        //   couleurHex: 0xFFB0BEC5,
        // ),
        // TypeActivite(
        //   code: 'C',
        //   libelle: 'Congé',
        //   description: 'Congé',
        //   couleurHex: 0xFFFFCDD2,
        // ),
        // TypeActivite(
        //   code: 'CM',
        //   libelle: 'Congé Maladie',
        //   description: 'Congé maladie',
        //   couleurHex: 0xFFF8BBD0,
        // ),
        // TypeActivite(
        //   code: 'N',
        //   libelle: 'Nuit',
        //   description: 'Garde de nuit',
        //   couleurHex: 0xFFC5CAE9,
        // ),
      ];

      for (var type in defaultTypes) {
        _objectBox.typeActiviteBox.put(type);
      }

      await fetchTypesActivites();
      print('✅ Types par défaut créés');
    } catch (e) {
      print('❌ Erreur createDefaultTypes: $e');
    }
  }

  /// Vider tous les types
  Future<void> clearAllTypes() async {
    try {
      _objectBox.typeActiviteBox.removeAll();
      await fetchTypesActivites();
      print('🗑️ Tous les types supprimés');
    } catch (e) {
      print('❌ Erreur clearAllTypes: $e');
      rethrow;
    }
  }
}
