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

import '../objectbox.g.dart';
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
  late final Box<Reservation> reservationBox;
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
    reservationBox = Box<Reservation>(store);
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
  }

  Future<void> _initializeAdmin() async {
    if (!kDebugMode) return;

    try {
      if (Admin.isAvailable()) {
        admin = Admin(store);
        debugPrint('🚀 ObjectBox Admin démarré avec succès !');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } else {
        debugPrint('⚠️ ObjectBox Admin non disponible sur cette plateforme');
      }
    } catch (error, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation d\'Admin : $error');
      debugPrintStack(stackTrace: stackTrace);
      admin = null;
    }
  }

  bool isAdminAvailable() => admin != null && kDebugMode;

  String? getAdminUrl() => admin == null ? null : 'http://127.0.0.1:8090';

  Future<void> dispose() async {
    try {
      admin?.close();
      admin = null;
      store.close();
      _initFuture = null;
    } catch (error) {
      debugPrint('Erreur lors de la fermeture : $error');
    }
  }

  Future<void> restartAdmin() async {
    if (!kDebugMode) return;
    try {
      admin?.close();
      admin = null;
      await _initializeAdmin();
    } catch (error) {
      debugPrint('Erreur lors du redémarrage d\'Admin : $error');
    }
  }

  void close() => store.close();

  /// Destructive database reset is an explicit administrative operation.
  /// It is intentionally never called by ObjectBox initialization or recovery.
  Future<void> deleteDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'objectbox');

    try {
      if (Store.isOpen(dbPath)) {
        await dispose();
      }
      final directoryObject = Directory(dbPath);
      if (await directoryObject.exists()) {
        await directoryObject.delete(recursive: true);
      }
      await init();
    } catch (error) {
      debugPrint(
          '❌ Erreur lors de la suppression explicite de la base : $error');
      rethrow;
    }
  }

  Future<void> insertOrUpdateProduit(Produit produit) async {
    try {
      final existingProduit =
          produitBox.query(Produit_.qr.equals(produit.qr!)).build().findFirst();

      if (existingProduit != null) {
        existingProduit.nom = produit.nom;
        existingProduit.description = produit.description;
        existingProduit.prixVente = produit.prixVente;
        existingProduit.minimStock = produit.minimStock;
        existingProduit.alertPeremption = produit.alertPeremption;
        existingProduit.derniereModification = DateTime.now();
        produitBox.put(existingProduit);
      } else {
        produitBox.put(produit);
      }
    } catch (error) {
      debugPrint('Erreur lors de l\'insertion/mise à jour du produit : $error');
      rethrow;
    }
  }

  /// Adds a small, self-contained demo catalogue for development screens.
  /// The other counters are retained for compatibility with the existing UI;
  /// only products are generated here because this store does not own the
  /// legacy fake-data graph anymore.
  void fillWithFakeData(
    int users,
    int clients,
    int suppliers,
    int products,
    int approvisionnements,
  ) {
    final count = products < 0 ? 0 : products;
    final now = DateTime.now();
    produitBox.putMany([
      for (var index = 0; index < count; index++)
        Produit(
          qr: 'demo-${now.microsecondsSinceEpoch}-$index',
          nom: 'Produit démo ${index + 1}',
          prixVente: 0,
          derniereModification: now,
        ),
    ]);
  }

  /// Removes products without a usable QR code and returns their count.
  int supprimerProduitsAvecQrCodeInvalide() {
    final ids = produitBox
        .getAll()
        .where((product) => product.qr == null || product.qr!.trim().isEmpty)
        .map((product) => product.id)
        .toList(growable: false);
    if (ids.isEmpty) return 0;
    return produitBox.removeMany(ids);
  }

  Future<Fournisseur> getFournisseurAleatoire() async {
    final count = fournisseurBox.count();
    if (count <= 0) {
      throw StateError('Aucun fournisseur disponible.');
    }
    final randomId = Random().nextInt(count) + 1;
    final fournisseur = fournisseurBox.get(randomId);
    if (fournisseur == null) {
      throw StateError('Fournisseur introuvable pour l\'ID $randomId.');
    }
    return fournisseur;
  }

  Future<void> checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Document _createFacture(Faker faker) {
    final types = ['vente', 'achat', 'devis', 'facture', 'bon', 'proforma']
      ..shuffle(random);
    final facture = Document(
      qrReference: faker.randomGenerator.integer(999999).toString(),
      impayer: faker.randomGenerator.decimal(min: 0, scale: 2),
      date: faker.date.dateTime(minYear: 2010, maxYear: 2024),
      derniereModification:
          faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      type: types.first,
    )..crud.target = Crud(
        createdBy: 1,
        updatedBy: 1,
        deletedBy: 1,
        dateCreation: faker.date.dateTime(minYear: 2010, maxYear: 2024),
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      );

    final numberOfLignes = faker.randomGenerator.integer(5, min: 1);
    for (var j = 0; j < numberOfLignes; j++) {
      final productCount = produitBox.count();
      if (productCount == 0) break;
      final produit =
          produitBox.get(faker.randomGenerator.integer(productCount) + 1);
      if (produit == null) continue;
      final ligne = LigneDocument(
        quantite: faker.randomGenerator.decimal(min: 1, scale: 10),
        prixUnitaire: produit.prixVente,
        derniereModification:
            faker.date.dateTime(minYear: 2000, maxYear: DateTime.now().year),
      );
      ligne.produit.target = produit;
      ligne.facture.target = facture;
      facture.lignesDocument.add(ligne);
    }
    return facture;
  }

  void addAnnonce(Annonces annonce) => annonces.put(annonce);

  List<Annonces> getAllAnnonces() => annonces.getAll();

  Future<String?> exportDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(join(dir.path, 'objectbox'));
      if (!await dbDir.exists())
        return 'Erreur: La base de données n\'existe pas.';

      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Sélectionnez le dossier d\'exportation',
      );
      if (selectedDirectory == null) return 'Exportation annulée.';

      final destinationPath = join(
        selectedDirectory,
        'kenzy_backup_${DateTime.now().millisecondsSinceEpoch}',
      );
      final destinationDir = Directory(destinationPath)
        ..createSync(recursive: true);
      await for (final entity in dbDir.list(recursive: false)) {
        if (entity is File) {
          await entity.copy(join(destinationPath, basename(entity.path)));
        }
      }
      return 'Base de données exportée avec succès vers $destinationPath';
    } catch (error) {
      return 'Erreur lors de l\'exportation: $error';
    }
  }

  Future<String?> exportAllToJson() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Dossier d\'exportation JSON',
      );
      if (selectedDirectory == null) return 'Exportation annulée.';

      final data = {
        'produits': produitBox.getAll().map((e) => e.toJson()).toList(),
        'clients': clientBox.getAll().map((e) => e.toJson()).toList(),
        'fournisseurs': fournisseurBox.getAll().map((e) => e.toJson()).toList(),
        'staff': staffBox.getAll().map((e) => e.toJson()).toList(),
        'activites': activiteBox.getAll().map((e) => e.toJson()).toList(),
        'branches': branchBox.getAll().map((e) => e.toJson()).toList(),
        'timeOffs': timeOffBox.getAll().map((e) => e.toJson()).toList(),
        'planifications':
            planificationBox.getAll().map((e) => e.toJson()).toList(),
        'planningHebdo':
            planningHebdoBox.getAll().map((e) => e.toJson()).toList(),
        'typeActivites':
            typeActiviteBox.getAll().map((e) => e.toJson()).toList(),
        'factures': factureBox.getAll().map((e) => e.toJson()).toList(),
        'lignesFactures': ligneFacture.getAll().map((e) => e.toJson()).toList(),
      };

      final filePath = join(
        selectedDirectory,
        'kenzy_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await File(filePath).writeAsString(jsonEncode(data));
      return 'Export JSON réussi : $filePath';
    } catch (error) {
      return 'Erreur JSON: $error';
    }
  }

  Future<String?> importAllFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null)
        return 'Importation annulée.';

      final file = File(result.files.single.path!);
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      var count = 0;

      void putList<T>(
          String key, List<T> Function(List<dynamic>) decode, Box<T> box) {
        if (!data.containsKey(key)) return;
        final list = decode(data[key] as List);
        box.putMany(list);
        count += list.length;
      }

      putList('produits',
          (list) => list.map((e) => Produit.fromJson(e)).toList(), produitBox);
      putList('clients', (list) => list.map((e) => Client.fromJson(e)).toList(),
          clientBox);
      putList(
          'fournisseurs',
          (list) => list.map((e) => Fournisseur.fromJson(e)).toList(),
          fournisseurBox);
      putList('staff', (list) => list.map((e) => Staff.fromJson(e)).toList(),
          staffBox);
      putList(
          'activites',
          (list) => list.map((e) => ActiviteJour.fromJson(e)).toList(),
          activiteBox);
      putList('branches',
          (list) => list.map((e) => Branch.fromJson(e)).toList(), branchBox);
      putList('timeOffs',
          (list) => list.map((e) => TimeOff.fromJson(e)).toList(), timeOffBox);
      putList(
          'planifications',
          (list) => list.map((e) => Planification.fromJson(e)).toList(),
          planificationBox);
      putList(
          'planningHebdo',
          (list) => list.map((e) => PlanningHebdo.fromJson(e)).toList(),
          planningHebdoBox);
      putList(
          'typeActivites',
          (list) => list.map((e) => TypeActivite.fromJson(e)).toList(),
          typeActiviteBox);
      putList('factures',
          (list) => list.map((e) => Document.fromJson(e)).toList(), factureBox);
      putList(
          'lignesFactures',
          (list) => list.map((e) => LigneDocument.fromJson(e)).toList(),
          ligneFacture);

      return 'Import JSON réussi : $count éléments importés';
    } catch (error) {
      return 'Erreur Import JSON: $error';
    }
  }

  Future<String?> exportProduitsToCsv() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Dossier d\'exportation CSV',
      );
      if (selectedDirectory == null) return 'Exportation annulée.';

      final rows = <List<dynamic>>[
        ['ID', 'QR', 'Nom', 'Prix Vente', 'Stock Minim', 'Description'],
        ...produitBox.getAll().map(
              (p) =>
                  [p.id, p.qr, p.nom, p.prixVente, p.minimStock, p.description],
            ),
      ];
      final filePath = join(
        selectedDirectory,
        'produits_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await File(filePath)
          .writeAsString(const ListToCsvConverter().convert(rows));
      return 'CSV Produits exporté : $filePath';
    } catch (error) {
      return 'Erreur CSV: $error';
    }
  }

  Future<String?> importProduitsFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null)
        return 'Importation annulée.';

      final file = File(result.files.single.path!);
      final fields =
          const CsvToListConverter().convert(await file.readAsString());
      final toImport = <Produit>[];

      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 3) continue;
        toImport.add(
          Produit(
            qr: row[1]?.toString(),
            nom: row[2]?.toString() ?? 'Inconnu',
            prixVente:
                double.tryParse(row.length > 3 ? row[3].toString() : '0') ?? 0,
            minimStock:
                double.tryParse(row.length > 4 ? row[4].toString() : '0') ?? 0,
            description: row.length > 5 ? row[5]?.toString() : null,
            derniereModification: DateTime.now(),
          ),
        );
      }

      produitBox.putMany(toImport);
      return '${toImport.length} produits importés';
    } catch (error) {
      return 'Erreur Import CSV: $error';
    }
  }
}
