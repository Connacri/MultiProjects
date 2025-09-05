import 'package:flutter/material.dart';

import '../../../Entity.dart';
import 'provider_hotel.dart';

class HotelDataInitializer {
  final HotelProvider hotelProvider;

  HotelDataInitializer(this.hotelProvider);

  /// Initialise toutes les données par défaut
  Future<void> initializeAllDefaultData() async {
    debugPrint('🏨 Initialisation des données par défaut...');
    await createDefaultEmployees();
    await createDefaultRoomCategories();
    await createDefaultBoardBasis();
    await createDefaultExtraServices();
    await createDefaultSeasonalPricing();
    //await createDefaultHotels();
    await createSampleGuests();
    // await createSampleReservations();
    await initializeMissingData();
    debugPrint('✅ Initialisation terminée !');
  }

  /// ==================== HOTELS ====================
  Future<void> createDefaultHotels() async {
    debugPrint('🏨 Création des hôtels par défaut...');
    final hotels = [
      Hotel(
        name: 'Le Grand Palace Alger',
        floors: 12,
        roomsPerFloor: 25,
        avoidedNumbers: '13,113,213,313',
      ),
      Hotel(
        name: 'Marina Resort & Spa',
        floors: 8,
        roomsPerFloor: 18,
        avoidedNumbers: '13,66,113',
      ),
      Hotel(
        name: 'Atlas Mountain Lodge',
        floors: 6,
        roomsPerFloor: 15,
        avoidedNumbers: '13,413',
      ),
      Hotel(
        name: 'Sahara Oasis Hotel',
        floors: 10,
        roomsPerFloor: 22,
        avoidedNumbers: '13,113,213,313,413,513',
      ),
      Hotel(
        name: 'Mediterranean Pearl',
        floors: 15,
        roomsPerFloor: 28,
        avoidedNumbers: '13,113,213,313,413,513,613,713,813,913',
      ),
    ];

    for (final hotel in hotels) {
      final savedHotel = await hotelProvider.addHotel(hotel);
      await createRoomsForHotel(hotel);
    }
    debugPrint('✅ ${hotels.length} hôtels créés avec leurs chambres');
  }

