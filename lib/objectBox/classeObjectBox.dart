import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
import '../Hopital/features/planning/data/objectbox/planning_snapshot_entity.dart';
import '../Hopital/features/planning/data/objectbox/rotation_state_snapshot_entity.dart';
import 'Entity.dart';

class ObjectBox {
  late final Store store;
  late final Box<Usero> userBox;
  late final Box<Crud> crudBox;
  late final Box<Produit> produitBox;
  late final Box<Approvisionnement> approvisionnementBox;
  late final Box<Fournisseur> fournisseurBox;
  late final Box<Document> factureBox;
  late final Box<LigneDocument> ligneFacture;
  late final Box<Client> clientBox;
  late final Box<DeletedProduct> deletedProduct;
  late final Box<Annonces> annonces;
  late final Box<Room> roomBox;
  late final Box<Guest> guestBox;
  late final Box<Employee> employeeBox;
  late final Box<Hotel> hotelBox;
  late final Box<RoomCategory> roomCategory;
  late final Box<BoardBasis> boardBasis;
  late final Box<ExtraService> extraService;
  late final Box<ReservationExtra> reservationExtra;
  late final Box<SeasonalPricing> seasonalPricing;
  late final Box<Staff> staffBox;
  late final Box<ActiviteJour> activiteBox;
  late final Box<Branch> branchBox;
  late final Box<TimeOff> timeOffBox;
  late final Box<Planification> planificationBox;
  late final Box<PlanningHebdo> planningHebdoBox;
  late final Box<TypeActivite> typeActiviteBox;
  late final Box<Message> messageBox;
  late final Box<Conversation> conversationBox;
  late final Box<MessageReceipt> messageReceiptBox;
  late final Box<ConversationParticipant> conversationParticipantBox;
  late final Box<MessageSyncQueue> messageSyncQueueBox;
  late final Box<MessageSearchIndex> messageSearchIndexBox;
  late final Box<SwipeQueue> swipeQueueBox;
  late final Box<Match> matchBox;
  late final Box<Profile> profileBox;

  late final Box<PlanningSnapshotEntity> planningSnapshotBox;
  late final Box<PlanningAssignmentEntity> planningAssignmentBox;
  late final Box<RotationStateSnapshotEntity> rotationStateSnapshotBox;

  Admin? admin;

  static final ObjectBox _singleton = ObjectBox._internal();
  factory ObjectBox() => _singleton;
  final random = Random();
  ObjectBox._internal();

  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'objectbox');

    if (!Store.isOpen(dbPath)) {
      try {
        store = await openStore(directory: dbPath);
        _initializeBoxes();
        await _initializeAdmin();
      } catch (e) {
        debugPrint('❌ Erreur lors de l\'ouverture du store ObjectBox : $e');
        if (e.toString().contains('does not match existing UID') ||
            e.toString().contains('failed to create store')) {
          debugPrint('⚠️ Mismatch de modèle détecté. Tentative de suppression et recréation de la base de données...');
          await _forceDeleteDatabase(dbPath);
          store = await openStore(directory: dbPath);
          _initializeBoxes();
          await _initializeAdmin();
          debugPrint('✅ Base de données réinitialisée avec succès.');
        } else {
          rethrow;
        }
      }
    } else {
      _initializeBoxes();
    }
  }

  void _initializeBoxes() {
    userBox = Box<Usero>(store);
    crudBox = Box<Crud>(store);
    produitBox = Box<Produit>(store);
    approvisionnementBox = Box<Approvisionnement>(store);
    fournisseurBox = Box<Fournisseur>(store);
    factureBox = Box<Document>(store);
    ligneFacture = Box<LigneDocument>(store);
    clientBox = Box<Client>(store);
    deletedProduct = Box<DeletedProduct>(store);
    annonces = Box<Annonces>(store);
    roomBox = Box<Room>(store);
    guestBox = Box<Guest>(store);
    employeeBox = Box<Employee>(store);
    hotelBox = Box<Hotel>(store);
    roomCategory = Box<RoomCategory>(store);
    boardBasis = Box<BoardBasis>(store);
    extraService = Box<ExtraService>(store);
    reservationExtra = Box<ReservationExtra>(store);
    seasonalPricing = Box<SeasonalPricing>(store);
    staffBox = Box<Staff>(store);
    activiteBox = Box<ActiviteJour>(store);
    branchBox = Box<Branch>(store);
    timeOffBox = Box<TimeOff>(store);
    planificationBox = Box<Planification>(store);
    planningHebdoBox = Box<PlanningHebdo>(store);
    typeActiviteBox = Box<TypeActivite>(store);
    messageBox = Box<Message>(store);
    conversationBox = Box<Conversation>(store);
    messageReceiptBox = Box<MessageReceipt>(store);
    conversationParticipantBox = Box<ConversationParticipant>(store);
    messageSyncQueueBox = Box<MessageSyncQueue>(store);
    messageSearchIndexBox = Box<MessageSearchIndex>(store);
    swipeQueueBox = Box<SwipeQueue>(store);
    matchBox = Box<Match>(store);
    profileBox = Box<Profile>(store);
    planningSnapshotBox = Box<PlanningSnapshotEntity>(store);
    planningAssignmentBox = Box<PlanningAssignmentEntity>(store);
    rotationStateSnapshotBox = Box<RotationStateSnapshotEntity>(store);
  }

  Future<void> _forceDeleteDatabase(String path) async {
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      debugPrint('🗑️ Répertoire ObjectBox supprimé : $path');
    }
  }

  Future<void> _initializeAdmin() async {
    if (kDebugMode) {
      try {
        if (Admin.isAvailable()) {
          admin = Admin(store);
          debugPrint('🚀 ObjectBox Admin démarré avec succès !');
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          debugPrint('⚠️ ObjectBox Admin non disponible sur cette plateforme');
        }
      } catch (e) {
        debugPrint('❌ Erreur lors de l\'initialisation d\'Admin : $e');
        admin = null;
      }
    }
  }

  bool isAdminAvailable() => admin != null && kDebugMode;
  String? getAdminUrl() => admin != null ? 'http://127.0.0.1:8090' : null;

  Future<String?> exportDatabase() async => 'Export MDB non implemente';
  Future<String?> exportAllToJson() async => 'Export JSON non implemente';
  Future<String?> exportProduitsToCsv() async => 'Export CSV non implemente';
  Future<String?> importAllFromJson() async => 'Import JSON non implemente';
  Future<String?> importProduitsFromCsv() async => 'Import CSV non implemente';

  void fillWithFakeData(int users, int clients, int suppliers, int products, int approvisionnements) {
    // Stub - generation de donnees factices non implementee
  }

  Future<void> dispose() async {
    try {
      admin?.close();
      admin = null;
      store.close();
    } catch (e) {
      debugPrint('Erreur lors de la fermeture : $e');
    }
  }

  void close() => store.close();
}
