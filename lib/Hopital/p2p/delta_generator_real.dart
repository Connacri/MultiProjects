import 'package:flutter/foundation.dart';
import '../../objectBox/Entity.dart';
import 'p2p_integration_fixed.dart';
import 'p2p_manager_fixed.dart';

/// Générateur de deltas pour la synchronisation P2P
/// Adapté aux entités réelles du projet
class DeltaGenerator with ChangeNotifier {
  static final DeltaGenerator _instance = DeltaGenerator._internal();

  factory DeltaGenerator() => _instance;

  DeltaGenerator._internal();

  final P2PManager _p2pManager = P2PManager();
  final P2PIntegration _p2pIntegration = P2PIntegration();

  /// Génère et broadcaste un delta pour Staff
  Future<void> syncStaff(Staff staff, String operation) async {
    try {
      // Utiliser l'ID comme identifiant unique (puisqu'il n'y a pas d'UUID)
      final delta = {
        'entity': 'Staff',
        'operation': operation, // 'create', 'update', 'delete'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'staffId': staff.id,
          'nom': staff.nom,
          'grade': staff.grade,
          'groupe': staff.groupe,
          'equipe': staff.equipe,
          'obs': staff.obs,
          'ordre': staff.ordre,
          'branchId': staff.branch.targetId, // ID de la branche liée
        },
      };

      print('[DeltaGenerator] 📤 Génération delta Staff: ${staff.nom} (ID: ${staff.id})');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta Staff broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync Staff: $e');
    }
  }

  /// Génère et broadcaste un delta pour ActiviteJour
  Future<void> syncActiviteJour(ActiviteJour activite, String operation) async {
    try {
      final delta = {
        'entity': 'ActiviteJour',
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'activiteId': activite.id,
          'jour': activite.jour,
          'statut': activite.statut,
          'staffId': activite.staff.targetId, // ID du staff lié
        },
      };

      print('[DeltaGenerator] 📤 Génération delta ActiviteJour: Jour ${activite.jour}, Statut ${activite.statut}');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta ActiviteJour broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync ActiviteJour: $e');
    }
  }

  /// Génère et broadcaste un delta pour Branch
  Future<void> syncBranch(Branch branch, String operation) async {
    try {
      final delta = {
        'entity': 'Branch',
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'branchId': branch.id,
          'branchNom': branch.branchNom,
        },
      };

      print('[DeltaGenerator] 📤 Génération delta Branch: ${branch.branchNom}');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta Branch broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync Branch: $e');
    }
  }

  /// Génère et broadcaste un delta pour TimeOff
  Future<void> syncTimeOff(TimeOff timeOff, String operation) async {
    try {
      final delta = {
        'entity': 'TimeOff',
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'timeOffId': timeOff.id,
          'debut': timeOff.debut.millisecondsSinceEpoch,
          'fin': timeOff.fin.millisecondsSinceEpoch,
          'motif': timeOff.motif,
          'staffId': timeOff.staff.targetId,
        },
      };

      print('[DeltaGenerator] 📤 Génération delta TimeOff');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta TimeOff broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync TimeOff: $e');
    }
  }

  /// Génère et broadcaste un delta pour Planification
  Future<void> syncPlanification(Planification planif, String operation) async {
    try {
      final delta = {
        'entity': 'Planification',
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'planifId': planif.id,
          'mois': planif.mois,
          'annee': planif.annee,
          'ordreEquipes': planif.ordreEquipes,
          'activitesJson': planif.activitesJson,
          'branchId': planif.branch.targetId,
        },
      };

      print('[DeltaGenerator] 📤 Génération delta Planification: ${planif.mois}/${planif.annee}');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta Planification broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync Planification: $e');
    }
  }

  /// Génère et broadcaste un delta pour PlanningHebdo
  Future<void> syncPlanningHebdo(PlanningHebdo planning, String operation) async {
    try {
      final delta = {
        'entity': 'PlanningHebdo',
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'planningId': planning.id,
          'staffId': planning.staff.targetId,
          'dimanche': planning.dimanche,
          'lundi': planning.lundi,
          'mardi': planning.mardi,
          'mercredi': planning.mercredi,
          'jeudi': planning.jeudi,
          'vendredi': planning.vendredi,
          'samedi': planning.samedi,
          'dateDebut': planning.dateDebut?.millisecondsSinceEpoch,
          'dateFin': planning.dateFin?.millisecondsSinceEpoch,
        },
      };

      print('[DeltaGenerator] 📤 Génération delta PlanningHebdo');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta PlanningHebdo broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync PlanningHebdo: $e');
    }
  }

  /// Génère et broadcaste un delta pour TypeActivite
  Future<void> syncTypeActivite(TypeActivite type, String operation) async {
    try {
      final delta = {
        'entity': 'TypeActivite',
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': {
          'typeId': type.id,
          'code': type.code,
          'libelle': type.libelle,
          'description': type.description,
          'couleurHex': type.couleurHex,
        },
      };

      print('[DeltaGenerator] 📤 Génération delta TypeActivite: ${type.code}');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta TypeActivite broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync TypeActivite: $e');
    }
  }

  /// Méthode générique pour n'importe quelle entité
  Future<void> syncEntity(
    String entityType,
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      final delta = {
        'entity': entityType,
        'operation': operation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'originId': _p2pManager.nodeId,
        'data': data,
      };

      print('[DeltaGenerator] 📤 Génération delta $entityType');
      await _p2pIntegration.broadcastDelta(delta);
      print('[DeltaGenerator] ✅ Delta $entityType broadcasté');
    } catch (e) {
      print('[DeltaGenerator] ❌ Erreur sync $entityType: $e');
    }
  }
}
