import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';
import 'ActivitePersonne.dart';
import 'p2p/delta_generator_real.dart';
import 'p2p/objectbox_sync_observer.dart';

/// ✅ StaffProvider CORRIGÉ - Synchronisation P2P automatique
class StaffProvider with ChangeNotifier {
  List<Staff> _staffs = [];
  late final ObjectBox _objectBox;
  bool _initialized = false;
  late final ObjectBoxSyncObserver _syncObserver;

  List<Staff> get staffs => _staffs;
  bool get isInitialized => _initialized;

  StaffProvider() {
    _initObjectBox();
  }

  Box<ActiviteJour> get activiteBox => _objectBox.activiteBox;

  Future<void> _initObjectBox() async {
    try {
      _objectBox = ObjectBox();
      _syncObserver = ObjectBoxSyncObserver(); // Récupérer l'instance singleton

      // ✅ NOUVEAU : S'enregistrer pour les notifications de changements
      _syncObserver.addStaffChangedListener(_onRemoteStaffChanged);
      _syncObserver.addActiviteChangedListener(_onRemoteActiviteChanged);

      await fetchStaffs();
      _initialized = true;
      notifyListeners();
      print('[StaffProvider] ✅ Initialisé avec ${_staffs.length} staffs');
      print(
          '[StaffProvider] 🔔 Listeners enregistrés pour les changements distants');
    } catch (e) {
      print('[StaffProvider] ❌ Erreur initialisation ObjectBox: $e');
    }
  }

  /// ✅ NOUVEAU : Callback appelé quand un delta distant modifie un Staff
  void _onRemoteStaffChanged() {
    print(
        '[StaffProvider] 🔔 Changement distant détecté - Rafraîchissement UI...');
    fetchStaffs(); // Rafraîchit l'UI
  }

  /// ✅ NOUVEAU : Callback appelé quand un delta distant modifie une Activité
  void _onRemoteActiviteChanged() {
    print(
        '[StaffProvider] 🔔 Changement Activité distant détecté - Rafraîchissement UI...');
    fetchStaffs(); // Rafraîchit l'UI
  }

  /// ✅ NOUVEAU : Nettoyer les listeners lors de la destruction
  @override
  void dispose() {
    _syncObserver.removeStaffChangedListener(_onRemoteStaffChanged);
    _syncObserver.removeActiviteChangedListener(_onRemoteActiviteChanged);
    print('[StaffProvider] 🧹 Listeners retirés');
    super.dispose();
  }

  /// ✅ MÉTHODE 1 : Mettre à jour un staff
  /// L'observer détecte automatiquement et synchronise
  Future<void> updateStaff(Staff staff) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(
          '[StaffProvider] 🔄 Mise à jour Staff: ${staff.nom} (ID: ${staff.id})');

      // ✅ SIMPLE : Juste mettre à jour dans ObjectBox
      _objectBox.staffBox.put(staff);

      print('[StaffProvider] ✅ Staff mis à jour dans ObjectBox');
      print('[StaffProvider] ⏳ L\'observer va détecter et synchroniser...');

      // Rafraîchir l'UI
      await fetchStaffs();

