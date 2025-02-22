// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../pages/invoice/providers.dart';
//
// class test extends StatelessWidget {
//   const test({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // final provider = Provider.of<FacturationProvider>(context);
//     // // Mettez à jour l'impayerController lorsque la facture change
//     // if (provider.factureEnCours != null) {
//     //   _impayerController.text = provider.impayer.toStringAsFixed(2);
//     // }
//
//     return Consumer<FacturationProvider>(builder: (context, provider, child) {
//       // Update impayer controller when invoice changes
//       if (provider.factureEnCours != null) {
//         _impayerController.text = provider.impayer.toStringAsFixed(2);
//       }
//       return Scaffold(
//         body: SingleChildScrollView(
//           scrollDirection: Axis.vertical,
//           child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   if (constraints.maxWidth < 600) {
//                     return Column(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: SizedBox(
//                             width: MediaQuery.of(context).size.width,
//                             child: ProductSearchBar(
//                               // commerceProvider: commerceProvider,
//                               // cartProvider: cartProvider,
//                                 barcodeBuffer: _barcodeBuffer,
//                                 barcodeBufferController:
//                                 _barcodeBufferController),
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: () => _showAddMarqueeDialog(context),
//                           icon: const Icon(Icons.add),
//                         ),
//                         SizedBox(
//                           height: 8,
//                         ),
//                         StreamBuilder<List<MarqueeData>>(
//                           stream: _marqueeDataStream,
//                           initialData: const [],
//                           builder: (context, snapshot) {
//                             if (snapshot.connectionState ==
//                                 ConnectionState.waiting) {
//                               return const Center(
//                                   child: CircularProgressIndicator());
//                             }
//                             if (snapshot.hasError) {
//                               return Center(
//                                   child: Text('Erreur: ${snapshot.error}'));
//                             }
//                             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                               return const Center(
//                                   child: Text('Aucune annonce disponible.'));
//                             }
//
//                             final marqueeData = snapshot.data!;
//
//                             return Container(
//                               height: 50,
//                               width: MediaQuery.of(context).size.width,
//                               padding: const EdgeInsets.symmetric(vertical: 10),
//                               color: Colors.yellow,
//                               child: Marqueer.builder(
//                                 pps: 50,
//                                 autoStart: true,
//                                 separatorBuilder: (_, index) => const Center(
//                                   child: Text(
//                                     '  -  ',
//                                     style: TextStyle(color: Colors.black),
//                                   ),
//                                 ),
//                                 scrollablePointerIgnoring: true,
//                                 direction: MarqueerDirection.rtl,
//                                 controller: _controller,
//                                 itemCount: marqueeData.length,
//                                 itemBuilder: (context, index) {
//                                   final item = marqueeData[index];
//
//                                   return InkWell(
//                                     onTap: () => _launchUrl(item.webUrl),
//                                     child: Row(
//                                       children: [
//                                         if (item.imageUrl.isNotEmpty)
//                                           AspectRatio(
//                                             aspectRatio: 1,
//                                             child: CachedNetworkImage(
//                                                 imageUrl: item.imageUrl,
//                                                 fit: BoxFit.cover,
//                                                 width: 50,
//                                                 height: 50),
//                                           ),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           "${item.text} : ${item.prix.toStringAsFixed(2)} DZD",
//                                           style: const TextStyle(
//                                               fontSize: 18,
//                                               color: Colors.black),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                             );
//                           },
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: ClientInfos(),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           child: TTC(
//                             totalAmount: provider.calculerTotalHT(),
//                             localImpayer:
//                             double.tryParse(_impayerController.text) ?? 0.0,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: provider.factureEnCours == null
//                               ? SizedBox.shrink()
//                               : TotalDetail(
//                               totalAmount: provider.calculerTotalHT(),
//                               localImpayer: double.tryParse(
//                                   _impayerController.text) ??
//                                   0.0,
//                               facture: provider.factureEnCours!),
//                         ),
//                         provider.lignesFacture.isEmpty
//                             ? SizedBox.shrink()
//                             : Padding(
//                           padding:
//                           const EdgeInsets.fromLTRB(16, 0, 16, 8),
//                           child: EditableField(
//                             initialValue: provider.impayer,
//                             impayerController: _impayerController,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 8),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               ElevatedButton.icon(
//                                 onPressed: provider.lignesFacture.isEmpty
//                                     ? null
//                                     : () {
//                                   provider
//                                       .creerNouvelleFacture(); // Crée une nouvelle facture
//                                   _impayerController.clear();
//                                   _rechercheController.clear();
//                                   context
//                                       .read<EditableFieldProvider>()
//                                       .AlwaystoggleEditable();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(15.0),
//                                   ),
//                                 ),
//                                 label: Text('Nouvelle'),
//                                 icon: Padding(
//                                   padding:
//                                   const EdgeInsets.symmetric(vertical: 18),
//                                   child: Icon(Icons.add),
//                                 ),
//                               ),
//                               ElevatedButton.icon(
//                                 onPressed: provider.lignesFacture.isEmpty
//                                     ? null
//                                     : () {
//                                   provider.sauvegarderFacture(context);
//                                   _impayerController.clear();
//                                   context
//                                       .read<EditableFieldProvider>()
//                                       .AlwaystoggleEditable();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   foregroundColor:
//                                   Theme.of(context).colorScheme.onPrimary,
//                                   backgroundColor:
//                                   Theme.of(context).colorScheme.primary,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(15.0),
//                                   ),
//                                 ),
//                                 label: Text('Sauvegarder'),
//                                 icon: Padding(
//                                   padding:
//                                   const EdgeInsets.symmetric(vertical: 18),
//                                   child: Icon(Icons.save),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: provider.lignesFacture.length,
//                           itemBuilder: (context, index) {
//                             final ligne = provider.lignesFacture[index];
//                             return Card(
//                               margin: const EdgeInsets.symmetric(
//                                   horizontal: 16, vertical: 8),
//                               child: Slidable(
//                                 key: ValueKey(ligne),
//                                 // Use a unique key for each Slidable
//                                 startActionPane: ActionPane(
//                                   motion: const ScrollMotion(),
//                                   dismissible: DismissiblePane(
//                                     onDismissed: () {
//                                       // Remove the item from the list and trigger a rebuild
//                                       provider.supprimerLigne(index);
//                                     },
//                                   ),
//                                   children: [
//                                     SlidableAction(
//                                       onPressed: (context) {
//                                         provider.supprimerLigne(index);
//                                       },
//                                       backgroundColor: Color(0xFFFE4A49),
//                                       foregroundColor: Colors.white,
//                                       icon: Icons.delete,
//                                       label: 'Delete',
//                                     ),
//                                   ],
//                                 ),
//                                 endActionPane: ActionPane(
//                                   motion: const ScrollMotion(),
//                                   dismissible: DismissiblePane(
//                                     onDismissed: () {
//                                       _showEditDialog(
//                                           context, ligne, provider, index);
//                                     },
//                                   ),
//                                   children: [
//                                     SlidableAction(
//                                       onPressed: (context) {
//                                         _showEditDialog(
//                                             context, ligne, provider, index);
//                                       },
//                                       backgroundColor: Color(0xFF0392CF),
//                                       foregroundColor: Colors.white,
//                                       icon: Icons.save,
//                                       label: 'Edit',
//                                     ),
//                                   ],
//                                 ),
//                                 child: ListTile(
//                                   leading: CircleAvatar(
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: FittedBox(
//                                         child: Text(
//                                             '${ligne.quantite.toStringAsFixed(2)}'),
//                                       ),
//                                     ),
//                                   ),
//                                   title: Text(ligne.produit.target?.nom ??
//                                       'Produit inconnu'),
//                                   subtitle: Text(
//                                       'PU: ${ligne.prixUnitaire.toStringAsFixed(2)}'),
//                                   trailing: Text(
//                                     '${(ligne.quantite * ligne.prixUnitaire).toStringAsFixed(2)}',
//                                     style: TextStyle(fontSize: 20),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     );
//                   }
//                   else {
//                     return
//                       Column(
//
//                         children: [
//                           ,
//                           Row(
//                             children: [
//                               SizedBox(
//                                 width: MediaQuery.of(context).size.width * 0.2,
//                                 child: ProductSearchBar(
//                                   // commerceProvider: commerceProvider,
//                                   // cartProvider: cartProvider,
//                                     barcodeBuffer: _barcodeBuffer,
//                                     barcodeBufferController:
//                                     _barcodeBufferController),
//                               ),
//                               IconButton(
//                                 onPressed: () => _showAddMarqueeDialog(context),
//                                 icon: const Icon(Icons.add),
//                               ),
//                               SizedBox(
//                                 width: 15,
//                               ),
//                               Expanded(
//                                 child: StreamBuilder<List<MarqueeData>>(
//                                   stream: _marqueeDataStream,
//                                   initialData: const [],
//                                   builder: (context, snapshot) {
//                                     if (snapshot.connectionState ==
//                                         ConnectionState.waiting) {
//                                       return const Center(
//                                           child: CircularProgressIndicator());
//                                     }
//                                     if (snapshot.hasError) {
//                                       return IconButton(
//                                           onPressed: () => _initializeMarqueeData(),
//                                           icon: Icon(Icons.refresh));
//                                       // Center(
//                                       //   child: Text('Erreur: ${snapshot.error}'));
//                                     }
//                                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                                       return const Center(
//                                           child: Text('Aucune annonce disponible.'));
//                                     }
//
//                                     final marqueeData = snapshot.data!;
//
//                                     return Container(
//                                       height: 50,
//                                       width: MediaQuery.of(context).size.width * 0.43,
//                                       padding:
//                                       const EdgeInsets.symmetric(vertical: 10),
//                                       color: Colors.yellow,
//                                       child: Marqueer.builder(
//                                         pps: 50,
//                                         autoStart: true,
//                                         separatorBuilder: (_, index) => const Center(
//                                           child: Text(
//                                             '  -  ',
//                                             style: TextStyle(color: Colors.black),
//                                           ),
//                                         ),
//                                         scrollablePointerIgnoring: true,
//                                         direction: MarqueerDirection.rtl,
//                                         controller: _controller,
//                                         itemCount: marqueeData.length,
//                                         itemBuilder: (context, index) {
//                                           final item = marqueeData[index];
//
//                                           return InkWell(
//                                             onTap: () => _launchUrl(item.webUrl),
//                                             child: Row(
//                                               children: [
//                                                 if (item.imageUrl.isNotEmpty)
//                                                   AspectRatio(
//                                                     aspectRatio: 1,
//                                                     child: CachedNetworkImage(
//                                                         imageUrl: item.imageUrl,
//                                                         fit: BoxFit.cover,
//                                                         width: 50,
//                                                         height: 50),
//                                                   ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   "${item.text} : ${item.prix.toStringAsFixed(2)} DZD",
//                                                   style: const TextStyle(
//                                                       fontSize: 18,
//                                                       color: Colors.black),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Row(
//                             children: [
//                               Expanded(flex: 4, child: ClientInfos()),
//                               Expanded(
//                                 flex: 3,
//                                 child: TTC(
//                                   totalAmount: provider.calculerTotalHT(),
//                                   localImpayer: double.tryParse(
//                                       _impayerController.text) ??
//                                       0.0,
//                                 ),
//                               ),
//                               Expanded(
//                                 flex: 2,
//                                 child: TotalDetail(
//                                     totalAmount: provider.calculerTotalHT(),
//                                     localImpayer: double.tryParse(
//                                         _impayerController.text) ??
//                                         0.0,
//                                     facture: provider.factureEnCours),
//                               ),
//                             ],
//                           ),
//                           SizedBox(
//                             height: 10,
//                           ),
//                           Container(
//                             height: 60,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               children: [
//                                 Spacer(
//                                   flex: 1,
//                                 ),
//                                 Expanded(
//                                   flex: 3,
//                                   child: provider.lignesFacture.isEmpty
//                                       ? SizedBox.shrink()
//                                       : EditableField(
//                                     initialValue: provider.impayer,
//                                     impayerController: _impayerController,
//                                   ),
//                                 ),
//                                 Spacer(
//                                   flex: 2,
//                                 ),
//                                 ElevatedButton.icon(
//                                   onPressed: provider.lignesFacture.isEmpty
//                                       ? null
//                                       : () {
//                                     provider
//                                         .creerNouvelleFacture(); // Crée une nouvelle facture
//                                     _impayerController.clear();
//                                     _rechercheController.clear();
//                                     context
//                                         .read<EditableFieldProvider>()
//                                         .AlwaystoggleEditable();
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(15.0),
//                                     ),
//                                   ),
//                                   label: Text('Nouvelle Facture'),
//                                   icon: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 18),
//                                     child: Icon(Icons.add),
//                                   ),
//                                 ),
//                                 Spacer(
//                                   flex: 2,
//                                 ),
//                                 ElevatedButton.icon(
//                                   onPressed: provider.lignesFacture.isEmpty
//                                       ? null
//                                       : () {
//                                     provider.sauvegarderFacture(context);
//                                     _impayerController.clear();
//                                     context
//                                         .read<EditableFieldProvider>()
//                                         .AlwaystoggleEditable();
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     foregroundColor:
//                                     Theme.of(context).colorScheme.onPrimary,
//                                     backgroundColor:
//                                     Theme.of(context).colorScheme.primary,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(15.0),
//                                     ),
//                                   ),
//                                   label: Text('Sauvegarder la facture'),
//                                   icon: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 18),
//                                     child: Icon(Icons.save),
//                                   ),
//                                 ),
//                                 Spacer(
//                                   flex: 1,
//                                 ),
//                               ],
//                             ),
//                           ),
//                           SizedBox(
//                             height: 20,
//                           ),
//                           Container(
//                             width: double.infinity,
//                             child: DataTable(
//                               columnSpacing: 24,
//                               // Couleur de l'entête
//                               // dataRowColor:
//                               //     WidgetStateProperty.resolveWith<Color?>(
//                               //   (Set<WidgetState> states) {
//                               //     // Alternance des couleurs des lignes
//                               //     if (states.contains(WidgetState.selected)) {
//                               //       return Colors.grey.shade300;
//                               //     }
//                               //     return null; // Couleur par défaut
//                               //   },
//                               //),
//                               headingRowColor: WidgetStateProperty.all(
//                                 Theme.of(context).colorScheme.primaryContainer,
//                               ),
//                               dataRowColor:
//                               WidgetStateProperty.resolveWith<Color?>(
//                                     (Set<WidgetState> states) {
//                                   if (states.contains(WidgetState.selected)) {
//                                     return Theme.of(context)
//                                         .colorScheme
//                                         .secondaryContainer;
//                                   }
//                                   return null; // Couleur par défaut
//                                 },
//                               ),
//                               showBottomBorder: true,
//                               columns: [
//                                 DataColumn(
//                                   label: Container(
//                                     //  color: Colors.greenAccent,
//                                     width: 30, // Largeur fixe pour QR
//                                     child:
//                                     Text('QR', textAlign: TextAlign.start),
//                                   ),
//                                 ),
//                                 DataColumn(
//                                   label: Container(
//                                     //   color: Colors.red,
//                                     width: 160, // Largeur fixe pour Produit
//                                     child: Text('Produit',
//                                         textAlign: TextAlign.start),
//                                   ),
//                                 ),
//                                 DataColumn(
//                                   label: Container(
//                                     //   color: Colors.yellow,
//                                     width: 100,
//                                     // Largeur fixe pour Quantité
//                                     child: Text('Quantité',
//                                         textAlign: TextAlign.center),
//                                   ),
//                                 ),
//                                 DataColumn(
//                                   label: Container(
//                                     //   color: Colors.blue,
//                                     width: 60, // Largeur fixe pour Quantité
//                                     child: Text('S.Restant',
//                                         textAlign: TextAlign.center),
//                                   ),
//                                 ),
//                                 DataColumn(
//                                   label: Container(
//                                     //     color: Colors.red,
//                                     width: 50, // Largeur fixe pour Prix
//                                     child: Text('Prix U',
//                                         textAlign: TextAlign.start),
//                                   ),
//                                 ),
//                                 DataColumn(
//                                   label: Container(
//                                     //      color: Colors.brown,
//                                     width: 50, // Largeur fixe pour Total
//                                     child: Text('Total',
//                                         textAlign: TextAlign.start),
//                                   ),
//                                 ),
//                                 DataColumn(
//                                   label: Container(
//                                     //      color: Colors.green,
//                                     width: 50, // Largeur fixe pour Actions
//                                     child: Text('', textAlign: TextAlign.start),
//                                   ),
//                                 ),
//                               ],
//                               rows: provider.lignesFacture.map((ligne) {
//                                 final index =
//                                 provider.lignesFacture.indexOf(ligne);
//                                 final state =
//                                 provider.getLigneEditionState(index);
//                                 final stockRestant = ligne.produit.target
//                                     ?.calculerStockTotal() ??
//                                     0.0;
//                                 return DataRow(
//                                   // color: WidgetStateProperty.resolveWith<Color?>(
//                                   //   (Set<WidgetState> states) {
//                                   //     // Alternance des couleurs : grise et transparente
//                                   //     return index.isEven
//                                   //         ? null
//                                   //         : Colors.grey.shade200;
//                                   //   },
//                                   // ),
//                                   color:
//                                   WidgetStateProperty.resolveWith<Color?>(
//                                         (Set<WidgetState> states) {
//                                       // Alternance des couleurs : surface et surfaceVariant
//                                       return index.isEven
//                                           ? Theme.of(context)
//                                           .colorScheme
//                                           .surface
//                                           : Theme.of(context)
//                                           .colorScheme
//                                           .surfaceContainerHighest;
//                                     },
//                                   ),
//                                   cells: [
//                                     DataCell(SelectableText(
//                                         ligne.produit.target?.qr ?? ' - ')),
//                                     DataCell(InkWell(
//                                       onTap: () => Navigator.of(context).push(
//                                           MaterialPageRoute(
//                                               builder: (ctx) =>
//                                                   ProduitDetailPage(
//                                                       produit: ligne
//                                                           .produit.target!))),
//                                       child: Text(
//                                         ligne.produit.target?.nom ??
//                                             'Produit inconnu',
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     )),
//                                     // DataCell(
//                                     //   // state.isEditedQty
//                                     //   //     ? TextFormField(
//                                     //   //         initialValue: ligne.quantite.toStringAsFixed(2),
//                                     //   //         keyboardType: TextInputType.number,
//                                     //   //         onChanged: (value) {
//                                     //   //           final nouvelleQuantite =
//                                     //   //               double.tryParse(value) ?? 0;
//                                     //   //           provider.modifierLigne(
//                                     //   //             index,
//                                     //   //             nouvelleQuantite,
//                                     //   //             ligne.prixUnitaire,
//                                     //   //           );
//                                     //   //         },
//                                     //   //         onTapOutside: (event) {
//                                     //   //           provider.toggleEditQty(index);
//                                     //   //         },
//                                     //   //       )
//                                     //   //     :
//                                     //   Text(ligne.quantite.toStringAsFixed(2)),
//                                     //   // onTap: () {
//                                     //   //   provider.toggleEditQty(index);
//                                     //   // },
//                                     //   // onTapDown: (TapDownDetails) {
//                                     //   //   provider.toggleEditQty(index);
//                                     //   // },
//                                     //   // onTapCancel: () {
//                                     //   //   provider.toggleEditQty(index);
//                                     //   // },
//                                     // ),
//                                     DataCell(
//                                       Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           IconButton(
//                                             icon: Icon(Icons.remove),
//                                             onPressed: () {
//                                               // Décrémente la quantité
//                                               provider.modifierLigne(
//                                                 index,
//                                                 ligne.quantite - 1,
//                                                 ligne.prixUnitaire,
//                                               );
//                                             },
//                                           ),
//                                           Text(ligne.quantite
//                                               .toStringAsFixed(2)),
//                                           IconButton(
//                                             icon: Icon(Icons.add),
//                                             onPressed: () {
//                                               // Incrémente la quantité
//                                               provider.modifierLigne(
//                                                 index,
//                                                 ligne.quantite + 1,
//                                                 ligne.prixUnitaire,
//                                               );
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     DataCell(
//                                         Text(stockRestant.toStringAsFixed(2))),
//                                     DataCell(
//                                       // state.isEditedPu
//                                       //     ? TextFormField(
//                                       //         initialValue:
//                                       //             ligne.prixUnitaire.toStringAsFixed(2),
//                                       //         keyboardType: TextInputType.number,
//                                       //         onChanged: (value) {
//                                       //           final nouveauPrix =
//                                       //               double.tryParse(value) ?? 0;
//                                       //           provider.modifierLigne(
//                                       //             index,
//                                       //             ligne.quantite,
//                                       //             nouveauPrix,
//                                       //           );
//                                       //         },
//                                       //         onTapOutside: (event) {
//                                       //           provider.toggleEditPu(index);
//                                       //         },
//                                       //       )
//                                       //     :
//                                       Text(
//                                         ligne.prixUnitaire.toStringAsFixed(2),
//                                         textAlign: TextAlign.end,
//                                       ),
//
//                                       //     onTap: () {
//                                       //   provider.toggleEditPu(index);
//                                       // }, showEditIcon: true
//                                     ),
//                                     DataCell(Text(
//                                       (ligne.quantite * ligne.prixUnitaire)
//                                           .toStringAsFixed(2),
//                                       textAlign: TextAlign.end,
//                                     )),
//                                     DataCell(
//                                       Row(
//                                         children: [
//                                           IconButton(
//                                             icon: Icon(Icons.delete),
//                                             onPressed: () {
//                                               provider.supprimerLigne(index);
//                                             },
//                                           ),
//                                           IconButton(
//                                             icon: Icon(Icons.edit),
//                                             onPressed: () {
//                                               _showEditDialog(context, ligne,
//                                                   provider, index);
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 );
//                               }).toList(),
//                             ),
//                           ),
//                         ],
//                       );
//                   }
//                 },
//               ),
//
//         ),
//       );
//     });
//   }
// }
//
//
//
