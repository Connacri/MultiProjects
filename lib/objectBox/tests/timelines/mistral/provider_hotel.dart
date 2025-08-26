import 'package:flutter/material.dart';

import '../../../../objectbox.g.dart';
import '../../../Entity.dart';
import '../../../classeObjectBox.dart';

//
// class HotelStructureProvider with ChangeNotifier {
//   final ObjectBox _objectBox = ObjectBox();
//
//   // Collections locales en mémoire
//   List<Room> _rooms = [];
//   List<Reservation> _reservations = [];
//   List<Guest> _guests = [];
//   List<Employee> _employees = [];
//
//   // Getters
//   List<Room> get rooms => _rooms;
//
//   List<Reservation> get reservations => _reservations;
//
//   List<Guest> get guests => _guests;
//
//   List<Employee> get employees => _employees;
//
//   // Constructeur avec initialisation
//   HotelStructureProvider() {
//     _initializeData();
//   }
//
// // Méthode d'initialisation des données
//   Future<void> _initializeData() async {
//     try {
//       // Chargement depuis ObjectBox
//       await loadData();
//
//       // // Si pas de données, créer des données par défaut (optionnel)
//       // if (_rooms.isEmpty && _employees.isEmpty) {
//       //   await _createDefaultData();
//       // }
//
//       notifyListeners();
//     } catch (e) {
//       print('Erreur lors de l\'initialisation des données: $e');
//     }
//   }
//
//   Hotel? _currentHotel;
//
//   Hotel? get currentHotel => _currentHotel;
//
//   /// === INITIALISATION ===
//   Future<void> loadData() async {
//     _rooms = _objectBox.roomBox.getAll();
//     _reservations = _objectBox.reservationBox.getAll();
//
//     _guests = _objectBox.guestBox.getAll();
//     _employees = _objectBox.employeeBox.getAll();
//     notifyListeners();
//   }
//
// // Créer des données par défaut (optionnel pour le développement)
//   Future<void> _createDefaultData() async {
//     try {
//       // Créer quelques chambres par défaut
//       final defaultRooms = [
//         Room(
//           code: "101",
//           type: "Single",
//           capacity: 1,
//           basePrice: 8000,
//         ),
//         Room(
//           code: "102",
//           type: "Double",
//           capacity: 2,
//           basePrice: 12000,
//         ),
//         Room(
//           code: "201",
//           type: "Suite",
//           capacity: 4,
//           basePrice: 20000,
//         ),
//       ];
//
//       // Créer quelques employés par défaut
//       final defaultEmployees = [
//         Employee(
//           fullName: "Ahmed Benali",
//           phoneNumber: "0555123456",
//           email: "ahmed@hotel.dz",
//         ),
//         Employee(
//           fullName: "Fatima Khedri",
//           phoneNumber: "0666789012",
//           email: "fatima@hotel.dz",
//         ),
//       ];
//
//       print('Données par défaut créées');
//     } catch (e) {
//       print('Erreur lors de la création des données par défaut: $e');
//     }
//   }
//
//   // Méthode pour rafraîchir les données manuellement
//   Future<void> refreshData() async {
//     await loadData();
//     notifyListeners();
//   }
//
//   // ======================
//   //        ROOMS
//   // ======================
//
//   void addRoom(Room room) {
//     _objectBox.roomBox.put(room);
//     loadData();
//   }
//
//   void updateRoom(Room room) {
//     _objectBox.roomBox.put(room, mode: PutMode.update);
//     loadData();
//   }
//
//   void deleteRoom(int id) {
//     _objectBox.roomBox.remove(id);
//     loadData();
//   }
//
//   // ======================
//   //        GUESTS
//   // ======================
//
//   void addGuest(Guest guest) {
//     _objectBox.guestBox.put(guest);
//     loadData();
//   }
//
//   void updateGuest(Guest guest) {
//     _objectBox.guestBox.put(guest, mode: PutMode.update);
//     loadData();
//   }
//
//   void deleteGuest(int id) {
//     _objectBox.guestBox.remove(id);
//     loadData();
//   }
//
//   // ======================
//   //      EMPLOYEES
//   // ======================
//
//   void addEmployee(Employee employee) {
//     _objectBox.employeeBox.put(employee);
//     loadData();
//   }
//
//   void updateEmployee(Employee employee) {
//     _objectBox.employeeBox.put(employee, mode: PutMode.update);
//     loadData();
//   }
//
//   void deleteEmployee(int id) {
//     _objectBox.employeeBox.remove(id);
//     loadData();
//   }
//
//   // ======================
//   //    RESERVATIONS
//   // ======================
//
//   void addReservation(Reservation reservation, Room room, Employee employee,
//       List<Guest> guests) {
//     reservation.room.target = room;
//     reservation.receptionist.target = employee;
//     reservation.guests.addAll(guests);
//
//     _objectBox.reservationBox.put(reservation);
//     loadData();
//   }
//
//   void updateReservation(Reservation reservation) {
//     _objectBox.reservationBox.put(reservation, mode: PutMode.update);
//     loadData();
//   }
//
//   void deleteReservation(int id) {
//     _objectBox.reservationBox.remove(id);
//     loadData();
//   }
//
//   // ======================
//   //   RECHERCHES UTILES
//   // ======================
//
//   List<Reservation> getReservationsByRoom(Room room) {
//     return _objectBox.reservationBox
//         .query(Reservation_.room.equals(room.id))
//         .build()
//         .find();
//   }
//
//   List<Reservation> getReservationsByGuest(Guest guest) {
//     return guest.reservations; // grâce au Many-to-Many
//   }
//
//   List<Reservation> getReservationsByEmployee(Employee employee) {
//     return employee.reservations;
//   }
// }
//
// class HotelManagementProvider with ChangeNotifier {
//   final ObjectBox objectBox;
//   late final Box<Hotel> hotelBox;
//   late final Box<Room> roomBox;
//
//   List<Hotel> _hotels = [];
//   bool _isFirstLaunch = true;
//
//   List<Hotel> get hotels => _hotels;
//
//   bool get isFirstLaunch => _isFirstLaunch;
//
//   HotelManagementProvider(this.objectBox) {
//     hotelBox = objectBox.store.box<Hotel>();
//     roomBox = objectBox.store.box<Room>();
//     checkFirstLaunch();
//   }
//
//   void checkFirstLaunch() {
//     final existing = hotelBox.getAll();
//     if (existing.isEmpty) {
//       _isFirstLaunch = true;
//       _hotels = [];
//     } else {
//       _isFirstLaunch = false;
//       _hotels = existing;
//     }
//     notifyListeners();
//   }
//
//   void addHotel(Hotel hotel) {
//     final id = hotelBox.put(hotel);
//     hotel.id = id;
//     _hotels = hotelBox.getAll(); // Recharger la liste
//     _isFirstLaunch = false;
//     notifyListeners();
//   }
//
//   void addRoomsToHotel(Hotel hotel, List<Room> rooms) {
//     // Sauvegarder toutes les chambres
//     for (final room in rooms) {
//       room.hotel.target = hotel;
//       roomBox.put(room);
//     }
//
//     // Recharger les hôtels pour mettre à jour les relations
//     _hotels = hotelBox.getAll();
//     notifyListeners();
//   }
//
//   void updateHotel(Hotel hotel) {
//     hotelBox.put(hotel);
//     _hotels = hotelBox.getAll();
//     notifyListeners();
//   }
//
//   void deleteHotel(int id) {
//     hotelBox.remove(id);
//     _hotels = hotelBox.getAll();
//     notifyListeners();
//   }
//
//   // void deleteHotel(int id) {
//   //   // Supprimer d'abord toutes les chambres de cet hôtel
//   //   final hotel = hotelBox.get(id);
//   //   if (hotel != null) {
//   //     final roomsToDelete = hotel.rooms.toList();
//   //     for (final room in roomsToDelete) {
//   //       roomBox.remove(room.id);
//   //     }
//   //   }
//   //
//   //   // Supprimer l'hôtel
//   //   hotelBox.remove(id);
//   //   _hotels = hotelBox.getAll();
//   //
//   //   // Si on supprime le dernier hôtel, redevenir en mode "first launch"
//   //   if (_hotels.isEmpty) {
//   //     _isFirstLaunch = true;
//   //   }
//   //   notifyListeners();
//   // }
//
//   void loadHotels() {
//     _hotels = hotelBox.getAll();
//     notifyListeners();
//   }
//
//   void updateRoomStatus(Room room, String newStatus) {
//     room.status = newStatus;
//     roomBox.put(room);
//     notifyListeners();
//   }
//
//   List<Room> getRoomsForHotel(Hotel hotel) {
//     return hotel.rooms.toList();
//   }
//
//   Room? getRoomByCode(String code) {
//     final query = roomBox.query(Room_.code.equals(code)).build();
//     final result = query.findFirst();
//     query.close();
//     return result;
//   }
// }
//
// class ReservationProvider with ChangeNotifier {
//   final ObjectBox _objectBox;
//   List<Reservation> _reservations = [];
//
//   ReservationProvider(this._objectBox) {
//     _loadReservations();
//   }
//
//   List<Reservation> get reservations => _reservations;
//
//   Future<void> _loadReservations() async {
//     _reservations = _objectBox.reservationBox.getAll();
//     notifyListeners();
//   }
//
//   Future<int> addReservation({
//     required Room room,
//     required Employee receptionist,
//     required List<Guest> guests,
//     required DateTime from,
//     required DateTime to,
//     required double pricePerNight,
//     String status = "Confirmée",
//   }) async {
//     final reservation = Reservation(
//       from: from,
//       to: to,
//       pricePerNight: pricePerNight,
//       status: status,
//     );
//
//     reservation.room.target = room;
//     reservation.receptionist.target = receptionist;
//     reservation.guests.addAll(guests);
//
//     final id = _objectBox.reservationBox.put(reservation);
//     await _loadReservations();
//     return id;
//   }
//
//   Future<bool> deleteReservation(int id) async {
//     final success = _objectBox.reservationBox.remove(id);
//     if (success) {
//       await _loadReservations();
//     }
//     return success;
//   }
//
//   Future<void> updateReservation(Reservation reservation) async {
//     _objectBox.reservationBox.put(reservation);
//     await _loadReservations();
//   }
//
//   List<Reservation> getReservationsByRoom(Room room) {
//     final query = _objectBox.reservationBox
//         .query(Reservation_.room.equals(room.id))
//         .build();
//     final results = query.find();
//     query.close();
//     return results;
//   }
//
//   List<Reservation> getReservationsInPeriod(DateTime start, DateTime end) {
//     return _reservations.where((reservation) {
//       return reservation.from.isBefore(end) && reservation.to.isAfter(start);
//     }).toList();
//   }
//
//   // Méthode utilitaire pour récupérer le nom de la chambre
//   String getRoomNameForReservation(Reservation reservation) {
//     return reservation.room.target?.code ?? 'Chambre inconnue';
//   }
//
//   // Méthode utilitaire pour récupérer le nom du client principal
//   String getPrimaryGuestName(Reservation reservation) {
//     return reservation.guests.isNotEmpty
//         ? reservation.guests.first.fullName
//         : 'Aucun client';
//   }
// }

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
  // GESTION DES HÔTELS
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

  // ============================================================================
  // GESTION DES CHAMBRES
  // ============================================================================

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

  List<Room> getAvailableRoomsForPeriod(DateTime from, DateTime to) {
    final conflictingReservations = getReservationsInPeriod(from, to);
    final occupiedRoomIds = conflictingReservations
        .map((res) => res.room.target?.id)
        .where((id) => id != null)
        .toSet();

    return _rooms
        .where((room) =>
            !occupiedRoomIds.contains(room.id) && room.status == 'Disponible')
        .toList();
  }

  // ============================================================================
  // GESTION DES CLIENTS
  // ============================================================================

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

  // ============================================================================
  // GESTION DES EMPLOYÉS
  // ============================================================================

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

  // ============================================================================
  // GESTION DES RÉSERVATIONS
  // ============================================================================

  Future<int> addReservation({
    required Room room,
    required Employee receptionist,
    required List<Guest> guests,
    required DateTime from,
    required DateTime to,
    required double pricePerNight,
    String status = "Confirmée",
  }) async {
    try {
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
      return id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la réservation: $e');
      rethrow;
    }
  }

  Future<bool> updateReservation(Reservation reservation) async {
    try {
      _reservationBox.put(reservation, mode: PutMode.update);
      await _loadAllData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la réservation: $e');
      return false;
    }
  }

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
  // MÉTHODES DE RECHERCHE ET ANALYSE
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
          reservation.from.isBefore(endOfDay);
    }).toList();
  }

  List<Reservation> getTodayCheckOuts() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _reservations.where((reservation) {
      return reservation.to.isAfter(startOfDay) &&
          reservation.to.isBefore(endOfDay);
    }).toList();
  }

  // ============================================================================
  // MÉTHODES UTILITAIRES
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
  // MÉTHODES DE DÉVELOPPEMENT (À SUPPRIMER EN PRODUCTION)
  // ============================================================================

  Future<void> createDefaultData() async {
    if (_rooms.isNotEmpty || _employees.isNotEmpty) return;

    try {
      // Créer des chambres par défaut
      final defaultRooms = [
        Room(code: "101", type: "Single", capacity: 1, basePrice: 8000),
        Room(code: "102", type: "Double", capacity: 2, basePrice: 12000),
        Room(code: "201", type: "Suite", capacity: 4, basePrice: 20000),
      ];

      // Créer des employés par défaut
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

      // Sauvegarder les données
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
