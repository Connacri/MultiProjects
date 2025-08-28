import 'package:flutter/material.dart';

import '../../../../objectbox.g.dart';
import '../../../Entity.dart';
import '../../../classeObjectBox.dart';

// ============================================================================
// PROVIDER DE BASE - Gestion commune des opérations CRUD
// ============================================================================
abstract class BaseEntityProvider<T> with ChangeNotifier {
  final ObjectBox objectBox;
  late final Box<T> box;
  List<T> _items = [];
  bool _isLoading = false;

  List<T> get items => _items;

  bool get isLoading => _isLoading;

  bool get isEmpty => _items.isEmpty;

  int get count => _items.length;

  BaseEntityProvider(this.objectBox) {
    box = getBox();
    _loadItems();
  }

  // Méthode abstraite à implémenter par chaque provider spécifique
  Box<T> getBox();

  Future<void> _loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = box.getAll();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Opérations CRUD génériques
  Future<int> add(T item) async {
    try {
      final id = box.put(item);
      await _loadItems();
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout: $e');
      rethrow;
    }
  }

  Future<bool> update(T item) async {
    try {
      box.put(item, mode: PutMode.update);
      await _loadItems();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final success = box.remove(id);
      if (success) {
        await _loadItems();
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return false;
    }
  }

  T? getById(int id) {
    return box.get(id);
  }

  Future<void> refresh() async {
    await _loadItems();
  }
}

// ============================================================================
// PROVIDER PRINCIPAL - Gestion complète de l'hôtel
// ============================================================================
class HotelProvider with ChangeNotifier {
  final ObjectBox _objectBox;

  // Boxes ObjectBox
  late final Box<Hotel> _hotelBox;
  late final Box<Room> _roomBox;
  late final Box<Reservation> _reservationBox;
  late final Box<Guest> _guestBox;
  late final Box<Employee> _employeeBox;

  // Collections en mémoire
  List<Hotel> _hotels = [];
  List<Room> _rooms = [];
  List<Reservation> _reservations = [];
  List<Guest> _guests = [];
  List<Employee> _employees = [];

  // État de l'application
  bool _isFirstLaunch = true;
  Hotel? _currentHotel;
  bool _isLoading = false;

  // Getters
  List<Hotel> get hotels => _hotels;

  List<Room> get rooms => _rooms;

  List<Reservation> get reservations => _reservations;

  List<Guest> get guests => _guests;

  List<Employee> get employees => _employees;

  bool get isFirstLaunch => _isFirstLaunch;

  Hotel? get currentHotel => _currentHotel;

  bool get isLoading => _isLoading;

  // Getters de commodité
  List<Room> get availableRooms =>
      _rooms.where((room) => room.status == 'Disponible').toList();

  List<Reservation> get activeReservations =>
      _reservations.where((res) => res.status == 'Confirmée').toList();

  HotelProvider(this._objectBox) {
    _initializeBoxes();
    _initialize();
  }

  void _initializeBoxes() {
    _hotelBox = _objectBox.store.box<Hotel>();
    _roomBox = _objectBox.store.box<Room>();
    _reservationBox = _objectBox.store.box<Reservation>();
    _guestBox = _objectBox.store.box<Guest>();
    _employeeBox = _objectBox.store.box<Employee>();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadAllData();
      _checkFirstLaunch();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllData() async {
    _hotels = _hotelBox.getAll();
    _rooms = _roomBox.getAll();
    _reservations = _reservationBox.getAll();
    _guests = _guestBox.getAll();
    _employees = _employeeBox.getAll();
  }

  void _checkFirstLaunch() {
    _isFirstLaunch = _hotels.isEmpty;
  }

  Future<void> refresh() async {
    await _loadAllData();
    notifyListeners();
  }

  // ============================================================================
  // MÉTHODES DE VÉRIFICATION DE DISPONIBILITÉ
  // ============================================================================

  /// Vérifie si une chambre est disponible pour une période donnée
  bool isRoomAvailable(Room room, DateTime from, DateTime to,
      {Reservation? excludeReservation}) {
    // Normaliser les dates (ignorer les heures/minutes/secondes)
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);

    // Vérifier que les dates sont valides
    if (fromDate.isAfter(toDate) || fromDate.isAtSameMomentAs(toDate)) {
      return false;
    }

    // Obtenir toutes les réservations pour cette chambre
    final roomReservations = getReservationsByRoom(room)
        .where((res) => res.status == 'Confirmée' || res.status == 'En cours')
        .toList();

    // Exclure une réservation spécifique (utile pour les mises à jour)
    if (excludeReservation != null) {
      roomReservations.removeWhere((res) => res.id == excludeReservation.id);
    }

    // Vérifier les chevauchements
    for (final reservation in roomReservations) {
      final existingFrom = DateTime(
          reservation.from.year, reservation.from.month, reservation.from.day);
      final existingTo = DateTime(
          reservation.to.year, reservation.to.month, reservation.to.day);

      // Vérification du chevauchement
      // Deux périodes se chevauchent si :
      // - La nouvelle période commence avant la fin de l'existante ET
      // - La nouvelle période se termine après le début de l'existante
      if (fromDate.isBefore(existingTo) && toDate.isAfter(existingFrom)) {
        return false; // Il y a un chevauchement
      }
    }

    return true;
  }

