import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';
import 'ActivitePersonne.dart';

class StaffProvider with ChangeNotifier {
  List<Staff> _staffs = [];
  late final ObjectBox _objectBox;

  List<Staff> get staffs => _staffs;

  StaffProvider() {
    _initObjectBox();
  }

  Box<ActiviteJour> get activiteBox => _objectBox.activiteBox;

  Future<void> _initObjectBox() async {
    try {
      _objectBox = ObjectBox();
      await fetchStaffs();
    } catch (e) {
      print('Erreur initialisation ObjectBox: $e');
    }
  }

  /// 🔹 Récupère tous les staffs avec leurs activités, branch et congés
  Future<void> fetchStaffs() async {
    try {
      _staffs = _objectBox.staffBox.getAll();
      //  print('Nombre de staffs récupérés: ${_staffs.length}');

      for (final staff in _staffs) {
        // print("\n--- STAFF ${staff.id} ---");
        // print(
        //     "Nom: ${staff.nom}, Grade: ${staff.grade}, Groupe: ${staff.groupe}");
        // print("Équipe: ${staff.equipe ?? "-"}");
        // print("Branch: ${staff.branch.target?.branchNom ?? "Non assigné"}");

        // Activités liées
        final activites = _objectBox.activiteBox
            .query(ActiviteJour_.staff.equals(staff.id))
            .build()
            .find();
        //  print("Activités: ${activites.length}");

        // Congés liés
        final timeOffs = staff.timeOff.toList();
        // print("Congés: ${timeOffs.length}");
        for (var timeOff in timeOffs) {
          // print(
          //     " - ${timeOff.debut} -> ${timeOff.fin} (${timeOff.motif ?? "aucun"})");
        }
      }

      notifyListeners();
    } catch (e) {
      print("Erreur fetchStaffs: $e");
    }
  }

  /// 🔹 Ajoute un staff avec ses activités
  Future<void> addStaff(Staff staff, List<String> activites) async {
    try {
      _objectBox.staffBox.put(staff);

      for (int i = 0; i < activites.length && i < 31; i++) {
        final activite = ActiviteJour(
          jour: i + 1,
          statut: activites[i],
        )
          ..staff.target = staff;

        _objectBox.activiteBox.put(activite);
      }

      await fetchStaffs();
    } catch (e) {
      print("Erreur addStaff: $e");
    }
  }

  /// 🔹 Mise à jour staff
  Future<void> updateStaff(Staff staff) async {
    try {
      _objectBox.staffBox.put(staff);
      await fetchStaffs();
    } catch (e) {
      print("Erreur updateStaff: $e");
    }
  }

  /// 🔹 Suppression staff + relations
  Future<void> deleteStaff(Staff staff) async {
    try {
      // Supprimer activités liées
      final activites = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staff.id))
          .build()
          .find();
      for (var act in activites) {
        _objectBox.activiteBox.remove(act.id);
      }

      // Supprimer congés liés
      for (var timeOff in staff.timeOff) {
        _objectBox.timeOffBox.remove(timeOff.id);
      }

      // Supprimer le staff
      _objectBox.staffBox.remove(staff.id);

      await fetchStaffs();
    } catch (e) {
      print("Erreur deleteStaff: $e");
    }
  }
}

/// Provider pour gérer les activités - VERSION AMÉLIORÉE
class ActiviteProvider with ChangeNotifier {
  late final ObjectBox _objectBox;

  ActiviteProvider() {
    _objectBox = ObjectBox();
  }

  // Méthodes publiques pour accéder aux boxes
  Box<ActiviteJour> get activiteBox => _objectBox.activiteBox;

  Box<TimeOff> get timeOffBox => _objectBox.timeOffBox;

  Box<Staff> get staffBox => _objectBox.staffBox;

  /// 🔹 VERSION CORRIGÉE : Met à jour une activité en respectant la logique métier
  Future<void> updateActivite(int staffId, int jour, String statut,
      {required int year, required int month}) async {
    try {
      final staff = _objectBox.staffBox.get(staffId);
      if (staff == null) {
        print("⚠️ Staff $staffId non trouvé");
        return;
      }

      final dateJour = DateTime(year, month, jour);

      // VÉRIFICATION 1 : Congés TimeOff (plus prioritaires)
      bool estEnCongeTimeOff = _isStaffOnLeaveTimeOff(staff, dateJour);

      if (estEnCongeTimeOff) {
        print(
            "🚫 ${staff
                .nom} est en congé TimeOff le $jour/$month/$year - Modification ignorée");
        return;
      }

      // VÉRIFICATION 2 : Activités de congé existantes (C, CM) - seulement si pas TimeOff
      final query = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staffId) &
      ActiviteJour_.jour.equals(jour))
          .build();
      final activites = query.find();
      query.close();

      bool estEnCongeActivite = false;
      ActiviteJour? activiteExistante;

      if (activites.isNotEmpty) {
        activiteExistante = activites.first;
        if (activiteExistante.statut == 'C' ||
            activiteExistante.statut == 'CM') {
          estEnCongeActivite = true;
          print(
              "🚫 ${staff
                  .nom} a un congé activité le jour $jour (${activiteExistante
                  .statut}) - Modification ignorée");
        }
      }

      // Si en congé activité, ignorer SAUF si on veut forcer un autre type de congé
      if (estEnCongeActivite && !['C', 'CM'].contains(statut)) {
        print(
            "⚠️ Modification IGNORÉE pour ${staff
                .nom} - jour $jour (congé activité existant)");
        return;
      }

      // MODIFICATION AUTORISÉE : Procéder à la mise à jour
      if (activiteExistante != null) {
        // Mise à jour de l'activité existante
        String ancienStatut = activiteExistante.statut;
        activiteExistante.statut = statut;
        _objectBox.activiteBox.put(activiteExistante);
        print(
            "✅ Activité mise à jour: ${staff
                .nom} jour $jour: $ancienStatut → $statut");
      } else {
        // Création d'une nouvelle activité
        final nouvelleActivite = ActiviteJour(jour: jour, statut: statut)
          ..staff.target = staff;
        _objectBox.activiteBox.put(nouvelleActivite);
        print("➕ Nouvelle activité créée: ${staff.nom} jour $jour = $statut");
      }

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
  Future<void> forceUpdateActiviteIgnoringLeave(int staffId, int jour,
      String statut,
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
        )
          ..branch.target = branch;

        _objectBox.staffBox.put(staff);

        // 3. Insérer les congés TimeOff AVANT les activités
        if (e.conges != null && e.conges!.isNotEmpty) {
          for (var conge in e.conges!) {
            final timeOff = TimeOff(
              debut: conge.debut,
              fin: conge.fin,
              motif: conge.motif,
            )
              ..staff.target = staff;
            _objectBox.timeOffBox.put(timeOff);
            print(
                "📅 Congé ajouté: ${staff.nom} du ${conge.debut} au ${conge
                    .fin}");
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
            "✅ Staff inséré: ${staff.nom} avec ${e.conges?.length ??
                0} congés");
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
  Future<void> clearAllActivites(BuildContext context) async {
    try {
      // 1️⃣ Supprimer toutes les activités
      _objectBox.activiteBox.removeAll();
      print("✅ Toutes les activités ont été supprimées.");

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
            "Aucun personnel médical trouvé avec les équipes: ${equipesOrdonnees
                .join(', ')}");
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
