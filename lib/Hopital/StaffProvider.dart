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
      print('Nombre de staffs récupérés: ${_staffs.length}');

      for (final staff in _staffs) {
        print("\n--- STAFF ${staff.id} ---");
        print(
            "Nom: ${staff.nom}, Grade: ${staff.grade}, Groupe: ${staff.groupe}");
        print("Équipe: ${staff.equipe ?? "-"}");
        print("Branch: ${staff.branch.target?.branchNom ?? "Non assigné"}");

        // Activités liées
        final activites = _objectBox.activiteBox
            .query(ActiviteJour_.staff.equals(staff.id))
            .build()
            .find();
        print("Activités: ${activites.length}");

        // Congés liés
        final timeOffs = staff.timeOff.toList();
        print("Congés: ${timeOffs.length}");
        for (var timeOff in timeOffs) {
          print(
              " - ${timeOff.debut} -> ${timeOff.fin} (${timeOff.motif ?? "aucun"})");
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
        )..staff.target = staff;

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

/// Provider pour gérer les activités
class ActiviteProvider with ChangeNotifier {
  late final ObjectBox _objectBox;

  ActiviteProvider() {
    _objectBox = ObjectBox();
  }

  /// 🔹 Met à jour ou insère une activité avec vérification des congés
  /// Version corrigée qui vérifie AUSSI les activités existantes avec statut C/CM
  Future<void> updateActivite(int staffId, int jour, String statut,
      {required int year, required int month}) async {
    try {
      final staff = _objectBox.staffBox.get(staffId);
      if (staff == null) throw Exception("Staff non trouvé");

      // VÉRIFICATION 1 : Congés dans TimeOff
      final dateJour = DateTime(year, month, jour);
      final timeOffs = staff.timeOff.toList();
      bool estEnCongeTimeOff = false;

      for (var timeOff in timeOffs) {
        if (dateJour.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
            dateJour.isBefore(timeOff.fin.add(Duration(days: 1)))) {
          estEnCongeTimeOff = true;
          print(
              "🚫 ${staff.nom} est en congé TimeOff le $jour/$month/$year (${timeOff.motif ?? 'Congé'})");
          break;
        }
      }

      // VÉRIFICATION 2 : Congés dans les activités existantes
      final query = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staffId) &
              ActiviteJour_.jour.equals(jour))
          .build();

      final activites = query.find();
      query.close();

      bool estEnCongeActivite = false;
      if (activites.isNotEmpty) {
        final activiteExistante = activites.first;
        if (activiteExistante.statut == 'C' ||
            activiteExistante.statut == 'CM') {
          estEnCongeActivite = true;
          print(
              "🚫 ${staff.nom} a déjà un congé le jour $jour (statut: ${activiteExistante.statut})");
        }
      }

      // Si en congé (TimeOff OU activité), ne pas modifier
      if (estEnCongeTimeOff || estEnCongeActivite) {
        print(
            "⚠️  Modification IGNORÉE pour ${staff.nom} - jour $jour (en congé)");
        return;
      }

      // Procéder à la modification normale
      if (activites.isNotEmpty) {
        final activite = activites.first;
        activite.statut = statut;
        _objectBox.activiteBox.put(activite);
        print("✅ Activité mise à jour: ${staff.nom} jour $jour = $statut");
      } else {
        final nouvelle = ActiviteJour(jour: jour, statut: statut)
          ..staff.target = staff;
        _objectBox.activiteBox.put(nouvelle);
        print("➕ Nouvelle activité créée: ${staff.nom} jour $jour = $statut");
      }

      notifyListeners();
    } catch (e) {
      print("Erreur updateActivite: $e");
    }
  }

  /// 🔹 Vérifie si un staff est en congé à une date donnée
  bool _isStaffOnLeave(Staff staff, DateTime dateJour) {
    final timeOffs = staff.timeOff.toList();

    for (var timeOff in timeOffs) {
      if (dateJour.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
          dateJour.isBefore(timeOff.fin.add(Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }

  /// 🔹 Version avec dates pour insertActivites
  Future<void> insertActivites(List<ActivitePersonne> liste,
      {required int year, required int month}) async {
    try {
      _objectBox.activiteBox.removeAll();
      _objectBox.staffBox.removeAll();
      _objectBox.branchBox.removeAll();
      _objectBox.timeOffBox.removeAll();

      for (var e in liste) {
        // Branch (service)
        Branch branch = _objectBox.branchBox
                .query(Branch_.branchNom.equals(e.branchNom ?? "Inconnu"))
                .build()
                .findFirst() ??
            Branch(branchNom: e.branchNom ?? "Inconnu");
        _objectBox.branchBox.put(branch);

        // Staff
        final staff = Staff(
          nom: e.nom,
          grade: e.grade,
          groupe: e.groupe,
          equipe: e.equipe,
          obs: e.obs,
        )..branch.target = branch;

        _objectBox.staffBox.put(staff);

        // Insérer les congés en premier
        if (e.conges != null) {
          for (var conge in e.conges!) {
            final timeOff = TimeOff(
              debut: conge.debut,
              fin: conge.fin,
              motif: conge.motif,
            )..staff.target = staff;
            _objectBox.timeOffBox.put(timeOff);
          }
        }

        // Traiter les activités en évitant d'écraser les congés
        for (int i = 0; i < e.jours.length && i < 31; i++) {
          final jour = i + 1;
          final statutJour = e.jours[i];

          // Utiliser les paramètres year/month
          final dateJour = DateTime(year, month, jour);
          final estEnConge = _isStaffOnLeave(staff, dateJour);

          if (estEnConge) {
            final activite = ActiviteJour(jour: jour, statut: 'C')
              ..staff.target = staff;
            _objectBox.activiteBox.put(activite);
          } else {
            final activite = ActiviteJour(jour: jour, statut: statutJour)
              ..staff.target = staff;
            _objectBox.activiteBox.put(activite);
          }
        }
      }

      await fetchStaffs();
    } catch (e) {
      print("Erreur insertActivites: $e");
    }
  }

  Future<void> fetchStaffs() async {
    final staffs = _objectBox.staffBox.getAll();
    print("Staffs dans la DB: ${staffs.length}");
  }

  /// 🔹 Supprimer toutes les activités
  Future<void> clearAllActivites(BuildContext context) async {
    try {
      _objectBox.activiteBox.removeAll();
      print("✅ Toutes les activités ont été supprimées.");
      notifyListeners();
      // Rafraîchir les staffs après suppression
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
    } catch (e) {
      print("Erreur clearAllActivites: $e");
    }
  }
}
