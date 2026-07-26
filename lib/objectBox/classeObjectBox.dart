import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:faker/faker.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:objectbox/objectbox.dart';

import '../objectbox.g.dart';
import '../features/planning/data/objectbox/planning_snapshot_entity.dart';
import '../features/planning/data/objectbox/rotation_state_snapshot_entity.dart';
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

  // New Planning architecture persistence boundary.
  late final Box<PlanningSnapshotEntity> planningSnapshotBox;
  late final Box<PlanningAssignmentEntity> planningAssignmentBox;
  late final Box<RotationStateSnapshotEntity> rotationStateSnapshotBox;

  Admin? admin;

  static final ObjectBox _singleton = ObjectBox._internal();

  factory ObjectBox() => _singleton;

  ObjectBox._internal();

  final random = Random();

  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initFuture != null) return _initFuture;
    _initFuture = _doInit();
    return _initFuture;
  }

  Future<void> _doInit() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'objectbox');

    try {
      if (Store.isOpen(dbPath)) {
        throw StateError(
          'ObjectBox store is already open at $dbPath. '
          'Reuse the existing application ObjectBox instance instead of '
          'opening a second Store.',
        );
      }

      store = await openStore(directory: dbPath);
      _initializeBoxes();
      await _initializeAdmin();
    } catch (error, stackTrace) {
      _initFuture = null;
      debugPrint('❌ Erreur lors de l\'ouverture du store ObjectBox : $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_isModelMismatch(error)) {
        throw StateError(
          'ObjectBox model mismatch detected. Local data was preserved. '
          'Fix the ObjectBox model migration/UIDs and regenerate the model '
          'with build_runner before retrying.',
        );
      }

      rethrow;
    }
  }

  bool _isModelMismatch(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('does not match existing uid') ||
        message.contains('failed to create store') ||
        (message.contains('model') && message.contains('uid'));
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

  // Existing ObjectBox methods remain below this point in the source file.
