import 'package:flutter/material.dart';

import '../../../../objectbox.g.dart';
import '../../../Entity.dart';
import '../../../classeObjectBox.dart';

class HotelProvider with ChangeNotifier {
  final ObjectBox _objectBox = ObjectBox();

  // Collections locales en mémoire
  List<Room> _rooms = [];
  List<Reservation> _reservations = [];
  List<Guest> _guests = [];
  List<Employee> _employees = [];

  // Getters
  List<Room> get rooms => _rooms;

  List<Reservation> get reservations => _reservations;

  List<Guest> get guests => _guests;

  List<Employee> get employees => _employees;

  // Constructeur avec initialisation
  HotelProvider() {
    _initializeData();
  }

// Méthode d'initialisation des données
  Future<void> _initializeData() async {
    try {
      // Chargement depuis ObjectBox
      await loadData();

      // Si pas de données, créer des données par défaut (optionnel)
      if (_rooms.isEmpty && _employees.isEmpty) {
        await _createDefaultData();
      }

      notifyListeners();
    } catch (e) {
      print('Erreur lors de l\'initialisation des données: $e');
    }
  }

  /// === INITIALISATION ===
  Future<void> loadData() async {
    _rooms = _objectBox.roomBox.getAll();
    _reservations = _objectBox.reservationBox.getAll();
    _guests = _objectBox.guestBox.getAll();
    _employees = _objectBox.employeeBox.getAll();
    notifyListeners();
  }

// Créer des données par défaut (optionnel pour le développement)
  Future<void> _createDefaultData() async {
    try {
      // Créer quelques chambres par défaut
      final defaultRooms = [
        Room(
          code: "101",
          type: "Single",
          capacity: 1,
          basePrice: 8000,
        ),
        Room(
          code: "102",
          type: "Double",
          capacity: 2,
          basePrice: 12000,
        ),
        Room(
          code: "201",
          type: "Suite",
          capacity: 4,
          basePrice: 20000,
        ),
      ];

      // Créer quelques employés par défaut
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

      print('Données par défaut créées');
    } catch (e) {
      print('Erreur lors de la création des données par défaut: $e');
    }
  }

  // Méthode pour rafraîchir les données manuellement
  Future<void> refreshData() async {
    await loadData();
    notifyListeners();
  }

  // ======================
  //        ROOMS
  // ======================

  void addRoom(Room room) {
    _objectBox.roomBox.put(room);
    loadData();
  }

  void updateRoom(Room room) {
    _objectBox.roomBox.put(room, mode: PutMode.update);
    loadData();
  }

  void deleteRoom(int id) {
    _objectBox.roomBox.remove(id);
    loadData();
  }

  // ======================
  //        GUESTS
  // ======================

  void addGuest(Guest guest) {
    _objectBox.guestBox.put(guest);
    loadData();
  }

  void updateGuest(Guest guest) {
    _objectBox.guestBox.put(guest, mode: PutMode.update);
    loadData();
  }

  void deleteGuest(int id) {
    _objectBox.guestBox.remove(id);
    loadData();
  }

  // ======================
  //      EMPLOYEES
  // ======================

  void addEmployee(Employee employee) {
    _objectBox.employeeBox.put(employee);
    loadData();
  }

  void updateEmployee(Employee employee) {
    _objectBox.employeeBox.put(employee, mode: PutMode.update);
    loadData();
  }

  void deleteEmployee(int id) {
    _objectBox.employeeBox.remove(id);
    loadData();
  }

  // ======================
  //    RESERVATIONS
  // ======================

  void addReservation(Reservation reservation, Room room, Employee employee,
      List<Guest> guests) {
    reservation.room.target = room;
    reservation.receptionist.target = employee;
    reservation.guests.addAll(guests);

    _objectBox.reservationBox.put(reservation);
    loadData();
  }

  void updateReservation(Reservation reservation) {
    _objectBox.reservationBox.put(reservation, mode: PutMode.update);
    loadData();
  }

  void deleteReservation(int id) {
    _objectBox.reservationBox.remove(id);
    loadData();
  }

  // ======================
  //   RECHERCHES UTILES
  // ======================

  List<Reservation> getReservationsByRoom(Room room) {
    return _objectBox.reservationBox
        .query(Reservation_.room.equals(room.id))
        .build()
        .find();
  }

  List<Reservation> getReservationsByGuest(Guest guest) {
    return guest.reservations; // grâce au Many-to-Many
  }

  List<Reservation> getReservationsByEmployee(Employee employee) {
    return employee.reservations;
  }
}
