import 'package:flutter/material.dart';

import '../../objectBox/Entity.dart'; // Tes entités originales
import '../../objectbox.g.dart';
import 'objectbox_p2p.dart';

class StaffProviderP2P with ChangeNotifier {
  List<Staff> _staffs = [];
  late final ObjectBoxP2P _objectBox;
  bool _initialized = false;

  List<Staff> get staffs => _staffs;
  bool get isInitialized => _initialized;

  StaffProviderP2P() {
    _initObjectBox();
  }

  Future<void> _initObjectBox() async {
    try {
      _objectBox = await ObjectBoxP2P.create();
      await fetchStaffs();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      print('Erreur initialisation ObjectBoxP2P: $e');
    }
  }

  // 🔹 TES MÉTHODES EXISTANTES RESTENT IDENTIQUES !
  Future<void> fetchStaffs() async {
    try {
      _staffs = _objectBox.staffBox.getAll(); // Box originale
      notifyListeners();
    } catch (e) {
      print("Erreur fetchStaffs: $e");
    }
  }

  Future<void> addStaff(Staff staff, List<String> activites) async {
    try {
      // 1. Sauvegarde originale
      _objectBox.staffBox.put(staff);

      // 2. Enregistrement P2P AUTOMATIQUE
      _objectBox.registerStaff(staff);

      // 3. Gestion des activités (existant)
      for (int i = 0; i < activites.length && i < 31; i++) {
        final activite = ActiviteJour(
          jour: i + 1,
          statut: activites[i],
        )..staff.target = staff;

        _objectBox.activiteBox.put(activite);
        _objectBox.registerActiviteJour(activite); // 🆕 P2P
      }

      await fetchStaffs();
    } catch (e) {
      print("Erreur addStaff: $e");
    }
  }

  Future<void> updateStaff(Staff staff) async {
    try {
      _objectBox.staffBox.put(staff);
      _objectBox.updateStaff(staff); // 🆕 P2P
      await fetchStaffs();
    } catch (e) {
      print("Erreur updateStaff: $e");
    }
  }

  Future<void> deleteStaff(Staff staff) async {
    try {
      // Suppression originale
      _objectBox.deleteStaff(staff); // 🆕 P2P (marque comme supprimé)

      // Nettoyage des relations (existant)
      final activites = _objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(staff.id))
          .build()
          .find();
      for (var act in activites) {
        _objectBox.activiteBox.remove(act.id);
      }

      for (var timeOff in staff.timeOff) {
        _objectBox.timeOffBox.remove(timeOff.id);
      }

      // Suppression finale
      _objectBox.staffBox.remove(staff.id);

      await fetchStaffs();
    } catch (e) {
      print("Erreur deleteStaff: $e");
    }
  }

  // 🔹 MÉTHODES P2P
  void applyRemoteDelta(Map<String, dynamic> delta) {
    _objectBox.applyDelta(delta);
    fetchStaffs(); // Rafraîchir l'UI
  }

  // TES AUTRES MÉTHODES EXISTANTES RESTENT IDENTIQUES
  Future<void> saveMonthActivities(int year, int month) async {
    // Ton code existant...
  }

  Future<bool> loadMonthActivities(int year, int month) async {
    // Ton code existant...
    return true;
  }
}