  /// Obtient la liste des chambres disponibles pour une période donnée
  List<Room> getAvailableRoomsForPeriod(DateTime from, DateTime to,
      {String? roomType}) {
    return _rooms.where((room) {
      // Filtrer par type si spécifié
      if (roomType != null && room.type != roomType) {
        return false;
      }

      // Vérifier si la chambre est dans un état disponible
      if (room.status != 'Disponible') {
        return false;
      }

      // Vérifier la disponibilité pour la période
      return isRoomAvailable(room, from, to);
    }).toList();
  }

  /// Vérifie s'il y a des conflits de réservation pour une période
  ReservationConflict? checkReservationConflict(
      Room room, DateTime from, DateTime to,
      {Reservation? excludeReservation}) {
    if (isRoomAvailable(room, from, to,
        excludeReservation: excludeReservation)) {
      return null;
    }

    final conflictingReservations = getReservationsByRoom(room)
        .where((res) => res.status == 'Confirmée' || res.status == 'En cours')
        .where((res) =>
            excludeReservation == null || res.id != excludeReservation.id)
        .where((res) {
      final fromDate = DateTime(from.year, from.month, from.day);
      final toDate = DateTime(to.year, to.month, to.day);
      final existingFrom =
          DateTime(res.from.year, res.from.month, res.from.day);
      final existingTo = DateTime(res.to.year, res.to.month, res.to.day);

      return fromDate.isBefore(existingTo) && toDate.isAfter(existingFrom);
    }).toList();

    return ReservationConflict(
      room: room,
      requestedFrom: from,
      requestedTo: to,
      conflictingReservations: conflictingReservations,
    );
  }

  // ============================================================================
  // GESTION DES RÉSERVATIONS (AMÉLIORÉE)
  // ============================================================================

  /// Ajoute une réservation avec vérification de disponibilité
  Future<ReservationResult> addReservation({
    required Room room,
    required Employee receptionist,
    required List<Guest> guests,
    required DateTime from,
    required DateTime to,
    required double pricePerNight,
    String status = "Confirmée",
    bool forceOverride = false,
  }) async {
    try {
      // Vérification de base
      if (guests.isEmpty) {
        return ReservationResult.error('Au moins un client doit être spécifié');
      }

      final fromDate = DateTime(from.year, from.month, from.day);
      final toDate = DateTime(to.year, to.month, to.day);

      if (fromDate.isAfter(toDate) || fromDate.isAtSameMomentAs(toDate)) {
        return ReservationResult.error(
            'La date de début doit être antérieure à la date de fin');
      }

      // Vérifier la disponibilité si ce n'est pas forcé
      if (!forceOverride) {
        final conflict = checkReservationConflict(room, from, to);
        if (conflict != null) {
          return ReservationResult.conflict(conflict);
        }
      }

      // Créer la réservation
      final reservation = Reservation(
        from: from,
        to: to,
        pricePerNight: pricePerNight,
        status: status,
      );

      reservation.room.target = room;
      reservation.receptionist.target = receptionist;
      reservation.guests.addAll(guests);

      final id = _reservationBox.put(reservation);
      await _loadAllData();
      notifyListeners();

      return ReservationResult.success(id);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la réservation: $e');
      return ReservationResult.error('Erreur lors de l\'ajout: $e');
    }
  }

  /// Met à jour une réservation avec vérification de disponibilité
// Ajoutez cette méthode corrigée dans votre HotelProvider