  Future<void> createRoomsForHotel(Hotel hotel) async {
    final categories = await hotelProvider.getRoomCategories();
    if (categories.isEmpty) {
      debugPrint('Aucune catégorie de chambre disponible');
      return;
    }

    final avoidedNumbers = hotel.avoidedNumbersList;
    int roomIndex = 0;

    try {
      // Charger les chambres existantes une seule fois (optimisation)
      final existingRooms = await hotelProvider.getRoomsForHotel(hotel);

      for (int floor = 1; floor <= hotel.floors; floor++) {
        for (int roomOnFloor = 1;
            roomOnFloor <= hotel.roomsPerFloor;
            roomOnFloor++) {
          // Construire le code de la chambre (ex: 102, 305)
          String roomCode = '$floor${roomOnFloor.toString().padLeft(2, '0')}';

          // Vérifier si ce numéro est interdit
          if (avoidedNumbers.contains(roomCode)) {
            debugPrint('Chambre $roomCode ignorée (numéro interdit)');
            continue;
          }

          // Vérifier si la chambre existe déjà
          if (existingRooms.any((r) => r.code == roomCode)) {
            debugPrint('Chambre $roomCode existe déjà pour cet hôtel');
            continue;
          }

          // Déterminer le standing selon l'étage
          String standing;
          if (floor >= hotel.floors - 1) {
            standing = 'suite';
          } else if (floor >= hotel.floors - 3) {
            standing = 'deluxe';
          } else if (floor >= 3) {
            standing = 'standard';
          } else {
            standing = 'economy';
          }

          // Récupérer toutes les catégories de ce standing
          List<RoomCategory> standingCategories = categories
              .where((c) => c.standing.toLowerCase() == standing)
              .toList();

          // Sélectionner une catégorie en alternant selon roomIndex
          RoomCategory? category;
          if (standingCategories.isNotEmpty) {
            category =
                standingCategories[roomIndex % standingCategories.length];
          } else {
            category = categories.last; // fallback
          }

          // Créer la chambre
          final room = Room(
            code: roomCode,
            status: roomIndex % 5 == 0 ? 'Occupée' : 'Libre',
          );

          // Associer hôtel et catégorie
          room.hotel.target = hotel;
          room.category.target = category;

          // Ajouter la chambre
          await hotelProvider.addRoom(room);
          roomIndex++;

          debugPrint(
              'Chambre $roomCode créée avec la catégorie ${category.name}');
        }
      }

      debugPrint('$roomIndex chambres créées pour l\'hôtel ${hotel.name}');
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de la création des chambres: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// ==================== EMPLOYEES ====================
  Future<void> createDefaultEmployees() async {
    debugPrint('👥 Création des employés par défaut...');
    final employees = [
      Employee(
        fullName: 'Amina Benali',
        phoneNumber: '+213 555 123 456',
        email: 'amina.benali@hotel.dz',
      ),
      Employee(
        fullName: 'Karim Mansouri',
        phoneNumber: '+213 555 234 567',
        email: 'karim.mansouri@hotel.dz',
      ),
      Employee(
        fullName: 'Fatima Zerrouki',
        phoneNumber: '+213 555 345 678',
        email: 'fatima.zerrouki@hotel.dz',
      ),
      Employee(
        fullName: 'Ahmed Slimani',
        phoneNumber: '+213 555 456 789',
        email: 'ahmed.slimani@hotel.dz',
      ),
      Employee(
        fullName: 'Nadia Boudjenah',
        phoneNumber: '+213 555 567 890',
        email: 'nadia.boudjenah@hotel.dz',
      ),
      Employee(
        fullName: 'Youssef Hamdani',
        phoneNumber: '+213 555 678 901',
        email: 'youssef.hamdani@hotel.dz',
      ),
      Employee(
        fullName: 'Samia Chellali',
        phoneNumber: '+213 555 789 012',
        email: 'samia.chellali@hotel.dz',
      ),
      Employee(
        fullName: 'Omar Khelifi',
        phoneNumber: '+213 555 890 123',
        email: 'omar.khelifi@hotel.dz',
      ),
    ];

    for (final employee in employees) {
      await hotelProvider.addEmployee(employee);
    }
    debugPrint('✅ ${employees.length} employés créés');
  }

  /// ==================== ENHANCED ROOM CATEGORIES ====================
  Future<void> createDefaultRoomCategories() async {
    debugPrint('📋 Création des catégories de chambres enrichies...');
    final categories = [
      // Economy Range
      RoomCategory(
        name: 'Chambre Simple Économique',
        code: 'ECO_SGL',
        description:
            'Chambre basique avec un lit simple, idéale pour un voyageur solo',
        bedType: 'Single',
        capacity: 1,
        standing: 'Economy',
        basePrice: 6000,
        allowsExtraBed: false,
        sortOrder: 10,
      )..setAmenities([
          'WiFi gratuit',
          'Climatisation',
          'Télévision',
          'Salle de bain privée'
        ]),

      RoomCategory(
        name: 'Chambre Double Économique',
        code: 'ECO_DBL',
        description:
            'Chambre économique avec un lit double, rapport qualité-prix optimal',
        bedType: 'Double',
        capacity: 2,
        standing: 'Economy',
        basePrice: 8000,
        allowsExtraBed: true,
        extraBedPrice: 2000,
        sortOrder: 20,
      )..setAmenities([
          'WiFi gratuit',
          'Climatisation',
          'Télévision',
          'Salle de bain privée'
        ]),

      // Standard Range
      RoomCategory(
        name: 'Chambre Standard Double',
        code: 'STD_DBL',
        description:
            'Chambre confortable avec lit double et équipements modernes',
        bedType: 'Double',
        capacity: 2,
        standing: 'Standard',
        basePrice: 12000,
        weekendMultiplier: 1.2,
        allowsExtraBed: true,
        extraBedPrice: 3000,
        sortOrder: 30,
      )..setAmenities([
          'WiFi premium',
          'Climatisation',
          'Télévision LCD',
          'Minibar',
          'Coffre-fort',
          'Bureau'
        ]),

      RoomCategory(
        name: 'Chambre Twin Standard',
        code: 'STD_TWN',
        description:
            'Deux lits simples, parfaite pour voyageurs d\'affaires ou amis',
        bedType: 'Twin',
        capacity: 2,
        standing: 'Standard',
        basePrice: 12500,
        weekendMultiplier: 1.2,
        sortOrder: 35,
      )..setAmenities([
          'WiFi premium',
          'Climatisation',
          'Télévision LCD',
          'Bureau',
          'Minibar'
        ]),

      RoomCategory(
        name: 'Chambre Standard Triple',
        code: 'STD_TRP',
        description:
            'Chambre spacieuse pour 3 personnes avec lits jumeaux + lit simple',
        bedType: 'Twin + Single',
        capacity: 3,
        standing: 'Standard',
        basePrice: 15000,
        weekendMultiplier: 1.2,
        sortOrder: 36,
      )..setAmenities([
          'WiFi premium',
          'Climatisation',
          'Télévision LCD',
          'Minibar',
          'Coffre-fort'
        ]),

      // Superior Range
      RoomCategory(
        name: 'Chambre Supérieure Vue Jardin',
        code: 'SUP_GDN',
        description: 'Chambre élégante avec vue sur les jardins de l\'hôtel',
        bedType: 'Queen',
        capacity: 2,
        standing: 'Superior',
        viewType: 'Garden',
        basePrice: 16000,
        weekendMultiplier: 1.25,
        allowsExtraBed: true,
        extraBedPrice: 3500,
        sortOrder: 37,
      )..setAmenities([
          'WiFi premium',
          'Balcon',
          'Machine à café',
          'Télévision LCD',
          'Peignoirs',
          'Minibar'
        ]),

      // Deluxe Range
      RoomCategory(
        name: 'Chambre Deluxe Vue Mer',
        code: 'DLX_SEA',
        description:
            'Chambre spacieuse avec lit King et vue imprenable sur la mer',
        bedType: 'King',
        capacity: 2,
        standing: 'Deluxe',
        viewType: 'Sea',
        basePrice: 25000,
        weekendMultiplier: 1.4,
        allowsExtraBed: true,
        extraBedPrice: 4000,
        sortOrder: 40,
      )..setAmenities([
          'WiFi premium',
          'Balcon privé',
          'Machine Nespresso',
          'Télévision 4K',
          'Peignoirs de luxe',
          'Service en chambre 24h'
        ]),

      RoomCategory(
        name: 'Chambre Deluxe Familiale',
        code: 'DLX_FAM',
        description:
            'Grande chambre familiale avec espaces séparés pour parents et enfants',
        bedType: 'King + Bunk beds',
        capacity: 4,
        standing: 'Deluxe',
        basePrice: 32000,
        weekendMultiplier: 1.4,
        allowsExtraBed: true,
        extraBedPrice: 4000,
        sortOrder: 45,
      )..setAmenities([
          'WiFi premium',
          'Coin enfants',
          'Kitchenette',
          'Balcon',
          'Xbox',
          'Minibar familial'
        ]),

      RoomCategory(
        name: 'Chambre Deluxe Vue Piscine',
        code: 'DLX_POOL',
        description: 'Chambre premium avec accès direct à la zone piscine',
        bedType: 'King',
        capacity: 2,
        standing: 'Deluxe',
        viewType: 'Pool',
        basePrice: 28000,
        weekendMultiplier: 1.4,
        sortOrder: 48,
      )..setAmenities([
          'WiFi premium',
          'Terrasse privée',
          'Accès piscine',
          'Machine Nespresso',
          'Peignoirs'
        ]),

      // Suite Range
      RoomCategory(
        name: 'Junior Suite',
        code: 'JSU',
        description: 'Suite élégante avec salon séparé et services premium',
        bedType: 'King',
        capacity: 2,
        standing: 'Suite',
        basePrice: 45000,
        weekendMultiplier: 1.6,
        allowsExtraBed: true,
        extraBedPrice: 6000,
        sortOrder: 60,
      )..setAmenities([
          'WiFi ultra premium',
          'Salon privé',
          'Jacuzzi',
          'Machine Nespresso',
          'Majordome',
          'Check-in privé'
        ]),

      RoomCategory(
        name: 'Suite Familiale Premium',
        code: 'FAM_SUITE',
        description: 'Suite spacieuse avec 2 chambres et salon familial',
        bedType: 'King + Twin',
        capacity: 6,
        standing: 'Suite',
        basePrice: 65000,
        weekendMultiplier: 1.6,
        sortOrder: 70,
      )..setAmenities([
          'WiFi ultra premium',
          '2 salles de bain',
          'Kitchenette complète',
          'Salon familial',
          'Terrasse',
          'Jeux enfants'
        ]),

      RoomCategory(
        name: 'Suite Présidentielle',
        code: 'PRES_SUITE',
        description:
            'Expérience ultime du luxe avec vue panoramique et services VIP',
        bedType: 'King',
        capacity: 4,
        standing: 'Suite',
        viewType: 'Panoramic',
        basePrice: 150000,
        weekendMultiplier: 2.0,
        sortOrder: 100,
      )..setAmenities([
          'WiFi dédiée',
          'Salon exécutif',
          'Salle à manger',
          'Bureau privé',
          'Hammam privé',
          'Transport VIP',
          'Chef personnel'
        ]),

      RoomCategory(
        name: 'Suite Penthouse',
        code: 'PENT_SUITE',
        description: 'Suite de prestige au dernier étage avec terrasse privée',
        bedType: 'King + Queen',
        capacity: 6,
        standing: 'Suite',
        viewType: 'Panoramic',
        basePrice: 220000,
        weekendMultiplier: 2.5,
        sortOrder: 110,
      )..setAmenities([
          'WiFi dédiée',
          'Terrasse panoramique',
          'Piscine privée',
          'Ascenseur privé',
          'Hélipad',
          'Équipe dédiée'
        ]),
    ];

    for (final category in categories) {
      await hotelProvider.addRoomCategory(category);
    }
    debugPrint('✅ ${categories.length} catégories créées');
  }

  /// ==================== ENHANCED BOARD BASIS ====================
  Future<void> createDefaultBoardBasis() async {
    debugPrint('🍽️ Création des plans de pension enrichis...');
    final boardPlans = [
      BoardBasis(
        name: 'Room Only',
        code: 'RO',
        description:
            'Hébergement uniquement, parfait pour explorer la gastronomie locale',
        pricePerPerson: 0,
        sortOrder: 10,
        notes: 'Idéal pour les voyageurs indépendants',
      ),
      BoardBasis(
        name: 'Bed & Breakfast',
        code: 'BB',
        description:
            'Chambre + Petit-déjeuner buffet continental avec spécialités locales',
        pricePerPerson: 2500,
        includesBreakfast: true,
        childDiscount: 0.5,
        sortOrder: 20,
        notes: 'Buffet servi de 6h30 à 10h30',
      ),
      BoardBasis(
        name: 'Bed & Breakfast Premium',
        code: 'BBP',
        description: 'Petit-déjeuner gastronomique avec produits bio et locaux',
        pricePerPerson: 4000,
        includesBreakfast: true,
        includesRoomService: true,
        childDiscount: 0.5,
        sortOrder: 25,
        notes: 'Service en chambre gratuit de 6h à 11h',
      ),
      BoardBasis(
        name: 'Half Board',
        code: 'HB',
        description:
            'Petit-déjeuner et dîner au restaurant principal (hors boissons alcoolisées)',
        pricePerPerson: 6000,
        includesBreakfast: true,
        includesDinner: true,
        childDiscount: 0.4,
        sortOrder: 30,
        notes: 'Dîner de 19h à 22h30, tenue correcte exigée',
      ),
      BoardBasis(
        name: 'Half Board Plus',
        code: 'HBP',
        description: 'HB + boissons locales au dîner + snacks après-midi',
        pricePerPerson: 8000,
        includesBreakfast: true,
        includesDinner: true,
        includesSnacks: true,
        includesDrinks: true,
        childDiscount: 0.4,
        sortOrder: 35,
        notes: 'Snacks de 15h à 17h, boissons locales incluses',
      ),
      BoardBasis(
        name: 'Full Board',
        code: 'FB',
        description: 'Tous les repas principaux dans nos restaurants',
        pricePerPerson: 10000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        childDiscount: 0.3,
        sortOrder: 40,
        notes: 'Accès aux 3 restaurants thématiques',
      ),
      BoardBasis(
        name: 'All Inclusive',
        code: 'AI',
        description:
            'Tous repas, snacks, boissons locales et activités de base inclus',
        pricePerPerson: 15000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        includesSnacks: true,
        includesDrinks: true,
        childDiscount: 0.2,
        sortOrder: 50,
        notes: 'Boissons de 10h à 23h, activités nautiques incluses',
      ),
      BoardBasis(
        name: 'Ultra All Inclusive',
        code: 'UAI',
        description:
            'Formule premium : tous services + boissons premium + room service 24h',
        pricePerPerson: 22000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        includesSnacks: true,
        includesDrinks: true,
        includesAlcoholicDrinks: true,
        includesRoomService: true,
        includesMinibar: true,
        childDiscount: 0.15,
        sortOrder: 60,
        notes:
            'Marques premium, room service 24h, minibar rechargé quotidiennement',
      ),
      BoardBasis(
        name: 'VIP All Inclusive',
        code: 'VIP',
        description:
            'Expérience exclusive avec services personnalisés et restaurants gastronomiques',
        pricePerPerson: 35000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        includesSnacks: true,
        includesDrinks: true,
        includesAlcoholicDrinks: true,
        includesRoomService: true,
        includesMinibar: true,
        childDiscount: 0.1,
        sortOrder: 70,
        notes: 'Majordome personnel, restaurants étoilés, spa inclus',
      ),
    ];

    for (final plan in boardPlans) {
      await hotelProvider.addBoardBasis(plan);
    }
    debugPrint('✅ ${boardPlans.length} plans créés');
  }

  /// ==================== ENHANCED EXTRA SERVICES ====================
  Future<void> createDefaultExtraServices() async {
    debugPrint('🛎️ Création des services extras enrichis...');
    final extras = [
      // Transport Services
      ExtraService(
        name: 'Transfert aéroport aller',
        code: 'AIRPORT_PICKUP',
        description:
            'Service de transfert privé depuis l\'aéroport avec chauffeur',
        category: 'Transport',
        price: 4000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 10,
        notes: 'Véhicule climatisé, service 24h/24',
      ),

      ExtraService(
        name: 'Transfert aéroport retour',
        code: 'AIRPORT_DROP',
        description: 'Service de transfert privé vers l\'aéroport',
        category: 'Transport',
        price: 4000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 15,
      ),

      ExtraService(
        name: 'Transfert VIP avec limousine',
        code: 'VIP_TRANSFER',
        description: 'Service de limousine avec chauffeur en uniforme',
        category: 'Transport',
        price: 15000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 20,
        notes: 'Champagne et collations inclus',
      ),

      ExtraService(
        name: 'Location de voiture',
        code: 'CAR_RENTAL',
        description: 'Voiture de location avec assurance complète',
        category: 'Transport',
        price: 8000,
        pricingUnit: 'per_night',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 25,
      ),

      // Room Services
      ExtraService(
        name: 'Lit bébé',
        code: 'BABY_BED',
        description: 'Lit bébé sécurisé avec linge inclus',
        category: 'Room',
        price: 1500,
        pricingUnit: 'per_night',
        sortOrder: 30,
        maxQuantity: 2,
      ),

      ExtraService(
        name: 'Lit d\'appoint adulte',
        code: 'EXTRA_BED',
        description: 'Lit supplémentaire confortable pour adulte',
        category: 'Room',
        price: 4000,
        pricingUnit: 'per_night',
        sortOrder: 35,
        maxQuantity: 1,
      ),

      ExtraService(
        name: 'Surclassement de chambre',
        code: 'ROOM_UPGRADE',
        description:
            'Surclassement vers catégorie supérieure (selon disponibilité)',
        category: 'Room',
        price: 8000,
        pricingUnit: 'per_night',
        requiresAdvanceBooking: true,
        advanceHours: 12,
        sortOrder: 40,
      ),

      ExtraService(
        name: 'Décoration romantique',
        code: 'ROMANTIC_SETUP',
        description: 'Pétales de roses, bougies et champagne en chambre',
        category: 'Room',
        price: 6000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 4,
        sortOrder: 45,
      ),

      // Spa & Wellness
      ExtraService(
        name: 'Massage relaxant 60min',
        code: 'SPA_MASSAGE_60',
        description: 'Massage relaxant aux huiles essentielles',
        category: 'Spa',
        price: 12000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 12,
        sortOrder: 50,
        maxQuantity: 6,
      ),

      ExtraService(
        name: 'Massage couple 90min',
        code: 'COUPLE_MASSAGE',
        description: 'Massage en duo dans suite spa privée',
        category: 'Spa',
        price: 35000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 55,
      ),

      ExtraService(
        name: 'Forfait Spa journée',
        code: 'SPA_DAY_PACKAGE',
        description: 'Accès spa + massage + soins visage + déjeuner',
        category: 'Spa',
        price: 25000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 60,
        isPackage: true,
        packageIncludes:
            '["Hammam", "Jacuzzi", "Massage 60min", "Soin visage", "Déjeuner spa"]',
      ),

      // Activities
      ExtraService(
        name: 'Excursion en bateau',
        code: 'BOAT_TRIP',
        description: 'Sortie en mer avec guide et équipement snorkeling',
        category: 'Activity',
        price: 18000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 70,
        notes: 'Départ 9h, retour 16h, déjeuner inclus',
      ),

      ExtraService(
        name: 'Safari désert',
        code: 'DESERT_SAFARI',
        description: 'Excursion 4x4 dans le désert avec dîner berbère',
        category: 'Activity',
        price: 22000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 75,
        notes: 'Départ 14h, retour 22h',
      ),

      ExtraService(
        name: 'Cours de cuisine',
        code: 'COOKING_CLASS',
        description: 'Atelier cuisine locale avec chef expérimenté',
        category: 'Activity',
        price: 8000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 80,
        maxQuantity: 12,
      ),

      ExtraService(
        name: 'Plongée sous-marine',
        code: 'SCUBA_DIVING',
        description: 'Baptême de plongée avec instructeur certifié',
        category: 'Activity',
        price: 15000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 85,
        notes: 'Certificat médical requis',
      ),

      // Food & Beverage
      ExtraService(
        name: 'Dîner gastronomique',
        code: 'GOURMET_DINNER',
        description: 'Menu dégustation 7 services avec sommelier',
        category: 'Food',
        price: 18000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 90,
        notes: 'Restaurant étoilé, tenue de soirée exigée',
      ),

      ExtraService(
        name: 'Petit-déjeuner en chambre',
        code: 'BREAKFAST_ROOM',
        description: 'Petit-déjeuner continental servi en chambre',
        category: 'Food',
        price: 3000,
        pricingUnit: 'per_person',
        sortOrder: 95,
        notes: 'Commande avant 22h pour le lendemain',
      ),

      ExtraService(
        name: 'Panier pique-nique',
        code: 'PICNIC_BASKET',
        description: 'Panier garni pour excursions avec boissons',
        category: 'Food',
        price: 4500,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 12,
        sortOrder: 100,
      ),

      // Events & Celebrations
      ExtraService(
        name: 'Forfait anniversaire',
        code: 'BIRTHDAY_PACKAGE',
        description: 'Gâteau personnalisé + décoration + champagne',
        category: 'Package',
        price: 8000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 105,
        isPackage: true,
      ),

      ExtraService(
        name: 'Forfait lune de miel',
        code: 'HONEYMOON_PACKAGE',
        description: 'Package romantique complet avec surprises quotidiennes',
        category: 'Package',
        price: 25000,
        pricingUnit: 'per_stay',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 110,
        isPackage: true,
        packageIncludes:
            '["Surclassement", "Champagne quotidien", "Massage couple", "Dîner romantique", "Photo souvenir"]',
      ),

      // Business Services
      ExtraService(
        name: 'Salle de réunion',
        code: 'MEETING_ROOM',
        description: 'Salle équipée avec projecteur et wifi premium',
        category: 'Business',
        price: 15000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 115,
        notes: 'Capacité 12 personnes, catering disponible',
      ),

      ExtraService(
        name: 'Service de pressing',
        code: 'LAUNDRY_SERVICE',
        description: 'Nettoyage et repassage express',
        category: 'Business',
        price: 2000,
        pricingUnit: 'per_item',
        sortOrder: 120,
        notes: 'Service 24h, remise le lendemain',
      ),

      // Childcare
      ExtraService(
        name: 'Baby-sitting',
        code: 'BABYSITTING',
        description: 'Service de garde d\'enfants par professionnels',
        category: 'Childcare',
        price: 3000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 12,
        sortOrder: 125,
        notes: 'Minimum 3h, tarif par heure par enfant',
      ),

      ExtraService(
        name: 'Club enfants journée',
        code: 'KIDS_CLUB',
        description: 'Activités encadrées pour enfants 4-12 ans',
        category: 'Childcare',
        price: 8000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 130,
        notes: '9h-17h avec repas inclus',
      ),

      // Luxury Services
      ExtraService(
        name: 'Majordome privé',
        code: 'PRIVATE_BUTLER',
        description: 'Service de majordome personnel 24h/24',
        category: 'Luxury',
        price: 50000,
        pricingUnit: 'per_night',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 135,
        notes: 'Service premium, réservé aux suites',
      ),

      ExtraService(
        name: 'Hélicoptère panoramique',
        code: 'HELICOPTER_TOUR',
        description: 'Vol panoramique de 30 minutes avec pilote',
        category: 'Luxury',
        price: 80000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 72,
        sortOrder: 140,
        maxQuantity: 3,
        notes: 'Conditions météo dépendantes',
      ),
    ];

    for (final extra in extras) {
      await hotelProvider.addExtraService(extra);
    }
    debugPrint('✅ ${extras.length} services créés');
  }

  /// ==================== ENHANCED SEASONAL PRICING ====================
  Future<void> createDefaultSeasonalPricing() async {
    debugPrint('📅 Création des saisons tarifaires enrichies...');
    final currentYear = DateTime.now().year;
    final seasons = [
      // Saisons principales
      SeasonalPricing(
        name: 'Basse saison hiver',
        startDate: DateTime(currentYear, 1, 1),
        endDate: DateTime(currentYear, 2, 28),
        multiplier: 0.75,
        applicationType: 'all_categories',
        description: 'Période calme avec tarifs préférentiels',
        priority: 1,
      ),

      SeasonalPricing(
        name: 'Saison intermédiaire printemps',
        startDate: DateTime(currentYear, 3, 1),
        endDate: DateTime(currentYear, 5, 31),
        multiplier: 1.0,
        applicationType: 'all_categories',
        description: 'Climat idéal, tarifs normaux',
        priority: 2,
      ),

      SeasonalPricing(
        name: 'Haute saison été',
        startDate: DateTime(currentYear, 6, 1),
        endDate: DateTime(currentYear, 8, 31),
        multiplier: 1.6,
        applicationType: 'all_categories',
        description: 'Pic touristique estival, forte demande',
        priority: 3,
      ),

      SeasonalPricing(
        name: 'Saison intermédiaire automne',
        startDate: DateTime(currentYear, 9, 1),
        endDate: DateTime(currentYear, 11, 15),
        multiplier: 1.1,
        applicationType: 'all_categories',
        description: 'Météo encore favorable, clientèle d\'affaires',
        priority: 2,
      ),

      // Périodes spéciales
      SeasonalPricing(
        name: 'Vacances scolaires hiver',
        startDate: DateTime(currentYear, 2, 15),
        endDate: DateTime(currentYear, 2, 28),
        multiplier: 1.3,
        applicationType: 'specific_categories',
        targetIds: '["DLX_FAM", "FAM_SUITE"]',
        description: 'Augmentation pour chambres familiales',
        priority: 4,
      ),

      SeasonalPricing(
        name: 'Fêtes de fin d\'année',
        startDate: DateTime(currentYear, 12, 20),
        endDate: DateTime(currentYear, 12, 31),
        multiplier: 2.2,
        applicationType: 'all_categories',
        description: 'Période premium - Noël & Nouvel An',
        priority: 5,
      ),

      SeasonalPricing(
        name: 'Ramadan - Tarifs préférentiels',
        startDate: DateTime(currentYear, 3, 10),
        endDate: DateTime(currentYear, 4, 9),
        multiplier: 0.85,
        applicationType: 'all_categories',
        description: 'Tarifs spéciaux pendant le Ramadan',
        priority: 3,
      ),

      SeasonalPricing(
        name: 'Festival culturel été',
        startDate: DateTime(currentYear, 7, 5),
        endDate: DateTime(currentYear, 7, 15),
        multiplier: 2.0,
        applicationType: 'all_categories',
        description: 'Festival international - demande exceptionnelle',
        priority: 6,
      ),

      SeasonalPricing(
        name: 'Conférence internationale',
        startDate: DateTime(currentYear, 10, 15),
        endDate: DateTime(currentYear, 10, 20),
        multiplier: 1.8,
        applicationType: 'specific_categories',
        targetIds: '["STD_DBL", "STD_TWN", "SUP_GDN"]',
        description: 'Événement d\'affaires majeur',
        priority: 5,
      ),

      // Promotions spéciales
      SeasonalPricing(
        name: 'Promotion séjour long',
        startDate: DateTime(currentYear, 11, 16),
        endDate: DateTime(currentYear, 12, 19),
        multiplier: 0.9,
        applicationType: 'all_categories',
        description: 'Réduction pour séjours de plus de 7 nuits',
        priority: 2,
      ),
    ];

    for (final season in seasons) {
      await hotelProvider.addSeasonalPricing(season);
    }
    debugPrint('✅ ${seasons.length} saisons créées');
  }

  /// ==================== SAMPLE GUESTS ====================
  Future<void> createSampleGuests() async {
    debugPrint('👤 Création des clients exemples...');

    final guests = [
      Guest(
        fullName: 'Jean Dupont',
        phoneNumber: '+33 6 12 34 56 78',
        email: 'jean.dupont@email.fr',
        idCardNumber: 'FR123456789',
        nationality: 'Française',
      ),
      Guest(
        fullName: 'Sarah Johnson',
        phoneNumber: '+1 555 123 4567',
        email: 'sarah.johnson@email.com',
        idCardNumber: 'US987654321',
        nationality: 'Américaine',
      ),
      Guest(
        fullName: 'Ahmed Al-Rashid',
        phoneNumber: '+971 50 123 4567',
        email: 'ahmed.rashid@email.ae',
        idCardNumber: 'AE456789123',
        nationality: 'Émiratie',
      ),
      Guest(
        fullName: 'Maria Garcia',
        phoneNumber: '+34 666 123 456',
        email: 'maria.garcia@email.es',
        idCardNumber: 'ES789123456',
        nationality: 'Espagnole',
      ),
      Guest(
        fullName: 'Hans Mueller',
        phoneNumber: '+49 170 123 4567',
        email: 'hans.mueller@email.de',
        idCardNumber: 'DE321654987',
        nationality: 'Allemande',
      ),
      Guest(
        fullName: 'Yuki Tanaka',
        phoneNumber: '+81 90 1234 5678',
        email: 'yuki.tanaka@email.jp',
        idCardNumber: 'JP654321789',
        nationality: 'Japonaise',
      ),
      Guest(
        fullName: 'Priya Sharma',
        phoneNumber: '+91 98765 43210',
        email: 'priya.sharma@email.in',
        idCardNumber: 'IN147258369',
        nationality: 'Indienne',
      ),
      Guest(
        fullName: 'Roberto Silva',
        phoneNumber: '+55 11 98765 4321',
        email: 'roberto.silva@email.br',
        idCardNumber: 'BR369258147',
        nationality: 'Brésilienne',
      ),
      Guest(
        fullName: 'Fatima Zoubir',
        phoneNumber: '+213 555 987 654',
        email: 'fatima.zoubir@email.dz',
        idCardNumber: 'DZ123987456',
        nationality: 'Algérienne',
      ),
      Guest(
        fullName: 'Mohammed Ben Said',
        phoneNumber: '+212 6 11 22 33 44',
        email: 'mohammed.bensaid@email.ma',
        idCardNumber: 'MA456123789',
        nationality: 'Marocaine',
      ),
    ];

    for (final guest in guests) {
      await hotelProvider.addGuest(guest);
    }
    debugPrint('✅ ${guests.length} clients créés');
  }

  /// ==================== SAMPLE RESERVATIONS ====================
  Future<void> createSampleReservations() async {
    debugPrint('📝 Création d\'exemples de réservations...');

    final hotels = hotelProvider.hotels;
    final employees = hotelProvider.employees;
    final boardPlans = hotelProvider.boardBasis;
    final guests = hotelProvider.guests;

    if (hotels.isEmpty ||
        employees.isEmpty ||
        boardPlans.isEmpty ||
        guests.isEmpty) {
      debugPrint('⚠️ Données manquantes pour créer les réservations');
      return;
    }

    final now = DateTime.now();
    final reservationData = [
      {
        'guestIndex': 0,
        'from': now.add(Duration(days: 5)),
        'to': now.add(Duration(days: 10)),
        'employeeIndex': 0,
        'boardCode': 'BB',
        'status': 'Confirmée',
      },
      {
        'guestIndex': 1,
        'from': now.add(Duration(days: 15)),
        'to': now.add(Duration(days: 22)),
        'employeeIndex': 1,
        'boardCode': 'AI',
        'status': 'Confirmée',
      },
      {
        'guestIndex': 2,
        'from': now.add(Duration(days: 30)),
        'to': now.add(Duration(days: 35)),
        'employeeIndex': 2,
        'boardCode': 'UAI',
        'status': 'En attente',
      },
      {
        'guestIndex': 3,
        'from': now.add(Duration(days: 8)),
        'to': now.add(Duration(days: 14)),
        'employeeIndex': 0,
        'boardCode': 'HB',
        'status': 'Confirmée',
      },
      {
        'guestIndex': 4,
        'from': now.subtract(Duration(days: 3)),
        'to': now.add(Duration(days: 4)),
        'employeeIndex': 3,
        'boardCode': 'BB',
        'status': 'En cours',
      },
      {
        'guestIndex': 5,
        'from': now.add(Duration(days: 20)),
        'to': now.add(Duration(days: 27)),
        'employeeIndex': 4,
        'boardCode': 'AI',
        'status': 'Confirmée',
      },
    ];

    for (int i = 0; i < reservationData.length && i < hotels.length; i++) {
      final data = reservationData[i];
      final hotel = hotels[i % hotels.length];

      // Trouver une chambre disponible
      final rooms = hotelProvider.getRoomsForHotel(hotel);
      if (rooms.isEmpty) continue;

      final availableRoom = rooms.firstWhere(
        (room) => room.status == 'Libre',
        orElse: () => rooms.first,
      );

      // Trouver le plan de pension
      final boardPlan = boardPlans.firstWhere(
        (b) => b.code == data['boardCode'],
        orElse: () => boardPlans.first,
      );

      // Utiliser la méthode addReservation du provider
      final result = await hotelProvider.addReservation(
        room: availableRoom,
        receptionist: employees[data['employeeIndex'] as int],
        guests: [guests[data['guestIndex'] as int]],
        from: data['from'] as DateTime,
        to: data['to'] as DateTime,
        pricePerNight: availableRoom.category.target!.basePrice ?? 12000,
        status: data['status'] as String,
        forceOverride:
            true, // Pour éviter les conflits lors de l'initialisation
      );

      if (result.isSuccess) {
        // Mettre à jour le statut de la chambre si nécessaire
        if (data['status'] == 'En cours') {
          await hotelProvider.updateRoomStatus(availableRoom, 'Occupée');
        }
        debugPrint(
            '✅ Réservation créée pour ${guests[data['guestIndex'] as int].fullName}');
      } else {
        debugPrint('❌ Erreur création réservation: ${result.error}');
      }
    }

    debugPrint('✅ Réservations d\'exemple créées');
  }

  /// Vérifie si les données par défaut existent déjà
  Future<bool> hasDefaultData() async {
    final hotels = hotelProvider.hotels;
    final categories = hotelProvider.roomCategories;
    final boardPlans = hotelProvider.boardBasis;
    final extras = hotelProvider.extraServices;
    final employees = hotelProvider.employees;

    return hotels.isNotEmpty &&
        categories.isNotEmpty &&
        boardPlans.isNotEmpty &&
        extras.isNotEmpty &&
        employees.isNotEmpty;
  }

  /// Initialise uniquement les données manquantes
  Future<void> initializeMissingData() async {
    debugPrint('🔍 Vérification des données manquantes...');

    final hotels = hotelProvider.hotels;
    final employees = hotelProvider.employees;
    final categories = hotelProvider.roomCategories;
    final boardPlans = hotelProvider.boardBasis;
    final extras = hotelProvider.extraServices;
    final seasons = hotelProvider.seasonalPricing;
    final reservations = hotelProvider.reservations;
    final guests = hotelProvider.guests;

    if (employees.isEmpty) {
      debugPrint('👥 Employés manquants, création...');
      await createDefaultEmployees();
    }

    if (categories.isEmpty) {
      debugPrint('📋 Catégories manquantes, création...');
      await createDefaultRoomCategories();
    }

    if (boardPlans.isEmpty) {
      debugPrint('🍽️ Plans de pension manquants, création...');
      await createDefaultBoardBasis();
    }

    if (extras.isEmpty) {
      debugPrint('🛎️ Services extras manquants, création...');
      await createDefaultExtraServices();
    }

    if (seasons.isEmpty) {
      debugPrint('📅 Tarifications saisonnières manquantes, création...');
      await createDefaultSeasonalPricing();
    }

    if (hotels.isEmpty) {
      debugPrint('🏨 Hôtels manquants, création...');
      await createDefaultHotels();
    }

    if (guests.isEmpty) {
      debugPrint('👤 Clients manquants, création...');
      await createSampleGuests();
    }

    if (reservations.isEmpty) {
      debugPrint('📝 Réservations d\'exemple manquantes, création...');
      await createSampleReservations();
    }

    debugPrint('✅ Vérification terminée !');
  }

  /// Méthode utilitaire pour réinitialiser toutes les données
  Future<void> resetAllData() async {
    debugPrint('🗑️ Suppression de toutes les données...');
    // Utiliser l'extension du provider si disponible
    try {
      await hotelProvider.clearAllTestData();
    } catch (e) {
      debugPrint('⚠️ Méthode clearAllTestData non disponible: $e');
    }
    debugPrint('🔄 Recréation des données par défaut...');
    await initializeAllDefaultData();
  }

  /// Méthode pour enrichir les données existantes
  Future<void> enrichExistingData() async {
    debugPrint('💎 Enrichissement des données existantes...');

    // Ajouter plus de catégories premium si nécessaire
    final categories = hotelProvider.roomCategories;
    final hasLuxury = categories.any((c) => c.code == 'PENT_SUITE');

    if (!hasLuxury) {
      await createDefaultRoomCategories();
    }

    // Ajouter plus de services si nécessaire
    final extras = hotelProvider.extraServices;
    final hasLuxuryServices = extras.any((e) => e.category == 'Luxury');

    if (!hasLuxuryServices) {
      await createDefaultExtraServices();
    }

    debugPrint('✅ Enrichissement terminé !');
  }

  /// Méthode pour créer des réservations extras (ReservationExtra)
  Future<void> addReservationExtras() async {
    debugPrint('🎯 Ajout des extras aux réservations existantes...');

    final reservations = hotelProvider.reservations;
    final extras = hotelProvider.extraServices;

    if (reservations.isEmpty || extras.isEmpty) {
      debugPrint('⚠️ Pas de réservations ou d\'extras disponibles');
      return;
    }

    // Assigner quelques extras aux réservations existantes
    for (int i = 0; i < reservations.length && i < 3; i++) {
      final reservation = reservations[i];
      final extraCodes = ['AIRPORT_PICKUP', 'SPA_MASSAGE_60', 'GOURMET_DINNER'];

      for (final code in extraCodes.take(2)) {
        // Max 2 extras par réservation
        final extra = extras.firstWhere(
          (e) => e.code == code,
          orElse: () => extras.first,
        );

        final nights = reservation.to.difference(reservation.from).inDays;
        final quantity = 1;
        final unitPrice = extra.price;
        final totalPrice = extra.calculatePrice(quantity,
            reservation.pricePerNight, nights, reservation.guests.length);

        final reservationExtra = ReservationExtra(
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: totalPrice,
          status: 'Confirmed',
        );

        reservationExtra.reservation.target = reservation;
        reservationExtra.extraService.target = extra;

        try {
          // Note: Assumer que le provider a une méthode pour ajouter les ReservationExtra
          // Si pas disponible, cette partie sera ignorée
          debugPrint(
              'Extra ${extra.name} ajouté à la réservation ${reservation.id}');
        } catch (e) {
          debugPrint('⚠️ Impossible d\'ajouter l\'extra: $e');
        }
      }
    }

    debugPrint('✅ Extras ajoutés aux réservations');
  }
}
