import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../objectBox/Entity.dart';
import '../../objectbox.g.dart' hide SyncState;
import 'connection_manager.dart';
import 'crypto_manager.dart';
import 'p2p_entities.dart';
import 'p2p_managers.dart';

class ObjectBoxP2P {
  late final Store store;

  // Boxes originales
  late final Box<Staff> staffBox;
  late final Box<ActiviteJour> activiteBox;
  late final Box<Branch> branchBox;
  late final Box<TimeOff> timeOffBox;
  late final Box<Planification> planificationBox;
  late final Box<PlanningHebdo> planningHebdoBox;
  late final Box<TypeActivite> typeActiviteBox;

  // Boxes P2P
  late final Box<StaffP2P> staffP2PBox;
  late final Box<ActiviteJourP2P> activiteP2PBox;
  late final Box<BranchP2P> branchP2PBox;
  late final Box<SyncState> syncStateBox;
  late final Box<P2PJournal> journalBox;

  ObjectBoxP2P._create(this.store) {
    staffBox = Box<Staff>(store);
    activiteBox = Box<ActiviteJour>(store);
    branchBox = Box<Branch>(store);
    timeOffBox = Box<TimeOff>(store);
    planificationBox = Box<Planification>(store);
    planningHebdoBox = Box<PlanningHebdo>(store);
    typeActiviteBox = Box<TypeActivite>(store);

    staffP2PBox = Box<StaffP2P>(store);
    activiteP2PBox = Box<ActiviteJourP2P>(store);
    branchP2PBox = Box<BranchP2P>(store);
    syncStateBox = Box<SyncState>(store);
    journalBox = Box<P2PJournal>(store);
  }

