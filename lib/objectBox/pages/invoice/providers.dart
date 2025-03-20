import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../objectbox.g.dart';
import '../../Entity.dart';
import '../../MyProviders.dart';
import '../../classeObjectBox.dart';

class FacturationProvider with ChangeNotifier {
  // List<Document> _factures = [];
  Document? _factureEnCours;
  Document? _factureEnEdition; // Copie de la facture en cours d'édition
  List<LigneDocument> _lignesFacture = [];
  List<Produit> _produitsTrouves = [];
  final Map<int, LigneEditionState> _ligneEditionStates = {};
  bool _isEditing =
      false; // Pour suivre si une facture est en cours de modification
  bool get isEditing => _isEditing;
  bool _hasChanges =
      false; // Pour suivre si des modifications ont été apportées.

  bool get hasChanges => _hasChanges;

  Document? get factureEnEdition => _factureEnEdition;

  //List<Document> get factures => _factures;

  Document? get factureEnCours => _factureEnCours;

  List<LigneDocument> get lignesFacture => _lignesFacture;

  List<Produit> get produitsTrouves => _produitsTrouves;

  Client? _clientTemporaire; // Client temporaire

  final ObjectBox _objectBox = ObjectBox();

  FacturationProvider() {
    _objectBox.init().then((_) {
      //_chargerFactures();
      chargerFactures2();
      _chargerFacturesTotal();
      //chargerFacturesPaginees();
    });
  }

  Client? _selectedClient;

  Client? get selectedClient => _selectedClient;

// Ajoutez un champ pour gérer l'impayé
  double _impayer = 0.0;

  double get impayer => _impayer;

  ////////////////////////////////Liste des facture//////////////////////////////////////

  bool _isLoadingListFacture = false;

  bool get isLoadingListFacture => _isLoadingListFacture;

  List<Document> _facturesList = [];

  List<Document> get facturesList => _facturesList.toList();

  int _currentPageFacture = 0;
  final int _pageSizeFacture = 20;
  bool _hasMoreFactures = true;

  bool get hasMoreFactures => _hasMoreFactures;