      print('[StaffProvider] ✅ UI rafraîchie');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print("[StaffProvider] ❌ Erreur updateStaff: $e");
      rethrow;
    }
  }

  /// ✅ MÉTHODE 2 : Ajouter un staff avec activités
  /// L'observer détecte automatiquement et synchronise
  Future<void> addStaff(Staff staff, List<String> activites) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[StaffProvider] 🆕 Création Staff: ${staff.nom}');

      // 1️⃣ Créer le staff dans ObjectBox
      final staffId = _objectBox.staffBox.put(staff);
      staff.id = staffId;
      print('[StaffProvider] ✅ Staff créé avec ID: $staffId');

      // 2️⃣ Créer les activités
      print('[StaffProvider] 📅 Création de ${activites.length} activités...');
      for (int i = 0; i < activites.length && i < 31; i++) {
        final activite = ActiviteJour(
          jour: i + 1,
          statut: activites[i],
        )..staff.target = staff;

        _objectBox.activiteBox.put(activite);
      }
      print('[StaffProvider] ✅ ${activites.length} activités créées');

      print('[StaffProvider] ⏳ L\'observer va détecter et synchroniser...');

      // 3️⃣ Rafraîchir l'UI
      await fetchStaffs();

      print('[StaffProvider] ✅ Staff et activités créés : ${staff.nom}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print("[StaffProvider] ❌ Erreur addStaff: $e");
      rethrow;
    }
  }

  /// ✅ MÉTHODE 3 : Supprimer un staff
  /// ATTENTION : La suppression nécessite un broadcast manuel
  /// car l'observer ne peut pas détecter un objet qui n'existe plus
  Future<void> deleteStaff(Staff staff) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(
          '[StaffProvider] 🗑️ Suppression Staff: ${staff.nom} (ID: ${staff.id})');

      // 1️⃣ Récupérer les activités liées
      final activites = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staff.id))
          .build()
          .find();
      print('[StaffProvider] 📋 ${activites.length} activités liées trouvées');

      // 2️⃣ Broadcaster la suppression du staff AVANT de le supprimer
      print('[StaffProvider] 📡 Broadcasting suppression staff...');
      await DeltaGenerator().syncStaff(staff, 'delete');

      // 3️⃣ Supprimer et broadcaster chaque activité
      for (var act in activites) {
        await DeltaGenerator().syncActiviteJour(act, 'delete');
        _objectBox.activiteBox.remove(act.id);
      }
      print('[StaffProvider] ✅ ${activites.length} activités supprimées');

      // 4️⃣ Supprimer et broadcaster les congés
      final timeOffs = staff.timeOff.toList();
      for (var timeOff in timeOffs) {
        await DeltaGenerator().syncTimeOff(timeOff, 'delete');
        _objectBox.timeOffBox.remove(timeOff.id);
      }
      print('[StaffProvider] ✅ ${timeOffs.length} congés supprimés');

      // 5️⃣ Supprimer le staff de la DB locale
      _objectBox.staffBox.remove(staff.id);
      print('[StaffProvider] ✅ Staff supprimé de la DB locale');

      // 6️⃣ Rafraîchir l'UI
      await fetchStaffs();

      print('[StaffProvider] ✅ Staff supprimé et synchronisé: ${staff.nom}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print("[StaffProvider] ❌ Erreur deleteStaff: $e");
      rethrow;
    }
  }

  /// ✅ MÉTHODE 4 : Récupérer tous les staffs
  Future<void> fetchStaffs() async {
    try {
      _staffs = _objectBox.staffBox.getAll();
      notifyListeners();
      print('[StaffProvider] 📊 ${_staffs.length} staffs chargés');
    } catch (e) {
      print("[StaffProvider] ❌ Erreur fetchStaffs: $e");
    }
  }

  /// ✅ MÉTHODE 5 : Sauvegarder les activités du mois
  Future<void> saveMonthActivities(int year, int month) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[StaffProvider] 💾 Sauvegarde activités $month/$year');

      // Récupérer toutes les activités
      final allActivites = _objectBox.activiteBox.getAll();
      print(
          '[StaffProvider] 📋 ${allActivites.length} activités à sauvegarder');

      // Construire la chaîne JSON
      final activitesData = allActivites
          .map((a) => "${a.staff.targetId}:${a.jour}:${a.statut}")
          .join(",");

      // Chercher ou créer la planification
      final query = _objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();

      Planification? planif = query.findFirst();
      query.close();

      if (planif != null) {
        // Mettre à jour la planification existante
        planif.activitesJson = activitesData;
        _objectBox.planificationBox.put(planif);
        print("[StaffProvider] ✅ Planification mise à jour pour $month/$year");
      } else {
        // Créer nouvelle planification
        final newPlanif = Planification(
          mois: month,
          annee: year,
          ordreEquipes: "",
          activitesJson: activitesData,
        );
        _objectBox.planificationBox.put(newPlanif);
        print(
            "[StaffProvider] ✅ Nouvelle planification créée pour $month/$year");
      }

      // ⏳ L'observer détectera et synchronisera automatiquement
      print(
          '[StaffProvider] ⏳ L\'observer va synchroniser la planification...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print("[StaffProvider] ❌ Erreur saveMonthActivities: $e");
      rethrow;
    }
  }

  /// ✅ MÉTHODE 6 : Charger les activités d'un mois
  Future<bool> loadMonthActivities(int year, int month) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[StaffProvider] 📂 Chargement activités $month/$year');

      // Chercher la planification
      final query = _objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();

      final planif = query.findFirst();
      query.close();

      // Toujours vider les activités existantes
      print('[StaffProvider] 🧹 Nettoyage activités existantes...');
      _objectBox.activiteBox.removeAll();

      if (planif == null ||
          planif.activitesJson == null ||
          planif.activitesJson!.isEmpty) {
        print("[StaffProvider] ℹ️ Nouveau mois : $month/$year (tableau vide)");
        await fetchStaffs();
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return false;
      }

      print("[StaffProvider] 🔄 Restauration depuis sauvegarde...");

      // Restaurer depuis la sauvegarde
      final activitesData = planif.activitesJson!.split(",");
      int restored = 0;

      for (final data in activitesData) {
        final parts = data.split(":");
        if (parts.length != 3) continue;

        final staffId = int.tryParse(parts[0]);
        final jour = int.tryParse(parts[1]);
        final statut = parts[2];

        if (staffId == null || jour == null) continue;

        final staff = _objectBox.staffBox.get(staffId);
        if (staff == null) {
          print("[StaffProvider] ⚠️ Staff $staffId non trouvé, ignoré");
          continue;
        }

        final activite = ActiviteJour(
          jour: jour,
          statut: statut,
        )..staff.target = staff;

        _objectBox.activiteBox.put(activite);
        restored++;
      }

      await fetchStaffs();
      print(
          "[StaffProvider] ✅ $restored activités restaurées pour $month/$year");
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return true;
    } catch (e) {
      print("[StaffProvider] ❌ Erreur loadMonthActivities: $e");
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return false;
    }
  }

  /// ✅ MÉTHODE UTILITAIRE : Obtenir un staff par ID
  Staff? getStaffById(int id) {
    try {
      return _objectBox.staffBox.get(id);
    } catch (e) {
      print("[StaffProvider] ❌ Erreur getStaffById: $e");
      return null;
    }
  }

  /// ✅ MÉTHODE UTILITAIRE : Filtrer par branche
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

  /// ✅ MÉTHODE UTILITAIRE : Filtrer par équipe
  List<Staff> getStaffsByTeam(String? team) {
    try {
      if (team == null) return [];
      return _staffs.where((staff) => staff.equipe == team).toList();
    } catch (e) {
      print("[StaffProvider] ❌ Erreur getStaffsByTeam: $e");
      return [];
    }
  }

  /// ✅ MÉTHODE UTILITAIRE : Rechercher des staffs
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
}

