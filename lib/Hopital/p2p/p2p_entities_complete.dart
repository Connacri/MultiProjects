import 'package:objectbox/objectbox.dart';

import '../../objectBox/Entity.dart';

// 🎯 ENTITÉS P2P - À générer avec ObjectBox generator
// Ces entités ne touchent PAS à vos entités existantes

// Métadonnées P2P pour Staff
@Entity()
class StaffP2P {
  int id = 0;

  @Unique()
  String staffUuid;

  String uuid;
  int version = 1;
  String originId;
  bool deleted = false;
  int lastModified;

  // Relation vers Staff original
  final staff = ToOne<Staff>();

  StaffP2P({
    required this.staffUuid,
    required this.uuid,
    required this.originId,
    required this.lastModified,
  });
}

// Métadonnées P2P pour ActiviteJour
@Entity()
class ActiviteJourP2P {
  int id = 0;

  @Unique()
  String activiteUuid;

  String uuid;
  int version = 1;
  String originId;
  bool deleted = false;
  int lastModified;

  final activite = ToOne<ActiviteJour>();

  ActiviteJourP2P({
    required this.activiteUuid,
    required this.uuid,
    required this.originId,
    required this.lastModified,
  });
}

// Métadonnées P2P pour Branch
@Entity()
class BranchP2P {
  int id = 0;

  @Unique()
  String branchUuid;

  String uuid;
  int version = 1;
  String originId;
  bool deleted = false;
  int lastModified;

  final branch = ToOne<Branch>();

  BranchP2P({
    required this.branchUuid,
    required this.uuid,
    required this.originId,
    required this.lastModified,
  });
}

// État de synchronisation global
@Entity()
class SyncState {
  int id = 0;

  String entityType;
  String entityUuid;
  int lastVersion;
  int lastSynced;
  String lastOriginId;
  bool pendingSync = false;

  SyncState({
    required this.entityType,
    required this.entityUuid,
    this.lastVersion = 1,
    this.lastSynced = 0,
    this.lastOriginId = '',
  });
}

// Journal des opérations P2P
@Entity()
class P2PJournal {
  int id = 0;

  String operation;
  String entityType;
  String entityUuid;
  String dataJson;
  int timestamp;
  String originId;
  bool synced = false;

  P2PJournal({
    required this.operation,
    required this.entityType,
    required this.entityUuid,
    required this.dataJson,
    required this.timestamp,
    required this.originId,
  });
}
