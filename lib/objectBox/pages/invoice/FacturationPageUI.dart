import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
// import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart' as intl;
import 'package:kenzy/objectBox/Entity.dart';
import 'package:kenzy/objectBox/pages/ProduitListScreen.dart';
import 'package:lottie/lottie.dart';
import 'package:marqueer/marqueer.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';
import 'package:url_launcher/url_launcher.dart';

// import 'package:webfeed_plus/domain/rss_feed.dart';
import '../../MyProviders.dart';
import '../../Utils/mobile_scanner/barcode_scanner_window.dart';
import '../../firebase/AddCarouselButton.dart';
import '../../firebase/ItemsCarousel.dart';
import '../ClientListScreen.dart';
import '../addProduct.dart';
import 'providers.dart';

///23/02/2025 16:45///
class FacturationPageUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'POS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              '${intl.DateFormat('EEE dd MMM yyyy - HH:mm', 'fr').format(DateTime.now()).capitalize}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          // WinMobile(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        icon: Icon(Icons.receipt_long, color: Colors.blue),
                        text: 'Détails',
                      ),
                      Tab(
                        icon: Icon(Icons.list, color: Colors.blue),
                        text: 'Liste',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        FactureDetail(),
                        FactureList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          // Pour les écrans moyens
          else if (constraints.maxWidth < 1200) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FactureDetail(),
                ),
                Expanded(
                  child: FactureList(),
                ),
              ],
            );
          }
          // Pour les grands écrans
          else {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(child: FactureDetail()),
                ),
                Expanded(
                  flex: 1,
                  child: FactureList(),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class FactureDetail extends StatefulWidget {
  @override
  State<FactureDetail> createState() => _FactureDetailState();
}

class _FactureDetailState extends State<FactureDetail> {
  final TextEditingController _rechercheController = TextEditingController();

  // final TextEditingController _impayerController =
  //     TextEditingController(text: '0');
  /// si l yaun probleme dans impayerProvider.impayerController je dois tout remettre a _impayerController
  String _barcodeBuffer = '';
  final TextEditingController _barcodeBufferController =
      TextEditingController();
  late Stream<List<MarqueeData>> _marqueeDataStream;
  final MarqueerController _controller = MarqueerController();

  @override
  void initState() {
    super.initState();

    // _marqueeDataStream =
    //     RssService.fetchMarqueeData('https://www.echoroukonline.com/feed');
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    //_impayerController.dispose();
    _barcodeBufferController.dispose();

    // Nettoyer le contrôleur pour éviter les fuites de mémoire
    // _impayerController.removeListener(_updateDisplayText);
    super.dispose();
  }

  // void _initializeMarqueeData() {
  //   _marqueeDataStream = Supabase.instance.client
  //       .from('marquee')
  //       .stream(primaryKey: ['id'])
  //       .order('created_at', ascending: false)
  //       .map((event) => event.map((row) => MarqueeData.fromMap(row)).toList());
  // }

  Widget build(BuildContext context) {
    // final provider = Provider.of<FacturationProvider>(context);
    // // Mettez à jour l'impayerController lorsque la facture change
    // if (provider.factureEnCours != null) {
    //   _impayerController.text = provider.impayer.toStringAsFixed(2);
    // }
    final impayerProvider = Provider.of<FacturationProvider>(context);

    return Consumer2<FacturationProvider, CommerceProvider>(
        builder: (context, factureProvider, commerceProvider, child) {
      // Update impayer controller when invoice changes
      if (factureProvider.factureEnCours != null) {
        impayerProvider.impayerController.text =
            factureProvider.impayer.toStringAsFixed(2);
      }
      return Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: ProductSearchBar(
                            // commerceProvider: commerceProvider,
                            // cartProvider: cartProvider,
                            barcodeBuffer: _barcodeBuffer,
                            barcodeBufferController: _barcodeBufferController),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddMarqueeDialog(context),
                      icon: const Icon(Icons.add),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    // StreamBuilder<List<MarqueeData>>(
                    //   stream: _marqueeDataStream,
                    //   initialData: const [],
                    //   builder: (context, snapshot) {
                    //     if (snapshot.connectionState ==
                    //         ConnectionState.waiting) {
                    //       return const Center(
                    //           child: CircularProgressIndicator());
                    //     }
                    //     if (snapshot.hasError) {
                    //       return Center(
                    //           child: Text('Erreur: ${snapshot.error}'));
                    //     }
                    //     if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    //       return const Center(child: Icon(Icons.error_outline));
                    //     }
                    //
                    //     return MarqueeWidget(
                    //         marqueeData: snapshot.data!,
                    //         controller: _controller);
                    //   },
                    // ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClientInfos(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TTC(
                        totalAmount: factureProvider.calculerTotalHT(),
                        localImpayer: double.tryParse(
                                impayerProvider.impayerController.text) ??
                            0.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: factureProvider.factureEnCours == null
                          ? SizedBox.shrink()
                          : TotalDetail(
                              totalAmount: factureProvider.calculerTotalHT(),
                              localImpayer: double.tryParse(
                                      impayerProvider.impayerController.text) ??
                                  0.0,
                              facture: factureProvider.factureEnCours!),
                    ),
                    factureProvider.lignesFacture.isEmpty
                        ? SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: EditableField(
                              initialValue: factureProvider.impayer,
                              impayerController:
                                  impayerProvider.impayerController,
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: factureProvider.lignesFacture.isEmpty
                                ? null
                                : () {
                                    factureProvider.sauvegarderFacture(
                                        context, commerceProvider);
                                    //   .creerNouvelleFacture(); // Crée une nouvelle facture
                                    impayerProvider.impayerController.clear();
                                    _rechercheController.clear();
                                    context
                                        .read<EditableFieldProvider>()
                                        .AlwaystoggleEditable();
                                  },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            label: Text('Nouvelle'),
                            icon: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Icon(Icons.add),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: factureProvider.lignesFacture.isEmpty
                                ? null
                                : () {
                                    factureProvider.sauvegarderFacture(
                                        context, commerceProvider);
                                    impayerProvider.impayerController.clear();
                                    context
                                        .read<EditableFieldProvider>()
                                        .AlwaystoggleEditable();
                                  },
                            style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            label: Text('Sauvegarder'),
                            icon: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Icon(Icons.save),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: factureProvider.lignesFacture.length,
                      itemBuilder: (context, index) {
                        final ligne = factureProvider.lignesFacture[index];
                        //final produit = commerceProvider.produits[index];
                        final produit = commerceProvider.produits.firstWhere(
                          (p) => p.id == ligne.produit.target?.id,
                        );
                        final stockRestant = produit.approvisionnements
                            .fold<double>(
                                0,
                                (previousValue, appro) =>
                                    previousValue + appro.quantite);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Slidable(
                            key: ValueKey(ligne),
                            // Use a unique key for each Slidable
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (context) async {
                                    bool? confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Confirmation"),
                                        content: Text(
                                            "Voulez-vous vraiment supprimer cette ligne de facture ?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            // Annuler
                                            child: Text("Non"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            // Confirmer
                                            child: Text("Oui"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      factureProvider.supprimerLigne(
                                          index); // Suppression confirmée
                                    }
                                  },
                                  backgroundColor: Color(0xFFFE4A49),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                ),
                              ],
                            ),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    _showEditDialog(
                                        context,
                                        ligne,
                                        factureProvider,
                                        commerceProvider,
                                        index);
                                  },
                                  backgroundColor: Color(0xFF0392CF),
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 0),
                              dense: true,
                              isThreeLine: true,
                              leading: CircleAvatar(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FittedBox(
                                    child: Text(ligne.quantite.truncate() ==
                                            ligne.quantite
                                        ? '${ligne.quantite.truncate()}'
                                        : '${ligne.quantite.toStringAsFixed(2)}'),
                                  ),
                                ),
                              ),
                              title: Text(
                                ligne.produit.target?.nom ?? 'Produit inconnu',
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                  'PU: ${formatManualPrice(ligne.prixUnitaire)}'),
                              trailing: FittedBox(
                                child: Text(
                                  '${formatManualPrice(ligne.quantite * ligne.prixUnitaire)}',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              } else {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: ProductSearchBar(
                                // commerceProvider: commerceProvider,
                                // cartProvider: cartProvider,
                                barcodeBuffer: _barcodeBuffer,
                                barcodeBufferController:
                                    _barcodeBufferController),
                          ),
                          IconButton(
                            onPressed: () => _showAddMarqueeDialog(context),
                            icon: const Icon(Icons.add),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          // Expanded(
                          //   child: StreamBuilder<List<MarqueeData>>(
                          //     stream: _marqueeDataStream,
                          //     initialData: const [],
                          //     builder: (context, snapshot) {
                          //       if (snapshot.connectionState ==
                          //           ConnectionState.waiting) {
                          //         return const Center(
                          //             child: CircularProgressIndicator());
                          //       }
                          //       if (snapshot.hasError) {
                          //         return
                          //             // IconButton(
                          //             //   onPressed: () => _initializeMarqueeData(),
                          //             //   icon: Icon(Icons.refresh));
                          //             Center(
                          //                 child: FittedBox(
                          //                     child: Text(
                          //                         'Erreur: ${snapshot.error}')));
                          //       }
                          //       if (!snapshot.hasData ||
                          //           snapshot.data!.isEmpty) {
                          //         return const Center(
                          //             child: Icon(Icons.error_outline));
                          //       }
                          //       return MarqueeWidget(
                          //           marqueeData: snapshot.data!,
                          //           controller: _controller);
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(flex: 4, child: ClientInfos()),
                          Expanded(
                            flex: 5,
                            child: TTC(
                              totalAmount: factureProvider.calculerTotalHT(),
                              localImpayer: double.tryParse(
                                      impayerProvider.impayerController.text) ??
                                  0.0,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TotalDetail(
                                totalAmount: factureProvider.calculerTotalHT(),
                                localImpayer: double.tryParse(impayerProvider
                                        .impayerController.text) ??
                                    0.0,
                                facture: factureProvider.factureEnCours),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Spacer(
                              flex: 1,
                            ),
                            Expanded(
                              flex: 5,
                              child: factureProvider.lignesFacture.isEmpty
                                  ? SizedBox.shrink()
                                  : EditableField(
                                      initialValue: factureProvider.impayer,
                                      impayerController:
                                          impayerProvider.impayerController,
                                    ),
                            ),
                            Spacer(
                              flex: 2,
                            ),
                            ElevatedButton.icon(
                              onPressed: factureProvider.lignesFacture.isEmpty
                                  ? null
                                  : () {
                                      //  factureProvider.estEnEdition(facture);
                                      factureProvider.sauvegarderFacture(
                                          context, commerceProvider);
                                      // .creerNouvelleFacture(); // Crée une nouvelle facture
                                      impayerProvider.impayerController.clear();
                                      _rechercheController.clear();
                                      context
                                          .read<EditableFieldProvider>()
                                          .AlwaystoggleEditable();
                                    },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              label: Text('Nouvelle Facture'),
                              icon: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Icon(Icons.add),
                              ),
                            ),
                            Spacer(
                              flex: 2,
                            ),
                            ElevatedButton.icon(
                              onPressed: factureProvider
                                          .lignesFacture.isEmpty ||
                                      !factureProvider.hasChanges
                                  ? null
                                  : () {
                                      factureProvider.sauvegarderFacture(
                                          context, commerceProvider);
                                      impayerProvider.impayerController.clear();
                                      context
                                          .read<EditableFieldProvider>()
                                          .AlwaystoggleEditable();
                                    },
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              label: Text('Sauvegarder la facture'),
                              icon: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Icon(Icons.save),
                              ),
                            ),
                            Spacer(
                              flex: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        width: double.infinity,
                        child: DataTable(
                          columnSpacing: 24,
                          // Couleur de l'entête
                          // dataRowColor:
                          //     WidgetStateProperty.resolveWith<Color?>(
                          //   (Set<WidgetState> states) {
                          //     // Alternance des couleurs des lignes
                          //     if (states.contains(WidgetState.selected)) {
                          //       return Colors.grey.shade300;
                          //     }
                          //     return null; // Couleur par défaut
                          //   },
                          //),
                          headingRowColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.primaryContainer,
                          ),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer;
                              }
                              return null; // Couleur par défaut
                            },
                          ),
                          showBottomBorder: true,
                          columns: [
                            DataColumn(
                              label: Container(
                                //color: Colors.greenAccent,
                                width: 20, // Largeur fixe pour QR
                                child: Text('QR', textAlign: TextAlign.start),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                //   color: Colors.red,
                                width: 120, // Largeur fixe pour Produit
                                child:
                                    Text('Produit', textAlign: TextAlign.start),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                //   color: Colors.yellow,
                                width: 100,
                                // Largeur fixe pour Quantité
                                child: Text('Quantité',
                                    textAlign: TextAlign.center),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                //   color: Colors.blue,
                                width: 60, // Largeur fixe pour Quantité
                                child: Text('S.Restant',
                                    textAlign: TextAlign.center),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                //     color: Colors.red,
                                width: 50, // Largeur fixe pour Prix
                                child:
                                    Text('Prix U', textAlign: TextAlign.start),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                //      color: Colors.brown,
                                width: 50, // Largeur fixe pour Total
                                child:
                                    Text('Total', textAlign: TextAlign.start),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                //      color: Colors.green,
                                width: 50, // Largeur fixe pour Actions
                                child: Text('', textAlign: TextAlign.start),
                              ),
                            ),
                          ],
                          rows: factureProvider.lignesFacture.map((ligne) {
                            final index =
                                factureProvider.lignesFacture.indexOf(ligne);
                            final state =
                                factureProvider.getLigneEditionState(index);
                            // final stockRestant = ligne.produit.target
                            //         ?.calculerStockTotal() ??
                            //     0.0;
                            // Calculer le total des quantités des approvisionnements***
                            // final produit =
                            //     commerceProvider.produits[index];
                            final produit =
                                commerceProvider.produits.firstWhere(
                              (p) => p.id == ligne.produit.target?.id,
                            );

                            final stockRestant = produit.approvisionnements
                                .fold<double>(
                                    0,
                                    (previousValue, appro) =>
                                        previousValue + appro.quantite);

                            return DataRow(
                              // color: WidgetStateProperty.resolveWith<Color?>(
                              //   (Set<WidgetState> states) {
                              //     // Alternance des couleurs : grise et transparente
                              //     return index.isEven
                              //         ? null
                              //         : Colors.grey.shade200;
                              //   },
                              // ),
                              color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  // Alternance des couleurs : surface et surfaceVariant
                                  return index.isEven
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest;
                                },
                              ),
                              cells: [
                                DataCell(SizedBox(
                                  width: 50,
                                  child: SelectableText(
                                      maxLines: 1,
                                      ligne.produit.target?.qr ?? ' - '),
                                )),
                                DataCell(SizedBox(
                                  width: 150,
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (ctx) => ProduitDetailPage(
                                                produit:
                                                    ligne.produit.target!))),
                                    child: Text(
                                      ligne.produit.target?.nom ??
                                          'Produit inconnu',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove),
                                        onPressed: () {
                                          // Assurez-vous que la quantité ne devient pas négative
                                          final nouvelleQuantite = max(
                                                  ligne.quantite - 1, 0)
                                              .toDouble(); // Exemple de validation
                                          // print(
                                          //     'nouvelleQuantite : $nouvelleQuantite');
                                          factureProvider.modifierLigne(
                                              index,
                                              nouvelleQuantite,
                                              ligne.prixUnitaire);
                                          // Décrémente la quantité
                                          // factureProvider.modifierLigne(
                                          //   index,
                                          //   ligne.quantite - 1,
                                          //   ligne.prixUnitaire,
                                          // );
                                        },
                                      ),
                                      Text(ligne.quantite.toStringAsFixed(2)),
                                      IconButton(
                                        icon: Icon(Icons.add),
                                        onPressed: () {
                                          final produitId =
                                              ligne.produit.target?.id;
                                          if (produitId == null) return;

                                          // 1. Récupérer les données nécessaires

                                          final originalQuantity =
                                              factureProvider
                                                  .getOriginalQuantity(
                                                      produitId);
                                          final currentQuantity =
                                              ligne.quantite;

                                          // 2. Calculer la quantité maximale autorisée
                                          final maxAllowed =
                                              originalQuantity + stockRestant;

                                          // 3. Calculer la nouvelle quantité avec la limite
                                          final nouvelleQuantite = min(
                                                  currentQuantity + 1,
                                                  maxAllowed)
                                              .toDouble();

                                          // 4. Mettre à jour la ligne
                                          factureProvider.modifierLigne(
                                            index,
                                            nouvelleQuantite,
                                            ligne.prixUnitaire,
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                DataCell(Text(
                                    (stockRestant ?? 0).toStringAsFixed(2))),
                                DataCell(
                                  Text(
                                    formatManualPrice(ligne.prixUnitaire),
                                    textAlign: TextAlign.end,
                                  ),

                                  //     onTap: () {
                                  //   provider.toggleEditPu(index);
                                  // }, showEditIcon: true
                                ),
                                DataCell(Text(
                                  formatManualPrice(
                                      ligne.quantite * ligne.prixUnitaire),
                                  textAlign: TextAlign.end,
                                )),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          factureProvider.supprimerLigne(index);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditDialog(
                                              context,
                                              ligne,
                                              factureProvider,
                                              commerceProvider,
                                              index);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      );
    });
  }

  void _showEditDialog(
      BuildContext context,
      LigneDocument ligne,
      FacturationProvider provider,
      CommerceProvider commerceProvider,
      int index) {
    final _formKey = GlobalKey<FormState>();

    // Controllers pour récupérer les valeurs
    final TextEditingController prixVenteController = TextEditingController(
      text: ligne.prixUnitaire.toStringAsFixed(2),
    );
    final TextEditingController quantiteController = TextEditingController(
      text: ligne.quantite.toStringAsFixed(2),
    );

    // Calcul du prix d'achat moyen
    final double prixAchat =
        (ligne.produit.target?.approvisionnements.isNotEmpty == true)
            ? ligne.produit.target!.approvisionnements
                    .map((a) => a.prixAchat ?? 0)
                    .reduce((a, b) => a + b) /
                ligne.produit.target!.approvisionnements.length
            : 0.0;

    // Récupérer le produit et le stock restant initial
    final produit = commerceProvider.produits.firstWhere(
      (p) => p.id == ligne.produit.target?.id,
    );

    double stockRestantVIrtuel = produit.approvisionnements.fold<double>(
        0, (previousValue, appro) => previousValue + appro.quantite);

    double stockRestantReel = produit.approvisionnements.fold<double>(
        0, (previousValue, appro) => previousValue + appro.quantite);

    // Fonction pour mettre à jour dynamiquement le stock
    void updateStockRestant(String value) {
      final quantite = double.tryParse(value) ?? 0.0;
      stockRestantVIrtuel = produit.approvisionnements.fold<double>(
              0, (previousValue, appro) => previousValue + appro.quantite) +
          ligne
              .quantite - // Réajuster l'ancienne quantité pour éviter un double comptage
          quantite;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier la Quantité ou Prix'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Prix Minimal: ${formatManualPrice(prixAchat)} DZD',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Text(
                      'Quantité Restante: ${(stockRestantVIrtuel).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    // Text(
                    //   'StockRestantReel: ${stockRestantReel.toStringAsFixed(2)}',
                    //   style: const TextStyle(fontSize: 20),
                    // ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: prixVenteController,
                      decoration:
                          const InputDecoration(labelText: 'Prix de vente'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final prixVente = double.tryParse(value ?? '');
                        if (prixVente == null || prixVente < prixAchat) {
                          return 'Le prix de vente doit être ≥ ${prixAchat.toStringAsFixed(2)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: quantiteController,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          updateStockRestant(value);
                        });
                      },
                      validator: (value) {
                        final quantite = double.tryParse(value ?? '') ?? 0.0;
                        final quantiteControllerDouble =
                            double.tryParse(quantiteController.text ?? '') ??
                                0.0;
                        if (quantite <= 0 ||
                            quantite >
                                (stockRestantVIrtuel +
                                    quantiteControllerDouble)) {
                          return 'La quantité doit être > 0 et ≤ ${(stockRestantVIrtuel + quantiteControllerDouble).toStringAsFixed(2)}';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final prixVente =
                          double.tryParse(prixVenteController.text);
                      final quantite =
                          double.tryParse(quantiteController.text) ?? 0.0;

                      if (prixVente == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Veuillez saisir un prix valide')),
                        );
                        return;
                      }

                      provider.modifierLigne(index, quantite, prixVente);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

//////
  void _showAddMarqueeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMarqueeDialog(),
    );
  }
}

class TotalFactures extends StatelessWidget {
  final List<Document> factures;

  const TotalFactures({required this.factures});

  @override
  Widget build(BuildContext context) {
    final total =
        factures.fold(0.0, (sum, facture) => sum + facture.montantTotal);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Total: ${total.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////

class FactureList extends StatefulWidget {
  @override
  _FactureListState createState() => _FactureListState();
}

class _FactureListState extends State<FactureList> {
  final ScrollController _scrollController = ScrollController();
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Create the ad objects and load ads.
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-2282149611905342/2166057043',
      request: AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          // print('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          //     print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
        // onAdOpened: (Ad ad) => print('$NativeAd onAdOpened.'),
        // onAdClosed: (Ad ad) => print('$NativeAd onAdClosed.'),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white12,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black38,
          backgroundColor: Colors.white70,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    super.dispose();
    _nativeAd?.dispose();
    _scrollController.dispose();
  }

  void _onScroll() {
    // print("🎯 Position actuelle : ${_scrollController.position.pixels}");
    // print(
    //     "🎯 Position maximale : ${_scrollController.position.maxScrollExtent}");

    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      //  print("📜 Début du chargement des factures supplémentaires...");
      Provider.of<FacturationProvider>(context, listen: false)
          .chargerFactures2();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.maybeOf(context);

    return Scaffold(
      body: Consumer2<FacturationProvider, CommerceProvider>(
        builder: (context, factureProvider, commerceProvider, child) {
          // print(
          //     "📊 Nombre de factures dans la liste : ${factureProvider
          //         .facturesList.length}");
          // print("🔄 _hasMoreFactures : ${factureProvider.hasMoreFactures}");

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: CarouselBanner(),
              ),
              Expanded(
                  flex: 2,
                  child: Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => CarouselForm(),
                                )),
                            child: Text('Ajouter Carousel')),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            '${factureProvider.totalfactures.length} Factures'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Afficher une boîte de dialogue de confirmation
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Confirmer la suppression'),
                              content: Text(
                                  'Voulez-vous vraiment supprimer cette facture?'),
                              actions: [
                                TextButton(
                                  child: Text('Annuler'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text('Supprimer'),
                                  onPressed: () {
                                    // Appeler votre fonction de suppression
                                    factureProvider.supprimerToutesFactures(
                                        commerceProvider);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )),
              // Flexible(
              //   child: // Remplacez l'ancien Text par :
              //       Padding(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              //     child: Text.rich(
              //       TextSpan(
              //         children: [
              //           TextSpan(
              //               text:
              //                   'HT: ${factureProvider.totalHT.toStringAsFixed(2)}  |  '),
              //           TextSpan(
              //               text:
              //                   'TVA: ${factureProvider.totalTVA.toStringAsFixed(2)}  |  '),
              //           TextSpan(
              //             text:
              //                 'Impayés: ${factureProvider.totalImpayer.toStringAsFixed(2)}\n',
              //             style: TextStyle(color: Colors.red),
              //           ),
              //           TextSpan(
              //               text:
              //                   'Total TTC: ${factureProvider.totalMontant.toStringAsFixed(2)} DZD  |  '),
              //           TextSpan(
              //             text:
              //                 'Bénéfice: ${intl.NumberFormat.currency(locale: 'fr_FR', symbol: 'DZD').format(factureProvider.totalBenefice)}\n',
              //             style: TextStyle(color: Colors.green),
              //           ),
              //         ],
              //         style: TextStyle(fontSize: 14),
              //       ),
              //       textAlign: TextAlign.start,
              //     ),
              //   ),
              // ),
              Flexible(
                flex: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoCard(null, 'HT', factureProvider.totalHT,
                                Colors.white70, Icons.attach_money),
                            _buildInfoCard(
                                'https://picsum.photos/200/300?random=5',
                                'Bénéfice',
                                factureProvider.totalBenefice,
                                Colors.white70,
                                Icons.monetization_on),
                            _buildInfoCard(
                                'https://picsum.photos/200/300?random=3',
                                'Impayés',
                                factureProvider.totalImpayer,
                                Colors.white70,
                                Icons.warning),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildInfoCard(
                                'https://picsum.photos/200/300?random=2',
                                'TVA',
                                factureProvider.totalTVA,
                                Colors.white70,
                                Icons.percent),
                            _buildInfoCard(
                                'https://picsum.photos/200/300?random=4',
                                'Total TTC',
                                factureProvider.totalMontant * 1.19,
                                Colors.white70,
                                Icons.calculate),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              factureProvider.facturesList.isEmpty
                  ? Expanded(
                      flex: 10,
                      child: Center(child: Text("Aucune facture disponible.")))
                  : Expanded(
                      flex: 10,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: factureProvider.facturesList.length,
                        itemBuilder: (context, index) {
                          if (index != 0 &&
                              index % 5 == 0 &&
                              _nativeAd != null &&
                              _nativeAdIsLoaded) {
                            return Align(
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 300,
                                    minHeight: 350,
                                    maxHeight: 400,
                                    maxWidth: 450,
                                  ),
                                  child: AdWidget(ad: _nativeAd!),
                                ));
                          }
                          if (index < factureProvider.facturesList.length) {
                            final facture =
                                factureProvider.facturesList.toList()[index];
                            bool estEnEdition =
                                factureProvider.estEnEdition(facture);
                            final isEditing = factureProvider.isEditing;
                            final hasChanges = factureProvider.hasChanges;
                            return Column(
                              children: [
                                Card(
                                  color: estEnEdition
                                      ? Colors.green.shade100
                                      : null,
                                  child: ListTile(
                                    onTap: () {
                                      // if (factureProvider.factureEnEdition!
                                      //     .lignesDocument.isEmpty) {
                                      //   factureProvider.supprimerFacture(
                                      //       facture, commerceProvider);
                                      // }

                                      if (isEditing && hasChanges) {
                                        print('voulez vous sauegarder?');

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Confirmation"),
                                              content: const Text(
                                                  "Voulez-vous sauvegarder les modifications ?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    factureProvider
                                                        .selectionnerFacture(
                                                            facture);
                                                    factureProvider
                                                        .commencerEdition(
                                                            facture);

                                                    tabController?.animateTo(0);
                                                    Navigator.of(context)
                                                        .pop(true);
                                                  },
                                                  // Fermer le dialogue
                                                  child: const Text("Annuler"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    factureProvider
                                                        .sauvegarderFacture(
                                                            context,
                                                            commerceProvider);
                                                    factureProvider
                                                        .clearImpayer(); // Réinitialiser le champ de texte
                                                    Navigator.of(context)
                                                        .pop(); // Fermer le dialogue après action
                                                  },
                                                  child:
                                                      const Text("Sauvegarder"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        if (factureProvider
                                            .estEnEdition(facture)) {
                                          factureProvider.terminerEdition();
                                          print('terminate');
                                        } else {
                                          factureProvider
                                              .selectionnerFacture(facture);
                                          factureProvider
                                              .commencerEdition(facture);
                                          context
                                              .read<EditableFieldProvider>()
                                              .AlwaystoggleEditable();
                                          context
                                              .read<FacturationProvider>()
                                              .AlwaystoggleEdit(index);
                                          tabController?.animateTo(0);
                                        }
                                      }
                                    },
                                    onFocusChange: (hasFocus) {
                                      if (!hasFocus &&
                                          factureProvider
                                              .estEnEdition(facture)) {
                                        factureProvider.terminerEdition();
                                      }
                                    },
                                    onLongPress: () {
                                      factureProvider.supprimerFacture(
                                          facture, commerceProvider);
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: estEnEdition
                                          ? Colors.white70
                                          : Colors.green,
                                      child: estEnEdition
                                          ? (isEditing && hasChanges
                                              ? Icon(
                                                  FontAwesomeIcons.penToSquare,
                                                  color: Colors.orange)
                                              : Icon(FontAwesomeIcons.check,
                                                  color: Colors.green))
                                          : Icon(FontAwesomeIcons.check,
                                              color: Colors.white70),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          facture.qrReference,
                                          style: TextStyle(
                                            color: estEnEdition
                                                ? Colors
                                                    .black // Texte en noir si estEnEdition est true
                                                : Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors
                                                        .white // Texte en blanc en mode sombre
                                                    : Colors
                                                        .black, // Texte en noir en mode clair
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text.rich(
                                      overflow: TextOverflow.ellipsis,
                                      TextSpan(
                                        text: 'Client: ',
                                        style: TextStyle(
                                          color: estEnEdition
                                              ? Colors
                                                  .black // Texte en noir si estEnEdition est true
                                              : Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors
                                                      .white // Texte en blanc en mode sombre
                                                  : Colors
                                                      .black, // Texte en noir en mode clair
                                        ),
                                        children: [
                                          TextSpan(
                                            text: facture.client.target?.nom ??
                                                'Inconnu',
                                            style: facture.client.target != null
                                                ? TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.w400)
                                                : TextStyle(
                                                    color: estEnEdition
                                                        ? Colors
                                                            .black // Texte en noir si estEnEdition est true
                                                        : Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors
                                                                .white // Texte en blanc en mode sombre
                                                            : Colors
                                                                .black, // Texte en noir en mode clair
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: facture.impayer! > 0.0
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${facture.montantTotal.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: estEnEdition
                                                      ? Colors
                                                          .black // Texte en noir si estEnEdition est true
                                                      : Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors
                                                              .white // Texte en blanc en mode sombre
                                                          : Colors
                                                              .black, // Texte en noir en mode clair
                                                ),
                                              ),
                                              Text(
                                                '${facture.impayer!.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            '${facture.montantTotal.toStringAsFixed(2)}',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                  ),
                                ),
                                Text(
                                  intl.DateFormat(
                                          'EEE dd MMM yyyy  -  HH:mm', 'fr')
                                      .format(DateTime.parse(
                                          facture.date.toString()))
                                      .capitalize,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            );
                          } else if (factureProvider.hasMoreFactures) {
                            return Center(child: CircularProgressIndicator());
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

Widget _buildInfoCard(
    String? imageUrl, String label, double value, Color color, IconData icon) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Stack(
        children: [
          // Image en arrière-plan avec dégradé blanc
          imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    color: Colors.green,
                    height: 100,
                    width: double.infinity,
                  ),
                ),
          // Dégradé blanc en bas
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87.withOpacity(0.9)],
                ),
              ),
            ),
          ),
          // Contenu avec icône et texte
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    Icon(
                      icon,
                      color: color,
                    ),
                    FittedBox(
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  child: Text(
                    intl.NumberFormat.currency(locale: 'fr_FR', symbol: 'DZD')
                        .format(value),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
// class _FactureListState extends State<FactureList> {
//   final FacturationProvider _factureProvider = FacturationProvider();
//
//   @override
//   void initState() {
//     super.initState();
//     _factureProvider.chargerFactures(reset: true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<FacturationProvider>(context);
//     final tabController = DefaultTabController.maybeOf(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Liste des Factures'),
//       ),
//       body: NotificationListener<ScrollNotification>(
//         onNotification: (ScrollNotification scrollInfo) {
//           if (!_factureProvider.isLoadingListFacture &&
//               scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent &&
//               _factureProvider.hasMoreFactures) {
//             print("Déclenchement du chargement supplémentaire...");
//             _factureProvider.chargerFactures();
//           }
//           return false;
//         },
//         child: ListView.builder(
//           itemCount: provider.facturesList.length,
//           shrinkWrap: true,
//           itemBuilder: (context, index) {
//             final facture = provider.facturesList[index];
//             bool estEnEdition = provider.estEnEdition(facture);
//             final isEditing = provider.isEditing;
//             final hasChanges = provider.hasChanges;
//
//             return Column(
//               children: [
//                 Card(
//                   color: estEnEdition ? Colors.green.shade100 : null,
//                   child: ListTile(
//                     onLongPress: () => provider.supprimerFacture(facture),
//                     leading: CircleAvatar(
//                       backgroundColor:
//                           estEnEdition ? Colors.white70 : Colors.green,
//                       child: estEnEdition
//                           ? (isEditing && hasChanges
//                               ? Icon(FontAwesomeIcons.penToSquare,
//                                   color: Colors.orange)
//                               : Icon(FontAwesomeIcons.check,
//                                   color: Colors.green))
//                           : Icon(FontAwesomeIcons.check, color: Colors.white70),
//                     ),
//                     title: Text(facture.qrReference),
//                     subtitle: Text.rich(
//                       overflow: TextOverflow.ellipsis,
//                       TextSpan(
//                         text: 'Client: ',
//                         style: TextStyle(color: Colors.black),
//                         children: [
//                           TextSpan(
//                             text: facture.client.target?.nom ?? 'Inconnu',
//                             style: facture.client.target != null
//                                 ? TextStyle(
//                                     color: Colors.blue,
//                                     fontWeight: FontWeight.w400)
//                                 : TextStyle(color: Colors.black),
//                           ),
//                         ],
//                       ),
//                     ),
//                     onTap: () {
//                       provider.selectionnerFacture(facture);
//                       provider.commencerEdition(facture);
//                       context
//                           .read<EditableFieldProvider>()
//                           .AlwaystoggleEditable();
//                       context
//                           .read<FacturationProvider>()
//                           .AlwaystoggleEdit(index);
//                       tabController?.animateTo(0);
//                     },
//                     trailing: facture.impayer! > 0.0
//                         ? Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 '${facture.montantTotal.toStringAsFixed(2)}',
//                                 style: TextStyle(fontSize: 20),
//                               ),
//                               Text(
//                                 '${facture.impayer!.toStringAsFixed(2)}',
//                                 style: TextStyle(color: Colors.red),
//                               ),
//                             ],
//                           )
//                         : Text(
//                             '${facture.montantTotal.toStringAsFixed(2)}',
//                             style: TextStyle(fontSize: 20),
//                           ),
//                   ),
//                 ),
//                 Text(
//                   DateFormat('EEE dd MMM yyyy  -  HH:mm', 'fr')
//                       .format(DateTime.parse(facture.date.toString()))
//                       .capitalize(),
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w300,
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class FactureList extends StatelessWidget {
//   final TabController? tabController;
//
//   const FactureList({this.tabController});
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<FacturationProvider>(context);
//     final tabController = DefaultTabController.maybeOf(context);
//     return ListView.builder(
//       itemCount: provider.factures.length,
//       shrinkWrap: true,
//       itemBuilder: (context, index) {
//         final facture = provider.factures.reversed.toList()[index];
//         bool estEnEdition = provider.estEnEdition(facture);
//         final isEditing = provider.isEditing;
//         final hasChanges = provider.hasChanges;
//
//         return Column(
//           children: [
//             Card(
//               color: estEnEdition ? Colors.green.shade100 : null,
//               child: ListTile(
//                 onLongPress: () => provider.supprimerFacture(facture),
//                 leading: CircleAvatar(
//                     backgroundColor:
//                         estEnEdition ? Colors.white70 : Colors.green,
//                     child: estEnEdition
//                         ? (isEditing && hasChanges
//                             ? Icon(FontAwesomeIcons.penToSquare,
//                                 color: Colors.orange)
//                             : Icon(FontAwesomeIcons.check, color: Colors.green))
//                         : Icon(FontAwesomeIcons.check, color: Colors.white70)),
//                 title: Text(facture.qrReference),
//                 subtitle: Text.rich(
//                   overflow: TextOverflow.ellipsis,
//                   TextSpan(
//                     text: 'Client: ',
//                     style: TextStyle(color: Colors.black),
//                     children: [
//                       TextSpan(
//                         text: facture.client.target?.nom ?? 'Inconnu',
//                         style: facture.client.target != null
//                             ? TextStyle(
//                                 color: Colors.blue,
//                                 fontWeight: FontWeight.w400,
//                               )
//                             : TextStyle(
//                                 color: Colors.black,
//                               ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 onTap: () {
//                   provider.selectionnerFacture(facture);
//                   provider.commencerEdition(facture);
//                   context.read<EditableFieldProvider>().AlwaystoggleEditable();
//                   context.read<FacturationProvider>().AlwaystoggleEdit(index);
//                   context.read<FacturationProvider>().AlwaystoggleEdit(index);
//                   // Change to the detail tab
//                   tabController?.animateTo(0);
//                 },
//                 trailing: facture.impayer! > 0.0
//                     ? Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             '${facture.montantTotal.toStringAsFixed(2)}',
//                             style: TextStyle(fontSize: 20),
//                           ),
//                           Text(
//                             '${facture.impayer!.toStringAsFixed(2)}',
//                             style: TextStyle(color: Colors.red),
//                           )
//                         ],
//                       )
//                     : Text(
//                         '${facture.montantTotal.toStringAsFixed(2)}',
//                         style: TextStyle(fontSize: 20),
//                       ),
//               ),
//             ),
//             Text(
//               DateFormat('EEE dd MMM yyyy  -  HH:mm', 'fr')
//                   .format(DateTime.parse(facture.date.toString()))
//                   .capitalize(),
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w300,
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

class ClientSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);
    final clients = provider.getClients();

    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner un client'),
      ),
      body: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return ListTile(
            title: Text(client.nom),
            subtitle: Text(client.phone),
            onTap: () {
              provider.selectClient(client);
              Navigator.pop(context);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Naviguer vers la page de création de client
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CreateClientPage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class CreateClientPage extends StatefulWidget {
  @override
  _CreateClientPageState createState() => _CreateClientPageState();
}

class _CreateClientPageState extends State<CreateClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _qrController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un nouveau client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Téléphone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un téléphone';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _adresseController,
                decoration: InputDecoration(labelText: 'Adresse'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une adresse';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _qrController,
                decoration: InputDecoration(labelText: 'QR Code'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await provider.createClient(
                        _nomController.text,
                        _phoneController.text,
                        _adresseController.text,
                        _qrController.text,
                        DateTime.now());
                    Navigator.pop(context);
                  }
                },
                child: Text('Créer le client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientInfos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FacturationProvider>(context);
    final client =
        //    provider.factureEnCours?.client.target ??
        provider.selectedClient;
    final clientProvider = Provider.of<ClientProvider>(context);
    //List<Document> factures = clientProvider.getFacturesForClient(client!);
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => client != null
                  ? ClientDetailsPage(client: client)
                  : ClientSelectionPage(),
            ),
          );
        },
        onLongPress: () async {
          bool? confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Confirmation"),
              content: Text("Voulez-vous vraiment réinitialiser le client ?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false), // Annuler
                  child: Text("Non"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  // Confirmer
                  child: Text("Oui"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            provider.resetClient(); // Exécuter l'action si confirmé
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: client != null
              ? Row(
                  children: [
                    Container(
                      height: 130,
                      width: 130,
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: SfBarcodeGenerator(
                          value: client.qr ?? '',
                          symbology: QRCode(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client: ${client.nom.capitalize}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18),
                          ),
                          Divider(),
                          Text(
                            'Téléphone: ${client.phone}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Adresse: ${client.adresse.capitalize}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qr: ${client.qr}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Nombre de factures : ${clientProvider.getFacturesForClient(client).length}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Container(
                    height: 130,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Client non identifié...',
                          style: TextStyle(fontSize: 18),
                        ),
                        Lottie.asset(
                          'assets/lotties/1 (8).json',
                          // Chemin vers ton fichier Lottie
                          width: 200, // Ajuste la taille de l'erreur à 30%
                          height: 100,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class TTC extends StatelessWidget {
  const TTC({
    super.key,
    required this.totalAmount,
    required double localImpayer,
  }) : _localImpayer = localImpayer;

  final double totalAmount;

  final double _localImpayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green,
      child: Container(
        height: 146,
        child: Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                intl.NumberFormat.currency(
                  locale: 'fr_DZ', // Locale pour l'Algérie
                  symbol: '', // Symbole de la devise
                  decimalDigits: 2, // Nombre de décimales
                ).format(totalAmount - _localImpayer),
                style: TextStyle(
                    fontSize: 100,
                    color: Colors.white,
                    fontFamily: 'oswald',
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TotalDetail extends StatelessWidget {
  const TotalDetail({
    super.key,
    required this.totalAmount,
    required double localImpayer,
    required this.facture,
  }) : _localImpayer = localImpayer;

  final double totalAmount;

  final double _localImpayer;
  final double fontSize = 15;
  final Document? facture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 146,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(
                facture != null ? 'Invoice #${facture?.id}' : '',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            FittedBox(
              child: Text(
                facture != null
                    ? intl.DateFormat('EEE dd MMM yyyy - HH:mm', 'fr')
                        .format(facture!.date)
                        .capitalize
                    : '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15),
              ),
            ),
            Divider(),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: fontSize,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${formatManualPrice(totalAmount)}',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA(19%): ',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: fontSize,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${formatManualPrice(totalAmount * 0.19)}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total TTC: ',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: fontSize,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${formatManualPrice(totalAmount * 1.19)}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            _localImpayer > 0.9
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Impayés',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: fontSize,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${formatManualPrice(_localImpayer)}',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: fontSize,
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
            Spacer(),
          ],
        ),
      ),
    );
  }
}

class EditableField extends StatefulWidget {
  final double initialValue;
  final TextEditingController impayerController;

  EditableField({
    Key? key,
    required this.initialValue,
    required this.impayerController,
  }) : super(key: key);

  @override
  State<EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<EditableField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = context.watch<EditableFieldProvider>().isEditable;
    final provider = context.read<EditableFieldProvider>();
    final providerF = Provider.of<FacturationProvider>(context, listen: false);
    double totalHT = providerF.calculerTotalHT();
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isEditable ? Colors.grey : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Text('Impayé : '),
          Expanded(
            child: isEditable
                ? TextFormField(
                    // controller: impayerController,
                    // Added missing controller
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      prefixIcon: Transform.scale(
                        scale: 0.7,
                        child: IconButton(
                          icon: Icon(isEditable ? Icons.check : Icons.edit),
                          color: isEditable ? Colors.green : Colors.blue,
                          onPressed: () {
                            if (isEditable) {
                              final nouvelleValeur = double.tryParse(
                                      widget.impayerController.text) ??
                                  0.0;
                              providerF.modifierImpayer(nouvelleValeur);
                            }
                            provider.toggleEditable();
                          },
                        ),
                      ),
                      suffixIcon: Transform.scale(
                        scale: 0.7,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          color: Colors.red,
                          onPressed: () {
                            widget.impayerController
                                .clear(); // Vider le texte du champ
                            final nouvelleValeur = 0.0;

                            // Mettre à jour l'état du provider avec la nouvelle valeur
                            providerF.modifierImpayer(nouvelleValeur);
                            // final nouvelleValeur = double.tryParse(
                            //         widget.impayerController.text) ??
                            //     0.0;
                            //
                            // if (nouvelleValeur > totalHT) {
                            //   _showErrorDialog(context, totalHT);
                            //   widget.impayerController.text =
                            //       totalHT.toStringAsFixed(2);
                            // } else {
                            //   providerF.modifierImpayer(nouvelleValeur);
                            //   provider.toggleEditable();
                            // }
                          },
                        ),
                      ),
                    ),

                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      // final nouvelleImpayer = double.tryParse(value) ?? 0;
                      // providerF.modifierImpayer(nouvelleImpayer);
                      final nouvelleImpayer = double.tryParse(value) ?? 0.0;

                      if (nouvelleImpayer > totalHT) {
                        _showErrorDialog(context, totalHT);
                        widget.impayerController.text =
                            totalHT.toStringAsFixed(2);
                      } else {
                        providerF.modifierImpayer(nouvelleImpayer);
                      }
                    },
                  )
                : Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          widget.impayerController.text,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          iconSize: 18,
                          onPressed: () {
                            provider.toggleEditable();
                            _focusNode.requestFocus();
                          }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Affiche une boîte de dialogue d'erreur si la valeur dépasse `totalHT`
void _showErrorDialog(BuildContext context, totalHT) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 100),
          const SizedBox(height: 8),
          const Text(
            'Valeur invalide',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              child: Text('Le montant impayé ne peut pas dépasser'),
            ),
          ),
          Expanded(
            child: FittedBox(
              child: Text('${totalHT.toStringAsFixed(2)}'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
// class EditableField extends StatelessWidget {
//   double initialValue;
//   final TextEditingController impayerController;
//
//   EditableField({
//     required this.initialValue,
//     required this.impayerController,
//     Key? key,
//   }) : super(key: key) {
//     // Initialiser le contrôleur avec la valeur initiale
//     impayerController.text = initialValue.toStringAsFixed(2);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isEditable = context.watch<EditableFieldProvider>().isEditable;
//     final provider = context.read<EditableFieldProvider>();
//     final providerF = Provider.of<FacturationProvider>(context, listen: false);
//
//     return Container(
//       padding: EdgeInsets.all(8.0), // Espacement à l'intérieur du cadre
//       decoration: BoxDecoration(
//         //      color: Colors.grey, // Couleur de fond
//         borderRadius: BorderRadius.circular(8.0), // Bords arrondis
//         border: Border.all(
//           color: Colors.grey, // Couleur de la bordure
//           width: 1.0, // Épaisseur de la bordure
//         ),
//       ),
//       child: Row(
//         children: [
//           Text('Impayé :'),
//           Expanded(
//             child: isEditable
//                 ? TextFormField(
//                     //controller: impayerController,
//                     textAlign: TextAlign.center,
//                     decoration: InputDecoration(
//                       //  labelText: 'Impayé',
//                       prefixIcon: Transform.scale(
//                         scale: 0.7,
//                         // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
//                         child: IconButton(
//                           icon: Icon(isEditable ? Icons.check : Icons.edit),
//                           color: isEditable ? Colors.green : Colors.blue,
//                           onPressed: () {
//                             if (isEditable) {
//                               // Appliquer les modifications et mettre à jour la valeur dans le provider
//                               final nouvelleValeur =
//                                   double.tryParse(impayerController.text) ??
//                                       0.0;
//                               providerF.modifierImpayer(nouvelleValeur);
//                             }
//                             provider.toggleEditable();
//                           },
//                         ),
//                       ),
//                       suffixIcon: Transform.scale(
//                         scale: 0.7,
//                         // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
//                         child: IconButton(
//                           icon: Icon(Icons.close),
//                           color: Colors.red,
//                           onPressed: () {
//                             impayerController
//                                 .clear(); // Vider le texte du champ
//                             final nouvelleValeur = 0.0;
//
//                             // Mettre à jour l'état du provider avec la nouvelle valeur
//                             providerF.modifierImpayer(nouvelleValeur);
//                           },
//                         ),
//                       ),
//                       // border: OutlineInputBorder(
//                       //   borderRadius: BorderRadius.circular(8.0),
//                       //   borderSide: BorderSide.none,
//                       // ),
//                       //filled: true,
//                       //contentPadding: EdgeInsets.all(15),
//                     ),
//                     // initialValue: providerF.impayer.toStringAsFixed(2),
//                     keyboardType:
//                         TextInputType.numberWithOptions(decimal: true),
//                     onChanged: (value) {
//                       final nouvelleImpayer = double.tryParse(value) ?? 0;
//                       impayerController.text = value;
//                       providerF.modifierImpayer(nouvelleImpayer);
//                       print(nouvelleImpayer);
//                       print(impayerController.text);
//                     },
//                   )
//                 : TextField(
//                     readOnly: true,
//                     controller: impayerController,
//                     textAlign: TextAlign.end,
//                     decoration: InputDecoration(
//                       suffixIcon: Transform.scale(
//                         scale: 0.7,
//                         // Ajustez cette valeur pour modifier la taille (1.0 est la taille par défaut)
//                         child: IconButton(
//                           icon: Icon(Icons.edit),
//                           color: Colors.blue,
//                           onPressed: () {
//                             final nouvelleValeur =
//                                 double.tryParse(impayerController.text) ?? 0.0;
//                             // providerF.modifierImpayer(nouvelleValeur);
//
//                             provider.toggleEditable();
//                           },
//                         ),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: false,
//                       contentPadding: EdgeInsets.all(15),
//                     ),
//                     keyboardType:
//                         TextInputType.numberWithOptions(decimal: true),
//                     // Permet les nombres décimaux
//                     onChanged: (value) {
//                       // // Valider et formater la valeur saisie
//                       // final impayer = double.tryParse(value) ?? 0.0;
//                       //
//                       // providerF.setImpayer(
//                       //     impayer); // Mettre à jour l'impayer dans le provider
//                       final nouvelleImpayer = double.tryParse(value) ?? 0;
//                       providerF.modifierImpayer(nouvelleImpayer);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class ProductSearchBar extends StatefulWidget {
  const ProductSearchBar({
    Key? key,
    required this.barcodeBuffer,
    required this.barcodeBufferController,
  }) : super(key: key);

  final String barcodeBuffer;
  final TextEditingController barcodeBufferController;

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  @override
  Widget build(BuildContext context) {
    final commerceProvider = Provider.of<CommerceProvider>(context);
    final facturationProvider = Provider.of<FacturationProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ProductSearchField(
        widget.barcodeBufferController,
        (context, commerceProvider, cartProvider, enteredQuantity,
            lignesDocument) {
          _processBarcode(
            context,
            commerceProvider,
            facturationProvider,
            enteredQuantity,
            lignesDocument,
          );
        },
      ),
    );
  }

  void _processBarcode(
    BuildContext context,
    CommerceProvider commerceProvider,
    FacturationProvider facturationProvider,
    double enteredQuantity,
    List<LigneDocument> lignesDocument, // Ajout de ce paramètre
  ) async {
    if (widget.barcodeBuffer.isNotEmpty) {
      final produit =
          await commerceProvider.getProduitByQrFacture(widget.barcodeBuffer);

      if (produit == null) {
        _navigateToAddProductPage(
            context, commerceProvider, facturationProvider);
      } else {
        facturationProvider.ajouterProduitALaFacture(
            produit, enteredQuantity, produit.prixVente);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Produit ajouté : ${produit.nom}'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      }
    }
  }

  void _navigateToAddProductPage(
    BuildContext context,
    CommerceProvider commerceProvider,
    FacturationProvider facturationProvider,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            addProduct(), // Remplacez par votre page d'ajout de produit
      ),
    );

    if (result != null && result is Produit) {
      facturationProvider.ajouterProduitALaFacture(result, 1, result.prixVente);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Nouveau produit ajouté : ${result.nom}'),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    }
  }
}

class ProductSearchField extends StatefulWidget {
  final TextEditingController _barcodeBufferController;
  final Function(BuildContext, CommerceProvider, FacturationProvider, double,
      List<LigneDocument>) _processBarcode;

  ProductSearchField(this._barcodeBufferController, this._processBarcode);

  @override
  State<ProductSearchField> createState() => _ProductSearchField1State();
}

class _ProductSearchField1State extends State<ProductSearchField> {
  bool isPasted = false;
  late FocusNode _focusNode;

  // Ajoutez une variable pour forcer la reconstruction
  int _autocompleteVersion = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Méthode pour forcer le rafraîchissement du widget Autocomplete
  void _refreshAutocomplete() {
    setState(() {
      _autocompleteVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final commerceProvider = Provider.of<CommerceProvider>(context);
    final facturationProvider = Provider.of<FacturationProvider>(context);

    return Autocomplete<Produit>(
      key: ValueKey(_autocompleteVersion),
      // Forcer la reconstruction ici
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text == '') {
          return const Iterable<Produit>.empty();
        }
        return await commerceProvider.rechercherProduits(textEditingValue.text);
      },
      displayStringForOption: (Produit option) => '${option.qr} ${option.nom}',
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              // Détecter un collage (longueur > ancienne longueur + 1)
              if (newValue.text.length > oldValue.text.length + 1) {
                isPasted = true;
                processAddingProduct2Invoice(
                    newValue.text,
                    context,
                    commerceProvider,
                    facturationProvider,
                    fieldTextEditingController,
                    fieldFocusNode,
                    setState,
                    isPasted);
              }
              return newValue;
            }),
          ],
          decoration: InputDecoration(
            labelText: 'Code Produit (ID ou QR)',
            border: OutlineInputBorder(),
            suffixIcon: (Platform.isIOS || Platform.isAndroid)
                ? IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      await scanQRCode(commerceProvider, facturationProvider,
                          fieldTextEditingController);
                    },
                  )
                : null,
          ),
          onChanged: (value) {},
          onFieldSubmitted: (value) async {
            processAddingProduct2Invoice(
                value,
                context,
                commerceProvider,
                facturationProvider,
                fieldTextEditingController,
                fieldFocusNode,
                setState,
                isPasted);
            // if (value.isNotEmpty) {
            //   final produit =
            //       await commerceProvider.getProduitByQrFacture(value);
            //   if (produit != null) {
            //     final stockRestant = produit.approvisionnements.fold<double>(
            //       0,
            //       (previousValue, appro) => previousValue + appro.quantite,
            //     );
            //     final currentQuantity = facturationProvider.lignesFacture
            //         .where((ligne) => ligne.produit.target?.id == produit.id)
            //         .fold<double>(0, (sum, ligne) => sum + ligne.quantite);
            //
            //     if (currentQuantity >= stockRestant) {
            //       if (context.mounted) {
            //         showDialog(
            //           context: context,
            //           builder: (context) => AlertDialog(
            //             title: Text("Limite atteinte"),
            //             content: Text(stockRestant <= 0
            //                 ? "Stock Indisponible"
            //                 : "Vous avez déjà ajouté ${currentQuantity.toInt()} fois '${produit.nom}', ce qui correspond au stock disponible."),
            //             actions: [
            //               TextButton(
            //                 onPressed: () => Navigator.pop(context),
            //                 child: Text("OK"),
            //               ),
            //             ],
            //           ),
            //         );
            //       }
            //     } else {
            //       facturationProvider.ajouterProduitALaFacture(
            //           produit, 1, produit.prixVente);
            //     }
            //   } else {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(
            //         content: Text('Aucun produit trouvé pour ce QR code.'),
            //         backgroundColor: Colors.red,
            //       ),
            //     );
            //   }
            //   fieldTextEditingController.clear();
            //   // Utilisation d'un callback post-frame pour redemander le focus
            //   // WidgetsBinding.instance.addPostFrameCallback((_) {
            //   //   FocusScope.of(context).requestFocus(fieldFocusNode);
            //   // });
            //   _refreshAutocomplete();
            // } else {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     SnackBar(
            //       content: Text('Veuillez entrer un code valide.'),
            //       backgroundColor: Colors.red,
            //     ),
            //   );
            // }
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Produit> onSelected,
          Iterable<Produit> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              height: 200.0,
              width: 300.0,
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Produit produit = options.elementAt(index);
                  // Calculer le stock restant pour chaque produit
                  final stockRestant = produit.approvisionnements.fold<double>(
                    0,
                    (previousValue, appro) => previousValue + appro.quantite,
                  );
                  return ListTile(
                    mouseCursor:
                        stockRestant <= 0 ? SystemMouseCursors.forbidden : null,
                    textColor: stockRestant <= 0 ? Colors.red : null,
                    // tileColor:
                    //     stockRestant <= 0 ? Colors.red : Colors.transparent,
                    contentPadding: const EdgeInsets.only(left: 5),
                    trailing: Container(
                      width: 50, // Taille fixe pour un carré
                      height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // Coins arrondis
                        child: // Remplacez votre Text(...) existant par :
                            Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Partie entière
                            Text(
                              stockRestant.truncate().toString(),
                              // Partie entière sans décimales
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w400),
                            ),

                            // Partie décimale (si nécessaire)
                            if (stockRestant != stockRestant.truncateToDouble())
                              Text(
                                ".${stockRestant.toStringAsFixed(2).split('.')[1]}",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blueGrey),
                              )
                          ],
                        ),
                      ),
                    ),
                    title: Text(
                      '${produit.nom}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                        'Prix: ${formatManualPrice(produit.prixVente)} DZD'),
                    leading: SizedBox(
                      width: 50, // Taille fixe pour un carré
                      height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // Coins arrondis
                        child: produit.image == null || produit.image!.isEmpty
                            ? Container(
                                color: Colors.grey[300],
                                // Couleur de fond si pas d'image
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey[600]),
                              )
                            : Image(
                                image: produit.image!.startsWith('http')
                                    ? CachedNetworkImageProvider(
                                        produit.image!,
                                        errorListener: (error) =>
                                            debugPrint("Image error"),
                                      )
                                    : FileImage(File(produit.image!))
                                        as ImageProvider,
                                fit: BoxFit
                                    .cover, // Remplir tout l'espace disponible
                              ),
                      ),
                    ),

                    onTap: stockRestant <= 0
                        ? null
                        : () {
                            // facturationProvider.ajouterProduitALaFacture(
                            //   produit,
                            //   1,
                            //   produit.prixVente,
                            // );
                            // 1. Calculer le stock restant à partir de tous les approvisionnements
                            final stockRestant =
                                produit.approvisionnements.fold<double>(
                              0,
                              (previousValue, appro) =>
                                  previousValue + appro.quantite,
                            );

                            // 2. Calculer la quantité déjà ajoutée dans la facture pour ce produit
                            final currentQuantity = facturationProvider
                                .lignesFacture
                                .where((ligne) =>
                                    ligne.produit.target?.id == produit.id)
                                .fold<double>(
                                    0, (sum, ligne) => sum + ligne.quantite);
                            final originalQuantity = facturationProvider
                                .getOriginalQuantity(produit.id);
                            // Calculer la quantité maximale autorisée (original + stock restant)

                            final maxAllowed = originalQuantity + stockRestant;
                            // Calculer la nouvelle quantité en s'assurant de ne pas dépasser la limite
                            final nouvelleQuantite =
                                min(currentQuantity + 1, maxAllowed).toDouble();
                            print(
                                'currentQuantity: $currentQuantity, stockRestant: $stockRestant');

                            if (maxAllowed <= 0) {
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Limite atteinte"),
                                    content: Text(stockRestant <= 0
                                        ? "Stock Indisponible"
                                        : "Vous avez déjà ajouté ${currentQuantity.toInt()} fois '${produit.nom}', ce qui correspond au stock disponible."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              // 4. Si le produit est déjà présent dans la facture, on souhaite incrémenter sa quantité
                              if (currentQuantity > 0) {
                                // On récupère l'identifiant du produit
                                final produitId = produit.id;
                                // Récupérer la quantité d'origine présente dans la facture (avant toute modification)

                                print(originalQuantity);
                                print(currentQuantity);
                                print(nouvelleQuantite);
                                print(maxAllowed);

                                /// ici qand j'atteind le max il s'arret et la dialog ne s'ouvre pas
                                if (nouvelleQuantite > maxAllowed) {
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Limite atteinte"),
                                        content: Text(
                                          "Vous avez déjà ajouté ${currentQuantity + 1.toInt()} fois '${produit.nom}', ce qui correspond au stock disponible.",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }

                                // Identifier l'index de la ligne à modifier dans la liste
                                final index = facturationProvider.lignesFacture
                                    .indexWhere(
                                  (ligne) =>
                                      ligne.produit.target?.id == produit.id,
                                );

                                if (index != -1) {
                                  facturationProvider.modifierLigne(
                                    index,
                                    nouvelleQuantite,
                                    produit.prixVente,
                                  );
                                }
                              } else {
                                // 5. Sinon, ajouter le produit dans la facture avec une quantité de 1
                                facturationProvider.ajouterProduitALaFacture(
                                  produit,
                                  1,
                                  produit.prixVente,
                                );
                              }
                            }

                            setState(() {
                              isPasted = false;
                              _refreshAutocomplete();
                            });
                          },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> scanQRCode(
      CommerceProvider commerceProvider,
      FacturationProvider facturationProvider,
      TextEditingController fieldTextEditingController) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWithScanWindow(),
      ),
    );

    // Vérification si le code est null ou vide
    if (code == null || code.isEmpty) {
      return;
    }

    // Recherche du produit via le QR code
    final produit = await commerceProvider.getProduitByQrFacture(code);

    if (produit == null) {
      // Produit introuvable, rediriger vers l'ajout de produit
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => addProduct()),
      );
    } else {
      // Produit trouvé, l'ajouter à la facture
      facturationProvider.ajouterProduitALaFacture(
        produit,
        1,
        produit.prixVente,
      );
    }

    // Nettoyage du champ de texte et focus
    fieldTextEditingController.clear();
    _focusNode.requestFocus();

    // Rafraîchir l'autocomplétion (si nécessaire)
    _refreshAutocomplete();
  }
}

// class _ProductSearchField1State extends State<ProductSearchField> {
//   bool isPasted = false;
//   late FocusNode _focusNode; // Déclarer un FocusNode
//
//   @override
//   void initState() {
//     super.initState();
//     _focusNode = FocusNode(); // Initialiser le FocusNode
//     _focusNode.requestFocus(); // Demander le focus au chargement
//   }
//
//   @override
//   void dispose() {
//     _focusNode
//         .dispose(); // Nettoyer le FocusNode lors de la suppression du widget
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final commerceProvider = Provider.of<CommerceProvider>(context);
//     final facturationProvider = Provider.of<FacturationProvider>(context);
//
//     return Autocomplete<Produit>(
//       optionsBuilder: (TextEditingValue textEditingValue) async {
//         if (textEditingValue.text == '') {
//           return const Iterable<Produit>.empty();
//         }
//         // Toujours effectuer la recherche pour l'autocomplétion
//         return await commerceProvider.rechercherProduits(textEditingValue.text);
//       },
//       displayStringForOption: (Produit option) => '${option.qr} ${option.nom}',
//       fieldViewBuilder: (BuildContext context,
//           TextEditingController fieldTextEditingController,
//           FocusNode fieldFocusNode,
//           VoidCallback onFieldSubmitted) {
//         return TextFormField(
//           controller: fieldTextEditingController,
//           focusNode: fieldFocusNode,
//           // focusNode: _focusNode,
//           // Utiliser notre FocusNode personnalisé
//           inputFormatters: [
//             TextInputFormatter.withFunction((oldValue, newValue) {
//               // Détecter si c'est un collage en comparant les longueurs
//               if (newValue.text.length > oldValue.text.length + 1) {
//                 isPasted = true;
//                 // Traiter le texte collé de manière asynchrone
//                 Future.microtask(() async {
//                   if (newValue.text.isNotEmpty) {
//                     final produit = await commerceProvider
//                         .getProduitByQrFacture(newValue.text);
//
//                     if (produit != null) {
//                       // Calculer le stock restant
//                       final stockRestant = produit.approvisionnements
//                           .fold<double>(
//                               0,
//                               (previousValue, appro) =>
//                                   previousValue + appro.quantite);
//
//                       if (stockRestant <= 0) {
//                         // Afficher une boîte de dialogue d'avertissement
//                         if (context.mounted) {
//                           showDialog(
//                             context: context,
//                             builder: (context) => AlertDialog(
//                               title: Text("Stock insuffisant"),
//                               content: Text(
//                                   "Le produit '${produit.nom}' est en rupture de stock."),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: Text("OK"),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//                       } else {
//                         // Ajouter le produit à la facture si le stock est suffisant
//                         facturationProvider.ajouterProduitALaFacture(
//                           produit,
//                           1,
//                           produit.prixVente,
//                         );
//
//                         // Effacer le champ après ajout
//                         fieldTextEditingController.clear();
//                       }
//                     }
//
//                     setState(() {
//                       isPasted = false;
//                     });
//                   }
//                 });
//               }
//               return newValue;
//             }),
//           ],
//           decoration: InputDecoration(
//             labelText: 'Code Produit (ID ou QR)',
//             border: OutlineInputBorder(),
//             // suffixIcon: IconButton(
//             //   icon: Icon(Icons.search),
//             //   onPressed: onFieldSubmitted,
//             // ),
//             suffixIcon: (Platform.isIOS || Platform.isAndroid)
//                 ? IconButton(
//                     icon: Icon(Icons.qr_code_scanner),
//                     onPressed: () async {
//                       await scanQRCode(commerceProvider, facturationProvider,
//                           fieldTextEditingController);
//                     },
//                   )
//                 : null,
//           ),
//           // La méthode onChanged ne fait plus rien d'automatique
//           onChanged: (value) {
//             // Ne rien faire ici, juste laisser l'autocomplétion fonctionner
//           },
//           // onFieldSubmitted: (value) {
//           //   if (value.isNotEmpty) {
//           //     widget._processBarcode(
//           //       context,
//           //       commerceProvider,
//           //       facturationProvider,
//           //       1,
//           //       facturationProvider.lignesFacture,
//           //     );
//           //     fieldTextEditingController.clear();
//           //   } else {
//           //     ScaffoldMessenger.of(context).showSnackBar(
//           //       SnackBar(
//           //         content:
//           //             Text('Entrée invalide. Veuillez entrer un code valide.'),
//           //       ),
//           //     );
//           //   }
//           // },
//           onFieldSubmitted: (value) async {
//             if (value.isNotEmpty) {
//               // Récupérer le produit par QR code
//               final produit =
//                   await commerceProvider.getProduitByQrFacture(value);
//
//               if (produit != null) {
//                 // Ajouter le produit à la facture
//                 facturationProvider.ajouterProduitALaFacture(
//                     produit, 1, produit.prixVente);
//
//                 // Afficher un message de confirmation
//                 // ScaffoldMessenger.of(context).showSnackBar(
//                 //   SnackBar(
//                 //     content: Text('${produit.nom} ajouté à la facture'),
//                 //     backgroundColor: Colors.green,
//                 //   ),
//                 // );
//               } else {
//                 // Aucun produit trouvé
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Aucun produit trouvé pour ce QR code.'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//
//               // Vider le champ après l'ajout
//               fieldTextEditingController.clear();
//
//               // Rétablir le focus sur le champ
//               _focusNode.requestFocus();
//             } else {
//               // Afficher un message d'erreur si le champ est vide
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Veuillez entrer un code valide.'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           },
//         );
//       },
//       optionsViewBuilder: (BuildContext context,
//           AutocompleteOnSelected<Produit> onSelected,
//           Iterable<Produit> options) {
//         return Align(
//           alignment: Alignment.topLeft,
//           child: Material(
//             elevation: 4.0,
//             child: Container(
//               height: 200.0,
//               width: 300.0,
//               child: ListView.builder(
//                 padding: EdgeInsets.all(8.0),
//                 itemCount: options.length,
//                 itemBuilder: (BuildContext context, int index) {
//                   final Produit produit = options.elementAt(index);
//
//                   final stockRestant = produit.approvisionnements.fold<double>(
//                       0,
//                       (previousValue, appro) => previousValue + appro.quantite);
//
//                   return ListTile(
//                     leading: CircleAvatar(
//                       child: Padding(
//                         padding: const EdgeInsets.all(4.0),
//                         child: FittedBox(child: Text('${produit.id}')),
//                       ),
//                     ),
//                     title: Text('${produit.qr} ${produit.nom}'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                             'Prix: ${produit.prixVente.toStringAsFixed(2)} DZD'),
//
//                         ///***************************************  le travaille est ici
//                         ///je dois limiter trailing a < stockrestant****************************************************
//
//                         Text('Stock Restant : ' +
//                             (stockRestant ?? 0).toStringAsFixed(2)),
//                         Text('Stock Restant : ' +
//                             (produit.stock ?? 0).toStringAsFixed(2)),
//                       ],
//                     ),
//                     // onTap: () {
//                     //   onSelected(option);
//                     // },
//                     // trailing: IconButton(
//                     //   icon: Icon(
//                     //     Icons.add_shopping_cart,
//                     //   ),
//                     //   onPressed: stockRestant <= 0
//                     //       ? null
//                     //       : () {
//                     //           facturationProvider.ajouterProduitALaFacture(
//                     //             produit,
//                     //             1,
//                     //             produit.prixVente,
//                     //           );
//                     //
//                     //           // ScaffoldMessenger.of(context).showSnackBar(
//                     //           //   SnackBar(
//                     //           //     content: Text('${option.nom} ajouté à la facture'),
//                     //           //   ),
//                     //           // );
//                     //         },
//                     // ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//       onSelected: (Produit selection) {
//         widget._processBarcode(
//           context,
//           commerceProvider,
//           facturationProvider,
//           1,
//           facturationProvider.lignesFacture,
//         );
//       },
//     );
//   }
//
//   Future<void> scanQRCode(
//       commerceProvider, facturationProvider, fieldTextEditingController) async {
//     // Simuler un scan de QR code pour tester
//     final code = await Navigator.of(context).push<String>(
//       MaterialPageRoute(
//         builder: (context) => BarcodeScannerWithScanWindow(), //QRViewExample(),
//       ),
//     );
//     final provider = Provider.of<CommerceProvider>(context, listen: false);
//     final produit = await provider.getProduitByQrFacture(code!);
//     if (produit == null) {
//       Navigator.of(context)
//           .push(MaterialPageRoute(builder: (ctx) => addProduct()));
//     } else {
//       // Récupérer le produit par QR code
//       final produit = await commerceProvider.getProduitByQrFacture(code);
//
//       if (produit != null) {
//         // Ajouter le produit à la facture
//         facturationProvider.ajouterProduitALaFacture(
//             produit, 1, produit.prixVente);
//
//         // Afficher un message de confirmation
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   SnackBar(
//         //     content: Text('${produit.nom} ajouté à la facture'),
//         //     backgroundColor: Colors.green,
//         //   ),
//         // );
//       } else {
//         // Aucun produit trouvé
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Aucun produit trouvé pour ce QR code.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//
//       // Vider le champ après l'ajout
//       fieldTextEditingController.clear();
//
//       // Rétablir le focus sur le champ
//       _focusNode.requestFocus();
//     }
//     // Rediriger le focus vers le TextFormField après l'ajout
//     FocusScope.of(context).requestFocus(_focusNode);
//   }
// }

class AddMarqueeDialog extends StatefulWidget {
  @override
  _AddMarqueeDialogState createState() => _AddMarqueeDialogState();
}

class _AddMarqueeDialogState extends State<AddMarqueeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _webUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addMarquee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('marquee').insert({
        'text': _textController.text.trim(),
        'prix': double.tryParse(_prixController.text) ?? 0.0,
        'imageUrl': _imageUrlController.text.trim(),
        'webUrl': _webUrlController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context); // Ferme la boîte de dialogue après succès
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${error.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une Marquee'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textController,
              decoration:
                  const InputDecoration(labelText: 'Texte de l\'annonce'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Champ requis' : null,
            ),
            TextFormField(
              controller: _prixController,
              decoration: const InputDecoration(labelText: 'Prix'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value == null || double.tryParse(value) == null
                      ? 'Entrer un prix valide'
                      : null,
            ),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                  labelText: 'URL de l\'image (facultatif)'),
            ),
            TextFormField(
              controller: _webUrlController,
              decoration:
                  const InputDecoration(labelText: 'URL Web (facultatif)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addMarquee,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _prixController.dispose();
    _imageUrlController.dispose();
    _webUrlController.dispose();
    super.dispose();
  }
}

class MarqueeWidget extends StatefulWidget {
  const MarqueeWidget({
    Key? key,
    required this.marqueeData,
    required this.controller,
  }) : super(key: key);

  final List<MarqueeData> marqueeData;
  final MarqueerController controller;

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Impossible d\'ouvrir $url';
    }
  }

  // Fonction pour détecter si le texte est en arabe
  bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Container(
            height: 50,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.yellow,
            child: Marqueer.builder(
              pps: 60,
              autoStart: true,
              separatorBuilder: (_, index) => const Center(
                child: Text(
                  '  -  ',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              scrollablePointerIgnoring: true,
              direction: MarqueerDirection.ltr,
              controller: widget.controller,
              itemCount: widget.marqueeData.length,
              itemBuilder: (context, index) {
                final item = widget.marqueeData[index];

                return InkWell(
                  onTap: () => _launchUrl(item.webUrl),
                  child: Row(
                    children: [
                      if (item.imageUrl.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontFamily:
                              isArabic(item.text) ? 'ArbFONTS' : 'Oswald',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          return Container(
            height: 50,
            width: MediaQuery.of(context).size.width * 0.43,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.yellow,
            child: Marqueer.builder(
              pps: 60,
              autoStart: true,
              separatorBuilder: (_, index) => const Center(
                child: Text(
                  '  -  ',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              scrollablePointerIgnoring: true,
              direction: MarqueerDirection.ltr,
              controller: widget.controller,
              itemCount: widget.marqueeData.length,
              itemBuilder: (context, index) {
                final item = widget.marqueeData[index];

                return InkWell(
                  onTap: () => _launchUrl(item.webUrl),
                  child: Row(
                    children: [
                      if (item.imageUrl.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontFamily:
                              isArabic(item.text) ? 'ArbFONTS' : 'Oswald',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}

Future<void> processAddingProduct2Invoice(
  String qrValue,
  BuildContext context,
  CommerceProvider commerceProvider,
  FacturationProvider facturationProvider,
  TextEditingController fieldTextEditingController,
  FocusNode fieldFocusNode,
  Function setState,
  bool isPasted,
) async {
  if (qrValue!.isNotEmpty) {
    final produit = await commerceProvider.getProduitByQrFacture(qrValue);

    if (produit != null) {
      // 1. Calculate remaining stock from all supplies
      final stockRestant = produit.approvisionnements.fold<double>(
        0,
        (previousValue, appro) => previousValue + appro.quantite,
      );

      // 2. Calculate quantity already added to the invoice for this product
      final currentQuantity = facturationProvider.lignesFacture
          .where((ligne) => ligne.produit.target?.id == produit.id)
          .fold<double>(0, (sum, ligne) => sum + ligne.quantite);

      final originalQuantity =
          facturationProvider.getOriginalQuantity(produit.id);

      // Calculate maximum allowed quantity (original + remaining stock)
      final maxAllowed = originalQuantity + stockRestant;

      // Calculate new quantity ensuring not to exceed the limit
      final nouvelleQuantite = min(currentQuantity + 1, maxAllowed).toDouble();

      print('currentQuantity: $currentQuantity, stockRestant: $stockRestant');

      // 3. Check stock availability
      if (maxAllowed <= 0) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Limite atteinte"),
              content: const Text("Stock Indisponible."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        // 4. If product is already in the invoice, increment its quantity
        if (currentQuantity > 0) {
          print(originalQuantity);
          print(currentQuantity);
          print(nouvelleQuantite);
          print(maxAllowed);

          // If we reach max, stop and don't open dialog
          if (nouvelleQuantite > maxAllowed) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Limite atteinte"),
                  content: Text(
                    "Vous avez déjà ajouté ${currentQuantity.toInt() + 1} fois '${produit.nom}', ce qui correspond au stock disponible.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          }

          // Find the index of the line to modify in the list
          final index = facturationProvider.lignesFacture.indexWhere(
            (ligne) => ligne.produit.target?.id == produit.id,
          );

          if (index != -1) {
            facturationProvider.modifierLigne(
              index,
              nouvelleQuantite,
              produit.prixVente,
            );
          }
        } else {
          // 5. Otherwise, add the product to the invoice with a quantity of 1
          facturationProvider.ajouterProduitALaFacture(
            produit,
            1,
            produit.prixVente,
          );
        }
        // Clear the input field after adding/modifying
        fieldTextEditingController!.clear();
      }
    }
    // Request focus on the TextFormField again
    fieldFocusNode!.requestFocus();
    setState(() {
      isPasted = false;
    });
  }
}

String formatManualPrice(double price) {
  return price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ') +
      ' DA';
}
