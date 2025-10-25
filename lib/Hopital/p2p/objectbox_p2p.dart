import '../../objectBox/Entity.dart';
import '../../objectBox/classeObjectBox.dart';
import '../../objectbox.g.dart';
import 'objectbox_sync_observer.dart';

/// Gestionnaire ObjectBox pour P2P - Singleton
/// ✅ CORRECTION MAJEURE: Gestion correcte des IDs dans les deltas
class ObjectBoxP2P {
  static ObjectBoxP2P? _instance;
  late final ObjectBox _objectBox;
  late final ObjectBoxSyncObserver _syncObserver;

  ObjectBoxP2P._internal(this._objectBox) {
    _syncObserver = ObjectBoxSyncObserver();
  }

  static Future<ObjectBoxP2P> getInstance() async {
    _instance ??= await _initialize();
    return _instance!;
  }

  static Future<ObjectBoxP2P> _initialize() async {
    try {
      final objectBox = ObjectBox();
      print('[ObjectBoxP2P] ✅ Store initialisé');
      return ObjectBoxP2P._internal(objectBox);
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  /// ✅ CORRECTION: Applique un delta en désactivant l'observer
  void applyDelta(Map<String, dynamic> delta) {
    try {
      final entityType = delta['entity'] as String?;
      final operation = delta['operation'] as String?;
      final data = delta['data'] as Map<String, dynamic>?;
      final originId = delta['originId'] as String?;

      if (entityType == null || operation == null || data == null) {
        print('[ObjectBoxP2P] ⚠️ Delta invalide: $delta');
        return;
      }

      print('[ObjectBoxP2P] 📥 Application delta: $operation sur $entityType');
      print('[ObjectBoxP2P] 📍 Origine: $originId');
      print('[ObjectBoxP2P] 📊 Données reçues: $data');

      // ✅ CRITIQUE: Désactiver l'observer pendant l'application
      _syncObserver.setApplyingRemoteDelta(true);

      try {
        // ✅ NOUVEAU : Marquer le delta AVANT l'application
        _syncObserver.markDeltaAsApplied(entityType, data);

        switch (entityType) {
          case 'Staff':
            _applyStaffDelta(operation, data);
            break;
          case 'ActiviteJour':
            _applyActiviteJourDelta(operation, data);
            break;
          case 'Branch':
            _applyBranchDelta(operation, data);
            break;
          case 'TimeOff':
            _applyTimeOffDelta(operation, data);
            break;
          case 'Planification':
            _applyPlanificationDelta(operation, data);
            break;
          case 'PlanningHebdo':
            _applyPlanningHebdoDelta(operation, data);
            break;
          case 'TypeActivite':
            _applyTypeActiviteDelta(operation, data);
            break;
          default:
            print('[ObjectBoxP2P] ⚠️ Type d\'entité inconnu: $entityType');
        }
      } finally {
        // ✅ CRITIQUE: Réactiver l'observer après un délai plus long
        Future.delayed(Duration(seconds: 3), () {
          _syncObserver.setApplyingRemoteDelta(false);
          print('[ObjectBoxP2P] 🔓 Observer réactivé après traitement delta');
        });
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur application delta: $e');
      print('[ObjectBoxP2P] Stack: ${StackTrace.current}');
      _syncObserver.setApplyingRemoteDelta(false);
    }
  }

  // ✅ CORRECTION MAJEURE: Accepter 'id' OU 'staffId'
  void _applyStaffDelta(String operation, Map<String, dynamic> data) {
    try {
      // ✅ CORRECTION: Chercher 'id' en priorité, puis 'staffId'
      final staffId = (data['id'] ?? data['staffId']) as int?;

      if (staffId == null) {
        print('[ObjectBoxP2P] ❌ ID manquant dans les données: $data');
        return;
      }

      print('[ObjectBoxP2P] 🔍 Traitement Staff ID: $staffId');

      switch (operation) {
        case 'create':
        case 'update':
          final existingStaff = _objectBox.staffBox.get(staffId);

          if (existingStaff != null) {
            // ✅ MISE À JOUR
            print('[ObjectBoxP2P] 🔄 Mise à jour Staff existant ID: $staffId');

            existingStaff.nom = data['nom'] ?? existingStaff.nom;
            existingStaff.grade = data['grade'] ?? existingStaff.grade;
            existingStaff.groupe = data['groupe'] ?? existingStaff.groupe;
            existingStaff.equipe = data['equipe'];
            existingStaff.obs = data['obs'];
            existingStaff.ordre = data['ordre'];

            // ✅ Gérer la relation Branch
            final branchId = data['branchId'];
            if (branchId != null) {
              _ensureBranchExists(branchId);
              existingStaff.branch.targetId = branchId;
            }

            _objectBox.staffBox.put(existingStaff);
            print(
                '[ObjectBoxP2P] ✅ Staff mis à jour: ${existingStaff.nom} (ID: $staffId)');
          } else {
            // ✅ CRÉATION
            print('[ObjectBoxP2P] ➕ Création nouveau Staff ID: $staffId');

            final newStaff = Staff(
              id: staffId,
              nom: data['nom'] ?? '',
              grade: data['grade'] ?? '',
              groupe: data['groupe'] ?? '',
              equipe: data['equipe'],
              obs: data['obs'],
              ordre: data['ordre'],
            );

            final branchId = data['branchId'];
            if (branchId != null) {
              _ensureBranchExists(branchId);
              newStaff.branch.targetId = branchId;
            }

            _objectBox.staffBox.put(newStaff, mode: PutMode.insert);
            print(
                '[ObjectBoxP2P] ✅ Nouveau Staff créé: ${newStaff.nom} (ID: $staffId)');
          }

          // ✅ VÉRIFICATION
          final verification = _objectBox.staffBox.get(staffId);
          if (verification != null) {
            print(
                '[ObjectBoxP2P] ✅ VÉRIFICATION: Staff $staffId existe - ${verification.nom}');
            print(
                '[ObjectBoxP2P] 📍 BranchId: ${verification.branch.targetId}');
          } else {
            print(
                '[ObjectBoxP2P] ❌ ERREUR: Staff $staffId introuvable après insertion!');
          }

          final totalStaff = _objectBox.staffBox.count();
          print('[ObjectBoxP2P] 📊 TOTAL Staff dans DB: $totalStaff');
          break;

        case 'delete':
          print('[ObjectBoxP2P] 🗑️ Suppression Staff ID: $staffId');
          _objectBox.staffBox.remove(staffId);
          print('[ObjectBoxP2P] ✅ Staff supprimé');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ ERREUR CRITIQUE Staff: $e');
      print('[ObjectBoxP2P] Stack: ${StackTrace.current}');
    }
  }

  // ✅ HELPER: S'assurer que la branche existe
  void _ensureBranchExists(int branchId) {
    final branch = _objectBox.branchBox.get(branchId);
    if (branch == null) {
      print('[ObjectBoxP2P] ⚠️ Branch $branchId n\'existe pas, création...');
      final newBranch = Branch(
        id: branchId,
        branchNom: 'Branche $branchId',
      );
      _objectBox.branchBox.put(newBranch, mode: PutMode.insert);
      print('[ObjectBoxP2P] ✅ Branch $branchId créée');
    }
  }

  void _applyActiviteJourDelta(String operation, Map<String, dynamic> data) {
    try {
      final activiteId = (data['id'] ?? data['activiteId']) as int?;
      if (activiteId == null) return;

      switch (operation) {
        case 'create':
        case 'update':
          final existingActivite = _objectBox.activiteBox.get(activiteId);

          if (existingActivite != null) {
            existingActivite.jour = data['jour'] ?? existingActivite.jour;
            existingActivite.statut = data['statut'] ?? existingActivite.statut;
            if (data['staffId'] != null) {
              existingActivite.staff.targetId = data['staffId'] as int;
            }
            _objectBox.activiteBox.put(existingActivite);
            print('[ObjectBoxP2P] ✅ ActiviteJour mise à jour: $activiteId');
          } else if (operation == 'create') {
            final newActivite = ActiviteJour(
              id: activiteId,
              jour: data['jour'] ?? 0,
              statut: data['statut'] ?? '',
            );
            if (data['staffId'] != null) {
              newActivite.staff.targetId = data['staffId'] as int;
            }
            _objectBox.activiteBox.put(newActivite, mode: PutMode.insert);
            print('[ObjectBoxP2P] ✅ ActiviteJour créée: $activiteId');
          }
          break;

        case 'delete':
          _objectBox.activiteBox.remove(activiteId);
          print('[ObjectBoxP2P] ✅ ActiviteJour supprimée: $activiteId');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta ActiviteJour: $e');
    }
  }

  void _applyBranchDelta(String operation, Map<String, dynamic> data) {
    try {
      final branchId = (data['id'] ?? data['branchId']) as int?;
      if (branchId == null) return;

      switch (operation) {
        case 'create':
        case 'update':
          final existingBranch = _objectBox.branchBox.get(branchId);

          if (existingBranch != null) {
            existingBranch.branchNom =
                data['branchNom'] ?? existingBranch.branchNom;
            _objectBox.branchBox.put(existingBranch);
            print('[ObjectBoxP2P] ✅ Branch mise à jour: $branchId');
          } else if (operation == 'create') {
            final newBranch = Branch(
              id: branchId,
              branchNom: data['branchNom'] ?? '',
            );
            _objectBox.branchBox.put(newBranch, mode: PutMode.insert);
            print('[ObjectBoxP2P] ✅ Branch créée: $branchId');
          }
          break;

        case 'delete':
          _objectBox.branchBox.remove(branchId);
          print('[ObjectBoxP2P] ✅ Branch supprimée: $branchId');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta Branch: $e');
    }
  }

  void _applyTimeOffDelta(String operation, Map<String, dynamic> data) {
    try {
      final timeOffId = (data['id'] ?? data['timeOffId']) as int?;
      if (timeOffId == null) return;

      switch (operation) {
        case 'create':
        case 'update':
          final existing = _objectBox.timeOffBox.get(timeOffId);
          if (existing != null) {
            existing.motif = data['motif'];
            if (data['debut'] != null) {
              existing.debut =
                  DateTime.fromMillisecondsSinceEpoch(data['debut']);
            }
            if (data['fin'] != null) {
              existing.fin = DateTime.fromMillisecondsSinceEpoch(data['fin']);
            }
            if (data['staffId'] != null) {
              existing.staff.targetId = data['staffId'];
            }
            _objectBox.timeOffBox.put(existing);
            print('[ObjectBoxP2P] ✅ TimeOff mis à jour: $timeOffId');
          } else if (operation == 'create') {
            final newTimeOff = TimeOff(
              id: timeOffId,
              debut: DateTime.fromMillisecondsSinceEpoch(data['debut'] ?? 0),
              fin: DateTime.fromMillisecondsSinceEpoch(data['fin'] ?? 0),
              motif: data['motif'],
            );
            if (data['staffId'] != null) {
              newTimeOff.staff.targetId = data['staffId'];
            }
            _objectBox.timeOffBox.put(newTimeOff, mode: PutMode.insert);
            print('[ObjectBoxP2P] ✅ TimeOff créé: $timeOffId');
          }
          break;
        case 'delete':
          _objectBox.timeOffBox.remove(timeOffId);
          print('[ObjectBoxP2P] ✅ TimeOff supprimé: $timeOffId');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta TimeOff: $e');
    }
  }

  void _applyPlanificationDelta(String operation, Map<String, dynamic> data) {
    try {
      final planifId = (data['id'] ?? data['planifId']) as int?;
      if (planifId == null) return;

      switch (operation) {
        case 'create':
        case 'update':
          final existing = _objectBox.planificationBox.get(planifId);
          if (existing != null) {
            existing.mois = data['mois'] ?? existing.mois;
            existing.annee = data['annee'] ?? existing.annee;
            existing.ordreEquipes =
                data['ordreEquipes'] ?? existing.ordreEquipes;
            existing.activitesJson = data['activitesJson'];
            if (data['branchId'] != null) {
              existing.branch.targetId = data['branchId'];
            }
            _objectBox.planificationBox.put(existing);
            print('[ObjectBoxP2P] ✅ Planification mise à jour: $planifId');
          } else if (operation == 'create') {
            final newPlanif = Planification(
              id: planifId,
              mois: data['mois'] ?? 1,
              annee: data['annee'] ?? 2025,
              ordreEquipes: data['ordreEquipes'] ?? '',
              activitesJson: data['activitesJson'],
            );
            if (data['branchId'] != null) {
              newPlanif.branch.targetId = data['branchId'];
            }
            _objectBox.planificationBox.put(newPlanif, mode: PutMode.insert);
            print('[ObjectBoxP2P] ✅ Planification créée: $planifId');
          }
          break;
        case 'delete':
          _objectBox.planificationBox.remove(planifId);
          print('[ObjectBoxP2P] ✅ Planification supprimée: $planifId');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta Planification: $e');
    }
  }

  void _applyPlanningHebdoDelta(String operation, Map<String, dynamic> data) {
    try {
      final planningId = (data['id'] ?? data['planningId']) as int?;
      if (planningId == null) return;

      switch (operation) {
        case 'create':
        case 'update':
          final existing = _objectBox.planningHebdoBox.get(planningId);
          if (existing != null) {
            existing.dimanche = data['dimanche'];
            existing.lundi = data['lundi'];
            existing.mardi = data['mardi'];
            existing.mercredi = data['mercredi'];
            existing.jeudi = data['jeudi'];
            existing.vendredi = data['vendredi'];
            existing.samedi = data['samedi'];
            if (data['dateDebut'] != null) {
              existing.dateDebut =
                  DateTime.fromMillisecondsSinceEpoch(data['dateDebut']);
            }
            if (data['dateFin'] != null) {
              existing.dateFin =
                  DateTime.fromMillisecondsSinceEpoch(data['dateFin']);
            }
            if (data['staffId'] != null) {
              existing.staff.targetId = data['staffId'];
            }
            _objectBox.planningHebdoBox.put(existing);
            print('[ObjectBoxP2P] ✅ PlanningHebdo mis à jour: $planningId');
          } else if (operation == 'create') {
            final newPlanning = PlanningHebdo(
              id: planningId,
              dimanche: data['dimanche'],
              lundi: data['lundi'],
              mardi: data['mardi'],
              mercredi: data['mercredi'],
              jeudi: data['jeudi'],
              vendredi: data['vendredi'],
              samedi: data['samedi'],
              dateDebut: data['dateDebut'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(data['dateDebut'])
                  : null,
              dateFin: data['dateFin'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(data['dateFin'])
                  : null,
            );
            if (data['staffId'] != null) {
              newPlanning.staff.targetId = data['staffId'];
            }
            _objectBox.planningHebdoBox.put(newPlanning, mode: PutMode.insert);
            print('[ObjectBoxP2P] ✅ PlanningHebdo créé: $planningId');
          }
          break;
        case 'delete':
          _objectBox.planningHebdoBox.remove(planningId);
          print('[ObjectBoxP2P] ✅ PlanningHebdo supprimé: $planningId');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta PlanningHebdo: $e');
    }
  }

  void _applyTypeActiviteDelta(String operation, Map<String, dynamic> data) {
    try {
      final typeId = (data['id'] ?? data['typeId']) as int?;
      if (typeId == null) return;

      switch (operation) {
        case 'create':
        case 'update':
          final existing = _objectBox.typeActiviteBox.get(typeId);
          if (existing != null) {
            existing.code = data['code'] ?? existing.code;
            existing.libelle = data['libelle'] ?? existing.libelle;
            existing.description = data['description'];
            existing.couleurHex = data['couleurHex'];
            _objectBox.typeActiviteBox.put(existing);
            print('[ObjectBoxP2P] ✅ TypeActivite mis à jour: $typeId');
          } else if (operation == 'create') {
            final newType = TypeActivite(
              id: typeId,
              code: data['code'] ?? '',
              libelle: data['libelle'] ?? '',
              description: data['description'],
              couleurHex: data['couleurHex'],
            );
            _objectBox.typeActiviteBox.put(newType, mode: PutMode.insert);
            print('[ObjectBoxP2P] ✅ TypeActivite créé: $typeId');
          }
          break;
        case 'delete':
          _objectBox.typeActiviteBox.remove(typeId);
          print('[ObjectBoxP2P] ✅ TypeActivite supprimé: $typeId');
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta TypeActivite: $e');
    }
  }

  ObjectBox getObjectBox() => _objectBox;

  void dispose() {
    print('[ObjectBoxP2P] ℹ️ ObjectBoxP2P dispose');
  }
}
