import 'package:flutter/material.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import 'ActivitePersonne.dart';

class StaffProvider with ChangeNotifier {
  List<Staff> _staffs = [];

  List<Staff> get staffs => _staffs;

  late final ObjectBox _objectBox;

  StaffProvider() {
    _initObjectBox();
  }

  void _initObjectBox() async {
    try {
      _objectBox = ObjectBox();
      await fetchStaffs();
    } catch (e) {
      print('Erreur initialisation ObjectBox: $e');
    }
  }

  /// Récupère tous les staffs avec leurs activités
  Future<void> fetchStaffs() async {
    try {
      _staffs = _objectBox.staffBox.getAll();

      print('=================== DEBUG FETCH STAFFS ===================');
      print('Nombre de staffs récupérés: ${_staffs.length}');

      // Debug complet de chaque staff
      for (int i = 0; i < _staffs.length; i++) {
        final staff = _staffs[i];
        print('\n--- STAFF ${i + 1} ---');
        print('ID: ${staff.id}');
        print('Nom: "${staff.nom}" (longueur: ${staff.nom.length})');
        print('Grade: "${staff.grade}" (longueur: ${staff.grade.length})');
        print('Groupe: "${staff.groupe}" (longueur: ${staff.groupe.length})');

        // Forcer le chargement des activités et les afficher
        final activites = staff.activites.toList();
        print('Nombre d\'activités: ${activites.length}');

        if (activites.isNotEmpty) {
          print('Activités détaillées:');
          for (var activite in activites.take(5)) {
            // Afficher les 5 premières
            print('  Jour ${activite.jour}: "${activite.statut}"');
          }
          if (activites.length > 5) {
            print('  ... et ${activites.length - 5} autres activités');
          }
        } else {
          print('AUCUNE ACTIVITÉ TROUVÉE POUR CE STAFF !');
        }
      }

      // Vérifier également le contenu de la base directement
      final totalActivites = _objectBox.activiteBox.getAll();
      print('\n--- VÉRIFICATION BASE DE DONNÉES ---');
      print('Total activités dans la base: ${totalActivites.length}');

      if (totalActivites.isNotEmpty) {
        print('Quelques activités de la base:');
        for (var activite in totalActivites.take(3)) {
          print(
              '  Activité ID: ${activite.id}, Jour: ${activite.jour}, Statut: "${activite.statut}"');
          print('    Staff lié: ${activite.staff.target?.nom ?? "AUCUN"}');
        }
      }

      print('=========================================================\n');

      notifyListeners();
    } catch (e) {
      print('Erreur lors de la récupération des staffs: $e');
      print('StackTrace: ${StackTrace.current}');
    }
  }

  /// Ajoute un staff avec ses 31 activités
  Future<void> addStaff(Staff staff, List<String> activites) async {
    try {
      // 1️⃣ Sauvegarder le staff pour générer l'id
      _objectBox.staffBox.put(staff);

      // 2️⃣ Créer chaque activité et assigner la relation ToOne correctement
      for (int i = 0; i < activites.length && i < 31; i++) {
        final activite = ActiviteJour(
          jour: i + 1,
          statut: activites[i],
        );

        // Lier le staff existant à l'activité
        activite.staff.target = staff;
        _objectBox.activiteBox.put(activite);
      }

      await fetchStaffs(); // notifie les widgets
    } catch (e) {
      print('Erreur lors de l\'ajout du staff: $e');
    }
  }

  /// Met à jour un staff (hors activités)
  Future<void> updateStaff(Staff staff) async {
    try {
      _objectBox.staffBox.put(staff);
      await fetchStaffs();
    } catch (e) {
      print('Erreur lors de la mise à jour du staff: $e');
    }
  }

  /// Supprime un staff et toutes ses activités
  Future<void> deleteStaff(Staff staff) async {
    try {
      // Supprimer les activités liées via la relation ToMany
      final activitesToDelete = staff.activites.toList();
      for (var activite in activitesToDelete) {
        _objectBox.activiteBox.remove(activite.id);
      }

      // Supprimer le staff
      _objectBox.staffBox.remove(staff.id);
      await fetchStaffs();
    } catch (e) {
      print('Erreur lors de la suppression du staff: $e');
    }
  }
}

/// Provider pour insérer plusieurs activités depuis une liste
class ActiviteProvider with ChangeNotifier {
  late final ObjectBox _objectBox;

  ActiviteProvider() {
    _objectBox = ObjectBox();
  }

  /// Insère la liste complète des activités depuis une liste de personnes
  Future<void> insertActivites(List<ActivitePersonne> liste) async {
    try {
      print('=================== DEBUG INSERTION ===================');
      print('Début insertion de ${liste.length} personnes...');

      // Nettoyer d'abord la base si nécessaire
      print('Nettoyage de la base existante...');
      _objectBox.activiteBox.removeAll();
      _objectBox.staffBox.removeAll();

      int staffCount = 0;
      int activiteCount = 0;

      for (var e in liste) {
        staffCount++;
        print('\n--- INSERTION STAFF ${staffCount} ---');
        print('Nom: "${e.nom}"');
        print('Grade: "${e.grade}"');
        print('Groupe: "${e.groupe}"');
        print('Nombre de jours d\'activité: ${e.jours.length}');

        // 1️⃣ Créer le staff avec toutes les informations
        final staff = Staff(
          nom: e.nom,
          grade: e.grade,
          groupe: e.groupe,
          equipe: e.equipe,
          mois: e.mois,
          horaire: e.horaire,
          obs: e.obs,
        );
        final staffId = _objectBox.staffBox.put(staff);
        print('Staff créé avec ID: $staffId');

        // Vérifier que le staff a bien été créé
        final verifyStaff = _objectBox.staffBox.get(staffId);
        if (verifyStaff != null) {
          print(
              'Vérification - Staff récupéré: "${verifyStaff.nom}", "${verifyStaff.grade}", "${verifyStaff.groupe}"');
        } else {
          print('ERREUR: Impossible de récupérer le staff créé !');
          continue;
        }

        // 2️⃣ Créer les activités et les lier au staff
        print('Création des activités:');
        for (int i = 0; i < e.jours.length && i < 31; i++) {
          activiteCount++;
          final activite = ActiviteJour(
            jour: i + 1,
            statut: e.jours[i],
          );

          activite.staff.target = staff;
          final activiteId = _objectBox.activiteBox.put(activite);

          if (i < 3) {
            // Afficher les 3 premières activités pour debug
            print(
                '  Activité ${i + 1}: Jour ${activite.jour}, Statut "${activite.statut}", ID: $activiteId');
          }
        }
        print('${e.jours.length} activités créées pour ${e.nom}');
      }

      print('\n--- RÉSUMÉ INSERTION ---');
      print('Total staffs insérés: $staffCount');
      print('Total activités insérées: $activiteCount');

      // Vérification finale
      final finalStaffs = _objectBox.staffBox.getAll();
      final finalActivites = _objectBox.activiteBox.getAll();
      print('Vérification finale:');
      print('  Staffs dans la base: ${finalStaffs.length}');
      print('  Activités dans la base: ${finalActivites.length}');

      // Test des relations
      if (finalStaffs.isNotEmpty) {
        final premierStaff = finalStaffs.first;
        final sesActivites = premierStaff.activites.toList();
        print(
            '  Relations - Premier staff "${premierStaff.nom}" a ${sesActivites.length} activités');
      }

      print('=========================================================\n');

      notifyListeners();
    } catch (e) {
      print('Erreur lors de l\'insertion des activités: $e');
      print('StackTrace: ${StackTrace.current}');
      rethrow;
    }
  }
}