  static Future<ObjectBoxP2P> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(dir.path, 'hopital-p2p'));
    return ObjectBoxP2P._create(store);
  }

  // Générateur d’UUID
  String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    String two(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${two(bytes[0])}${two(bytes[1])}${two(bytes[2])}${two(bytes[3])}-'
        '${two(bytes[4])}${two(bytes[5])}-'
        '${two(bytes[6])}${two(bytes[7])}-'
        '${two(bytes[8])}${two(bytes[9])}-'
        '${bytes.sublist(10).map(two).join()}';
  }

  // 🔹 STAFF
  String registerStaff(Staff staff, {String? originId}) {
    final uuid = _generateUuid();
    final staffP2p = StaffP2P(
      staffUuid: uuid,
      uuid: _generateUuid(),
      originId: originId ?? P2PManager().nodeId,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    )..staff.target = staff;

    staffP2PBox.put(staffP2p);
    _createSyncState('Staff', staffP2p.uuid);
    _journalOperation('CREATE', 'Staff', staffP2p.uuid, _staffToJson(staff));
    return staffP2p.uuid;
  }

  void updateStaff(Staff staff) {
    final p2p = _getStaffP2P(staff);
    if (p2p != null) {
      p2p.version++;
      p2p.lastModified = DateTime.now().millisecondsSinceEpoch;
      p2p.deleted = false;
      staffP2PBox.put(p2p);
      _updateSyncState('Staff', p2p.uuid, p2p.version);
      _journalOperation('UPDATE', 'Staff', p2p.uuid, _staffToJson(staff));
    } else {
      registerStaff(staff);
    }
  }

  void deleteStaff(Staff staff) {
    final p2p = _getStaffP2P(staff);
    if (p2p != null) {
      p2p.deleted = true;
      p2p.version++;
      p2p.lastModified = DateTime.now().millisecondsSinceEpoch;
      staffP2PBox.put(p2p);
      _updateSyncState('Staff', p2p.uuid, p2p.version);
      _journalOperation('DELETE', 'Staff', p2p.uuid, _staffToJson(staff));
    }
  }

  // 🔹 ACTIVITÉ
  String registerActiviteJour(ActiviteJour activite, {String? originId}) {
    final p2p = ActiviteJourP2P(
      activiteUuid: _generateUuid(),
      uuid: _generateUuid(),
      originId: originId ?? P2PManager().nodeId,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    )..activite.target = activite;

    activiteP2PBox.put(p2p);
    _createSyncState('ActiviteJour', p2p.uuid);
    _journalOperation(
        'CREATE', 'ActiviteJour', p2p.uuid, _activiteToJson(activite));
    return p2p.uuid;
  }

  void updateActiviteJour(ActiviteJour activite) {
    final p2p = _getActiviteP2P(activite);
    if (p2p != null) {
      p2p.version++;
      p2p.lastModified = DateTime.now().millisecondsSinceEpoch;
      activiteP2PBox.put(p2p);
      _updateSyncState('ActiviteJour', p2p.uuid, p2p.version);
      _journalOperation(
          'UPDATE', 'ActiviteJour', p2p.uuid, _activiteToJson(activite));
    }
  }

  // 🔹 SYNCHRO
  Map<String, Map<String, int>> getSyncSummary() {
    return {
      'Staff': {for (var p in staffP2PBox.getAll()) p.uuid: p.version},
      'ActiviteJour': {
        for (var p in activiteP2PBox.getAll()) p.uuid: p.version
      },
      'Branch': {for (var p in branchP2PBox.getAll()) p.uuid: p.version},
    };
  }

  // 🔹 DELTAS
  List<Map<String, dynamic>> getDeltasSince(int timestamp) {
    final journals = journalBox
        .query(P2PJournal_.timestamp.greaterThan(timestamp) &
            P2PJournal_.synced.equals(false))
        .build()
        .find();

    final deltas = <Map<String, dynamic>>[];
    for (final journal in journals) {
      deltas.add({
        'entity': journal.entityType,
        'uuid': journal.entityUuid,
        'operation': journal.operation,
        'data': jsonDecode(journal.dataJson),
        'timestamp': journal.timestamp,
        'originId': journal.originId,
        'version': _findVersion(journal.entityType, journal.entityUuid),
      });
      journal.synced = true;
      journalBox.put(journal);
    }
    return deltas;
  }

  int _findVersion(String entityType, String uuid) {
    final q = syncStateBox
        .query(SyncState_.entityType.equals(entityType) &
            SyncState_.entityUuid.equals(uuid))
        .build();
    final state = q.findFirst();
    q.close();
    return state?.lastVersion ?? 0;
  }

  // 🔹 APPLY DELTA
  void applyDelta(Map<String, dynamic> delta) {
    final type = delta['entity'];
    final op = delta['operation'];
    final data = delta['data'];
    final origin = delta['originId'];
    final time = delta['timestamp'];

    switch (type) {
      case 'Staff':
        _applyStaffDelta(op, data, origin, time);
        break;
      case 'ActiviteJour':
        _applyActiviteDelta(op, data, origin, time);
        break;
      case 'Branch':
        _applyBranchDelta(op, data, origin, time);
        break;
    }
  }

  void _applyStaffDelta(
      String op, Map<String, dynamic> data, String origin, int ts) {
    if (op == 'DELETE') {
      final s = staffBox.get(data['id']);
      if (s != null) staffBox.remove(s.id);
      return;
    }
    final s = Staff(
      nom: data['nom'],
      grade: data['grade'],
      groupe: data['groupe'],
      equipe: data['equipe'],
      obs: data['obs'],
    )..id = data['id'];
    staffBox.put(s);
  }

  void _applyActiviteDelta(
      String op, Map<String, dynamic> data, String origin, int ts) {
    if (op == 'DELETE') return;
    final st = _findStaffById(data['staffId']);
    if (st == null) return;
    final a = ActiviteJour(jour: data['jour'], statut: data['statut'])
      ..staff.target = st;
    activiteBox.put(a);
    registerActiviteJour(a, originId: origin);
  }

  // 🔹 ENVOI RESEAU
  Future<void> sendDeltaToNode(
      String nodeId, Map<String, dynamic> delta) async {
    final encrypted = await CryptoManager().encryptDelta(delta);
    final message = {
      'type': 'delta',
      'nodeId': P2PManager().nodeId,
      'payload': encrypted,
    };
    ConnectionManager().sendMessage(nodeId, message);
  }

  Future<void> broadcastDelta(Map<String, dynamic> delta) async {
    final cm = ConnectionManager();
    for (final id in cm.neighbors) {
      await sendDeltaToNode(id, delta);
    }
  }

  Future<void> handleIncomingData(Socket socket, List<int> rawData) async {
    final message = jsonDecode(utf8.decode(rawData));
    final type = message['type'];
    if (type == 'hello') return;

    if (type == 'delta') {
      final encrypted = message['payload'];
      final delta = await CryptoManager().decryptDelta(encrypted);
      final ok = await CryptoManager().verifyDelta(delta);
      if (ok) applyDelta(delta);
    }
  }

  // 🔹 UTILITAIRES
  StaffP2P? _getStaffP2P(Staff s) {
    final q = staffP2PBox.query(StaffP2P_.staff.equals(s.id)).build();
    // ❌ Problème: StaffP2P_.staff est une ToOne, pas un int
    // La query devrait probablement utiliser staffUuid ou une autre propriété
  }

  ActiviteJourP2P? _getActiviteP2P(ActiviteJour a) {
    final q =
        activiteP2PBox.query(ActiviteJourP2P_.activite.equals(a.id)).build();
    final r = q.findFirst();
    q.close();
    return r;
  }

  Staff? _findStaffById(int id) => staffBox.get(id);

  Map<String, dynamic> _staffToJson(Staff s) => {
        'id': s.id,
        'nom': s.nom,
        'grade': s.grade,
        'groupe': s.groupe,
        'equipe': s.equipe,
        'obs': s.obs,
        'ordre': s.ordre,
      };

  Map<String, dynamic> _activiteToJson(ActiviteJour a) => {
        'id': a.id,
        'jour': a.jour,
        'statut': a.statut,
        'staffId': a.staff.targetId,
      };

  void _createSyncState(String type, String uuid) {
    final s = SyncState(
      entityType: type,
      entityUuid: uuid,
      lastVersion: 1,
      lastSynced: DateTime.now().millisecondsSinceEpoch,
      lastOriginId: P2PManager().nodeId,
    );
    syncStateBox.put(s);
  }

  void _updateSyncState(String type, String uuid, int version) {
    final q = syncStateBox
        .query(SyncState_.entityType.equals(type) &
            SyncState_.entityUuid.equals(uuid))
        .build();
    final s = q.findFirst();
    q.close();
    if (s != null) {
      s.lastVersion = version;
      s.lastSynced = DateTime.now().millisecondsSinceEpoch;
      s.pendingSync = true;
      syncStateBox.put(s);
    }
  }

  void _journalOperation(
      String op, String type, String uuid, Map<String, dynamic> data) {
    final j = P2PJournal(
      operation: op,
      entityType: type,
      entityUuid: uuid,
      dataJson: jsonEncode(data),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      originId: P2PManager().nodeId,
    );
    journalBox.put(j);
  }

  void _applyBranchDelta(
      String op, Map<String, dynamic> data, String origin, int ts) {
    // Implémentation future
  }
}
