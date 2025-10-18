import '../../objectBox/Entity.dart';
import '../../objectBox/classeObjectBox.dart';
import 'delta_generator_real.dart';

/// Service de synchronisation P2P automatique
/// Utilisation simple : remplace vos appels directs à ObjectBox
class P2PSyncService {
  final ObjectBox _objectBox = ObjectBox();
  final DeltaGenerator _deltaGenerator = DeltaGenerator();
  final syncService = P2PSyncService();

  // ========== STAFF ==========

  /// Crée un Staff avec sync automatique
  Future<Staff> createStaff(Staff staff) async {
    final savedId = _objectBox.staffBox.put(staff);
    final savedStaff = _objectBox.staffBox.get(savedId)!;
    print('[P2PSync] ✅ Staff créé localement: ${savedStaff.nom}');

    await _deltaGenerator.syncStaff(savedStaff, 'create');
    print('[P2PSync] 📤 Staff synchronisé');
    return savedStaff;
  }

  /// Met à jour un Staff avec sync automatique
  Future<void> updateStaff(Staff staff) async {
    _objectBox.staffBox.put(staff);
    print('[P2PSync] ✅ Staff mis à jour localement: ${staff.nom}');

    await _deltaGenerator.syncStaff(staff, 'update');
    print('[P2PSync] 📤 Staff synchronisé');
  }

  /// Supprime un Staff avec sync automatique
  Future<void> deleteStaff(Staff staff) async {
    print('[P2PSync] 🗑️ Suppression Staff: ${staff.nom}');

    await _deltaGenerator.syncStaff(staff, 'delete');
    _objectBox.staffBox.remove(staff.id);
    print('[P2PSync] ✅ Staff supprimé et synchronisé');
  }

  // ========== ACTIVITE JOUR ==========

  /// Crée une ActiviteJour avec sync automatique
  Future<ActiviteJour> createActivite(ActiviteJour activite) async {
    final savedId = _objectBox.activiteBox.put(activite);
    final savedActivite = _objectBox.activiteBox.get(savedId)!;
    print('[P2PSync] ✅ Activité créée: Jour ${savedActivite.jour}');

    await _deltaGenerator.syncActiviteJour(savedActivite, 'create');
    return savedActivite;
  }

  /// Met à jour une ActiviteJour avec sync automatique
  Future<void> updateActivite(ActiviteJour activite) async {
    _objectBox.activiteBox.put(activite);
    print('[P2PSync] ✅ Activité mise à jour: Jour ${activite.jour}');

    await _deltaGenerator.syncActiviteJour(activite, 'update');
  }

  /// Supprime une ActiviteJour avec sync automatique
  Future<void> deleteActivite(ActiviteJour activite) async {
    await _deltaGenerator.syncActiviteJour(activite, 'delete');
    _objectBox.activiteBox.remove(activite.id);
    print('[P2PSync] ✅ Activité supprimée et synchronisée');
  }

  // ========== BRANCH ==========

  /// Crée un Branch avec sync automatique
  Future<Branch> createBranch(Branch branch) async {
    final savedId = _objectBox.branchBox.put(branch);
    final savedBranch = _objectBox.branchBox.get(savedId)!;
    print('[P2PSync] ✅ Branch créée: ${savedBranch.branchNom}');

    await _deltaGenerator.syncBranch(savedBranch, 'create');
    return savedBranch;
  }

  /// Met à jour un Branch avec sync automatique
  Future<void> updateBranch(Branch branch) async {
    _objectBox.branchBox.put(branch);
    print('[P2PSync] ✅ Branch mise à jour: ${branch.branchNom}');

    await _deltaGenerator.syncBranch(branch, 'update');
  }

  /// Supprime un Branch avec sync automatique
  Future<void> deleteBranch(Branch branch) async {
    await _deltaGenerator.syncBranch(branch, 'delete');
    _objectBox.branchBox.remove(branch.id);
    print('[P2PSync] ✅ Branch supprimée et synchronisée');
  }

  // ========== TIME OFF ==========

  /// Crée un TimeOff avec sync automatique
  Future<TimeOff> createTimeOff(TimeOff timeOff) async {
    final savedId = _objectBox.timeOffBox.put(timeOff);
    final savedTimeOff = _objectBox.timeOffBox.get(savedId)!;
    print('[P2PSync] ✅ TimeOff créé');

    await _deltaGenerator.syncTimeOff(savedTimeOff, 'create');
    return savedTimeOff;
  }

  /// Met à jour un TimeOff avec sync automatique
  Future<void> updateTimeOff(TimeOff timeOff) async {
    _objectBox.timeOffBox.put(timeOff);
    await _deltaGenerator.syncTimeOff(timeOff, 'update');
  }