  /// Met à jour une réservation avec vérification de disponibilité
  Future<ReservationResult> updateReservation(
    Reservation reservation, {
    Room? newRoom,
    DateTime? newFrom,
    DateTime? newTo,
    bool forceOverride = false,
  }) async {
    try {
      final roomToCheck = newRoom ?? reservation.room.target!;
      final fromToCheck = newFrom ?? reservation.from;
      final toToCheck = newTo ?? reservation.to;

      // Vérifier la disponibilité si ce n'est pas forcé
      if (!forceOverride) {
        final conflict = checkReservationConflict(
            roomToCheck, fromToCheck, toToCheck,
            excludeReservation: reservation);
        if (conflict != null) {
          return ReservationResult.conflict(conflict);
        }
      }

      // Appliquer les modifications
      if (newRoom != null) reservation.room.target = newRoom;
      if (newFrom != null) reservation.from = newFrom;
      if (newTo != null) reservation.to = newTo;

      // IMPORTANT : Utiliser PutMode.update ET s'assurer que l'ID existe
      if (reservation.id != 0) {
        _reservationBox.put(reservation, mode: PutMode.update);
      } else {
        // Si l'ID est 0, c'est un problème - forcer la création d'un nouvel ID
        final newId = _reservationBox.put(reservation);
        reservation.id = newId;
      }

      await _loadAllData();
      notifyListeners();

      return ReservationResult.success(reservation.id);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la réservation: $e');
      return ReservationResult.error('Erreur lors de la mise à jour: $e');
    }
  }

// Alternative plus sûre : créer une méthode updateReservationComplete
  Future<ReservationResult> updateReservationComplete({
    required Reservation reservation,
    Room? newRoom,
    Employee? newReceptionist,
    List<Guest>? newGuests,
    DateTime? newFrom,
    DateTime? newTo,
    double? newPricePerNight,
    String? newStatus,
    bool forceOverride = false,
  }) async {
    try {
      final roomToCheck = newRoom ?? reservation.room.target!;
      final fromToCheck = newFrom ?? reservation.from;
      final toToCheck = newTo ?? reservation.to;

      // Vérifier la disponibilité si ce n'est pas forcé
      if (!forceOverride) {
        final conflict = checkReservationConflict(
            roomToCheck, fromToCheck, toToCheck,
            excludeReservation: reservation);
        if (conflict != null) {
          return ReservationResult.conflict(conflict);
        }
      }

      // S'assurer que tous les guests ont des IDs
      if (newGuests != null) {
        for (final guest in newGuests) {
          if (guest.id == 0) {
            final guestId = _guestBox.put(guest);
            guest.id = guestId;
          }
        }
      }

      // Appliquer toutes les modifications
      if (newRoom != null) reservation.room.target = newRoom;
      if (newReceptionist != null)
        reservation.receptionist.target = newReceptionist;
      if (newFrom != null) reservation.from = newFrom;
      if (newTo != null) reservation.to = newTo;
      if (newPricePerNight != null)
        reservation.pricePerNight = newPricePerNight;
      if (newStatus != null) reservation.status = newStatus;

      if (newGuests != null) {
        reservation.guests.clear();
        reservation.guests.addAll(newGuests);
      }

      // Sauvegarder avec vérification de l'ID
      if (reservation.id != 0) {
        _reservationBox.put(reservation, mode: PutMode.update);
      } else {
        final newId = _reservationBox.put(reservation);
        reservation.id = newId;
      }

      await _loadAllData();
      notifyListeners();

      return ReservationResult.success(reservation.id);
    } catch (e) {
      debugPrint(
          'Erreur lors de la mise à jour complète de la réservation: $e');
      return ReservationResult.error('Erreur lors de la mise à jour: $e');
    }
  }

  // ============================================================================
  // MÉTHODES UTILITAIRES POUR L'UI
  // ============================================================================

  /// Obtient le taux d'occupation pour une période donnée
  double getOccupancyRateForPeriod(DateTime from, DateTime to) {
    if (_rooms.isEmpty) return 0.0;

    final totalRooms = _rooms.length;
    final occupiedRooms =
        _rooms.where((room) => !isRoomAvailable(room, from, to)).length;

    return (occupiedRooms / totalRooms) * 100;
  }

  /// Obtient les suggestions de chambres alternatives en cas de conflit
  List<Room> getAlternativeRooms(String roomType, DateTime from, DateTime to,
      {int maxSuggestions = 5}) {
    return getAvailableRoomsForPeriod(from, to, roomType: roomType)
        .take(maxSuggestions)
        .toList();
  }

