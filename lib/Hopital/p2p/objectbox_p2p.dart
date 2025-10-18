import '../../objectBox/classeObjectBox.dart';

/// Gestionnaire ObjectBox pour P2P - Singleton
/// Responsabilité: Gérer le stockage local des entités P2P
/// ✅ CORRECTION: Utiliser l'instance ObjectBox existante au lieu de créer une nouvelle
class ObjectBoxP2P {
  static ObjectBoxP2P? _instance;
  late final ObjectBox _objectBox;

  ObjectBoxP2P._internal(this._objectBox);

  /// Instance singleton
  static Future<ObjectBoxP2P> getInstance() async {
    _instance ??= await _initialize();
    return _instance!;
  }

  /// Initialise en utilisant l'ObjectBox existant
  static Future<ObjectBoxP2P> _initialize() async {
    try {
      // ✅ Utiliser l'instance ObjectBox existante (singleton)
      final objectBox = ObjectBox();
      print(
          '[ObjectBoxP2P] ✅ Store initialisé (réutilisant ObjectBox existant)');
      return ObjectBoxP2P._internal(objectBox);
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  /// Applique un delta localement
  void applyDelta(Map<String, dynamic> delta) {
    try {
      final entityType = delta['entity'] as String?;
      final operation = delta['operation'] as String?;
      final data = delta['data'] as Map<String, dynamic>?;

      if (entityType == null || operation == null || data == null) {
        print('[ObjectBoxP2P] ⚠️ Delta invalide: $delta');
        return;
      }

      print(
        '[ObjectBoxP2P] Appel du delta: $operation sur $entityType',
      );

      // Implémenter selon vos entités
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
        default:
          print('[ObjectBoxP2P] ⚠️ Type d\'entité inconnu: $entityType');
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur application delta: $e');
    }
  }

  /// Applique un delta Staff
  void _applyStaffDelta(String operation, Map<String, dynamic> data) {
    try {
      switch (operation) {
        case 'create':
        case 'update':
          print('[ObjectBoxP2P] Staff mise à jour: ${data['staffUuid']}');
          // TODO: Implémenter la création/mise à jour Staff
          // Exemple :
          // final staffId = data['staffId'] as int?;
          // if (staffId != null) {
          //   final staff = _objectBox.staffBox.get(staffId);
          //   if (staff != null) {
          //     staff.nom = data['nom'] ?? staff.nom;
          //     _objectBox.staffBox.put(staff);
          //   }
          // }
          break;
        case 'delete':
          print('[ObjectBoxP2P] Staff supprimé: ${data['staffUuid']}');
          // TODO: Implémenter la suppression Staff
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta Staff: $e');
    }
  }

  /// Applique un delta ActiviteJour
  void _applyActiviteJourDelta(String operation, Map<String, dynamic> data) {
    try {
      switch (operation) {
        case 'create':
        case 'update':
          print(
              '[ObjectBoxP2P] ActiviteJour mise à jour: ${data['activiteUuid']}');
          // TODO: Implémenter la création/mise à jour ActiviteJour
          break;
        case 'delete':
          print(
              '[ObjectBoxP2P] ActiviteJour supprimé: ${data['activiteUuid']}');
          // TODO: Implémenter la suppression ActiviteJour
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta ActiviteJour: $e');
    }
  }

  /// Applique un delta Branch
  void _applyBranchDelta(String operation, Map<String, dynamic> data) {
    try {
      switch (operation) {
        case 'create':
        case 'update':
          print('[ObjectBoxP2P] Branch mise à jour: ${data['branchUuid']}');
          // TODO: Implémenter la création/mise à jour Branch
          break;
        case 'delete':
          print('[ObjectBoxP2P] Branch supprimé: ${data['branchUuid']}');
          // TODO: Implémenter la suppression Branch
          break;
      }
    } catch (e) {
      print('[ObjectBoxP2P] ❌ Erreur delta Branch: $e');
    }
  }

  /// Accès à l'ObjectBox existant pour les opérations avancées
  ObjectBox getObjectBox() => _objectBox;

  /// Dispose de l'instance (ne ferme pas le store car il est géré par ObjectBox singleton)
  void dispose() {
    print(
        '[ObjectBoxP2P] ℹ️ ObjectBoxP2P dispose (Store managé par ObjectBox)');
    // Ne pas fermer le store ici car c'est un singleton géré ailleurs
  }
}