  /// Supprime un TimeOff avec sync automatique
  Future<void> deleteTimeOff(TimeOff timeOff) async {
    await _deltaGenerator.syncTimeOff(timeOff, 'delete');
    _objectBox.timeOffBox.remove(timeOff.id);
  }

  // ========== PLANIFICATION ==========

  /// Crée une Planification avec sync automatique
  Future<Planification> createPlanification(Planification planif) async {
    final savedId = _objectBox.planificationBox.put(planif);
    final savedPlanif = _objectBox.planificationBox.get(savedId)!;
    print(
        '[P2PSync] ✅ Planification créée: ${savedPlanif.mois}/${savedPlanif.annee}');

    await _deltaGenerator.syncPlanification(savedPlanif, 'create');
    return savedPlanif;
  }

  /// Met à jour une Planification avec sync automatique
  Future<void> updatePlanification(Planification planif) async {
    _objectBox.planificationBox.put(planif);
    print(
        '[P2PSync] ✅ Planification mise à jour: ${planif.mois}/${planif.annee}');

    await _deltaGenerator.syncPlanification(planif, 'update');
  }

  /// Supprime une Planification avec sync automatique
  Future<void> deletePlanification(Planification planif) async {
    await _deltaGenerator.syncPlanification(planif, 'delete');
    _objectBox.planificationBox.remove(planif.id);
  }

  // ========== PLANNING HEBDO ==========

  /// Crée un PlanningHebdo avec sync automatique
  Future<PlanningHebdo> createPlanningHebdo(PlanningHebdo planning) async {
    final savedId = _objectBox.planningHebdoBox.put(planning);
    final savedPlanning = _objectBox.planningHebdoBox.get(savedId)!;
    print('[P2PSync] ✅ PlanningHebdo créé');

    await _deltaGenerator.syncPlanningHebdo(savedPlanning, 'create');
    return savedPlanning;
  }

  /// Met à jour un PlanningHebdo avec sync automatique
  Future<void> updatePlanningHebdo(PlanningHebdo planning) async {
    _objectBox.planningHebdoBox.put(planning);
    await _deltaGenerator.syncPlanningHebdo(planning, 'update');
  }

  /// Supprime un PlanningHebdo avec sync automatique
  Future<void> deletePlanningHebdo(PlanningHebdo planning) async {
    await _deltaGenerator.syncPlanningHebdo(planning, 'delete');
    _objectBox.planningHebdoBox.remove(planning.id);
  }

  // ========== TYPE ACTIVITE ==========

  /// Crée un TypeActivite avec sync automatique
  Future<TypeActivite> createTypeActivite(TypeActivite type) async {
    final savedId = _objectBox.typeActiviteBox.put(type);
    final savedType = _objectBox.typeActiviteBox.get(savedId)!;
    print('[P2PSync] ✅ TypeActivite créé: ${savedType.code}');

    await _deltaGenerator.syncTypeActivite(savedType, 'create');
    return savedType;
  }

  /// Met à jour un TypeActivite avec sync automatique
  Future<void> updateTypeActivite(TypeActivite type) async {
    _objectBox.typeActiviteBox.put(type);
    await _deltaGenerator.syncTypeActivite(type, 'update');
  }

  /// Supprime un TypeActivite avec sync automatique
  Future<void> deleteTypeActivite(TypeActivite type) async {
    await _deltaGenerator.syncTypeActivite(type, 'delete');
    _objectBox.typeActiviteBox.remove(type.id);
  }

  // ========== BATCH OPERATIONS ==========

  /// Synchronise plusieurs activités d'un coup (pour un mois entier par exemple)
  Future<void> syncMultipleActivites(List<ActiviteJour> activites) async {
    print(
        '[P2PSync] 📦 Synchronisation batch de ${activites.length} activités');

    for (final activite in activites) {
      _objectBox.activiteBox.put(activite);
      await _deltaGenerator.syncActiviteJour(activite, 'update');
    }

    print('[P2PSync] ✅ Batch synchronisé');
  }

  /// Synchronise toutes les modifications d'une planification
  Future<void> syncFullPlanification(
    Planification planif,
    List<ActiviteJour> activites,
  ) async {
    print(
        '[P2PSync] 📦 Sync planification complète: ${planif.mois}/${planif.annee}');

    // Sync la planification
    _objectBox.planificationBox.put(planif);
    await _deltaGenerator.syncPlanification(planif, 'update');

    // Sync toutes les activités
    for (final activite in activites) {
      _objectBox.activiteBox.put(activite);
      await _deltaGenerator.syncActiviteJour(activite, 'update');
    }

    print('[P2PSync] ✅ Planification complète synchronisée');
  }
}