  /// Obtient le calendrier d'occupation d'une chambre
  Map<DateTime, ReservationStatus> getRoomCalendar(
      Room room, DateTime startMonth, DateTime endMonth) {
    final calendar = <DateTime, ReservationStatus>{};
    final roomReservations = getReservationsByRoom(room);

    var currentDate = DateTime(startMonth.year, startMonth.month, 1);
    final lastDay = DateTime(endMonth.year, endMonth.month + 1, 0);

    while (currentDate.isBefore(lastDay) ||
        currentDate.isAtSameMomentAs(lastDay)) {
      calendar[currentDate] = ReservationStatus.available;

      // Vérifier si cette date est occupée
      for (final reservation in roomReservations) {
        if (reservation.status != 'Confirmée' &&
            reservation.status != 'En cours') continue;

        final resFrom = DateTime(reservation.from.year, reservation.from.month,
            reservation.from.day);
        final resTo = DateTime(
            reservation.to.year, reservation.to.month, reservation.to.day);

        if ((currentDate.isAfter(resFrom) ||
                currentDate.isAtSameMomentAs(resFrom)) &&
            currentDate.isBefore(resTo)) {
          calendar[currentDate] = ReservationStatus.occupied;
          break;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return calendar;
  }

  // ============================================================================
  // MÉTHODES DE RECHERCHE ET ANALYSE (CONSERVÉES)
  // ============================================================================

  List<Reservation> getReservationsByRoom(Room room) {
    try {
      final query =
          _reservationBox.query(Reservation_.room.equals(room.id)).build();
      final results = query.find();
      query.close();
      return results;
    } catch (e) {
      debugPrint('Erreur lors de la recherche de réservations par chambre: $e');
      return [];
    }
  }

  List<Reservation> getReservationsByGuest(Guest guest) {
    return guest.reservations.toList();
  }

  List<Reservation> getReservationsByEmployee(Employee employee) {
    return employee.reservations.toList();
  }

  List<Reservation> getReservationsInPeriod(DateTime start, DateTime end) {
    return _reservations.where((reservation) {
      return reservation.from.isBefore(end) && reservation.to.isAfter(start);
    }).toList();
  }

  List<Reservation> getTodayCheckIns() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _reservations.where((reservation) {
      return reservation.from.isAfter(startOfDay) &&
          reservation.from.isBefore(endOfDay) &&
          (reservation.status == 'Confirmée' ||
              reservation.status == 'En cours');
    }).toList();
  }

  List<Reservation> getTodayCheckOuts() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _reservations.where((reservation) {
      return reservation.to.isAfter(startOfDay) &&
          reservation.to.isBefore(endOfDay) &&
          (reservation.status == 'Confirmée' ||
              reservation.status == 'En cours');
    }).toList();
  }

  // ============================================================================
  // MÉTHODES UTILITAIRES (CONSERVÉES)
  // ============================================================================

  String getRoomNameForReservation(Reservation reservation) {
    return reservation.room.target?.code ?? 'Chambre inconnue';
  }

  String getPrimaryGuestName(Reservation reservation) {
    return reservation.guests.isNotEmpty
        ? reservation.guests.first.fullName
        : 'Aucun client';
  }

  double calculateTotalPrice(Reservation reservation) {
    final nights = reservation.to.difference(reservation.from).inDays;
    return reservation.pricePerNight * nights;
  }

  int getOccupancyRate() {
    if (_rooms.isEmpty) return 0;
    final occupiedRooms =
        _rooms.where((room) => room.status == 'Occupée').length;
    return ((occupiedRooms / _rooms.length) * 100).round();
  }

  Map<String, int> getRoomTypeStatistics() {
    final Map<String, int> stats = {};
    for (final room in _rooms) {
      stats[room.type!] = (stats[room.type] ?? 0) + 1;
    }
    return stats;
  }

  // ============================================================================
  // GESTION DES HÔTELS, CHAMBRES, CLIENTS, EMPLOYÉS (CONSERVÉES)
  // ============================================================================

  Future<int> addHotel(Hotel hotel) async {
    try {
      final id = _hotelBox.put(hotel);
      hotel.id = id;
      _hotels = _hotelBox.getAll();
      _isFirstLaunch = false;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'hôtel: $e');
      rethrow;
    }
  }

  Future<bool> updateHotel(Hotel hotel) async {
    try {
      _hotelBox.put(hotel, mode: PutMode.update);
      await _loadAllData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'hôtel: $e');
      return false;
    }
  }

  Future<bool> deleteHotel(int id) async {
    try {
      final success = _hotelBox.remove(id);
      if (success) {
        _hotels = _hotelBox.getAll();
        if (_hotels.isEmpty) {
          _isFirstLaunch = true;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'hôtel: $e');
      return false;
    }
  }

  void setCurrentHotel(Hotel hotel) {
    _currentHotel = hotel;
    notifyListeners();
  }

  Future<int> addRoom(Room room) async {
    try {
      final id = _roomBox.put(room);
      await _loadAllData();
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la chambre: $e');
      rethrow;
    }
  }

  Future<void> addRoomsToHotel(Hotel hotel, List<Room> rooms) async {
    try {
      for (final room in rooms) {
        room.hotel.target = hotel;
        _roomBox.put(room);
      }
      await _loadAllData();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout des chambres à l\'hôtel: $e');
      rethrow;
    }
  }

