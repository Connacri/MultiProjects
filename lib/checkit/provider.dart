import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final firebaseApp = Firebase.app();

/// Provider pour gérer les signalements via Firebase Realtime Database
class SignalementProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref("signalements");

  // final _db = FirebaseDatabase.instanceFor(
  //         app: firebaseApp,
  //         databaseURL: 'https://walletdz-d12e0-default-rtdb.firebaseio.com/')
  //     .ref('signalements');

  // Stockage des signalements par numéro
  Map<String, List<Signalement>> _signalementsParNumero = {};

  Map<String, List<Signalement>> get signalementsParNumero =>
      _signalementsParNumero;

  /// Écoute les mises à jour en temps réel
  void chargerSignalements() {
    _db.onValue.listen((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      _signalementsParNumero =
          (data ?? {}).map<String, List<Signalement>>((key, value) {
        final signalements = (value as Map? ?? {})
            .values
            .whereType<Map<dynamic, dynamic>>()
            .map(Signalement.fromJson)
            .toList();
        return MapEntry(key.toString(), signalements);
      });
      notifyListeners();
    });
  }

  /// Ajoute un signalement dans Firebase et met à jour l'état
  Future<void> ajouterSignalement(Signalement signalement) async {
    try {
      final ref = _db.child(signalement.numero.toString()).push();
      await ref.set(signalement.toJson());
      print('Signalement ajouté pour le numéro ${signalement.numero}');
    } catch (e) {
      print('Erreur lors de l\'ajout du signalement : $e');
      rethrow;
    }
  }

  /// Retourne le nombre de signalements pour un numéro donné
  int nombreSignalements(String numero) {
    return _signalementsParNumero[numero]?.length ?? 0;
  }

  /// Retourne la liste des signalements pour un numéro donné
  List<Signalement> getSignalements(String numero) {
    return _signalementsParNumero[numero] ?? [];
  }
}

/// Modèle de données pour un signalement
class Signalement {
  final String numero;
  final String? description;
  final String signalePar;
  final String motif;
  final int gravite;
  final DateTime date;

  Signalement({
    required this.numero,
    this.description,
    required this.signalePar,
    required this.motif,
    required this.gravite,
    required this.date,
  });

  /// Convertir en JSON pour Firestore
  Map<String, dynamic> toJson() => {
        'numero': numero,
        'description': description,
        'signalePar': signalePar,
        'motif': motif,
        'gravite': gravite,
        'date': date.toIso8601String(),
      };

  static Signalement fromJson(Map<dynamic, dynamic> json) {
    return Signalement(
      numero: json['numero'],
      description: json['description'] ?? '',
      signalePar: json['signalePar'],
      motif: json['motif'],
      gravite: json['gravite'],
      date: DateTime.parse(json['date']),
    );
  }
}
