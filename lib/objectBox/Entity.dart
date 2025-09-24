import 'dart:convert';

import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  @Id()
  int id;
  String? photo;
  @Index()
  String username;
  String password;
  String email;
  @Index()
  String? phone;
  String role;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final crud = ToOne<Crud>();

  User({
    this.id = 0,
    this.photo,
    required this.username,
    required this.password,
    this.phone,
    required this.email,
    required this.role,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      photo: json['photo'],
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Produit {
  int id;
  @Unique(onConflict: ConflictStrategy.replace)
  @Index() // Indexation du QR pour une recherche rapide
  String? qr; // Stocker les QR codes comme une chaîne avec des séparateurs
  String? image;
  @Index()
  String nom;
  String? description;
  double prixVente;
  double? tax;
  double? qtyPartiel;
  double? pricePartielVente;
  double? minimStock;
  int? alertPeremption;
  bool isSynced;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime derniereModification;

  @Backlink()
  final approvisionnements = ToMany<Approvisionnement>();

  // Correction : renommage de la relation ToMany<QrCode>

  // final qrcodes = ToMany<QrCode>();
  final crud = ToOne<Crud>();

  Produit({
    this.id = 0,
    this.qr,
    this.image,
    required this.nom,
    this.description,
    required this.prixVente,
    this.tax,
    this.qtyPartiel,
    this.pricePartielVente,
    this.minimStock,
    this.alertPeremption,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

// // Getter pour récupérer les QR codes sous forme de liste
//   List<String> get qrCodeList {
//     return qr != null && qr!.isNotEmpty ? qr!.split(',') : [];
//   }
//
//   // Setter pour mettre à jour les QR codes
//   set qrCodeList(List<String> codes) {
//     qr = codes.join(',');
//   }
//
//   void addQrCode(String code) {
//     List<String> codes = qrCodeList;
//     codes.add(code);
//     qrCodeList = codes; // Met à jour la chaîne JSON avec la nouvelle liste
//   }
// Getter pour récupérer les QR codes sous forme de liste
  List<String> get qrCodeList => qr?.split(',') ?? [];

// Setter pour mettre à jour les QR codes
  set qrCodeList(List<String> codes) {
    if (codes.isEmpty) {
      qr = null;
    } else {
      qr = codes.join(',');
    }
  }

// Méthode pour ajouter un QR code à la liste existante
  void addQrCode(String code) {
    final codes = List<String>.from(qrCodeList); // Copie de la liste actuelle
    if (!codes.contains(code)) {
      codes.add(code);
      qrCodeList = codes; // Mettre à jour la chaîne avec la nouvelle liste
    }
  }

  double get stock =>
      approvisionnements.fold(0.0, (sum, appro) => sum + appro.quantite);

// Méthode pour calculer le stock total à partir des approvisionnements
  double calculerStockTotal() {
    // Si la liste des approvisionnements est vide, retourne 0
    if (approvisionnements.isEmpty) {
      return 0.0;
    }

    // Utilise fold() pour calculer la somme des quantités d'approvisionnement
    double stockTotal = approvisionnements.fold(0.0, (total, appro) {
      return total + appro.quantite;
    });

    return stockTotal;
  }

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] ?? 0,
      qr: json['qr'],
      image: json['image'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      prixVente: (json['prixVente'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      qtyPartiel: (json['qtyPartiel'] ?? 0).toDouble(),
      pricePartielVente: (json['pricePartielVente'] ?? 0.0).toDouble(),
      minimStock: (json['minimStock'] ?? 0).toDouble(),
      alertPeremption: (json['alertPeremption'] ?? 0).toInt(),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Approvisionnement {
  int id;
  double quantite;
  bool isSynced;
  double? prixAchat;
  @Index()
  DateTime? derniereModification;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime? datePeremption;

  final produit = ToOne<Produit>();

  // Relation vers l'entité Fournisseur
  final fournisseur = ToOne<Fournisseur>();
  final crud = ToOne<Crud>();

  Approvisionnement({
    this.id = 0,
    required this.quantite,
    this.prixAchat,
    this.datePeremption,
    this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Approvisionnement.fromJson(Map<String, dynamic> json) {
    return Approvisionnement(
      id: json['id'] ?? 0,
      quantite: (json['quantite'] ?? 0).toDouble(),
      prixAchat: (json['prixAchat'] ?? 0).toDouble(),
      datePeremption: json['datePeremption'] != null
          ? DateTime.parse(json['datePeremption'])
          : null,
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Crud {
  int id;
  int? createdBy;
  int updatedBy;
  int? deletedBy;
  bool isSynced;
  @Property(type: PropertyType.date)
  DateTime? dateCreation;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime derniereModification;

  @Property(type: PropertyType.date)
  DateTime? dateDeleting;

  Crud({
    this.id = 0,
    this.createdBy,
    required this.updatedBy,
    this.deletedBy,
    this.dateCreation,
    required this.derniereModification,
    this.dateDeleting,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Crud.fromJson(Map<String, dynamic> json) {
    return Crud(
      id: json['id'] ?? 0,
      createdBy: json['createdBy']?.toInt(),
      updatedBy: json['updatedBy']?.toInt() ?? 1,
      deletedBy: json['deletedBy']?.toInt(),
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : DateTime.now(),
      dateDeleting: json['dateDeleting'] != null
          ? DateTime.parse(json['dateDeleting'])
          : null,
      derniereModification: DateTime.parse(
          json['derniereModification'] ?? DateTime.now().toIso8601String()),
    );
  }
}

@Entity()
class Fournisseur {
  int id;
  @Unique()
  @Index()
  String? qr;
  @Index()
  String nom;
  @Index()
  String? phone;
  String? adresse;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final crud = ToOne<Crud>();

  @Backlink()
  final approvisionnements = ToMany<Approvisionnement>();

  Fournisseur({
    this.id = 0,
    this.qr,
    required this.nom,
    this.phone,
    this.adresse,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Fournisseur.fromJson(Map<String, dynamic> json) {
    return Fournisseur(
      id: json['id'] ?? 0,
      qr: json['qr'],
      nom: json['nom'] ?? '',
      phone: json['phone'],
      adresse: json['adresse'],
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Client {
  int id;
  @Index()
  String qr;
  @Index()
  String nom;
  @Index()
  String phone;
  String adresse;
  String? description;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  @Backlink()
  final factures = ToMany<Document>();

  final crud = ToOne<Crud>();

  Client({
    this.id = 0,
    required this.qr,
    required this.nom,
    required this.phone,
    required this.adresse,
    this.description,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      qr: json['qr'] ?? '',
      nom: json['nom'] ?? '',
      phone: json['phone'] ?? '',
      adresse: json['adresse'] ?? '',
      description: json['description'] ?? '',
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Document {
  //int id;
  @Id()
  int id = 0;
  @Index()
  String type; // 'vente', 'achat', etc.
  @Index()
  String qrReference;
  double? impayer;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  @Property(type: PropertyType.date)
  DateTime date;

  // Relations spécifiques
  final client = ToOne<Client>();
  final fournisseur = ToOne<Fournisseur>();
  final crud = ToOne<Crud>();

  double montantVerse = 0.0; // Montant payé

  @Backlink()
  final lignesDocument = ToMany<LigneDocument>();

  Document({
    this.id = 0,
    required this.date,
    required this.qrReference,
    required this.type,
    this.montantVerse = 0.0,
    required this.impayer,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  // Montant total calculé
  double get montantTotal =>
      lignesDocument.fold(0.0, (sum, ligne) => sum + ligne.sousTotal);

  // État calculé en fonction du montant payé et du total
  DocumentEtat get etat {
    if (montantVerse >= montantTotal) {
      return DocumentEtat.paye;
    } else if (montantVerse > 0) {
      return DocumentEtat.partiellementPaye;
    } else {
      return DocumentEtat.nonPaye;
    }
  }

  // Validation basée sur le type
  bool get estValide {
    if (type == 'vente' && client.target == null) {
      return false;
    }
    if (type == 'achat' && fournisseur.target == null) {
      return false;
    }
    return true;
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      qrReference: json['qrReference'] ?? '',
      impayer: (json['impayer'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class LigneDocument {
  // int id;
  @Id()
  int id = 0;
  double quantite;
  double prixUnitaire;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final produit = ToOne<Produit>();
  final facture = ToOne<Document>();

  LigneDocument({
    this.id = 0,
    required this.quantite,
    required this.prixUnitaire,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  // Sous-total calculé automatiquement
  double get sousTotal => quantite * prixUnitaire;

  factory LigneDocument.fromJson(Map<String, dynamic> json) {
    return LigneDocument(
      id: json['id'] ?? 0,
      quantite: (json['quantite'] ?? 0).toDouble(),
      prixUnitaire: (json['prixUnitaire'] ?? 0).toDouble(),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

// État des documents
enum DocumentEtat {
  paye,
  partiellementPaye,
  nonPaye,
}

@Entity()
class DeletedProduct {
  @Id()
  int id = 0;
  @Index()
  String name;
  String description;
  double price;
  int quantity;
  int delaisPeremption;
  DateTime derniereModification;
  bool isSynced;
  DateTime syncedAt;

  final crud = ToOne<Crud>();

  DeletedProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.delaisPeremption,
    required this.derniereModification,
    this.isSynced = false,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();

  factory DeletedProduct.fromJson(Map<String, dynamic> json) {
    return DeletedProduct(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0).toInt(),
      delaisPeremption: (json['delaisPeremption']).toInt(),
      derniereModification: json['derniereModification'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['derniereModification'])
          : DateTime.now(),
    );
  }
}

@Entity()
class Annonces {
  int id = 0; // Clé primaire automatique
  String titre = ''; // Titre de l'annonce
  String prix = ''; // Prix de l'annonce
  String lien = ''; // Lien vers l'annonce
  String categorie = ''; // Catégorie de l'annonce

  Annonces({
    required this.titre,
    required this.prix,
    required this.lien,
    required this.categorie,
  });
}

/// ==================== Hotel & ROOM ====================
@Entity()
class Hotel {
  @Id()
  int id = 0;

  String name;
  int floors;
  int roomsPerFloor;
  String avoidedNumbers; // Stockage des numéros évités comme string

  // Backlink vers les chambres de l'hôtel
  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';
  @Backlink('hotel')
  final rooms = ToMany<Room>();

  /// Ajout : relation vers SeasonalPricing sélectionné
  final selectedSeasonalPricing = ToOne<SeasonalPricing>();

  Hotel({
    required this.name,
    required this.floors,
    required this.roomsPerFloor,
    this.avoidedNumbers = '',
    this.photosJson = '[]',
  });

  // Helper pour récupérer la liste des numéros évités
  List<String> get avoidedNumbersList {
    if (avoidedNumbers.isEmpty) return [];
    return avoidedNumbers.split(',').map((e) => e.trim()).toList();
  }

  // Helper pour définir les numéros évités
  void setAvoidedNumbers(List<String> numbers) {
    avoidedNumbers = numbers.join(',');
  }

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

@Entity()
class Room {
  @Id()
  int id = 0;

  @Index()
  String code;

  // String? type; // Peut être remplacé par category.name
  // int? capacity; // Peut être remplacé par category.capacity
  // double? basePrice; // Peut être remplacé par category.basePrice
  String status;

  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';

  // NOUVELLE RELATION
  final category = ToOne<RoomCategory>();

  @Backlink('room')
  final reservations = ToMany<Reservation>();
  final hotel = ToOne<Hotel>();

  Room({
    required this.code,
    // this.type,
    // this.capacity,
    // this.basePrice,
    this.status = "free",
    this.photosJson = '[]',
  });

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

/// ==================== ROOM CATEGORY ====================
@Entity()
class RoomCategory {
  @Id()
  int id = 0;

  String name; // "Deluxe Sea View", "Standard Twin", "Junior Suite"
  String code; // "DLXSV", "STDTW", "JRSUI" - pour les systèmes
  String description;

  // Caractéristiques principales
  String bedType; // "Single", "Double", "Twin", "King", "Queen"
  int capacity; // Nombre de personnes
  String standing; // "Economy", "Standard", "Superior", "Deluxe", "Suite"
  String? viewType; // "Sea", "Pool", "Garden", "Mountain", "City", "Courtyard"

  // Équipements inclus
  String amenities; // JSON string des équipements
  double basePrice; // Prix de base par nuit

  // Paramètres de tarification
  double
      seasonMultiplier; // Multiplicateur saison (1.0 = normal, 1.5 = haute saison)
  double weekendMultiplier; // Multiplicateur week-end
  bool allowsExtraBed; // Peut-on ajouter un lit supplémentaire
  double extraBedPrice; // Prix du lit supplémentaire

  // État
  bool isActive; // Actif ou non
  int sortOrder; // Ordre d'affichage

  // Relations
  @Backlink('category')
  final rooms = ToMany<Room>();

  RoomCategory({
    required this.name,
    required this.code,
    required this.description,
    required this.bedType,
    required this.capacity,
    required this.standing,
    this.viewType,
    this.amenities = '[]',
    required this.basePrice,
    this.seasonMultiplier = 1.0,
    this.weekendMultiplier = 1.0,
    this.allowsExtraBed = false,
    this.extraBedPrice = 0.0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  // Helper pour récupérer les équipements
  List<String> get amenitiesList {
    try {
      // Simuler le parsing JSON - en réalité vous utiliseriez dart:convert
      if (amenities.isEmpty || amenities == '[]') return [];
      return amenities
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Helper pour définir les équipements
  void setAmenities(List<String> items) {
    amenities = '["${items.join('", "')}"]';
  }
}

/// ==================== BOARD BASIS (Plans de pension) ====================
@Entity()
class BoardBasis {
  @Id()
  int id = 0;

  String name; // "Bed & Breakfast", "Half Board", "All Inclusive"
  String code; // "BB", "HB", "AI"
  String description;

  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';

  // Détails des repas inclus
  bool includesBreakfast;
  bool includesLunch;
  bool includesDinner;
  bool includesSnacks;
  bool includesDrinks;
  bool includesAlcoholicDrinks;
  bool includesRoomService;
  bool includesMinibar;

  // Tarification
  double pricePerPerson; // Prix par personne par nuit
  double childDiscount; // Réduction enfant (0.0 à 1.0)

  // Paramètres
  bool isActive;
  int sortOrder;
  String? notes; // Notes spéciales (horaires, restrictions)

  BoardBasis({
    required this.name,
    required this.code,
    required this.description,
    this.includesBreakfast = false,
    this.includesLunch = false,
    this.includesDinner = false,
    this.includesSnacks = false,
    this.includesDrinks = false,
    this.includesAlcoholicDrinks = false,
    this.includesRoomService = false,
    this.includesMinibar = false,
    required this.pricePerPerson,
    this.childDiscount = 0.0,
    this.isActive = true,
    this.sortOrder = 0,
    this.notes,
    this.photosJson = '[]',
  });

  // Helper pour obtenir un résumé des inclusions
  String get inclusionsSummary {
    final inclusions = <String>[];

    final inclusionMap = {
      includesBreakfast: 'Petit déjeuner',
      includesLunch: 'Déjeuner',
      includesDinner: 'Dîner',
      includesSnacks: 'Snacks',
      includesDrinks: 'Boissons',
      includesAlcoholicDrinks: 'Boissons alcoolisées',
      includesRoomService: 'Room service',
      includesMinibar: 'Minibar',
    };

    inclusions.addAll(inclusionMap.entries
        .where((entry) => entry.key)
        .map((entry) => entry.value));

    if (inclusions.isEmpty) return 'Aucun service inclus';
    if (inclusions.length <= 2) return inclusions.join(', ');
    return '${inclusions.take(2).join(', ')} (+${inclusions.length - 2} autres)';
  }

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

/// ==================== EXTRAS & OPTIONS ====================
@Entity()
class ExtraService {
  @Id()
  int id = 0;

  String name; // "Transfert aéroport", "Massage", "Lit bébé"
  String code; // "AIRPORT", "SPA_MASSAGE", "BABY_BED"
  String description;
  String category; // "Transport", "Spa", "Room", "Food", "Activity", "Package"
  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';

  // Tarification
  double price;
  String pricingUnit; // "per_item", "per_person", "per_night", "per_stay"
  bool isPercentage; // Si c'est un pourcentage du prix de chambre

  // Disponibilité
  bool requiresAdvanceBooking;
  int advanceHours; // Heures à l'avance requises
  int maxQuantity; // Quantité maximum (0 = illimité)
  bool isActive;

  // Paramètres
  int sortOrder;
  String? notes;
  bool isPackage; // Si c'est un package (combinaison de services)
  String? packageIncludes; // JSON des services inclus dans le package

  ExtraService({
    required this.name,
    required this.code,
    required this.description,
    required this.category,
    required this.price,
    this.pricingUnit = 'per_item',
    this.isPercentage = false,
    this.requiresAdvanceBooking = false,
    this.advanceHours = 0,
    this.maxQuantity = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.notes,
    this.isPackage = false,
    this.packageIncludes,
    this.photosJson = '[]',
  });

  // Helper pour le calcul du prix
  double calculatePrice(
      int quantity, double roomPrice, int nights, int persons) {
    switch (pricingUnit) {
      case 'per_person':
        return price * quantity * persons;
      case 'per_night':
        return price * quantity * nights;
      case 'per_stay':
        return price * quantity;
      case 'percentage_room':
        return (price / 100) * roomPrice * quantity;
      default:
        return price * quantity;
    }
  }

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

/// ==================== RESERVATION EXTRA (Junction table) ====================
@Entity()
class ReservationExtra {
  @Id()
  int id = 0;

  final reservation = ToOne<Reservation>();
  final extraService = ToOne<ExtraService>();

  int quantity;
  double unitPrice; // Prix au moment de la réservation
  double totalPrice; // Prix total calculé
  String
      status; // "Pending", "Confirmed", "Cancelled", "Completed" "free" "leaved" "arrived "waiting"
  DateTime? scheduledDate; // Date programmée pour le service
  String? notes;

  ReservationExtra({
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.status = 'Pending',
    this.scheduledDate,
    this.notes,
  });
}

/// ==================== SEASONAL PRICING ====================
@Entity()
class SeasonalPricing {
  @Id()
  int id = 0;

  String name;
  DateTime startDate;
  DateTime endDate;
  double multiplier;

  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';
  String applicationType; // all_categories, specific_categories, specific_rooms
  String targetIds; // JSON array des IDs concernés
  bool isActive;
  int priority;
  String? description;

  SeasonalPricing({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.multiplier,
    this.applicationType = 'all_categories',
    this.targetIds = '[]',
    this.isActive = true,
    this.priority = 0,
    this.description,
    this.photosJson = '[]',
  });

  bool isDateInSeason(DateTime date) {
    return date.isAfter(startDate.subtract(Duration(days: 1))) &&
        date.isBefore(endDate.add(Duration(days: 1)));
  }

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

/// ==================== GUEST ====================
@Entity()
class Guest {
  @Id()
  int id = 0;

  String fullName;
  String phoneNumber;
  String? email;
  String idCardNumber;
  String? nationality;

  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';

  // Relation Many-to-Many avec Reservation
  @Backlink('guests')
  final reservations = ToMany<Reservation>();

  Guest({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.idCardNumber,
    this.nationality,
    this.photosJson = '[]',
  });

  /// ---- Factory ----
  factory Guest.fromMap(Map<String, dynamic> map) {
    return Guest(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      idCardNumber: map['idCardNumber'] ?? '',
      nationality: map['nationality'] ?? '',
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'idCardNumber': idCardNumber,
      'nationality': nationality,
    };
  }

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

/// ==================== RESERVATION CORRIGÉE ====================
@Entity()
class Reservation {
  @Id()
  int id = 0;

  final room = ToOne<Room>();
  final receptionist = ToOne<Employee>();
  final guests = ToMany<Guest>();

  // NOUVELLES RELATIONS
  final boardBasis = ToOne<BoardBasis>();
  @Backlink('reservation')
  final extras = ToMany<ReservationExtra>();

  // ✅ Ajout saison
  final seasonalPricing = ToOne<SeasonalPricing>();

  // ✅ Multiplicateur saisonnier
  double seasonalMultiplier;

  DateTime from;
  DateTime to;
  double pricePerNight;
  String status;

  // 🚀 Ajout pour gestion des réductions
  double discountPercent; // ex: 10 = 10%
  double discountAmount; // ex: 2000 DZD
// NOUVEAU : Ajouter ces champs
  String? discountType = 'percentage'; // 'percentage' ou 'amount'
  String? discountAppliedTo =
      'total'; // 'room', 'board', 'extras', 'total', 'specific'
  String? selectedDiscountItems = ''; // JSON string

  // Champs calculés optionnels
  double? cachedBoardBasisPrice;
  double? cachedExtrasTotal;

  Reservation({
    required this.from,
    required this.to,
    required this.pricePerNight,
    this.status = "Confirmed",
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.discountType,
    this.discountAppliedTo,
    this.selectedDiscountItems,
    this.cachedBoardBasisPrice,
    this.cachedExtrasTotal,
    this.seasonalMultiplier = 1.0, // valeur par défaut
  });

  // Prix du plan de pension
  double get boardBasisPrice {
    if (cachedBoardBasisPrice != null) return cachedBoardBasisPrice!;
    final boardBasisTarget = boardBasis.target;
    if (boardBasisTarget == null) return 0.0;
    final nights = to.difference(from).inDays;
    final persons = guests.length;
    return boardBasisTarget.pricePerPerson * persons * nights;
  }

  // Total extras
  double get extrasTotal {
    if (cachedExtrasTotal != null) return cachedExtrasTotal!;
    return extras.fold(0.0, (sum, extra) => sum + extra.totalPrice);
  }

  // ✅ Total avec réduction appliquée
  double get totalPrice {
    final nights = to.difference(from).inDays;
    final roomTotal = pricePerNight * nights;
    final boardTotal = boardBasisPrice;
    final subtotal = roomTotal + boardTotal + extrasTotal;

    final reduction = (subtotal * (discountPercent / 100)) + discountAmount;
    return (subtotal - reduction).clamp(0, double.infinity);
  }

  // Méthodes utilitaires
  int get numberOfNights => to.difference(from).inDays;

  int get numberOfGuests => guests.length;

  bool get isActive => status != "Cancelled" && status != "leaved";

  bool get hasArrived => status == "arrived" || status == "leaved";

  double get averagePricePerPersonPerNight {
    final persons = numberOfGuests;
    final nights = numberOfNights;
    if (persons == 0 || nights == 0) return 0.0;
    return totalPrice / (persons * nights);
  }

  void refreshCaches() {
    cachedBoardBasisPrice = null;
    cachedExtrasTotal = null;
  }

  bool get isValid {
    return from.isBefore(to) &&
        pricePerNight > 0 &&
        room.target != null &&
        receptionist.target != null &&
        guests.isNotEmpty;
  }

  @override
  String toString() {
    return 'Reservation{id: $id, room: ${room.target?.code}, from: $from, to: $to, status: $status, total: ${totalPrice.toStringAsFixed(2)} DZD, discount: ${discountPercent}% + ${discountAmount} DZD}';
  }
}

@Entity()
class Employee {
  @Id()
  int id = 0;

  String fullName;
  String phoneNumber;
  String? email;

  // Liste des photos sauvegardées en JSON (local & online mélangées)
  String photosJson = '[]';
  @Backlink('receptionist')
  final reservations = ToMany<Reservation>();

  Employee({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.photosJson = '[]',
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  /// ===== Helpers =====

  List<Map<String, dynamic>> get photos =>
      List<Map<String, dynamic>>.from(jsonDecode(photosJson));

  void setPhotos(List<Map<String, dynamic>> list) {
    photosJson = jsonEncode(list);
  }

  void addPhoto({required String path, required String type}) {
    final list = photos;
    list.add({"type": type, "path": path});
    setPhotos(list);
  }

  void removePhoto(String path) {
    final list = photos;
    list.removeWhere((photo) => photo["path"] == path);
    setPhotos(list);
  }
}

///********************* Hopital ******************************

@Entity()
class Personnel {
  @Id()
  int id = 0;

  String nom;
  String prenom;
  String fonction; // ex: Rhumatologue, ATS, IDE, Psychologue
  String grade; // Médecin Chef, Médecin Principal, ATS Principal...
  String service; // Service de Rhumatologie, Pharmacie, Hygiène, etc.

  final affectations = ToMany<AffectationJour>();
  final activites = ToMany<ActiviteHebdo>();
  final observations = ToMany<Observation>();
  final groupeTravail = ToOne<GroupeTravail>(); // <-- relation ToOne

  Personnel({
    required this.nom,
    required this.prenom,
    required this.fonction,
    required this.grade,
    required this.service,
  });

  factory Personnel.fromMap(Map<String, dynamic> map) {
    return Personnel(
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      fonction: map['fonction'] ?? '',
      grade: map['grade'] ?? '',
      service: map['service'] ?? '',
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'fonction': fonction,
      'grade': grade,
      'service': service,
    };
  }
}

@Entity()
class Service {
  @Id()
  int id = 0;

  String nom;

  Service({required this.nom});

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(nom: map['nom'] ?? '')..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() => {'id': id, 'nom': nom};
}

@Entity()
class PlanningMois {
  @Id()
  int id = 0;

  int annee;
  int mois;

  final affectations = ToMany<AffectationJour>();

  PlanningMois({required this.annee, required this.mois});

  factory PlanningMois.fromMap(Map<String, dynamic> map) {
    return PlanningMois(
      annee: map['annee'] ?? DateTime.now().year,
      mois: map['mois'] ?? DateTime.now().month,
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() => {'id': id, 'annee': annee, 'mois': mois};
}

@Entity()
class AffectationJour {
  @Id()
  int id = 0;

  DateTime date;

  @Property(type: PropertyType.byte)
  int statut; // index de StatutActivite

  final personnel = ToOne<Personnel>();
  final planningMois = ToOne<PlanningMois>();

  AffectationJour({required this.date, required this.statut});

  // constructeur vide optionnel
  AffectationJour.empty()
      : date = DateTime.now(),
        statut = StatutActivite.normal.index;

  factory AffectationJour.fromMap(Map<String, dynamic> map) {
    return AffectationJour(
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      statut: map['statut'] ?? StatutActivite.normal.index,
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'statut': statut,
      };
}

@Entity()
class ActiviteHebdo {
  @Id()
  int id = 0;

  String jour; // Dimanche, Lundi, etc.
  String activite; // Consultation, EPSP, Visite Générale...

  final personnel = ToOne<Personnel>();

  ActiviteHebdo({required this.jour, required this.activite});

  factory ActiviteHebdo.fromMap(Map<String, dynamic> map) {
    return ActiviteHebdo(
      jour: map['jour'] ?? '',
      activite: map['activite'] ?? '',
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'jour': jour,
        'activite': activite,
      };
}

@Entity()
class Observation {
  @Id()
  int id = 0;

  String type; // Congé, Congé Maternité, Congé Maladie...
  String details; // ex: "11 jours à partir du 08/09/2025"
  DateTime dateDebut;
  DateTime? dateFin;

  final personnel = ToOne<Personnel>();

  Observation({
    required this.type,
    required this.details,
    required this.dateDebut,
    this.dateFin,
  });

  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      type: map['type'] ?? '',
      details: map['details'] ?? '',
      dateDebut: DateTime.tryParse(map['dateDebut'] ?? '') ?? DateTime.now(),
      dateFin:
          map['dateFin'] != null ? DateTime.tryParse(map['dateFin']) : null,
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'details': details,
        'dateDebut': dateDebut.toIso8601String(),
        'dateFin': dateFin?.toIso8601String(),
      };
}

@Entity()
class GroupeTravail {
  @Id()
  int id = 0;

  late String nom;
  late String service; // "Médecins", "Infirmiers", "Bureau", "Femmes de ménage"
  final membres = ToMany<Personnel>();

  GroupeTravail({required this.nom, required this.service});

  GroupeTravail.empty(); // nécessaire pour ObjectBox
  factory GroupeTravail.fromMap(Map<String, dynamic> map) {
    return GroupeTravail(
      nom: map['nom'] ?? '',
      service: map['service'] ?? 'Médecins', // valeur par défaut
    )..id = map['id'] ?? 0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'service': service, // avant il manquait le service
      };
}

enum StatutActivite {
  normal, // N
  repos, // R
  garde, // G
  recuperation, // Ré
  conge, // C
  congeMaladie // CM
}

///==========================================================================///

/// ========================================
/// HOSPITAL PLANNING MANAGEMENT ENTITIES
/// ========================================

/// Staff Entity - Complete hospital staff
@Entity()
class Staff {
  @Id()
  int id = 0;

  // Identifiers
  @Index()
  @Unique()
  String staffNumber;

  @Index()
  String lastName;

  @Index()
  String firstName;

  // Professional information
  @Index()
  int function; // Index in HospitalFunction enum

  @Index()
  String grade;

  @Index()
  String service;

  @Index()
  String department;

  @Index()
  int category; // Index in PersonnelCategory enum

  // Guard group for nurses (A, B, C, D)
  @Index()
  String? guardGroup;

  // Contact
  String? phone;
  String? email;
  String? address;

  // Work schedule
  @Index()
  int scheduleType; // Index in ScheduleType enum

  String? scheduleStart; // "08:00"
  String? scheduleEnd; // "16:00"

  // Status and availability
  @Index()
  int status; // Index in EmployeeStatus enum

  @Index()
  bool isActive = true;

  @Index()
  bool isAvailableForGuard = false;

  // Specialized information (for doctors)
  String? specialty;

  // Leaves and absences
  @Property(type: PropertyType.date)
  DateTime? leaveStart;

  @Property(type: PropertyType.date)
  DateTime? leaveEnd;

  String? leaveReason;

  // Metadata
  @Property(type: PropertyType.date)
  DateTime creationDate = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime? lastModification;

  String? observations;

  // Qualifications stored as comma-separated String
  String qualifications = '';

  // Relations
  @Backlink('staff')
  final dailyPlannings = ToMany<DailyPlanning>();

  @Backlink('staff')
  final medicalActivities = ToMany<MedicalActivity>();

  @Backlink('staff')
  final leaves = ToMany<Leave>();

  final hospitalService = ToOne<HospitalService>();

  Staff({
    this.staffNumber = '',
    this.lastName = '',
    this.firstName = '',
    this.function = 0,
    this.grade = '',
    this.service = '',
    this.department = '',
    this.category = 0,
    this.guardGroup,
    this.phone,
    this.email,
    this.address,
    this.scheduleType = 0,
    this.scheduleStart,
    this.scheduleEnd,
    this.status = 0, // EmployeeStatus.active
    this.isActive = true,
    this.isAvailableForGuard = false,
    this.specialty,
    List<String>? qualificationsList,
    this.leaveStart,
    this.leaveEnd,
    this.leaveReason,
    DateTime? creationDate,
    this.lastModification,
    this.observations,
  })  : creationDate = creationDate ?? DateTime.now(),
        qualifications = qualificationsList?.join(',') ?? '';

  // Utility methods
  String get fullName => '$firstName $lastName';

  bool get isDoctor =>
      PersonnelCategory.values[category] == PersonnelCategory.medical &&
      (HospitalFunction.values[function] == HospitalFunction.doctor ||
          HospitalFunction.values[function] == HospitalFunction.chiefDoctor ||
          HospitalFunction.values[function] == HospitalFunction.rheumatologist);

  bool get isNurse =>
      PersonnelCategory.values[category] == PersonnelCategory.paramedical &&
      (HospitalFunction.values[function] == HospitalFunction.nurse ||
          HospitalFunction.values[function] == HospitalFunction.majorNurse ||
          HospitalFunction.values[function] == HospitalFunction.nurseAide ||
          HospitalFunction.values[function] ==
              HospitalFunction.registeredNurse);

  bool get isOnLeave =>
      leaveStart != null &&
      leaveEnd != null &&
      DateTime.now().isAfter(leaveStart!) &&
      DateTime.now().isBefore(leaveEnd!.add(Duration(days: 1)));

  String get completeFunction =>
      HospitalFunction.values[function] == HospitalFunction.doctor &&
              specialty != null
          ? '$specialty - $grade'
          : '${HospitalFunction.values[function].displayName} - $grade';

  List<String> get qualificationsList =>
      qualifications.isEmpty ? [] : qualifications.split(',');

  set qualificationsList(List<String> value) =>
      qualifications = value.join(',');
}

/// Monthly Planning Entity - Planning structure by month
@Entity()
class MonthlyPlanning {
  @Id()
  int id = 0;

  @Index()
  int month = 1; // 1-12

  @Index()
  int year = DateTime.now().year;

  @Index()
  String service = '';

  @Index()
  String department = '';

  @Index()
  int planningType = 0; // Index in PlanningType enum

  String? title;
  String? description;

  @Property(type: PropertyType.date)
  DateTime creationDate = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime? modificationDate;

  @Index()
  int status = 0; // Index in PlanningStatus enum

  @Index()
  bool isValidated = false;

  String? observations;

  // Approval metadata
  String? approvedBy;

  @Property(type: PropertyType.date)
  DateTime? approvalDate;

  // Relations
  @Backlink('monthlyPlanning')
  final dailyPlannings = ToMany<DailyPlanning>();

  final hospitalService = ToOne<HospitalService>();

  MonthlyPlanning();

  // Utility methods
  String get monthName => _monthNames[month - 1];

  String get period => '$monthName $year';

  int get numberOfDays => DateTime(year, month + 1, 0).day;

  bool get isApproved =>
      PlanningStatus.values[status] == PlanningStatus.approved;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
}

/// ========================================
/// CLASS FOR PARSING FILES
/// ========================================

class PlanningParser {
  /// Parse monthly activity table data
  static List<DailyPlanning> parseMonthlyTable(
    String tableContent,
    int month,
    int year,
  ) {
    final plannings = <DailyPlanning>[];
    final lines = tableContent.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Parse each line of the table
      final cells = line.split('\t'); // Assuming tab separation

      if (cells.length >= 33) {
        // Name + Grade + 31 days
        final name = cells[0].trim();
        final grade = cells[1].trim();

        // Create staff if necessary
        final staff = Staff(
          lastName: name.split(' ').last,
          firstName: name.split(' ').first,
          grade: grade,
          staffNumber: 'EMP_${DateTime.now().millisecondsSinceEpoch}',
        );

        // Parse activities for each day
        for (int day = 1; day <= 31; day++) {
          if (cells.length > day + 1) {
            final activityCode = cells[day + 1].trim();
            if (activityCode.isNotEmpty) {
              final date = DateTime(year, month, day);
              final planning = DailyPlanning()
                ..dayDate = date
                ..dayOfMonth = day
                ..activityType = ActivityTypeHelper.fromCode(activityCode).index
                ..status = ActivityStatus.scheduled.index
                ..isWeekend = date.weekday == 6 || date.weekday == 7;

              planning.staff.target = staff;
              plannings.add(planning);
            }
          }
        }
      }
    }

    return plannings;
  }

  /// Parse weekly medical planning
  static List<MedicalActivity> parseDoctorPlanning(String planningContent) {
    final activities = <MedicalActivity>[];
    final lines = planningContent.split('\n');

    String? currentName;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Detect doctor name
      if (line.contains('|') && line.split('|').length >= 6) {
        final cells = line.split('|').map((e) => e.trim()).toList();

        if (cells[1].isNotEmpty && !cells[1].contains('**')) {
          currentName = cells[1];
        }

        if (currentName != null) {
          // Parse weekly activities
          final weekActivities = [
            cells[2], // Sunday
            cells[3], // Monday
            cells[4], // Tuesday
            cells[5], // Wednesday
            cells[6], // Thursday
          ];

          for (int i = 0; i < weekActivities.length; i++) {
            final activityText = weekActivities[i];
            if (activityText.isNotEmpty) {
              final activity = MedicalActivity()
                ..activityName = activityText
                ..weekDay = i
                ..activityType =
                    _determineMedicalActivityType(activityText).index
                ..startTime = '08:00'
                ..endTime = '16:00'
                ..isActive = true;

              activities.add(activity);
            }
          }
        }
      }
    }

    return activities;
  }

  /// Determines medical activity type from text
  static MedicalActivityType _determineMedicalActivityType(String text) {
    final normalizedText = text.toLowerCase();

    if (normalizedText.contains('consultation')) {
      return MedicalActivityType.consultation;
    } else if (normalizedText.contains('visit')) {
      return MedicalActivityType.generalVisit;
    } else if (normalizedText.contains('service')) {
      return MedicalActivityType.service;
    } else if (normalizedText.contains('biotherapy')) {
      return MedicalActivityType.biotherapy;
    } else if (normalizedText.contains('dmo')) {
      return MedicalActivityType.dmo;
    } else if (normalizedText.contains('pedagogical')) {
      return MedicalActivityType.pedagogicalDay;
    } else if (normalizedText.contains('external') ||
        normalizedText.contains('epsp')) {
      return MedicalActivityType.externalConsultation;
    }

    return MedicalActivityType.consultation; // Default
  }
}

/// ========================================
/// CLASS FOR EXPORT/IMPORT FLUTTER
/// ========================================

class PlanningExporter {
  /// Export planning to CSV format
  static String exportToCSV(List<DailyPlanning> plannings) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('Last Name,First Name,Grade,Day,Date,Activity,Status');

    // Data
    for (final planning in plannings) {
      final staff = planning.staff.target;
      if (staff != null) {
        final type = ActivityType.values[planning.activityType];
        buffer.writeln([
          staff.lastName,
          staff.firstName,
          staff.grade,
          planning.dayOfMonth,
          planning.dayDate.toIso8601String().split('T')[0],
          type.displayName,
          ActivityStatus.values[planning.status].name,
        ].join(','));
      }
    }

    return buffer.toString();
  }

  /// Generate data for Flutter DataTable
  static Map<String, dynamic> generateTableData(
    List<Staff> staffs,
    Map<String, List<DailyPlanning>> planningsByEmployee,
    int month,
    int year,
  ) {
    final numberOfDays = DateTime(year, month + 1, 0).day;
    final monthName = PlanningHelper._monthNames[month - 1];

    final columns = <String>['Name', 'Grade'];
    for (int day = 1; day <= numberOfDays; day++) {
      columns.add(day.toString());
    }

    final rows = <Map<String, String>>[];

    for (final staff in staffs) {
      final plannings = planningsByEmployee[staff.fullName] ?? [];
      final row = <String, String>{
        'Name': staff.fullName,
        'Grade': staff.grade,
      };

      for (int day = 1; day <= numberOfDays; day++) {
        final planning = plannings.firstWhere(
          (p) => p.dayOfMonth == day,
          orElse: () => DailyPlanning()..activityType = ActivityType.rest.index,
        );

        final code = ActivityType.values[planning.activityType].code;
        row[day.toString()] = code;
      }

      rows.add(row);
    }

    return {
      'title': 'Planning $monthName $year',
      'columns': columns,
      'rows': rows,
      'numberOfDays': numberOfDays,
    };
  }

  /// Generate planning report
  static String generateReport(
    MonthlyPlanning monthlyPlanning,
    List<Staff> staffs,
    Map<String, List<DailyPlanning>> planningsByEmployee,
  ) {
    final buffer = StringBuffer();
    final stats = <String, int>{
      'totalEmployees': staffs.length,
      'totalWorkDays': 0,
      'totalGuardDays': 0,
      'totalRestDays': 0,
      'totalLeaveDays': 0,
    };

    buffer.writeln('=== PLANNING REPORT ===');
    buffer.writeln('Period: ${monthlyPlanning.period}');
    buffer.writeln('Service: ${monthlyPlanning.service}');
    buffer.writeln('Department: ${monthlyPlanning.department}');
    buffer.writeln(
        'Status: ${PlanningStatus.values[monthlyPlanning.status].name}');
    buffer.writeln('');

    buffer.writeln('=== EMPLOYEES ===');
    for (final staff in staffs) {
      buffer.writeln('${staff.fullName} - ${staff.grade}');
      final plannings = planningsByEmployee[staff.fullName] ?? [];
      final employeeStats = PlanningHelper.calculateStatistics(plannings);

      stats['totalWorkDays'] = stats['totalWorkDays']! + employeeStats['work']!;
      stats['totalGuardDays'] =
          stats['totalGuardDays']! + employeeStats['guard']!;
      stats['totalRestDays'] = stats['totalRestDays']! + employeeStats['rest']!;
      stats['totalLeaveDays'] =
          stats['totalLeaveDays']! + employeeStats['leave']!;

      buffer.writeln('  - Work days: ${employeeStats['work']}');
      buffer.writeln('  - Guard days: ${employeeStats['guard']}');
      buffer.writeln('  - Rest days: ${employeeStats['rest']}');
      buffer.writeln('  - Leave days: ${employeeStats['leave']}');
      buffer.writeln('');
    }

    buffer.writeln('=== GLOBAL STATISTICS ===');
    buffer.writeln('Total staffs: ${stats['totalEmployees']}');
    buffer.writeln('Total work days: ${stats['totalWorkDays']}');
    buffer.writeln('Total guard days: ${stats['totalGuardDays']}');
    buffer.writeln('Total rest days: ${stats['totalRestDays']}');
    buffer.writeln('Total leave days: ${stats['totalLeaveDays']}');

    return buffer.toString();
  }
}

/// ========================================
/// VALIDATION AND BUSINESS RULES
/// ========================================

class PlanningValidator {
  /// Validate guard rotation rules
  static List<String> validateGuardRotation(List<DailyPlanning> plannings) {
    final errors = <String>[];
    int consecutiveGuards = 0;
    int consecutiveRests = 0;

    for (int i = 0; i < plannings.length; i++) {
      final current = ActivityType.values[plannings[i].activityType];
      final previous =
          i > 0 ? ActivityType.values[plannings[i - 1].activityType] : null;

      // Count consecutive guards
      if (current == ActivityType.guard) {
        consecutiveGuards++;
        consecutiveRests = 0;

        if (consecutiveGuards > 3) {
          errors
              .add('Day ${i + 1}: More than 3 consecutive guards not allowed');
        }
      } else if (current == ActivityType.rest ||
          current == ActivityType.recovery) {
        consecutiveRests++;
        consecutiveGuards = 0;
      } else {
        consecutiveGuards = 0;
        consecutiveRests = 0;
      }

      // Must have rest after guard
      if (previous == ActivityType.guard &&
          current != ActivityType.recovery &&
          current != ActivityType.rest) {
        errors.add('Day ${i + 1}: Recovery or rest required after guard duty');
      }

      // Weekend guard rules
      if (plannings[i].isWeekend && current == ActivityType.guard) {
        // Check if staff has had recent weekend guard
        final recentWeekendGuards = _countRecentWeekendGuards(plannings, i);
        if (recentWeekendGuards > 1) {
          errors.add('Day ${i + 1}: Too many weekend guards in short period');
        }
      }
    }

    return errors;
  }

  /// Count recent weekend guards for fair distribution
  static int _countRecentWeekendGuards(
      List<DailyPlanning> plannings, int currentIndex) {
    int count = 0;
    final lookbackDays = 14; // Look back 2 weeks
    final startIndex =
        (currentIndex - lookbackDays).clamp(0, plannings.length - 1);

    for (int i = startIndex; i < currentIndex; i++) {
      if (plannings[i].isWeekend &&
          ActivityType.values[plannings[i].activityType] ==
              ActivityType.guard) {
        count++;
      }
    }

    return count;
  }

  /// Validate leave conflicts
  static List<String> validateLeaveConflicts(
    List<Staff> staffs,
    List<Leave> proposedLeaves,
  ) {
    final errors = <String>[];

    for (final leave in proposedLeaves) {
      final staff = leave.staff.target;
      if (staff == null) continue;

      // Check minimum staff requirements
      final overlappingLeaves = proposedLeaves
          .where((other) =>
              other != leave &&
              other.staff.target?.hospitalService.target ==
                  staff.hospitalService.target &&
              _datesOverlap(leave.startDate, leave.endDate, other.startDate,
                  other.endDate))
          .toList();

      if (overlappingLeaves.length >= 2) {
        errors.add(
            '${staff.fullName}: Too many concurrent leaves in same service');
      }

      // Check holiday period restrictions
      if (_isHighDemandPeriod(leave.startDate, leave.endDate)) {
        errors.add(
            '${staff.fullName}: Leave during high-demand period requires special approval');
      }
    }

    return errors;
  }

  /// Check if dates overlap
  static bool _datesOverlap(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2.add(Duration(days: 1))) &&
        end1.isAfter(start2.subtract(Duration(days: 1)));
  }

  /// Check if period is high-demand (holidays, summer, etc.)
  static bool _isHighDemandPeriod(DateTime startDate, DateTime endDate) {
    final highDemandPeriods = [
      // Summer vacation
      [DateTime(startDate.year, 7, 1), DateTime(startDate.year, 8, 31)],
      // End of year holidays
      [DateTime(startDate.year, 12, 20), DateTime(startDate.year + 1, 1, 10)],
    ];

    for (final period in highDemandPeriods) {
      if (_datesOverlap(startDate, endDate, period[0], period[1])) {
        return true;
      }
    }

    return false;
  }
}

/// ========================================
/// ADVANCED PLANNING ALGORITHMS
/// ========================================

class PlanningAlgorithm {
  /// Generate optimal planning using constraint satisfaction
  static Map<String, List<DailyPlanning>> generateOptimalPlanning({
    required List<Staff> staffs,
    required MonthlyPlanning monthlyPlanning,
    required Map<String, dynamic> constraints,
  }) {
    final planningsByEmployee = <String, List<DailyPlanning>>{};
    final numberOfDays = monthlyPlanning.numberOfDays;

    // Initialize empty plannings for all staffs
    for (final staff in staffs) {
      planningsByEmployee[staff.fullName] =
          _initializeEmptyPlannings(staff, monthlyPlanning);
    }

    // Apply constraints and optimization
    _distributeGuardDuties(staffs, planningsByEmployee, numberOfDays);
    _balanceWorkload(staffs, planningsByEmployee);
    _optimizeWeekendDistribution(staffs, planningsByEmployee);

    return planningsByEmployee;
  }

  /// Initialize empty planning for an staff
  static List<DailyPlanning> _initializeEmptyPlannings(
      Staff staff, MonthlyPlanning monthlyPlanning) {
    final plannings = <DailyPlanning>[];

    for (int day = 1; day <= monthlyPlanning.numberOfDays; day++) {
      final date = DateTime(monthlyPlanning.year, monthlyPlanning.month, day);
      final planning = DailyPlanning()
        ..dayDate = date
        ..dayOfMonth = day
        ..activityType = ActivityType.normal.index
        ..status = ActivityStatus.scheduled.index
        ..isWeekend = date.weekday == 6 || date.weekday == 7
        ..isHoliday = PlanningHelper._isHoliday(date);

      planning.staff.target = staff;
      planning.monthlyPlanning.target = monthlyPlanning;
      plannings.add(planning);
    }

    return plannings;
  }

  /// Distribute guard duties fairly
  static void _distributeGuardDuties(
    List<Staff> staffs,
    Map<String, List<DailyPlanning>> planningsByEmployee,
    int numberOfDays,
  ) {
    final guardEligibleEmployees =
        staffs.where((e) => e.isAvailableForGuard && e.isActive).toList();

    if (guardEligibleEmployees.isEmpty) return;

    // Calculate required guards per month (assuming 1 guard per day)
    final totalGuardsNeeded = numberOfDays;
    final guardsPerEmployee =
        totalGuardsNeeded ~/ guardEligibleEmployees.length;
    final extraGuards = totalGuardsNeeded % guardEligibleEmployees.length;

    int currentEmployeeIndex = 0;
    int guardsAssigned = 0;

    for (int day = 1; day <= numberOfDays; day++) {
      final staff = guardEligibleEmployees[currentEmployeeIndex];
      final plannings = planningsByEmployee[staff.fullName]!;
      final dayPlanning = plannings[day - 1];

      // Assign guard if not weekend or if weekend guard is needed
      if (!dayPlanning.isWeekend || _needsWeekendGuard(day, numberOfDays)) {
        dayPlanning.activityType = ActivityType.guard.index;

        // Add recovery day after guard
        if (day < numberOfDays) {
          plannings[day].activityType = ActivityType.recovery.index;
        }

        guardsAssigned++;
      }

      // Rotate to next staff
      if (guardsAssigned >=
          guardsPerEmployee + (currentEmployeeIndex < extraGuards ? 1 : 0)) {
        currentEmployeeIndex =
            (currentEmployeeIndex + 1) % guardEligibleEmployees.length;
        guardsAssigned = 0;
      }
    }
  }

  /// Check if weekend guard is needed
  static bool _needsWeekendGuard(int day, int numberOfDays) {
    // Simplified logic - can be enhanced based on hospital requirements
    return day % 7 == 0 || day % 7 == 6; // Saturday or Sunday
  }

  /// Balance workload across staffs
  static void _balanceWorkload(
    List<Staff> staffs,
    Map<String, List<DailyPlanning>> planningsByEmployee,
  ) {
    for (final staff in staffs) {
      final plannings = planningsByEmployee[staff.fullName]!;
      final stats = PlanningHelper.calculateStatistics(plannings);

      // Adjust if workload is unbalanced
      final totalWork = stats['work']! + stats['guard']!;
      final expectedWork = (plannings.length * 0.7).round(); // 70% work days

      if (totalWork > expectedWork) {
        _reduceWorkload(plannings, totalWork - expectedWork);
      } else if (totalWork < expectedWork * 0.8) {
        _increaseWorkload(plannings, (expectedWork * 0.8).round() - totalWork);
      }
    }
  }

  /// Reduce workload by converting work days to rest
  static void _reduceWorkload(List<DailyPlanning> plannings, int daysToReduce) {
    int reduced = 0;

    for (final planning in plannings) {
      if (reduced >= daysToReduce) break;

      if (ActivityType.values[planning.activityType] == ActivityType.normal &&
          !planning.isWeekend) {
        planning.activityType = ActivityType.rest.index;
        reduced++;
      }
    }
  }

  /// Increase workload by converting rest days to work
  static void _increaseWorkload(
      List<DailyPlanning> plannings, int daysToIncrease) {
    int increased = 0;

    for (final planning in plannings) {
      if (increased >= daysToIncrease) break;

      if (ActivityType.values[planning.activityType] == ActivityType.rest &&
          !planning.isWeekend &&
          !planning.isHoliday) {
        planning.activityType = ActivityType.normal.index;
        increased++;
      }
    }
  }

  /// Optimize weekend distribution
  static void _optimizeWeekendDistribution(
    List<Staff> staffs,
    Map<String, List<DailyPlanning>> planningsByEmployee,
  ) {
    for (final staff in staffs) {
      final plannings = planningsByEmployee[staff.fullName]!;
      final weekendPlannings = plannings.where((p) => p.isWeekend).toList();

      // Ensure fair weekend rotation
      int weekendWorked = 0;
      for (final weekend in weekendPlannings) {
        final type = ActivityType.values[weekend.activityType];
        if (type == ActivityType.normal || type == ActivityType.guard) {
          weekendWorked++;
        }
      }

      // Adjust weekend work based on staff preferences and fairness
      final maxWeekendWork = (weekendPlannings.length * 0.5).round();
      if (weekendWorked > maxWeekendWork) {
        _reduceWeekendWork(weekendPlannings, weekendWorked - maxWeekendWork);
      }
    }
  }

  /// Reduce weekend work
  static void _reduceWeekendWork(
      List<DailyPlanning> weekendPlannings, int toReduce) {
    int reduced = 0;

    for (final planning in weekendPlannings) {
      if (reduced >= toReduce) break;

      final type = ActivityType.values[planning.activityType];
      if (type == ActivityType.normal) {
        planning.activityType = ActivityType.rest.index;
        reduced++;
      }
    }
  }
}

/// ========================================
/// REPORTING AND ANALYTICS
/// ========================================

class PlanningAnalytics {
  /// Generate comprehensive analytics report
  static Map<String, dynamic> generateAnalytics({
    required List<Staff> staffs,
    required Map<String, List<DailyPlanning>> planningsByEmployee,
    required MonthlyPlanning monthlyPlanning,
  }) {
    final analytics = <String, dynamic>{
      'period': monthlyPlanning.period,
      'service': monthlyPlanning.service,
      'totalEmployees': staffs.length,
      'employeeStats': <String, dynamic>{},
      'serviceStats': <String, dynamic>{},
      'trends': <String, dynamic>{},
      'recommendations': <String>[],
    };

    // Staff-level statistics
    final employeeStats = <String, Map<String, dynamic>>{};
    int totalWorkDays = 0;
    int totalGuardDays = 0;
    int totalRestDays = 0;

    for (final staff in staffs) {
      final plannings = planningsByEmployee[staff.fullName] ?? [];
      final stats = PlanningHelper.calculateStatistics(plannings);
      final workloadPercentage =
          (stats['work']! + stats['guard']!) / stats['total']! * 100;

      employeeStats[staff.fullName] = {
        'grade': staff.grade,
        'function': HospitalFunction.values[staff.function].displayName,
        'workDays': stats['work'],
        'guardDays': stats['guard'],
        'restDays': stats['rest'],
        'leaveDays': stats['leave'],
        'workloadPercentage': workloadPercentage.round(),
        'isBalanced': workloadPercentage >= 60 && workloadPercentage <= 80,
      };

      totalWorkDays += stats['work']!;
      totalGuardDays += stats['guard']!;
      totalRestDays += stats['rest']!;
    }

    analytics['employeeStats'] = employeeStats;

    // Service-level statistics
    analytics['serviceStats'] = {
      'totalWorkDays': totalWorkDays,
      'totalGuardDays': totalGuardDays,
      'totalRestDays': totalRestDays,
      'averageWorkload':
          staffs.isEmpty ? 0 : (totalWorkDays / staffs.length).round(),
      'guardCoverage': totalGuardDays / monthlyPlanning.numberOfDays * 100,
      'staffUtilization': (totalWorkDays + totalGuardDays) /
          (staffs.length * monthlyPlanning.numberOfDays) *
          100,
    };

    // Trends and patterns
    analytics['trends'] = _analyzeTrends(planningsByEmployee, monthlyPlanning);

    // Generate recommendations
    analytics['recommendations'] = _generateRecommendations(
        staffs, planningsByEmployee, analytics['serviceStats']);

    return analytics;
  }

  /// Analyze trends in planning
  static Map<String, dynamic> _analyzeTrends(
    Map<String, List<DailyPlanning>> planningsByEmployee,
    MonthlyPlanning monthlyPlanning,
  ) {
    final weeklyStats = <int, Map<String, int>>{};
    final weekendsStats = {'workingWeekends': 0, 'totalWeekends': 0};

    // Weekly breakdown
    for (int week = 1; week <= 4; week++) {
      weeklyStats[week] = {'work': 0, 'guard': 0, 'rest': 0};
    }

    planningsByEmployee.forEach((employeeName, plannings) {
      for (final planning in plannings) {
        final week = ((planning.dayOfMonth - 1) ~/ 7) + 1;
        final activityType = ActivityType.values[planning.activityType];

        if (weeklyStats[week] != null) {
          switch (activityType) {
            case ActivityType.normal:
              weeklyStats[week]!['work'] = weeklyStats[week]!['work']! + 1;
              break;
            case ActivityType.guard:
              weeklyStats[week]!['guard'] = weeklyStats[week]!['guard']! + 1;
              break;
            default:
              weeklyStats[week]!['rest'] = weeklyStats[week]!['rest']! + 1;
              break;
          }
        }

        // Weekend analysis
        if (planning.isWeekend) {
          weekendsStats['totalWeekends'] = weekendsStats['totalWeekends']! + 1;
          if (activityType == ActivityType.normal ||
              activityType == ActivityType.guard) {
            weekendsStats['workingWeekends'] =
                weekendsStats['workingWeekends']! + 1;
          }
        }
      }
    });

    return {
      'weeklyBreakdown': weeklyStats,
      'weekendUtilization': weekendsStats['totalWeekends']! > 0
          ? (weekendsStats['workingWeekends']! /
                  weekendsStats['totalWeekends']! *
                  100)
              .round()
          : 0,
    };
  }

  /// Generate recommendations based on analysis
  static List<String> _generateRecommendations(
    List<Staff> staffs,
    Map<String, List<DailyPlanning>> planningsByEmployee,
    Map<String, dynamic> serviceStats,
  ) {
    final recommendations = <String>[];

    // Check staff utilization
    final utilization = serviceStats['staffUtilization'] as double;
    if (utilization > 90) {
      recommendations.add(
          'Staff utilization is very high (${utilization.round()}%). Consider hiring additional staff.');
    } else if (utilization < 60) {
      recommendations.add(
          'Staff utilization is low (${utilization.round()}%). Consider optimizing schedules or redistributing tasks.');
    }

    // Check guard coverage
    final guardCoverage = serviceStats['guardCoverage'] as double;
    if (guardCoverage < 80) {
      recommendations.add(
          'Guard coverage is below recommended level (${guardCoverage.round()}%). Increase guard assignments.');
    }

    // Check workload balance
    final unbalancedEmployees = <String>[];
    planningsByEmployee.forEach((name, plannings) {
      final stats = PlanningHelper.calculateStatistics(plannings);
      final workload =
          (stats['work']! + stats['guard']!) / stats['total']! * 100;
      if (workload > 85 || workload < 50) {
        unbalancedEmployees.add('$name (${workload.round()}%)');
      }
    });

    if (unbalancedEmployees.isNotEmpty) {
      recommendations.add(
          'Workload imbalance detected for: ${unbalancedEmployees.join(', ')}');
    }

    // Check weekend distribution
    final weekendWorkers = <String>[];
    planningsByEmployee.forEach((name, plannings) {
      final weekendWork = plannings
          .where((p) =>
              p.isWeekend &&
              (ActivityType.values[p.activityType] == ActivityType.normal ||
                  ActivityType.values[p.activityType] == ActivityType.guard))
          .length;
      final totalWeekends = plannings.where((p) => p.isWeekend).length;

      if (totalWeekends > 0 && weekendWork / totalWeekends > 0.6) {
        weekendWorkers.add(name);
      }
    });

    if (weekendWorkers.isNotEmpty) {
      recommendations.add(
          'High weekend workload for: ${weekendWorkers.join(', ')}. Consider rotation.');
    }

    return recommendations;
  }
}

/// ========================================
/// NOTIFICATION SYSTEM
/// ========================================

class PlanningNotificationManager {
  /// Generate notifications for planning changes
  static List<Map<String, dynamic>> generateNotifications({
    required List<Staff> staffs,
    required Map<String, List<DailyPlanning>> planningsByEmployee,
    required MonthlyPlanning monthlyPlanning,
  }) {
    final notifications = <Map<String, dynamic>>[];

    // Check for upcoming guard duties
    final today = DateTime.now();
    final upcoming = today.add(Duration(days: 3));

    planningsByEmployee.forEach((employeeName, plannings) {
      for (final planning in plannings) {
        if (planning.dayDate.isAfter(today) &&
            planning.dayDate.isBefore(upcoming) &&
            ActivityType.values[planning.activityType] == ActivityType.guard) {
          notifications.add({
            'type': 'upcoming_guard',
            'staff': employeeName,
            'date': planning.dayDate,
            'message':
                'Upcoming guard duty on ${_formatDate(planning.dayDate)}',
            'priority': 'medium',
          });
        }
      }
    });

    // Check for schedule conflicts
    final conflicts = _detectScheduleConflicts(planningsByEmployee);
    for (final conflict in conflicts) {
      notifications.add({
        'type': 'schedule_conflict',
        'staff': conflict['staff'],
        'date': conflict['date'],
        'message': conflict['message'],
        'priority': 'high',
      });
    }

    return notifications;
  }

  /// Detect schedule conflicts
  static List<Map<String, dynamic>> _detectScheduleConflicts(
      Map<String, List<DailyPlanning>> planningsByEmployee) {
    final conflicts = <Map<String, dynamic>>[];

    planningsByEmployee.forEach((employeeName, plannings) {
      for (int i = 0; i < plannings.length - 1; i++) {
        final current = plannings[i];
        final next = plannings[i + 1];

        // Check for guard followed by normal work (should be recovery)
        if (ActivityType.values[current.activityType] == ActivityType.guard &&
            ActivityType.values[next.activityType] == ActivityType.normal) {
          conflicts.add({
            'staff': employeeName,
            'date': next.dayDate,
            'message':
                'Normal work scheduled after guard duty without recovery period',
          });
        }

        // Check for too many consecutive work days
        int consecutiveWork = 0;
        for (int j = i; j < plannings.length && j < i + 7; j++) {
          final type = ActivityType.values[plannings[j].activityType];
          if (type == ActivityType.normal || type == ActivityType.guard) {
            consecutiveWork++;
          } else {
            break;
          }
        }

        if (consecutiveWork > 6) {
          conflicts.add({
            'staff': employeeName,
            'date': plannings[i + 6].dayDate,
            'message': 'More than 6 consecutive work days scheduled',
          });
        }
      }
    });

    return conflicts;
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}

/// Daily Planning Entity - Day by day detail
@Entity()
class DailyPlanning {
  @Id()
  int id = 0;

  @Index()
  @Property(type: PropertyType.date)
  DateTime dayDate = DateTime.now();

  @Index()
  int dayOfMonth = 1; // 1-31

  @Index()
  int activityType = 0; // Index in ActivityType enum

  @Index()
  int status = 0; // Index in ActivityStatus enum

  // Specific schedule
  String? startTime;
  String? endTime;

  // Activity information
  String? activityLocation;
  String? activityDescription;

  @Index()
  bool isWeekend = false;

  @Index()
  bool isHoliday = false;

  // Relations
  late final staff = ToOne<Staff>();
  final monthlyPlanning = ToOne<MonthlyPlanning>();

  DailyPlanning() {
    // Calculate isWeekend after initialization
    isWeekend = dayDate.weekday == 6 || dayDate.weekday == 7;
  }

  // Utility methods
  String get dayName => _dayNames[dayDate.weekday - 1];

  String get activityCode => ActivityType.values[activityType].code;

  bool get isRest =>
      ActivityType.values[activityType] == ActivityType.rest ||
      ActivityType.values[activityType] == ActivityType.recovery;

  bool get isWork =>
      !isRest && ActivityType.values[activityType] != ActivityType.leave;

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
}

/// Medical Activity Entity - Specialized activities for doctors
@Entity()
class MedicalActivity {
  @Id()
  int id = 0;

  @Index()
  @Property(type: PropertyType.date)
  DateTime activityDate = DateTime.now();

  @Index()
  int weekDay = 0; // Index in WeekDay enum

  @Index()
  int activityType = 0; // Index in MedicalActivityType enum

  String activityName = '';
  String? description;
  String? location;

  // Schedule
  String startTime = '08:00';
  String endTime = '16:00';

  @Index()
  bool isRecurrent = false; // Repeats every week

  @Index()
  bool isActive = true;

  String? observations;

  // Relations
  final staff = ToOne<Staff>();

  MedicalActivity();

  // Utility methods
  String get dayName => WeekDay.values[weekDay].displayName;

  Duration get duration {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return end.difference(start);
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

/// Leave Entity - Leave and absence management
@Entity()
class Leave {
  @Id()
  int id = 0;

  @Index()
  @Property(type: PropertyType.date)
  DateTime startDate = DateTime.now();

  @Index()
  @Property(type: PropertyType.date)
  DateTime endDate = DateTime.now();

  @Index()
  int leaveType = 0; // Index in LeaveType enum

  String? reason;
  String? observations;

  @Index()
  int status = 0; // Index in LeaveStatus enum

  // Administrative information
  String? requestNumber;

  @Property(type: PropertyType.date)
  DateTime requestSubmissionDate = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime? approvalDate;

  String? approvedBy;

  @Index()
  bool isFullyPaid = true;

  // Relations
  final staff = ToOne<Staff>();

  Leave();

  // Utility methods
  int get numberOfDays => endDate.difference(startDate).inDays + 1;

  bool get isApproved => LeaveStatus.values[status] == LeaveStatus.approved;

  bool get isOngoing =>
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate.add(Duration(days: 1)));

  bool get isFinished => DateTime.now().isAfter(endDate);
}

/// Hospital Service Entity - Services and departments
@Entity()
class HospitalService {
  @Id()
  int id = 0;

  @Index()
  @Unique()
  String serviceCode = '';

  @Index()
  String name = '';

  String? description;
  String? location;
  String? phone;

  // Managers
  String? serviceChief;
  String? medicalSupervisor;
  String? generalDirector;

  // Capacity
  int? numberOfEmployees;
  int? numberOfDoctors;
  int? numberOfNurses;

  @Index()
  bool isActive = true;

  // Metadata
  @Property(type: PropertyType.date)
  DateTime creationDate = DateTime.now();

  // Relations
  @Backlink('hospitalService')
  final staffs = ToMany<Staff>();

  @Backlink('hospitalService')
  final monthlyPlannings = ToMany<MonthlyPlanning>();

  HospitalService();

  // Utility methods
  int get totalStaff => staffs.where((e) => e.isActive).length;

  int get medicalStaff => staffs
      .where((e) =>
          e.isActive &&
          PersonnelCategory.values[e.category] == PersonnelCategory.medical)
      .length;

  int get paramedicalStaff => staffs
      .where((e) =>
          e.isActive &&
          PersonnelCategory.values[e.category] == PersonnelCategory.paramedical)
      .length;

  // Methods for guard groups
  List<Staff> getEmployeesByGroup(String group) =>
      staffs.where((e) => e.guardGroup == group && e.isActive).toList();

  Map<String, List<Staff>> get guardGroups {
    final groups = <String, List<Staff>>{
      'A': [],
      'B': [],
      'C': [],
      'D': [],
    };

    for (final staff
        in staffs.where((e) => e.isActive && e.guardGroup != null)) {
      groups[staff.guardGroup]?.add(staff);
    }

    return groups;
  }
}

/// Planning Statistics Entity - For dashboards and reports
@Entity()
class PlanningStatistics {
  @Id()
  int id = 0;

  @Index()
  int month = 1;

  @Index()
  int year = DateTime.now().year;

  @Index()
  String service = '';

  @Index()
  String statisticsType = '';

  // Numerical statistics
  int? totalWorkDays;
  int? totalGuardDays;
  int? totalRestDays;
  int? totalLeaveDays;
  int? totalAbsenceDays;

  // Percentages
  double? presenceRate;
  double? absenceRate;
  double? guardOccupationRate;

  // JSON data for flexibility
  String? detailedDataJson;

  @Property(type: PropertyType.date)
  DateTime calculationDate = DateTime.now();

  // Relations
  final serviceRelation = ToOne<HospitalService>();

  PlanningStatistics();
}

/// Entity to manage planning templates
@Entity()
class PlanningTemplate {
  @Id()
  int id = 0;

  @Index()
  String name = '';

  String? description;

  @Index()
  int scheduleType = 0; // Normal 8h-16h, Guard 12h, etc.

  // Rotation pattern (ex: "N,N,R,R" for 2 normal days, 2 rest)
  String rotationPattern = '';

  @Index()
  bool isActive = true;

  @Property(type: PropertyType.date)
  DateTime creationDate = DateTime.now();

  PlanningTemplate();

  List<String> get patternList => rotationPattern.split(',');

  set patternList(List<String> value) => rotationPattern = value.join(',');
}

/// ========================================
/// ENUMERATIONS
/// ========================================

enum HospitalFunction {
  // Medical staff
  doctor,
  chiefDoctor,
  principalDoctor,
  generalPractitioner,
  rheumatologist,

  // Paramedical staff
  nurse,
  majorNurse,
  nurseAide, // Aide-soignant
  principalNurseAide,
  registeredNurse, // Infirmier diplômé d'État

  // Administrative staff
  administrator,
  administrativeAgent,
  officeAgent,

  // Specialized staff
  psychologist,
  pharmacist,
  pharmacyManager,

  // Technical staff
  hygieneAgent,
  technicalAgent,
}

enum PersonnelCategory {
  medical,
  paramedical,
  administrative,
  technical,
  support,
}

enum ScheduleType {
  normal8to16, // 8h-16h
  guard12h, // Guard 12h
  guard24h, // 8h-8h (24h)
  night, // Night schedule
  variable, // Variable schedule
}

enum EmployeeStatus {
  active,
  onLeave,
  training,
  sick,
  suspended,
  retired,
  resigned,
}

enum PlanningType {
  monthly,
  weekly,
  guards,
  leaves,
  medicalActivities,
}

enum PlanningStatus {
  draft,
  inProgress,
  validated,
  approved,
  archived,
}

enum ActivityType {
  normal, // N
  guard, // G
  recovery, // Ré or R
  leave, // C
  sickLeave, // CM
  rest, // Rest
  training, // Training
  meeting, // Meeting
}

enum ActivityStatus {
  scheduled,
  confirmed,
  postponed,
  cancelled,
  completed,
}

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

enum MedicalActivityType {
  consultation,
  generalVisit,
  service,
  biotherapy,
  dmo, // Bone densitometry
  pedagogicalDay,
  externalConsultation, // EPSP
  emergency,
  training,
  research,
}

enum LeaveType {
  annual,
  sick,
  maternity,
  paternity,
  training,
  exceptional,
  unpaid,
}

enum LeaveStatus {
  pending,
  approved,
  refused,
  cancelled,
  postponed,
}

/// ========================================
/// EXTENSIONS FOR DISPLAY
/// ========================================

extension HospitalFunctionExtension on HospitalFunction {
  String get displayName {
    switch (this) {
      case HospitalFunction.doctor:
        return 'Doctor';
      case HospitalFunction.chiefDoctor:
        return 'Chief Doctor';
      case HospitalFunction.principalDoctor:
        return 'Principal Doctor';
      case HospitalFunction.generalPractitioner:
        return 'General Practitioner';
      case HospitalFunction.rheumatologist:
        return 'Rheumatologist';
      case HospitalFunction.nurse:
        return 'Nurse';
      case HospitalFunction.majorNurse:
        return 'Major Nurse';
      case HospitalFunction.nurseAide:
        return 'Nurse Aide';
      case HospitalFunction.principalNurseAide:
        return 'Principal Nurse Aide';
      case HospitalFunction.registeredNurse:
        return 'Registered Nurse';
      case HospitalFunction.administrator:
        return 'Administrator';
      case HospitalFunction.administrativeAgent:
        return 'Administrative Agent';
      case HospitalFunction.officeAgent:
        return 'Office Agent';
      case HospitalFunction.psychologist:
        return 'Psychologist';
      case HospitalFunction.pharmacist:
        return 'Pharmacist';
      case HospitalFunction.pharmacyManager:
        return 'Pharmacy Manager';
      case HospitalFunction.hygieneAgent:
        return 'Hygiene Agent';
      case HospitalFunction.technicalAgent:
        return 'Technical Agent';
    }
  }

  String get abbreviation {
    switch (this) {
      case HospitalFunction.doctor:
        return 'MD';
      case HospitalFunction.chiefDoctor:
        return 'CMD';
      case HospitalFunction.rheumatologist:
        return 'RHEUM';
      case HospitalFunction.nurse:
        return 'RN';
      case HospitalFunction.majorNurse:
        return 'MN';
      case HospitalFunction.nurseAide:
        return 'NA';
      case HospitalFunction.principalNurseAide:
        return 'PNA';
      case HospitalFunction.registeredNurse:
        return 'RN';
      default:
        return displayName.toUpperCase();
    }
  }
}

extension ActivityTypeExtension on ActivityType {
  String get code {
    switch (this) {
      case ActivityType.normal:
        return 'N';
      case ActivityType.guard:
        return 'G';
      case ActivityType.recovery:
        return 'R';
      case ActivityType.leave:
        return 'L';
      case ActivityType.sickLeave:
        return 'SL';
      case ActivityType.rest:
        return 'REST';
      case ActivityType.training:
        return 'T';
      case ActivityType.meeting:
        return 'M';
    }
  }

  String get displayName {
    switch (this) {
      case ActivityType.normal:
        return 'Normal';
      case ActivityType.guard:
        return 'Guard';
      case ActivityType.recovery:
        return 'Recovery';
      case ActivityType.leave:
        return 'Leave';
      case ActivityType.sickLeave:
        return 'Sick Leave';
      case ActivityType.rest:
        return 'Rest';
      case ActivityType.training:
        return 'Training';
      case ActivityType.meeting:
        return 'Meeting';
    }
  }

  // Color for interface
  String get color {
    switch (this) {
      case ActivityType.normal:
        return '#4CAF50'; // Green
      case ActivityType.guard:
        return '#F44336'; // Red
      case ActivityType.recovery:
        return '#FF9800'; // Orange
      case ActivityType.rest:
        return '#2196F3'; // Blue
      case ActivityType.leave:
        return '#9C27B0'; // Purple
      case ActivityType.sickLeave:
        return '#E91E63'; // Pink
      case ActivityType.training:
        return '#795548'; // Brown
      case ActivityType.meeting:
        return '#607D8B'; // Blue Grey
    }
  }
}

/// Utility class for ActivityType
class ActivityTypeHelper {
  static ActivityType fromCode(String code) {
    switch (code.toUpperCase().trim()) {
      case 'N':
        return ActivityType.normal;
      case 'G':
        return ActivityType.guard;
      case 'R':
      case 'RÉ':
      case 'RE':
        return ActivityType.recovery;
      case 'REST':
        return ActivityType.rest;
      case 'L':
      case 'C':
        return ActivityType.leave;
      case 'SL':
      case 'CM':
        return ActivityType.sickLeave;
      case 'T':
      case 'F':
        return ActivityType.training;
      case 'M':
      case 'RU':
        return ActivityType.meeting;
      default:
        return ActivityType.normal;
    }
  }

  // Get color for interface
  static String getColor(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.normal:
        return '#4CAF50'; // Green
      case ActivityType.guard:
        return '#F44336'; // Red
      case ActivityType.recovery:
        return '#FF9800'; // Orange
      case ActivityType.rest:
        return '#2196F3'; // Blue
      case ActivityType.leave:
        return '#9C27B0'; // Purple
      case ActivityType.sickLeave:
        return '#E91E63'; // Pink
      case ActivityType.training:
        return '#795548'; // Brown
      case ActivityType.meeting:
        return '#607D8B'; // Blue Grey
    }
  }
}

extension WeekDayExtension on WeekDay {
  String get displayName {
    switch (this) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
      case WeekDay.saturday:
        return 'Saturday';
      case WeekDay.sunday:
        return 'Sunday';
    }
  }

  String get abbreviation {
    switch (this) {
      case WeekDay.monday:
        return 'Mon';
      case WeekDay.tuesday:
        return 'Tue';
      case WeekDay.wednesday:
        return 'Wed';
      case WeekDay.thursday:
        return 'Thu';
      case WeekDay.friday:
        return 'Fri';
      case WeekDay.saturday:
        return 'Sat';
      case WeekDay.sunday:
        return 'Sun';
    }
  }
}

/// ========================================
/// UTILITIES FOR OPTIMAL UX/UI
/// ========================================

class PlanningHelper {
  /// Creates an empty planning for a given month
  static MonthlyPlanning createEmptyPlanning({
    required int month,
    required int year,
    required String service,
    required String department,
  }) {
    final planning = MonthlyPlanning()
      ..month = month
      ..year = year
      ..service = service
      ..department = department
      ..planningType = PlanningType.monthly.index
      ..title = 'Planning ${_monthNames[month - 1]} $year'
      ..status = PlanningStatus.draft.index;

    return planning;
  }

  /// Generates days of a month with default activities
  static List<DailyPlanning> generateMonthDays({
    required MonthlyPlanning monthlyPlanning,
    required Staff staff,
    String? activityPattern,
  }) {
    final days = <DailyPlanning>[];
    final numberOfDays =
        DateTime(monthlyPlanning.year, monthlyPlanning.month + 1, 0).day;

    final pattern = activityPattern?.split(',') ?? ['N']; // Default normal

    for (int day = 1; day <= numberOfDays; day++) {
      final date = DateTime(monthlyPlanning.year, monthlyPlanning.month, day);
      final activityIndex = (day - 1) % pattern.length;
      final activityType = ActivityTypeHelper.fromCode(pattern[activityIndex]);

      final planning = DailyPlanning()
        ..dayDate = date
        ..dayOfMonth = day
        ..activityType = activityType.index
        ..status = ActivityStatus.scheduled.index
        ..isWeekend = date.weekday == 6 || date.weekday == 7
        ..isHoliday = _isHoliday(date);

      planning.staff.target = staff;
      planning.monthlyPlanning.target = monthlyPlanning;

      days.add(planning);
    }

    return days;
  }

  /// Checks if a date is a holiday (adapt according to country)
  static bool _isHoliday(DateTime date) {
    // Fixed holidays in Algeria (example)
    final holidays = [
      DateTime(date.year, 1, 1), // New Year
      DateTime(date.year, 5, 1), // Labor Day
      DateTime(date.year, 7, 5), // Independence Day
      DateTime(date.year, 11, 1), // Revolution Anniversary
    ];

    return holidays.any(
        (holiday) => holiday.day == date.day && holiday.month == date.month);
  }

  /// Applies a rotation template to a planning
  static void applyTemplate({
    required List<DailyPlanning> plannings,
    required PlanningTemplate template,
  }) {
    final pattern = template.patternList;

    for (int i = 0; i < plannings.length; i++) {
      final activityCode = pattern[i % pattern.length];
      plannings[i].activityType =
          ActivityTypeHelper.fromCode(activityCode).index;
    }
  }

  /// Calculates planning statistics
  static Map<String, int> calculateStatistics(List<DailyPlanning> plannings) {
    final stats = <String, int>{
      'total': plannings.length,
      'work': 0,
      'guard': 0,
      'rest': 0,
      'leave': 0,
      'recovery': 0,
    };

    for (final planning in plannings) {
      final type = ActivityType.values[planning.activityType];
      switch (type) {
        case ActivityType.normal:
          stats['work'] = stats['work']! + 1;
          break;
        case ActivityType.guard:
          stats['guard'] = stats['guard']! + 1;
          break;
        case ActivityType.rest:
          stats['rest'] = stats['rest']! + 1;
          break;
        case ActivityType.leave:
        case ActivityType.sickLeave:
          stats['leave'] = stats['leave']! + 1;
          break;
        case ActivityType.recovery:
          stats['recovery'] = stats['recovery']! + 1;
          break;
        default:
          break;
      }
    }

    return stats;
  }

  /// Validates planning consistency (not too many consecutive guards, etc.)
  static List<String> validatePlanning(List<DailyPlanning> plannings) {
    final errors = <String>[];
    int consecutiveGuards = 0;

    for (int i = 0; i < plannings.length; i++) {
      final planning = plannings[i];
      final type = ActivityType.values[planning.activityType];

      if (type == ActivityType.guard) {
        consecutiveGuards++;
        if (consecutiveGuards > 2) {
          errors.add(
              'More than 2 consecutive guards detected on day ${planning.dayOfMonth}');
        }
      } else {
        consecutiveGuards = 0;
      }

      // Check rest after guard
      if (i > 0 &&
          ActivityType.values[plannings[i - 1].activityType] ==
              ActivityType.guard &&
          type != ActivityType.recovery &&
          type != ActivityType.rest) {
        errors.add('No rest after guard on day ${planning.dayOfMonth}');
      }
    }

    return errors;
  }

  /// Generates balanced planning for a guard group
  static Map<String, List<DailyPlanning>> generateGroupPlanning({
    required List<Staff> staffs,
    required MonthlyPlanning monthlyPlanning,
    required String basePattern,
  }) {
    final planningsByEmployee = <String, List<DailyPlanning>>{};

    for (int i = 0; i < staffs.length; i++) {
      final staff = staffs[i];
      final plannings = generateMonthDays(
        monthlyPlanning: monthlyPlanning,
        staff: staff,
        activityPattern: _shiftPattern(basePattern, i),
      );
      planningsByEmployee[staff.fullName] = plannings;
    }

    return planningsByEmployee;
  }

  /// Shifts a pattern to avoid all staffs having the same activity
  static String _shiftPattern(String pattern, int shift) {
    final elements = pattern.split(',');
    final shifted = <String>[];

    for (int i = 0; i < elements.length; i++) {
      final index = (i + shift) % elements.length;
      shifted.add(elements[index]);
    }

    return shifted.join(',');
  }

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
}
