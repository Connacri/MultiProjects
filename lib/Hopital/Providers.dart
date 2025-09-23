import 'package:flutter/material.dart';
import 'package:kenzy/Hopital/repos.dart';
import 'package:kenzy/Hopital/seed.dart';

import '../objectBox/Entity.dart';
import '../objectbox.g.dart'; // tes entités ObjectBox (Personnel, etc.)

class PersonnelProvider with ChangeNotifier {
  final PersonnelRepository repo;
  List<Personnel> _personnels = [];

  PersonnelProvider(this.repo) {
    loadPersonnels();
  }

  List<Personnel> get personnels => _personnels;

  /// Charger tous les personnels
  void loadPersonnels() {
    _personnels = repo.getAll();
    notifyListeners();
  }

  /// Ajouter un nouveau personnel
  void addPersonnel(Personnel p) {
    repo.createPersonnel(p);
    loadPersonnels();
  }

  /// Mettre à jour un personnel
  void updatePersonnel(Personnel p) {
    repo.updatePersonnel(p);
    loadPersonnels();
  }

  /// Supprimer un personnel
  void deletePersonnel(int id) {
    repo.deletePersonnel(id);
    loadPersonnels();
  }

  /// Recharger manuellement
  void refresh() => loadPersonnels();
}

class AffectationJourProvider with ChangeNotifier {
  final AffectationJourRepository repo;
  List<AffectationJour> _affectations = [];

  AffectationJourProvider(this.repo) {
    loadAffectations();
  }

  List<AffectationJour> get affectations => _affectations;

  /// Charger toutes les affectations
  void loadAffectations() {
    _affectations = repo.getAll();
    notifyListeners();
  }

  /// Charger les affectations d'un mois précis
  List<AffectationJour> getForMonth(int annee, int mois) {
    return _affectations
        .where((a) => a.date.year == annee && a.date.month == mois)
        .toList();
  }

  /// Charger les affectations d'un personnel
  List<AffectationJour> getForPersonnel(int personnelId) {
    return _affectations
        .where((a) => a.personnel.target?.id == personnelId)
        .toList();
  }

  /// Ajouter une affectation
  void addAffectation(AffectationJour aff) {
    repo.createAffectation(aff);
    loadAffectations();
  }

  /// Mettre à jour une affectation
  void updateAffectation(AffectationJour aff) {
    repo.updateAffectation(aff);
    loadAffectations();
  }

  /// Supprimer une affectation
  void deleteAffectation(int id) {
    repo.deleteAffectation(id);
    loadAffectations();
  }

  /// Recharger manuellement
  void refresh() => loadAffectations();
}

class ActiviteHebdoProvider with ChangeNotifier {
  final ActiviteHebdoRepository repo;
  List<ActiviteHebdo> _activites = [];

  ActiviteHebdoProvider(this.repo) {
    loadActivites();
  }

  List<ActiviteHebdo> get activites => _activites;

  /// Charger toutes les activités
  void loadActivites() {
    _activites = repo.getAll();
    notifyListeners();
  }

  /// Charger les activités d’un jour précis
  List<ActiviteHebdo> getByJour(String jour) {
    return _activites.where((a) => a.jour == jour).toList();
  }

  /// Charger les activités d’un personnel
  List<ActiviteHebdo> getByPersonnel(int personnelId) {
    return _activites
        .where((a) => a.personnel.target?.id == personnelId)
        .toList();
  }

  /// Ajouter une activité
  void addActivite(ActiviteHebdo act) {
    repo.createActivite(act);
    loadActivites();
  }

  /// Mettre à jour une activité
  void updateActivite(ActiviteHebdo act) {
    repo.updateActivite(act);
    loadActivites();
  }

  /// Supprimer une activité
  void deleteActivite(int id) {
    repo.deleteActivite(id);
    loadActivites();
  }

  /// Recharger manuellement
  void refresh() => loadActivites();
}

class ImportProvider with ChangeNotifier {
  final DatabaseSeeder seeder;
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  bool _isImporting = false;

  ImportProvider(Store store) : seeder = DatabaseSeeder(store);

  bool get isImporting => _isImporting;

  Future<void> runSeed(List<Map<String, dynamic>> rows) async {
    if (_isImporting) return;
    _isImporting = true;
    progress.value = 0.0;
    notifyListeners();

    // Import manuel avec suivi
    final total = rows.length;
    int done = 0;

    for (final chunk in rows) {
      await Future.delayed(const Duration(milliseconds: 50)); // simule calcul
      seeder.importMatrix([chunk]); // import ligne par ligne
      done++;
      progress.value = done / total;
    }

    _isImporting = false;
    notifyListeners();
  }
}


class GroupeTravailProvider with ChangeNotifier {
  final GroupeTravailRepository repo;
  List<GroupeTravail> _groupes = [];

  GroupeTravailProvider(this.repo) {
    loadGroupes();
  }

  List<GroupeTravail> get groupes => _groupes;

  /// Charger tous les groupes depuis le repository
  void loadGroupes() {
    _groupes = repo.getAll();
    notifyListeners();
  }

  /// Ajouter un nouveau groupe
  void addGroupe(GroupeTravail g) {
    repo.createGroupe(g);
    loadGroupes();
  }

  /// Mettre à jour un groupe
  void updateGroupe(GroupeTravail g) {
    repo.updateGroupe(g);
    loadGroupes();
  }

  /// Supprimer un groupe
  void deleteGroupe(int id) {
    repo.deleteGroupe(id);
    loadGroupes();
  }

  /// Recharger manuellement
  void refresh() => loadGroupes();
}
