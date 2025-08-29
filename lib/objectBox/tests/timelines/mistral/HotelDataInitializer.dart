import 'package:flutter/material.dart';

import '../../../Entity.dart';
import 'provider_hotel.dart';

class HotelDataInitializer {
  final HotelProvider hotelProvider;

  HotelDataInitializer(this.hotelProvider);

  /// Initialise toutes les données par défaut
  Future<void> initializeAllDefaultData() async {
    debugPrint('🏨 Initialisation des données par défaut...');
    await createDefaultRoomCategories();
    await createDefaultBoardBasis();
    await createDefaultExtraServices();
    await createDefaultSeasonalPricing();
    await initializeMissingData();
    debugPrint('✅ Initialisation terminée !');
  }

  /// ==================== ROOM CATEGORIES ====================
  Future<void> createDefaultRoomCategories() async {
    debugPrint('📋 Création des catégories de chambres...');
    final categories = [
      // Economy
      RoomCategory(
        name: 'Chambre Simple Économique',
        code: 'ECO_SGL',
        description:
            'Chambre basique avec un lit simple, idéale pour un voyageur solo ou un court séjour',
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
        description: 'Chambre économique avec un lit double',
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

      // Standard
      RoomCategory(
        name: 'Chambre Standard Double',
        code: 'STD_DBL',
        description:
            'Chambre confortable avec lit double et équipements standards',
        bedType: 'Double',
        capacity: 2,
        standing: 'Standard',
        basePrice: 12000,
        weekendMultiplier: 1.2,
        allowsExtraBed: true,
        extraBedPrice: 3000,
        sortOrder: 30,
      )..setAmenities([
          'WiFi gratuit',
          'Climatisation',
          'Télévision LCD',
          'Minibar',
          'Coffre-fort'
        ]),

      RoomCategory(
        name: 'Chambre Twin Standard',
        code: 'STD_TWN',
        description: 'Deux lits simples, idéale pour amis ou collègues',
        bedType: 'Twin',
        capacity: 2,
        standing: 'Standard',
        basePrice: 12500,
        weekendMultiplier: 1.2,
        sortOrder: 35,
      )..setAmenities([
          'WiFi gratuit',
          'Climatisation',
          'Télévision LCD',
          'Salle de bain privée'
        ]),

      // Deluxe
      RoomCategory(
        name: 'Chambre Deluxe Vue Mer',
        code: 'DLX_SEA',
        description:
            'Chambre spacieuse avec lit King et vue imprenable sur la mer',
        bedType: 'King',
        capacity: 2,
        standing: 'Deluxe',
        basePrice: 20000,
        weekendMultiplier: 1.3,
        sortOrder: 40,
      )..setAmenities([
          'WiFi premium',
          'Balcon',
          'Machine à café',
          'Télévision 4K',
          'Peignoirs'
        ]),

      RoomCategory(
        name: 'Chambre Deluxe Familiale',
        code: 'DLX_FAM',
        description:
            'Grande chambre pour 4 personnes, parfaite pour les familles',
        bedType: 'Double + Twin',
        capacity: 4,
        standing: 'Deluxe',
        basePrice: 28000,
        weekendMultiplier: 1.3,
        allowsExtraBed: true,
        extraBedPrice: 4000,
        sortOrder: 50,
      )..setAmenities([
          'WiFi premium',
          'Climatisation',
          'Minibar',
          'Balcon',
          'Service en chambre'
        ]),

      // Suites
      RoomCategory(
        name: 'Junior Suite',
        code: 'JSU',
        description: 'Suite élégante avec coin salon et chambre séparée',
        bedType: 'King',
        capacity: 2,
        standing: 'Suite',
        basePrice: 35000,
        weekendMultiplier: 1.5,
        sortOrder: 60,
      )..setAmenities([
          'WiFi premium',
          'Salon privé',
          'Jacuzzi',
          'Machine Nespresso',
          'Peignoirs de luxe'
        ]),

      RoomCategory(
        name: 'Suite Présidentielle',
        code: 'PRES_SUITE',
        description:
            'Expérience ultime du luxe avec plusieurs pièces et services VIP',
        bedType: 'King',
        capacity: 4,
        standing: 'Suite',
        basePrice: 120000,
        weekendMultiplier: 2.0,
        sortOrder: 100,
      )..setAmenities([
          'WiFi premium',
          'Salon exécutif',
          'Piscine privée',
          'Service majordome',
          'Salle à manger',
          'Transport inclus'
        ]),
    ];

    for (final category in categories) {
      await hotelProvider.addRoomCategory(category);
    }
    debugPrint('✅ ${categories.length} catégories créées');
  }

  /// ==================== BOARD BASIS ====================
  Future<void> createDefaultBoardBasis() async {
    debugPrint('🍽️ Création des plans de pension...');
    final boardPlans = [
      BoardBasis(
        name: 'Room Only',
        code: 'RO',
        description: 'Hébergement uniquement, aucun repas inclus',
        pricePerPerson: 0,
        sortOrder: 10,
      ),
      BoardBasis(
        name: 'Bed & Breakfast',
        code: 'BB',
        description: 'Chambre + Petit-déjeuner buffet',
        pricePerPerson: 2000,
        includesBreakfast: true,
        sortOrder: 20,
      ),
      BoardBasis(
        name: 'Half Board',
        code: 'HB',
        description:
            'Petit-déjeuner et dîner inclus (hors boissons alcoolisées)',
        pricePerPerson: 4500,
        includesBreakfast: true,
        includesDinner: true,
        sortOrder: 30,
      ),
      BoardBasis(
        name: 'Full Board',
        code: 'FB',
        description: 'Petit-déjeuner, déjeuner et dîner inclus',
        pricePerPerson: 7000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        sortOrder: 40,
      ),
      BoardBasis(
        name: 'All Inclusive',
        code: 'AI',
        description: 'Tous les repas, snacks, boissons locales inclus',
        pricePerPerson: 10000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        includesSnacks: true,
        includesDrinks: true,
        sortOrder: 50,
      ),
      BoardBasis(
        name: 'Ultra All Inclusive',
        code: 'UAI',
        description: 'Toutes boissons premium + room service + minibar inclus',
        pricePerPerson: 15000,
        includesBreakfast: true,
        includesLunch: true,
        includesDinner: true,
        includesSnacks: true,
        includesDrinks: true,
        includesAlcoholicDrinks: true,
        includesRoomService: true,
        includesMinibar: true,
        sortOrder: 60,
      ),
    ];

    for (final plan in boardPlans) {
      await hotelProvider.addBoardBasis(plan);
    }
    debugPrint('✅ ${boardPlans.length} plans créés');
  }

  /// ==================== EXTRA SERVICES ====================
  Future<void> createDefaultExtraServices() async {
    debugPrint('🛎️ Création des services extras...');
    final extras = [
      ExtraService(
        name: 'Transfert aéroport aller',
        code: 'AIRPORT_PICKUP',
        description: 'Service de transfert depuis l’aéroport',
        category: 'Transport',
        price: 3000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 10,
      ),
      ExtraService(
        name: 'Transfert aéroport retour',
        code: 'AIRPORT_DROP',
        description: 'Service de transfert vers l’aéroport',
        category: 'Transport',
        price: 3000,
        pricingUnit: 'per_item',
        requiresAdvanceBooking: true,
        advanceHours: 24,
        sortOrder: 20,
      ),
      ExtraService(
        name: 'Lit bébé',
        code: 'BABY_BED',
        description: 'Lit bébé ajouté dans la chambre',
        category: 'Room',
        price: 1000,
        pricingUnit: 'per_night',
        sortOrder: 30,
      ),
      ExtraService(
        name: 'Massage spa 60min',
        code: 'SPA_MASSAGE',
        description: 'Massage relaxant au spa',
        category: 'Spa',
        price: 8000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 12,
        sortOrder: 40,
      ),
      ExtraService(
        name: 'Accès piscine privée',
        code: 'POOL_ACCESS',
        description: 'Accès exclusif à la piscine privée',
        category: 'Activity',
        price: 5000,
        pricingUnit: 'per_stay',
        sortOrder: 50,
      ),
      ExtraService(
        name: 'Excursion en bateau',
        code: 'BOAT_TRIP',
        description: 'Sortie en mer avec guide',
        category: 'Activity',
        price: 15000,
        pricingUnit: 'per_person',
        requiresAdvanceBooking: true,
        advanceHours: 48,
        sortOrder: 60,
      ),
    ];

    for (final extra in extras) {
      await hotelProvider.addExtraService(extra);
    }
    debugPrint('✅ ${extras.length} services créés');
  }

  /// ==================== SEASONAL PRICING ====================
  Future<void> createDefaultSeasonalPricing() async {
    debugPrint('📅 Création des saisons tarifaires...');
    final currentYear = DateTime.now().year;
    final seasons = [
      SeasonalPricing(
        name: 'Basse saison hiver',
        startDate: DateTime(currentYear, 1, 1),
        endDate: DateTime(currentYear, 3, 31),
        multiplier: 0.8,
        applicationType: 'all_categories',
        description: 'Réduction hivernale sur toutes les catégories',
        priority: 1,
      ),
      SeasonalPricing(
        name: 'Moyenne saison printemps',
        startDate: DateTime(currentYear, 4, 1),
        endDate: DateTime(currentYear, 6, 15),
        multiplier: 1.0,
        applicationType: 'all_categories',
        description: 'Tarifs normaux pour le printemps',
        priority: 2,
      ),
      SeasonalPricing(
        name: 'Haute saison été',
        startDate: DateTime(currentYear, 6, 16),
        endDate: DateTime(currentYear, 9, 15),
        multiplier: 1.5,
        applicationType: 'all_categories',
        description: 'Afflux touristique estival, tarifs augmentés',
        priority: 3,
      ),
      SeasonalPricing(
        name: 'Fêtes de fin d’année',
        startDate: DateTime(currentYear, 12, 15),
        endDate: DateTime(currentYear, 12, 31),
        multiplier: 2.0,
        applicationType: 'all_categories',
        description: 'Période de Noël & Nouvel An, tarifs premium',
        priority: 4,
      ),
    ];

    for (final season in seasons) {
      await hotelProvider.addSeasonalPricing(season);
    }
    debugPrint('✅ ${seasons.length} saisons créées');
  }

  /// Vérifie si les données par défaut existent déjà
  Future<bool> hasDefaultData() async {
    final categories = await hotelProvider.getRoomCategories();
    final boardPlans = await hotelProvider.getBoardBasis();
    final extras = await hotelProvider.getExtraServices();
    return categories.isNotEmpty && boardPlans.isNotEmpty && extras.isNotEmpty;
  }

  /// Initialise uniquement les données manquantes
  Future<void> initializeMissingData() async {
    debugPrint('🔍 Vérification des données manquantes...');
    final categories = await hotelProvider.getRoomCategories();
    final boardPlans = await hotelProvider.getBoardBasis();
    final extras = await hotelProvider.getExtraServices();
    final seasons = await hotelProvider.getSeasonalPricing();

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
    debugPrint('✅ Vérification terminée !');
  }
}
