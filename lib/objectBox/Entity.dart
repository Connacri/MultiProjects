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
  @Backlink('hotel')
  final rooms = ToMany<Room>();

  /// Ajout : relation vers SeasonalPricing sélectionné
  final selectedSeasonalPricing = ToOne<SeasonalPricing>();

  Hotel({
    required this.name,
    required this.floors,
    required this.roomsPerFloor,
    this.avoidedNumbers = '',
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
    this.status = "Libre",
  });

// Helper pour obtenir le prix effectif selon la catégorie et la saison
// double getEffectivePrice(DateTime date) {
//   final categoryPrice = category.target?.basePrice ?? basePrice ?? 0.0;
//   // Ici vous pourriez ajouter la logique de calcul saisonnier
//   return categoryPrice;
// }
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
  String status; // "Pending", "Confirmed", "Cancelled", "Completed"
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
  });

  bool isDateInSeason(DateTime date) {
    return date.isAfter(startDate.subtract(Duration(days: 1))) &&
        date.isBefore(endDate.add(Duration(days: 1)));
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

  // Relation Many-to-Many avec Reservation
  @Backlink('guests')
  final reservations = ToMany<Reservation>();

  Guest({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.idCardNumber,
    this.nationality,
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

  // Champs calculés optionnels
  double? cachedBoardBasisPrice;
  double? cachedExtrasTotal;

  Reservation({
    required this.from,
    required this.to,
    required this.pricePerNight,
    this.status = "Confirmée",
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
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

  bool get isActive => status != "Annulée" && status != "Parti";

  bool get hasArrived => status == "Arrivé" || status == "Parti";

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

  @Backlink('receptionist')
  final reservations = ToMany<Reservation>();

  Employee({
    required this.fullName,
    required this.phoneNumber,
    this.email,
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
}
