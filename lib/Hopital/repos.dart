import '../objectBox/Entity.dart';
import '../objectbox.g.dart';

/// ==================== GroupeTravail ====================
class GroupeTravailRepository {
  final Box<GroupeTravail> _box;

  GroupeTravailRepository(this._box);

  int createGroupe(GroupeTravail groupe) => _box.put(groupe);

  GroupeTravail? getGroupe(int id) => _box.get(id);

  List<GroupeTravail> getAll() => _box.getAll();

  GroupeTravail? getByNom(String nom) =>
      _box.query(GroupeTravail_.nom.equals(nom)).build().findFirst();

  void updateGroupe(GroupeTravail groupe) => _box.put(groupe);

  void deleteGroupe(int id) => _box.remove(id);

  void clearAll() => _box.removeAll();
}

/// ==================== Observation ====================
class ObservationRepository {
  final Box<Observation> _box;

  ObservationRepository(this._box);

  int createObservation(Observation obs) => _box.put(obs);

  Observation? getObservation(int id) => _box.get(id);

  List<Observation> getAll() => _box.getAll();

  List<Observation> getByPersonnel(int personnelId) =>
      _box.query(Observation_.personnel.equals(personnelId)).build().find();

  List<Observation> getByType(String type) =>
      _box.query(Observation_.type.equals(type)).build().find();

  void updateObservation(Observation obs) => _box.put(obs);

  void deleteObservation(int id) => _box.remove(id);

  void clearAll() => _box.removeAll();
}

/// ==================== ActiviteHebdo ====================
class ActiviteHebdoRepository {
  final Box<ActiviteHebdo> _box;

  ActiviteHebdoRepository(this._box);

  int createActivite(ActiviteHebdo activite) => _box.put(activite);

  ActiviteHebdo? getActivite(int id) => _box.get(id);

  List<ActiviteHebdo> getAll() => _box.getAll();

  List<ActiviteHebdo> getByJour(String jour) =>
      _box.query(ActiviteHebdo_.jour.equals(jour)).build().find();

  List<ActiviteHebdo> getByPersonnel(int personnelId) =>
      _box.query(ActiviteHebdo_.personnel.equals(personnelId)).build().find();

  void updateActivite(ActiviteHebdo activite) => _box.put(activite);

  void deleteActivite(int id) => _box.remove(id);

  void clearAll() => _box.removeAll();
}

/// ==================== AffectationJour ====================
class AffectationJourRepository {
  final Box<AffectationJour> _box;

  AffectationJourRepository(this._box);

  int createAffectation(AffectationJour affectation) => _box.put(affectation);

  AffectationJour? getAffectation(int id) => _box.get(id);

  List<AffectationJour> getAll() => _box.getAll();

  List<AffectationJour> getByDate(DateTime date) => _box
      .query(AffectationJour_.date.equals(date.millisecondsSinceEpoch))
      .build()
      .find();

  List<AffectationJour> getByPersonnel(int personnelId) =>
      _box.query(AffectationJour_.personnel.equals(personnelId)).build().find();

  void updateAffectation(AffectationJour affectation) => _box.put(affectation);

  void deleteAffectation(int id) => _box.remove(id);

  void clearAll() => _box.removeAll();
}

/// ==================== PlanningMois ====================
class PlanningMoisRepository {
  final Box<PlanningMois> _box;

  PlanningMoisRepository(this._box);

  int createPlanning(PlanningMois planning) => _box.put(planning);

  PlanningMois? getPlanning(int id) => _box.get(id);

  List<PlanningMois> getAllPlannings() => _box.getAll();

  List<PlanningMois> getPlanningsByYear(int year) =>
      _box.query(PlanningMois_.annee.equals(year)).build().find();

  void updatePlanning(PlanningMois planning) => _box.put(planning);

  void deletePlanning(int id) => _box.remove(id);

  void clearAll() => _box.removeAll();
}

/// ==================== Personnel ====================
class PersonnelRepository {
  final Box<Personnel> _box;

  PersonnelRepository(this._box);

  // CREATE
  int createPersonnel(Personnel p) => _box.put(p);

  // READ
  Personnel? getPersonnel(int id) => _box.get(id);

  List<Personnel> getAll() => _box.getAll();

  List<Personnel> searchByNom(String nom) =>
      _box.query(Personnel_.nom.contains(nom)).build().find();

  // UPDATE
  void updatePersonnel(Personnel p) => _box.put(p);

  // DELETE
  void deletePersonnel(int id) => _box.remove(id);

  void clearAll() => _box.removeAll();
}