  Future<void> chargerFactures2({bool reset = false}) async {
    if (_isLoadingListFacture || !_hasMoreFactures) {
      print(
          "🚫 Appel ignoré : _isLoadingListFacture = $_isLoadingListFacture, _hasMoreFactures = $_hasMoreFactures");
      return;
    }

    _isLoadingListFacture = true;
    notifyListeners();
    print("🔄 Début du chargement des factures...");

    try {
      if (reset) {
        _currentPageFacture = 0;
        _facturesList.clear(); // Utilisez _facturesList au lieu de facturesList
        print(
            "🔄 Réinitialisation de la pagination : _currentPageFacture = $_currentPageFacture");
      }

      final offset = _currentPageFacture * _pageSizeFacture;
      final limit = _pageSizeFacture;
      print("📊 Pagination : offset = $offset, limit = $limit");

      final query = _objectBox.factureBox
          .query()
          .order(Document_.id, flags: Order.descending)
          .build()
        ..offset = offset
        ..limit = limit;

      print("🔍 Exécution de la requête pour récupérer les factures...");
      final newFactures = await query.find();
      print("✅ ${newFactures.length} factures récupérées");

      // Ajouter les nouvelles factures à _facturesList
      _facturesList.addAll(
          newFactures); // Utilisez _facturesList au lieu de facturesList
      print(
          "📥 ${newFactures.length} factures ajoutées à _facturesList : ${_facturesList.length}");

      if (newFactures.length < _pageSizeFacture) {
        _hasMoreFactures = false;
        print(
            "⛔ Plus de factures à charger : _hasMoreFactures = $_hasMoreFactures");
      } else {
        _currentPageFacture++;
        _hasMoreFactures = true;
        print(
            "➡️ Page suivante : _currentPageFacture = $_currentPageFacture, _hasMoreFactures = $_hasMoreFactures");
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des factures : $e");
    } finally {
      _isLoadingListFacture = false;
      notifyListeners();
      print(
          "✅ Chargement terminé : _isLoadingListFacture = $_isLoadingListFacture");
    }
  }

  List<Document> _totalfactures = [];

  List<Document> get totalfactures => _totalfactures;

  void _chargerFacturesTotal() {
    _totalfactures = _objectBox.factureBox.getAll().toList();
    notifyListeners();
  }

  ///////////////////////////////////////////////////////////////////////////////////////
  // Future<void> chargerFactures({bool reset = true}) async {
  //   if (_isLoadingListFacture || !_hasMoreFactures) return;
  //
  //   _isLoadingListFacture = true;
  //   notifyListeners();
  //
  //   try {
  //     // Calculer l'offset et le limit pour la pagination
  //     final offset = _currentPageFacture * _pageSizeFacture;
  //     final limit = _pageSizeFacture; // Limite des résultats à récupérer
  //     // Construire et configurer la requête
  //     final query = _objectBox.factureBox
  //         .query()
  //         .order(Document_.derniereModification, flags: Order.descending)
  //         .build()
  //       ..offset = offset
  //       ..limit = limit;
  //
  //     // Effectuer la recherche dans ObjectBox
  //     final nouvellesFactures = await query
  //         .find(); // Utilisation de `await` pour exécution asynchrone
  //     query.close(); // Fermer la requête après utilisation
  //
  //     if (nouvellesFactures.isEmpty) {
  //       _hasMoreFactures =
  //           false; // Indiquer qu'il n'y a plus de données disponibles
  //     } else {
  //       _facturesList.addAll(
  //           nouvellesFactures); // Ajouter les nouvelles factures à la liste
  //       _currentPageFacture++; // Passer à la page suivante
  //     }
  //   } catch (e) {
  //     print("Erreur lors de la récupération des factures : $e");
  //   } finally {
  //     _isLoadingListFacture = false;
  //     notifyListeners();
  //   }
  // }

  void setImpayer(double impayer) {
    _impayer = impayer;
    // _isEditing = true;
    _hasChanges = true;
    notifyListeners();
  }

  void commencerEdition(Document facture) {
    _factureEnEdition = facture;
    _isEditing = true; // Activer l'état d'édition
    _hasChanges = false; // Réinitialiser l'état des modifications
    notifyListeners();
  }

  void modifierLigne(int index, double quantite, double prixUnitaire) {
    if (index >= 0 && index < _lignesFacture.length) {
      _lignesFacture[index].quantite = quantite;
      _lignesFacture[index].prixUnitaire = prixUnitaire;
      _hasChanges = true; // Marquer qu'il y a des modifications
      notifyListeners();
    }
  }

  void modifierImpayer(double impayer) {
    _impayer = impayer;
    _hasChanges = true; // Marquer qu'il y a des modifications
    notifyListeners();
  }

  void selectClient(Client client) {
    _selectedClient = client;
    // if (_factureEnEdition != null) {
    //   _factureEnEdition!.client.target = client;
    // }
    _hasChanges = true;

    notifyListeners();
  }

  void resetClient() {
    // Déconnecter temporairement le client uniquement pour la facture en cours
    // if (_factureEnCours != null) {
    //   _factureEnCours!.client.target = null;
    // }

    // Ne réinitialise que le client sélectionné dans l'état local
    _selectedClient = null;
    _hasChanges = true;
    notifyListeners();
  }

  // Méthode pour créer un nouveau client
  Future<void> createClient(String nom, String phone, String adresse, String qr,
      DateTime derniereModification) async {
    final nouveauClient = Client(
      nom: nom,
      phone: phone,
      adresse: adresse,
      qr: qr,
      derniereModification: derniereModification,
    );
    _objectBox.clientBox.put(nouveauClient);
    notifyListeners();
  }

  // Méthode pour récupérer tous les clients
  List<Client> getClients() {
    return _objectBox.clientBox.getAll();
  }

  // void _chargerFactures() {
  //   _factures = _objectBox.factureBox.getAll();
  //   notifyListeners();
  // }

  void marquerCommeSauvegardee(Document facture) {
    _factureEnEdition = null; // Réinitialiser la facture en cours d'édition
    notifyListeners();
  }

  // Méthode pour vérifier si une facture est en cours d'édition
  bool estEnEdition(Document facture) {
    return _factureEnEdition?.id == facture.id;
  }

  void terminerEdition() {
    _factureEnEdition = null;
    // 🗑️ Si la facture supprimée est celle en cours, la réinitialiser

    _factureEnCours = null;
    _lignesFacture.clear();
    _selectedClient = null;
    _impayer = 0.0;
    clearImpayer();
    notifyListeners();
  }

  LigneEditionState getLigneEditionState(int index) {
    _ligneEditionStates.putIfAbsent(index, () => LigneEditionState());
    return _ligneEditionStates[index]!;
  }

  void toggleEditQty(int index) {
    final state = getLigneEditionState(index);
    state.isEditedQty = !state.isEditedQty;
    notifyListeners();
  }

  void toggleEditPu(int index) {
    final state = getLigneEditionState(index);
    state.isEditedPu = !state.isEditedPu;
    notifyListeners();
  }

  void AlwaystoggleEdit(int index) {
    final state = LigneEditionState();
    state.isEditedPu = !state.isEditedPu;
    notifyListeners();
  }

  bool _isEditable = false;

  bool get isEditable => _isEditable;

  void toggleEditImpayer() {
    _isEditable = !_isEditable;
    notifyListeners();
  }

  void setEditable(bool value) {
    _isEditable = value;
    notifyListeners();
  }

  void rechercherProduits(String texte) {
    if (texte.isEmpty) {
      _produitsTrouves.clear();
    } else {
      final query = _objectBox.produitBox.query(
        Produit_.nom.contains(texte, caseSensitive: false) |
            Produit_.qr.contains(texte, caseSensitive: false) |
            Produit_.id.equals(int.tryParse(texte) ?? 0),
      );
      _produitsTrouves = query.build().find();
    }
    notifyListeners();
  }

  void ajouterProduitALaFacture(
      Produit produit, double quantite, double prixUnitaire) {
    // Vérifier si le produit existe déjà dans la facture
    final ligneExistanteIndex = _lignesFacture.indexWhere(
      (ligne) => ligne.produit.target?.id == produit.id,
    );

    if (ligneExistanteIndex != -1) {
      // Si le produit existe, incrémenter la quantité
      _lignesFacture[ligneExistanteIndex].quantite += quantite;
    } else {
      // Sinon, ajouter une nouvelle ligne
      final nouvelleLigne = LigneDocument(
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        derniereModification: DateTime.now(),
      );
      nouvelleLigne.produit.target = produit;
      _lignesFacture.add(nouvelleLigne);
    }
    _hasChanges = true; // Marquer qu'il y a des modifications

    notifyListeners();
  }

  void supprimerLigne(int index) {
    if (index >= 0 && index < _lignesFacture.length) {
      print('Suppression de la ligne à l\'index $index'); // Ajoutez ce log
      _lignesFacture.removeAt(index);

      _hasChanges = true; // Marquer qu'il y a des modifications
      notifyListeners();
    } else {
      print('Erreur : Index invalide pour la suppression'); // Ajoutez ce log
    }
  }

  double calculerTotalHT() {
    return _lignesFacture.fold(0.0, (total, ligne) {
      return total + (ligne.quantite * ligne.prixUnitaire);
    });
  }

  double calculerTVA() {
    const tauxTVA = 0.20;
    return calculerTotalHT() * tauxTVA;
  }

  double calculerTotalTTC() {
    return calculerTotalHT() + calculerTVA();
  }

  void creerNouvelleFacture11() {
    // Créer une nouvelle facture
    _factureEnCours = Document(
      type: 'vente',
      // ou 'achat'
      qrReference: 'REFnouv${DateTime.now().millisecondsSinceEpoch}',
      // Référence unique
      impayer: 0.0,
      derniereModification: DateTime.now(),
      isSynced: false,
      date: DateTime.now(),
    );
    _selectedClient = null;
    _impayer = 0.0;
    // Réinitialiser les lignes de la facture
    _lignesFacture.clear();
    clearImpayer();
    // Notifier les listeners pour mettre à jour l'interface utilisateur
    notifyListeners();
  }

  double getOriginalQuantity(int produitId) {
    if (_factureEnCours == null) return 0.0; // Si c'est une nouvelle facture
    final originalLines = _factureEnCours!.lignesDocument;
    final originalLine = originalLines.firstWhere(
      (line) => line.produit.target?.id == produitId,
      orElse: () {
        // Return a default LigneDocument object or handle the case appropriately
        // For example, you can return a LigneDocument with a quantity of 0.0
        return LigneDocument(
            quantite: 0.0,
            prixUnitaire: 0.0,
            derniereModification: DateTime.now()); // Adjust this as needed
      },
    );
    return originalLine.quantite;
  }

  void selectionnerFacture(Document facture) {
    _factureEnEdition = Document(
      id: facture.id,
      type: facture.type,
      qrReference: facture.qrReference,
      impayer: facture.impayer ?? 0.0,
      // Copiez l'impayé
      derniereModification: facture.derniereModification,
      isSynced: facture.isSynced,
      syncedAt: facture.syncedAt,
      date: facture.date,
    );
    // Copier le client associé à la facture
    _selectedClient = facture.client.target;
    // Copiez les lignes de document
    _factureEnEdition!.lignesDocument
        .addAll(facture.lignesDocument.map((ligne) {
      return LigneDocument(
        id: ligne.id,
        quantite: ligne.quantite,
        prixUnitaire: ligne.prixUnitaire,
        derniereModification: ligne.derniereModification,
        isSynced: ligne.isSynced,
        syncedAt: ligne.syncedAt,
      )..produit.target = ligne.produit.target;
    }));

    _factureEnCours = facture;
    _lignesFacture = _factureEnEdition!.lignesDocument.toList();
    _impayer = facture.impayer ?? 0.0; // Initialisez l'impayé

    notifyListeners();
  }

  Future<void> sauvegarderFacture1(
      BuildContext context, CommerceProvider commerceProvider) async {
    try {
      final Map<int, double> quantitesToDeduct = {};

// Si on modifie une facture existante, récupérer ses anciennes quantités
      final Map<int, double> ancienneQuantite = {};

      if (_factureEnCours != null) {
        for (final ancienneLigne in _factureEnCours!.lignesDocument) {
          final produitId = ancienneLigne.produit.target?.id;
          if (produitId != null) {
            ancienneQuantite[produitId] =
                (ancienneQuantite[produitId] ?? 0) + ancienneLigne.quantite;
          }
        }
      }

// Maintenant, on calcule la différence entre l'ancienne et la nouvelle quantité
      for (final ligne in _lignesFacture) {
        final produitId = ligne.produit.target?.id;
        if (produitId != null) {
          final nouvelleQuantite = ligne.quantite;
          final ancienneQte = ancienneQuantite[produitId] ?? 0;

          // Calculer la différence
          final difference = nouvelleQuantite - ancienneQte;

          // On ne stocke que la quantité supplémentaire à déduire
          if (difference != 0) {
            quantitesToDeduct[produitId] = difference;
          }
          print('difference = $difference');
        }
      }

      // Check if we have enough stock for all products
      for (final entry in quantitesToDeduct.entries) {
        final produit = _objectBox.produitBox.get(entry.key);
        if (produit == null) continue;

        final stockDisponible = produit.calculerStockTotal();
        if (stockDisponible < entry.value) {
          //throw Exception('Stock insuffisant pour le produit: ${produit.nom}');
          // Afficher le dialogue d'erreur
          await showDialog(
            context: context,
            barrierDismissible: false, // L'utilisateur doit cliquer sur OK
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'Stock Insuffisant',
                  style: TextStyle(color: Colors.red),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Le stock est insuffisant pour le produit:'),
                    SizedBox(height: 8),
                    Text(
                      produit.nom,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'Stock disponible: ${stockDisponible.toStringAsFixed(2)}'),
                    Text(
                        'Quantité demandée: ${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.red, width: 2),
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'OK',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }

      // Deduct quantities from approvisionnements
      for (final entry in quantitesToDeduct.entries) {
        final produitId = entry.key;
        double quantiteADeduire = entry.value;

        // Get all approvisionnements for this product, ordered by date
        final query = _objectBox.approvisionnementBox
            .query(Approvisionnement_.produit.equals(produitId))
          ..order(Approvisionnement_.datePeremption);

        final approvisionnements = query.build().find();

        //   if (quantiteADeduire > 0) {
        // Deduct quantities following FIFO
        for (final appro in approvisionnements) {
          //if (quantiteADeduire < 0) break;

          //  if (appro.quantite > 0) {
          print(
              'yes > 000000000000 ${appro.quantite} quantiteADeduire ${quantiteADeduire}');
          final quantitePrelevee = min(appro.quantite, quantiteADeduire);
          appro.quantite -= quantitePrelevee;
          quantiteADeduire -= quantitePrelevee;

          // Update the approvisionnement in the database
          _objectBox.approvisionnementBox.put(appro);
        }
        // }
        // }
        // else if (quantiteADeduire < 0) {
        //   // Restitution de stock si on a diminué la quantité
        //   final approvisionnement = Approvisionnement(
        //     quantite: quantiteADeduire, // On remet en stock
        //     datePeremption: DateTime.now()
        //         .add(Duration(days: 365)), // Ajuster selon la logique
        //   );
        //
        //   _objectBox.approvisionnementBox.put(approvisionnement);
        // }
        notifyListeners();
        // Recharger les produits si nécessaire
        chargerFactures2(reset: true);
      }

      // Original invoice saving logic
      if (_factureEnCours == null) {
        final nouvelleFacture = Document(
          type: 'vente',
          qrReference: 'REF${DateTime.now().millisecondsSinceEpoch}',
          impayer: _impayer,
          derniereModification: DateTime.now(),
          isSynced: false,
          date: DateTime.now(),
        );

        nouvelleFacture.client.target = _selectedClient;
        nouvelleFacture.lignesDocument.addAll(_lignesFacture);
        _objectBox.factureBox.put(nouvelleFacture);

        for (final ligne in _lignesFacture) {
          ligne.facture.target = nouvelleFacture;
          _objectBox.ligneFacture.put(ligne);
        }

        _facturesList.add(nouvelleFacture);
      } else {
        _factureEnCours!.lignesDocument.clear();
        _factureEnCours!.lignesDocument.addAll(_lignesFacture);
        _factureEnCours!.impayer = _impayer;
        _factureEnCours!.client.target = _selectedClient;
        _objectBox.factureBox.put(_factureEnCours!);

        for (final ligne in _lignesFacture) {
          ligne.facture.target = _factureEnCours;
          _objectBox.ligneFacture.put(ligne);
        }
      }

      // Reset state

      _factureEnCours = null;
      _factureEnEdition = null;
      _lignesFacture.clear();
      _impayer = 0.0;

      _selectedClient = null;
      chargerFactures2(reset: true);
      _chargerFacturesTotal();

      print('Facture sauvegardée avec succès');
      _isEditing = false;
      _hasChanges = false;
      // 🔴 Notification pour mettre à jour les produits
      commerceProvider.chargerProduits(reset: true);
      clearImpayer();
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la sauvegarde de la facture: $e');
      // Afficher une alerte générique en cas d'erreur
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Erreur',
              style: TextStyle(color: Colors.red),
            ),
            content: Text('Une erreur est survenue lors de la sauvegarde: $e'),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.red, width: 2),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      rethrow; // Rethrow the exception to handle it in the UI
    }
  }

  Future<void> sauvegarderFacture(
    BuildContext context,
    CommerceProvider commerceProvider,
  ) async {
    try {
      // 1. Calcul des quantités à déduire/restaurer
      final quantitesToAdjust = <int, double>{};
      final ancienneQuantite = <int, double>{};

      // Récupération des quantités originales
      if (_factureEnCours != null) {
        for (final ligne in _factureEnCours!.lignesDocument) {
          final produitId = ligne.produit.target?.id;
          if (produitId != null) {
            ancienneQuantite[produitId] =
                (ancienneQuantite[produitId] ?? 0) + ligne.quantite;
          }
        }
      }

      // Calcul des différences pour les produits existants
      for (final ligne in _lignesFacture) {
        final produitId = ligne.produit.target?.id;
        if (produitId == null) continue;

        final nouvelleQuantite = ligne.quantite;
        final ancienneQte = ancienneQuantite[produitId] ?? 0;
        final difference = nouvelleQuantite - ancienneQte;

        if (difference != 0) {
          quantitesToAdjust[produitId] = difference;
        }
      }

      // Gestion des produits supprimés de la facture
      for (final entry in ancienneQuantite.entries) {
        final produitId = entry.key;
        final produitPresent = _lignesFacture.any(
          (ligne) => ligne.produit.target?.id == produitId,
        );

        if (!produitPresent) {
          quantitesToAdjust[produitId] = -(entry.value); // Restauration
        }
      }

      // 2. Vérification du stock
      for (final entry in quantitesToAdjust.entries) {
        final produitId = entry.key;
        final delta = entry.value;
        final produit = _objectBox.produitBox.get(produitId);

        if (produit == null || delta == 0) continue;

        final stockDisponible = produit.calculerStockTotal();

        // Vérifier suffisance pour les déductions
        if (delta > 0 && stockDisponible < delta) {
          throw StateError('Stock insuffisant pour ${produit.nom} '
              '(${stockDisponible.toStringAsFixed(2)} disponible vs ${delta.toStringAsFixed(2)} demandé)');
        }
      }

      // 3. Application des ajustements au stock
      for (final entry in quantitesToAdjust.entries) {
        final produitId = entry.key;
        final delta = entry.value;
        final approvisionnements = _objectBox.approvisionnementBox
            .query(Approvisionnement_.produit.equals(produitId))
            .order(Approvisionnement_.datePeremption)
            .build()
            .find();

        double remaining = delta.abs();

        for (final appro in approvisionnements) {
          if (remaining <= 0) break;

          final maxToTake = min(appro.quantite, remaining);

          if (delta > 0) {
            // Cas d'augmentation : soustraire du stock
            appro.quantite -= maxToTake;
            remaining -= maxToTake;
          } else {
            // Cas de diminution : restaurer le stock
            appro.quantite += maxToTake;
            remaining -= maxToTake;
          }

          _objectBox.approvisionnementBox.put(appro);
        }

        if (remaining > 0 && delta > 0) {
          // Stock insuffisant malgré vérification (race condition)
          throw StateError('Erreur de synchronisation de stock');
        }
      }

      // 4. Enregistrement de la facture
      if (_factureEnCours == null) {
        // Création nouvelle facture
        final nouvelleFacture = Document(
          type: 'vente',
          qrReference: 'REF${DateTime.now().millisecondsSinceEpoch}',
          impayer: _impayer,
          derniereModification: DateTime.now(),
          date: DateTime.now(),
        )..client.target = _selectedClient;

        nouvelleFacture.lignesDocument.addAll(_lignesFacture);

        _objectBox.factureBox.put(nouvelleFacture);
        for (final ligne in _lignesFacture) {
          ligne.facture.target = nouvelleFacture;
          _objectBox.ligneFacture.put(ligne);
        }
        _facturesList.add(nouvelleFacture);
      } else {
        // Mise à jour facture existante
        _factureEnCours!
          ..lignesDocument.clear()
          ..lignesDocument.addAll(_lignesFacture)
          ..impayer = _impayer
          ..client.target = _selectedClient;

        _objectBox.factureBox.put(_factureEnCours!);
        for (final ligne in _lignesFacture) {
          ligne.facture.target = _factureEnCours;
          _objectBox.ligneFacture.put(ligne);
        }
      }

      // 5. Nettoyage et mise à jour
      _factureEnCours = null;
      _factureEnEdition = null;
      _lignesFacture.clear();
      _impayer = 0.0;
      _selectedClient = null;

      // Mise à jour des données

      chargerFactures2(reset: true);
      commerceProvider.chargerProduits(reset: true);
      _chargerFacturesTotal();

      print('Facture sauvegardée avec succès');
      _isEditing = false;
      _hasChanges = false;
      clearImpayer();
      notifyListeners();
    } on StateError catch (e) {
      // Gestion des erreurs de stock
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Erreur de stock', style: TextStyle(color: Colors.red)),
          content: Text(e.message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      );
      rethrow;
    } catch (e, stack) {
      print('Erreur inattendue: $e\n$stack');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void annulerEdition() {
    _isEditing = false; // Désactiver l'état d'édition
    _hasChanges = false; // Réinitialiser l'état des modifications
    clearImpayer();
    notifyListeners();
  }

// Future<void> supprimerFacture(Document facture) async {
//   // Supprimer la facture de la base de données
//   _objectBox.factureBox.remove(facture.id);
//
//   // Supprimer les lignes de document associées
//   for (final ligne in facture.lignesDocument) {
//     _objectBox.ligneFacture.remove(ligne.id);
//   }
//
//   // Mettre à jour la liste des factures
//   _facturesList.remove(facture);
//
//   // Si la facture supprimée est la facture en cours, la réinitialiser
//   if (_factureEnCours?.id == facture.id) {
//     _factureEnCours = null;
//     _lignesFacture.clear();
//   }
//
//   // Notifier les listeners pour mettre à jour l'interface utilisateur
//   notifyListeners();
// }

  TextEditingController impayerController = TextEditingController();

  void clearImpayer() {
    impayerController.clear(); // Réinitialiser le champ de texte
    notifyListeners(); // Notifier les widgets pour mettre à jour l'affichage
  }

  @override
  void dispose() {
    impayerController.dispose();
    super.dispose();
  }

  Future<void> supprimerFacture(
      Document facture, CommerceProvider commerceProvider) async {
    try {
      // 🔄 Rétablir les quantités dans les approvisionnements
      for (final ligne in facture.lignesDocument) {
        final produitId = ligne.produit.target?.id;
        if (produitId == null) continue;

        double quantiteARetablir = ligne.quantite;

        // Récupérer les approvisionnements triés par date de péremption croissante
        final query = _objectBox.approvisionnementBox
            .query(Approvisionnement_.produit.equals(produitId))
          ..order(Approvisionnement_.datePeremption);
        final approvisionnements = query.build().find();

        for (final appro in approvisionnements) {
          if (quantiteARetablir <= 0) break;

          appro.quantite += quantiteARetablir;
          quantiteARetablir = 0; // Tout est rétabli ici

          // Mettre à jour l'approvisionnement dans la base de données
          _objectBox.approvisionnementBox.put(appro);
        }
      }

      // 🔴 Supprimer d'abord les lignes de document associées
      for (final ligne in facture.lignesDocument) {
        _objectBox.ligneFacture.remove(ligne.id);
      }

      // 🔴 Supprimer ensuite la facture
      _objectBox.factureBox.remove(facture.id);

      // 🔄 Mettre à jour la liste des factures après suppression
      _chargerFacturesTotal();
      // Mettre à jour la liste des factures
      _facturesList.remove(facture);
      // 🗑️ Si la facture supprimée est celle en cours, la réinitialiser
      if (_factureEnCours?.id == facture.id) {
        _factureEnCours = null;
        _lignesFacture.clear();
      }

      print('Facture supprimée avec succès et quantités rétablies');
      // 🔴 Notification pour mettre à jour les produits
      commerceProvider.chargerProduits(reset: true);
      _factureEnCours = null;
      _lignesFacture.clear();

      _factureEnEdition = null;

      _impayer = 0.0;
      _selectedClient = null;

      print('Facture sauvegardée avec succès');
      _isEditing = false;
      _hasChanges = false;
      clearImpayer();
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression de la facture: $e');
      rethrow;
    }
  }

  Future<void> supprimerToutesFactures(
      CommerceProvider commerceProvider) async {
    try {
      // 1. Récupérer toutes les factures
      final factures = _objectBox.factureBox.getAll();

      // 2. Pour chaque facture, restaurer les quantités de stock
      for (final facture in factures) {
        // Rétablir les quantités dans les approvisionnements
        for (final ligne in facture.lignesDocument) {
          final produitId = ligne.produit.target?.id;
          if (produitId == null) continue;

          double quantiteARetablir = ligne.quantite;

          // Récupérer les approvisionnements triés par date de péremption croissante
          final query = _objectBox.approvisionnementBox
              .query(Approvisionnement_.produit.equals(produitId))
            ..order(Approvisionnement_.datePeremption);
          final approvisionnements = query.build().find();

          for (final appro in approvisionnements) {
            if (quantiteARetablir <= 0) break;

            appro.quantite += quantiteARetablir;
            quantiteARetablir = 0; // Tout est rétabli ici

            // Mettre à jour l'approvisionnement dans la base de données
            _objectBox.approvisionnementBox.put(appro);
          }
        }

        // Supprimer toutes les lignes de document associées
        for (final ligne in facture.lignesDocument) {
          _objectBox.ligneFacture.remove(ligne.id);
        }
      }

      // 3. Supprimer toutes les factures d'un coup
      _objectBox.factureBox.removeAll();

      // 4. Mettre à jour l'interface utilisateur
      facturesList.clear();
      chargerFactures2(reset: true);
      _chargerFacturesTotal();
      _facturesList = [];
      _facturesList.clear();
      _factureEnCours = null;
      lignesFacture.clear();

      _factureEnEdition = null;

      _impayer = 0.0;
      _selectedClient = null;
      clearImpayer();
      print('Facture sauvegardée avec succès');
      _isEditing = false;
      _hasChanges = false;
      print('Toutes les factures ont été supprimées avec succès');

      // 5. Notification pour mettre à jour les produits
      commerceProvider.chargerProduits(reset: true);

      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression de toutes les factures: $e');
      rethrow;
    }
  }
// Future<void> supprimerFacture(Document facture) async {
//   try {
//     // Rétablir les quantités dans les approvisionnements
//     for (final ligne in facture.lignesDocument) {
//       final produitId = ligne.produit.target?.id;
//       if (produitId == null) continue;
//
//       double quantiteARetablir = ligne.quantite;
//
//       // Récupérer les approvisionnements triés par date de péremption croissante
//       final query = _objectBox.approvisionnementBox
//           .query(Approvisionnement_.produit.equals(produitId))
//         ..order(Approvisionnement_.datePeremption);
//
//       final approvisionnements = query.build().find();
//
//       // Répartir la quantité à rétablir sur plusieurs approvisionnements si nécessaire
//       for (final appro in approvisionnements) {
//         if (quantiteARetablir <= 0) break;
//
//         // On rétablit la quantité dans l'approvisionnement le plus ancien
//         appro.quantite += quantiteARetablir;
//         quantiteARetablir = 0;
//
//         // Mettre à jour l'approvisionnement dans la base de données
//         _objectBox.approvisionnementBox.put(appro);
//       }
//     }
//
//     // Supprimer la facture de la base de données
//     _objectBox.factureBox.remove(facture.id);
//
//     // Supprimer les lignes de document associées
//     for (final ligne in facture.lignesDocument) {
//       _objectBox.ligneFacture.remove(ligne.id);
//     }
//
//     // Mettre à jour la liste des factures
//     _facturesList.remove(facture);
//
//     // Si la facture supprimée est la facture en cours, la réinitialiser
//     if (_factureEnCours?.id == facture.id) {
//       _factureEnCours = null;
//       _lignesFacture.clear();
//     }
//
//     print('Facture supprimée avec succès et quantités rétablies');
//     notifyListeners();
//   } catch (e) {
//     print('Erreur lors de la suppression de la facture: $e');
//     rethrow;
//   }
// }
}

class LigneEditionState {
  bool isEditedQty = false;
  bool isEditedImpayer = false;
  bool isEditedPu = false;
}

class EditableFieldProvider with ChangeNotifier {
  bool _isEditable = false;

  bool get isEditable => _isEditable;

  bool _hasChanges = false;

  bool get hasChanges => _hasChanges;

//   bool _hasChanges =
//       false; // Pour suivre si des modifications ont été apportées
//
//   bool get hasChanges => _hasChanges;
//
// // Ajoutez un champ pour gérer l'impayé
//   double _impayer = 0.0;
//
//   double get impayer => _impayer;
//
//   void setImpayer(double value) {
//     _impayer = value;
//     // _isEditing = true;
//     _hasChanges = true;
//     notifyListeners();
//   }
  void AlwaystoggleEditable() {
    _isEditable = false;
    print('isEditable: $_isEditable'); // Ajout de log
    notifyListeners();
  }

  void toggleEditable() {
    _isEditable = !_isEditable;
    print('isEditable: $_isEditable'); // Ajout de log
    notifyListeners();
  }
}

/// Extension on DateTime to standardize date handling
extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

/// Response class for paginated results
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : hasNextPage = (currentPage + 1) * pageSize < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Filter options for document queries
class DocumentFilterOptions {
  final String? searchQuery;
  final DateTimeRange? dateRange;
  final DocumentEtat? etat;
  final String? type;
  final bool? isSynced;

  DocumentFilterOptions({
    this.searchQuery,
    this.dateRange,
    this.etat,
    this.type,
    this.isSynced,
  });
}

class ConnectionStatusProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isBlocked = false;
  Duration _offlineDuration = Duration.zero;
  Timer? _timer;

  bool get isOnline => _isOnline;

  bool get isBlocked => _isBlocked;

  String get remainingTime => _formatRemainingTime();

  Duration get offlineDuration => _offlineDuration;

  ConnectionStatusProvider() {
    _init();
  }

  Future<void> _init() async {
    await checkInternetConnection();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await checkInternetConnection();
      notifyListeners();
    });
  }

  Future<void> checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final prefs = await SharedPreferences.getInstance();

    if (connectivityResult == ConnectivityResult.none) {
      final lastOnline = prefs.getString('lastOnlineCheck');
      if (lastOnline != null) {
        _offlineDuration =
            DateTime.now().difference(DateTime.parse(lastOnline));
        _isBlocked = _offlineDuration.inDays >= 2;
      }
      _isOnline = false;
    } else {
      await prefs.setString(
          'lastOnlineCheck', DateTime.now().toIso8601String());
      _isOnline = true;
      _isBlocked = false;
      _offlineDuration = Duration.zero;
    }
  }

  String _formatRemainingTime() {
    if (_isOnline) return "Connecté";
    final remaining = Duration(days: 2) - _offlineDuration;
    return remaining.isNegative
        ? "Blocage actif"
        : "${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