  Future<bool> updateRoom(Room room) async {
    try {
      _roomBox.put(room, mode: PutMode.update);
      await _loadAllData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la chambre: $e');
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    try {
      final success = _roomBox.remove(id);
      if (success) {
        await _loadAllData();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la chambre: $e');
      return false;
    }
  }

  Future<bool> updateRoomStatus(Room room, String newStatus) async {
    try {
      room.status = newStatus;
      return await updateRoom(room);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut de la chambre: $e');
      return false;
    }
  }

  Room? getRoomByCode(String code) {
    try {
      final query = _roomBox.query(Room_.code.equals(code)).build();
      final result = query.findFirst();
      query.close();
      return result;
    } catch (e) {
      debugPrint('Erreur lors de la recherche de chambre par code: $e');
      return null;
    }
  }

  List<Room> getRoomsForHotel(Hotel hotel) {
    return hotel.rooms.toList();
  }

  Future<int> addGuest(Guest guest) async {
    try {
      final id = _guestBox.put(guest);
      await _loadAllData();
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du client: $e');
      rethrow;
    }
  }

  Future<bool> updateGuest(Guest guest) async {
    try {
      _guestBox.put(guest, mode: PutMode.update);
      await _loadAllData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du client: $e');
      return false;
    }
  }

  Future<bool> deleteGuest(int id) async {
    try {
      final success = _guestBox.remove(id);
      if (success) {
        await _loadAllData();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du client: $e');
      return false;
    }
  }

  Future<int> addEmployee(Employee employee) async {
    try {
      final id = _employeeBox.put(employee);
      await _loadAllData();
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'employé: $e');
      rethrow;
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    try {
      _employeeBox.put(employee, mode: PutMode.update);
      await _loadAllData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'employé: $e');
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      final success = _employeeBox.remove(id);
      if (success) {
        await _loadAllData();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'employé: $e');
      return false;
    }
  }

  // Ancienne méthode de suppression de réservation
  Future<bool> deleteReservation(int id) async {
    try {
      final success = _reservationBox.remove(id);
      if (success) {
        await _loadAllData();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la réservation: $e');
      return false;
    }
  }

  // ============================================================================
  // MÉTHODES DE DÉVELOPPEMENT (À SUPPRIMER EN PRODUCTION)
  // ============================================================================

  Future<void> createDefaultData() async {
    if (_rooms.isNotEmpty || _employees.isNotEmpty) return;

    try {
      final defaultRooms = [
        Room(code: "101", type: "Single", capacity: 1, basePrice: 8000),
        Room(code: "102", type: "Double", capacity: 2, basePrice: 12000),
        Room(code: "201", type: "Suite", capacity: 4, basePrice: 20000),
      ];

      final defaultEmployees = [
        Employee(
          fullName: "Ahmed Benali",
          phoneNumber: "0555123456",
          email: "ahmed@hotel.dz",
        ),
        Employee(
          fullName: "Fatima Khedri",
          phoneNumber: "0666789012",
          email: "fatima@hotel.dz",
        ),
      ];

      for (final room in defaultRooms) {
        await addRoom(room);
      }

      for (final employee in defaultEmployees) {
        await addEmployee(employee);
      }

      debugPrint('Données par défaut créées avec succès');
    } catch (e) {
      debugPrint('Erreur lors de la création des données par défaut: $e');
    }
  }
}

// ============================================================================
// CLASSES D'AIDE
// ============================================================================

class ReservationResult {
  final bool isSuccess;
  final int? reservationId;
  final String? error;
  final ReservationConflict? conflict;

  ReservationResult._({
    required this.isSuccess,
    this.reservationId,
    this.error,
    this.conflict,
  });

  factory ReservationResult.success(int id) => ReservationResult._(
        isSuccess: true,
        reservationId: id,
      );

  factory ReservationResult.error(String message) => ReservationResult._(
        isSuccess: false,
        error: message,
      );

  factory ReservationResult.conflict(ReservationConflict conflict) =>
      ReservationResult._(
        isSuccess: false,
        conflict: conflict,
      );
}

class ReservationConflict {
  final Room room;
  final DateTime requestedFrom;
  final DateTime requestedTo;
  final List<Reservation> conflictingReservations;

  ReservationConflict({
    required this.room,
    required this.requestedFrom,
    required this.requestedTo,
    required this.conflictingReservations,
  });
}

enum ReservationStatus {
  available,
  occupied,
  maintenance,
  blocked,
}
