import 'package:flutter/foundation.dart';
import 'package:kenzy/checkit/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignalementProviderSupabase with ChangeNotifier {
  final _client = Supabase.instance.client;

  final Map<String, List<Signalement>> _signalementsParNumero = {};

  Map<String, List<Signalement>> get signalementsParNumero =>
      _signalementsParNumero;

  String normalizeNumero(dynamic numero) {
    // Convertir l'entrée en String et supprimer les espaces
    String numStr = numero.toString().replaceAll(RegExp(r'\s+'), '');

    // Retirer le préfixe +213 s'il est présent
    if (numStr.startsWith('+213')) {
      numStr = numStr.substring(4);
    }
    // Retirer le préfixe 00213 s'il est présent
    else if (numStr.startsWith('00213')) {
      numStr = numStr.substring(5);
    }

    // Retirer le 0 initial s'il est présent
    if (numStr.startsWith('0')) {
      numStr = numStr.substring(1);
    }

    return numStr;
  }

  // Future<void> chargerSignalements() async {
  //   final response = await _client
  //       .from('signalements')
  //       .select()
  //       .order('date', ascending: false);
  //
  //   final data = response as List;
  //
  //   _signalementsParNumero.clear();
  //
  //   for (final item in data) {
  //     final s = Signalement.fromJson(item);
  //
  //     // Normalisation du numéro
  //     String numero = s.numero.toString().replaceAll(RegExp(r'\s+'), '');
  //     if (numero.startsWith('+213')) {
  //       numero = '0' + numero.substring(4);
  //     } else if (numero.startsWith('213')) {
  //       numero = '0' + numero.substring(3);
  //     }
  //
  //     // Utilise le numéro normalisé comme clé
  //     _signalementsParNumero.putIfAbsent(numero, () => []).add(s);
  //   }
  //
  //   notifyListeners();
  // }
  Future<void> chargerSignalements() async {
    final response = await _client
        .from('signalements')
        .select()
        .order('date', ascending: false);

    final data = response as List;
    _signalementsParNumero.clear();

    for (final item in data) {
      final s = Signalement.fromJson(item);

      // Normalisation du numéro
      String numero = normalizeNumero(s.numero.toString());

      // Utilise le numéro normalisé comme clé
      _signalementsParNumero.putIfAbsent(numero, () => []).add(s);
    }

    notifyListeners();
  }

  /// Retourne l’opérateur à partir du numéro
  String detecterOperateur(String numero) {
    if (numero.startsWith('05') || numero.startsWith('5')) {
      return 'Ooredoo';
    } else if (numero.startsWith('06') || numero.startsWith('6')) {
      return 'Mobilis';
    } else if (numero.startsWith('07') || numero.startsWith('7')) {
      return 'Djezzy';
    } else {
      return 'Inconnu';
    }
  }

  /// Retourne le chemin du logo de l’opérateur
  String getLogoOperateur(String operateur) {
    switch (operateur) {
      case 'Ooredoo':
        return 'assets/logos/ooredoo.png';
      case 'Mobilis':
        return 'assets/logos/mobilis.png';
      case 'Djezzy':
        return 'assets/logos/djezzy.png';
      default:
        return 'assets/logos/inconnu.png';
    }
  }

  Future<void> ajouterSignalement(Signalement signalement) async {
    await _client.from('signalements').insert(signalement.toJson());
    await chargerSignalements(); // recharge après ajout
  }

  int nombreSignalements(String numero) {
    return _signalementsParNumero[numero]?.length ?? 0;
  }

  List<Signalement> getSignalements(String numero) {
    return _signalementsParNumero[numero] ?? [];
  }
}