/// Provider pour gérer les activités - VERSION AMÉLIORÉE
class ActiviteProvider with ChangeNotifier {
  late final ObjectBox _objectBox;
  late final DeltaGenerator _deltaGenerator; // ✅ AJOUTER

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

  /// 🔹 Vérifie si un staff est en congé TimeOff à une date donnée
  bool _isStaffOnLeaveTimeOff(Staff staff, DateTime dateJour) {
    final timeOffs = staff.timeOff.toList();

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

  /// 🔹 VERSION CORRIGÉE : insertActivites avec gestion des congés
  Future<void> insertActivites(List<ActivitePersonne> liste,
      {required int year, required int month}) async {
    try {
      // Nettoyage complet de la base (si nécessaire)
      _objectBox.activiteBox.removeAll();
      _objectBox.staffBox.removeAll();
      _objectBox.branchBox.removeAll();
      _objectBox.timeOffBox.removeAll();

      for (var e in liste) {
        // 1. Créer/récupérer Branch
        Branch branch = _objectBox.branchBox
                .query(Branch_.branchNom.equals(e.branchNom ?? "Rhumatologie"))
                .build()
                .findFirst() ??
            Branch(branchNom: e.branchNom ?? "Rhumatologie");
        _objectBox.branchBox.put(branch);

        // 2. Créer Staff
        final staff = Staff(
          nom: e.nom,
          grade: e.grade,
          groupe: e.groupe,
          equipe: e.equipe,
          obs: e.obs,
        )..branch.target = branch;

        _objectBox.staffBox.put(staff);

        // 3. Insérer les congés TimeOff AVANT les activités
        if (e.conges != null && e.conges!.isNotEmpty) {
          for (var conge in e.conges!) {
            final timeOff = TimeOff(
              debut: conge.debut,
              fin: conge.fin,
              motif: conge.motif,
            )..staff.target = staff;
            _objectBox.timeOffBox.put(timeOff);
            print(
                "📅 Congé ajouté: ${staff.nom} du ${conge.debut} au ${conge.fin}");
          }
        }

        // 4. Traiter les activités journalières avec respect des congés
        for (int i = 0; i < e.jours.length && i < 31; i++) {
          final jour = i + 1;
          final statutJour = e.jours[i];
          final dateJour = DateTime(year, month, jour);

          // Vérifier si le staff est en congé TimeOff ce jour-là
          final estEnCongeTimeOff = _isStaffOnLeaveTimeOff(staff, dateJour);

          String statutFinal;
          if (estEnCongeTimeOff) {
            // Si en congé TimeOff, forcer 'C'
            statutFinal = 'C';
          } else {
            // Sinon utiliser le statut planifié
            statutFinal = statutJour;
          }

          final activite = ActiviteJour(jour: jour, statut: statutFinal)
            ..staff.target = staff;
          _objectBox.activiteBox.put(activite);
        }

        print(
            "✅ Staff inséré: ${staff.nom} avec ${e.conges?.length ?? 0} congés");
      }

      await fetchStaffs();
      print("🎉 Insertion terminée: ${liste.length} staffs traités");
    } catch (e) {
      print("❌ Erreur insertActivites: $e");
      rethrow;
    }
  }

  Future<void> fetchStaffs() async {
    final staffs = _objectBox.staffBox.getAll();
    print("📊 Staffs dans la DB: ${staffs.length}");
    notifyListeners();
  }

  /// 🔹 Supprimer toutes les activités
  /// 🔹 Supprimer toutes les activités et réinitialiser les obs des staffs
  Future<void> clearAllActivitesAncien(BuildContext context) async {
    try {
      // 1️⃣ Supprimer toutes les activités
      _objectBox.activiteBox.removeAll();

      print("✅ Toutes les activités ont été supprimées.");
      // _objectBox.timeOffBox.removeAll();
      //print("✅ Toutes les Congés ont été supprimées.");
      // 2️⃣ Réinitialiser les obs des staffs
      final staffs = _objectBox.staffBox.getAll();
      for (var staff in staffs) {
        if (staff.obs != null && staff.obs!.isNotEmpty) {
          staff.obs = null; // ou "" si tu préfères une chaîne vide
          _objectBox.staffBox.put(staff);
        }
      }
      print("✅ Tous les champs 'obs' des staffs ont été réinitialisés.");

      notifyListeners();

      // 3️⃣ Rafraîchir les staffs après la modification
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
    } catch (e) {
      print("❌ Erreur clearAllActivitesEtObs: $e");
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

  Future<void> clearAllExceptStaffs(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("⚠️ Confirmation"),
          ],
        ),
        content: Text(
          "Cette action va supprimer :\n\n"
          "• Toutes les activités\n"
          "• Tous les congés\n"
          "• Toutes les planifications\n"
          "• Toutes les branches\n\n"
          "Les staffs seront conservés mais réinitialisés.\n\n"
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("CONFIRMER"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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

      // 4️⃣ Supprimer toutes les branches
      _objectBox.branchBox.removeAll();
      print("✅ Toutes les branches supprimées.");

      // 5️⃣ Réinitialiser les staffs (sans les supprimer)
      final staffs = _objectBox.staffBox.getAll();
      for (var staff in staffs) {
        staff.obs = null;
        staff.equipe = null;

        // Vider les relations ToMany
        staff.activites.clear();
        staff.timeOff.clear();

        _objectBox.staffBox.put(staff);
      }
      print("✅ Tous les staffs réinitialisés (obs, équipes, relations).");

      notifyListeners();

      // 6️⃣ Rafraîchir l'interface
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ Base de données nettoyée (staffs conservés)"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Erreur clearAllExceptStaffs: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur : $e"),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
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
