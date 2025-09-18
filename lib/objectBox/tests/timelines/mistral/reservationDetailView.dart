// void _showReservationDetails(Reservation reservation) {
//   final nights = reservation.to.difference(reservation.from).inDays;
//   final totalPrice = reservation.totalPrice; // Utiliser le prix total calculé
//   final roomCode = reservation.room.target?.code ?? "N/A";
//   final roomCategory = reservation.room.target?.category.target?.name ?? "N/A";
//   final seasonalPricing = reservation.seasonalPricing.target;
//
//   // Calculer les détails des prix
//   final baseRoomTotal = reservation.pricePerNight * nights;
//   final seasonalMultiplier = seasonalPricing?.multiplier ?? 1.0;
//   final seasonalAdjustment = baseRoomTotal * (seasonalMultiplier - 1.0);
//
//   // Calculer le total des extras
//   final extrasTotal = reservation.extras
//       .fold(0.0, (sum, extra) => sum + (extra.totalPrice ?? 0.0));
//
//   // Calculer le total du plan de pension
//   final boardBasisTotal = reservation.boardBasis.target != null
//       ? reservation.boardBasis.target!.pricePerPerson *
//           reservation.guests.length *
//           nights
//       : 0.0;
//
//   // Informations sur les réductions
//   final hasDiscount =
//       reservation.discountPercent > 0 || reservation.discountAmount > 0;
//   final discountType = reservation.discountType ?? 'percentage';
//   final discountAppliedTo = reservation.discountAppliedTo ?? 'total';
//
//   showDialog(
//     context: context,
//     builder: (context) => Dialog(
//       insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: 500,
//           maxHeight: MediaQuery.of(context).size.height * 0.9,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // ==== HEADER ====
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Theme.of(context).primaryColor,
//                     Theme.of(context).primaryColor.withOpacity(0.8),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       Icons.receipt_long,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Détails de la Réservation',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'Réservation #${reservation.id}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.white.withOpacity(0.9),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//
//             // ==== CONTENU SCROLLABLE ====
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Informations principales
//                     _buildInfoCard88(
//                       title: 'Informations générales',
//                       icon: Icons.info_outline,
//                       children: [
//                         _buildDetailRow88('Chambre', 'ROOM-$roomCode'),
//                         _buildDetailRow88('Catégorie', roomCategory),
//                         _buildDetailRow88('Statut', reservation.status),
//                         _buildDetailRow88('Réceptionniste',
//                             reservation.receptionist.target?.fullName ?? 'N/A'),
//                       ],
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Clients
//                     _buildInfoCard88(
//                       title: 'Clients (${reservation.guests.length})',
//                       icon: Icons.people,
//                       children: reservation.guests
//                           .map(
//                             (guest) => Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                               child: Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 16,
//                                     backgroundColor: Theme.of(context)
//                                         .primaryColor
//                                         .withOpacity(0.2),
//                                     child: Text(
//                                       guest.fullName.isNotEmpty
//                                           ? guest.fullName
//                                               .substring(0, 1)
//                                               .toUpperCase()
//                                           : '?',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                         color: Theme.of(context).primaryColor,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           guest.fullName,
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                         if (guest.phoneNumber.isNotEmpty)
//                                           Text(
//                                             guest.phoneNumber,
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600],
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           )
//                           .toList(),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Dates et durée
//                     _buildInfoCard88(
//                       title: 'Séjour',
//                       icon: Icons.calendar_today,
//                       children: [
//                         _buildDateRow88(
//                             'Arrivée', reservation.from, Colors.green),
//                         _buildDateRow88('Départ', reservation.to, Colors.red),
//                         const SizedBox(height: 8),
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color:
//                                 Theme.of(context).primaryColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.hotel,
//                                 color: Theme.of(context).primaryColor,
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 '$nights nuit${nights > 1 ? 's' : ''}',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Theme.of(context).primaryColor,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Plan de pension si présent
//                     if (reservation.boardBasis.target != null) ...[
//                       _buildInfoCard88(
//                         title: 'Plan de pension',
//                         icon: Icons.restaurant,
//                         children: [
//                           _buildDetailRow88('Type',
//                               '${reservation.boardBasis.target!.name} (${reservation.boardBasis.target!.code})'),
//                           _buildDetailRow88('Prix par personne/nuit',
//                               '${reservation.boardBasis.target!.pricePerPerson.toStringAsFixed(2)} DA'),
//                           _buildDetailRow88('Total pension',
//                               '${boardBasisTotal.toStringAsFixed(2)} DA'),
//                           if (reservation
//                               .boardBasis.target!.inclusionsSummary.isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Text(
//                                 reservation
//                                     .boardBasis.target!.inclusionsSummary,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[600],
//                                   fontStyle: FontStyle.italic,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Services supplémentaires
//                     if (reservation.extras.isNotEmpty) ...[
//                       _buildInfoCard88(
//                         title:
//                             'Services supplémentaires (${reservation.extras.length})',
//                         icon: Icons.add_circle_outline,
//                         children: [
//                           ...reservation.extras
//                               .map(
//                                 (extra) => Container(
//                                   margin: const EdgeInsets.only(bottom: 8),
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue.withOpacity(0.05),
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(
//                                       color: Colors.blue.withOpacity(0.2),
//                                     ),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: Text(
//                                               extra.extraService.target?.name ??
//                                                   'Service inconnu',
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ),
//                                           Text(
//                                             '${(extra.totalPrice ?? 0.0).toStringAsFixed(2)} DA',
//                                             style: TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               color: Theme.of(context)
//                                                   .primaryColor,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: [
//                                           Text(
//                                             'Qté: ${extra.quantity}',
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600],
//                                             ),
//                                           ),
//                                           const SizedBox(width: 16),
//                                           Text(
//                                             'PU: ${extra.unitPrice.toStringAsFixed(2)} DA',
//                                             style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.green.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'Total extras',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   '${extrasTotal.toStringAsFixed(2)} DA',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.green[700],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Tarification saisonnière
//                     if (seasonalPricing != null) ...[
//                       _buildInfoCard88(
//                         title: 'Tarification saisonnière',
//                         icon: Icons.wb_sunny,
//                         children: [
//                           _buildDetailRow88('Saison', seasonalPricing.name),
//                           _buildDetailRow88('Période',
//                               '${_formatDate88(seasonalPricing.startDate)} - ${_formatDate88(seasonalPricing.endDate)}'),
//                           _buildDetailRow88('Multiplicateur',
//                               '${(seasonalMultiplier * 100).toStringAsFixed(0)}%'),
//                           if (seasonalAdjustment != 0)
//                             _buildDetailRow88('Ajustement saisonnier',
//                                 '${seasonalAdjustment > 0 ? '+' : ''}${seasonalAdjustment.toStringAsFixed(2)} DA'),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Réductions si présentes
//                     if (hasDiscount) ...[
//                       _buildInfoCard88(
//                         title: 'Réductions appliquées',
//                         icon: Icons.local_offer,
//                         children: [
//                           if (reservation.discountPercent > 0)
//                             _buildDetailRow88('Réduction pourcentage',
//                                 '${reservation.discountPercent.toStringAsFixed(1)}%'),
//                           if (reservation.discountAmount > 0)
//                             _buildDetailRow88('Réduction montant fixe',
//                                 '${reservation.discountAmount.toStringAsFixed(2)} DA'),
//                           _buildDetailRow88('Type d\'application',
//                               _getDiscountAppliedToLabel88(discountAppliedTo)),
//                           _buildDetailRow88(
//                               'Mode de calcul',
//                               discountType == 'percentage'
//                                   ? 'Pourcentage'
//                                   : 'Montant fixe'),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                     ],
//
//                     // Récapitulatif des prix
//                     _buildPricingCard88(
//                       reservation: reservation,
//                       nights: nights,
//                       baseRoomTotal: baseRoomTotal,
//                       seasonalAdjustment: seasonalAdjustment,
//                       boardBasisTotal: boardBasisTotal,
//                       extrasTotal: extrasTotal,
//                       totalPrice: totalPrice,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // ==== FOOTER ====
//             Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.green.shade400,
//                     Colors.green.shade600,
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(20),
//                   bottomRight: Radius.circular(20),
//                 ),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.celebration,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Réservation confirmée',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     reservation.guests.map((g) => g.fullName).join(", "),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.hotel,
//                           color: Colors.green.shade700,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           "ROOM-$roomCode",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green.shade700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
//
// Widget _buildInfoCard88({
//   required String title,
//   required IconData icon,
//   required List<Widget> children,
// }) {
//   return Card(
//     elevation: 2,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 icon,
//                 size: 20,
//                 color: Theme.of(context).primaryColor,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).primaryColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ...children,
//         ],
//       ),
//     ),
//   );
// }
//
// Widget _buildDetailRow88(String label, String value) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           flex: 2,
//           child: Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//             ),
//           ),
//         ),
//         Expanded(
//           flex: 3,
//           child: Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.w500,
//               fontSize: 14,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
//
// Widget _buildDateRow88(String label, DateTime date, Color color) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Icon(
//             label == 'Arrivée' ? Icons.flight_land : Icons.flight_takeoff,
//             color: color,
//             size: 16,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Text(
//               _formatDate88(date),
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }
//
// Widget _buildPricingCard88({
//   required Reservation reservation,
//   required int nights,
//   required double baseRoomTotal,
//   required double seasonalAdjustment,
//   required double boardBasisTotal,
//   required double extrasTotal,
//   required double totalPrice,
// }) {
//   return Card(
//     elevation: 3,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).primaryColor.withOpacity(0.05),
//             Theme.of(context).primaryColor.withOpacity(0.02),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.receipt,
//                 color: Theme.of(context).primaryColor,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Récapitulatif des prix',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).primaryColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//
//           // Chambre
//           _buildPriceRow88(
//             'Chambre ($nights nuit${nights > 1 ? 's' : ''})',
//             '${baseRoomTotal.toStringAsFixed(2)} DA',
//           ),
//
//           // Ajustement saisonnier
//           if (seasonalAdjustment != 0)
//             _buildPriceRow88(
//               'Ajustement saisonnier',
//               '${seasonalAdjustment > 0 ? '+' : ''}${seasonalAdjustment.toStringAsFixed(2)} DA',
//               color: seasonalAdjustment > 0 ? Colors.orange : Colors.blue,
//             ),
//
//           // Plan de pension
//           if (boardBasisTotal > 0)
//             _buildPriceRow88(
//               'Plan de pension',
//               '${boardBasisTotal.toStringAsFixed(2)} DA',
//             ),
//
//           // Services supplémentaires
//           if (extrasTotal > 0)
//             _buildPriceRow88(
//               'Services supplémentaires',
//               '${extrasTotal.toStringAsFixed(2)} DA',
//             ),
//
//           // Réductions
//           if (reservation.discountPercent > 0 ||
//               reservation.discountAmount > 0) ...[
//             const Divider(),
//             if (reservation.discountPercent > 0)
//               _buildPriceRow88(
//                 'Réduction (${reservation.discountPercent.toStringAsFixed(1)}%)',
//                 '-${_calculateDiscountAmount88(reservation, baseRoomTotal + boardBasisTotal + extrasTotal).toStringAsFixed(2)} DA',
//                 color: Colors.red,
//               ),
//             if (reservation.discountAmount > 0)
//               _buildPriceRow88(
//                 'Réduction (montant fixe)',
//                 '-${reservation.discountAmount.toStringAsFixed(2)} DA',
//                 color: Colors.red,
//               ),
//           ],
//
//           const Divider(thickness: 2),
//
//           // Total final
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'TOTAL À PAYER',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 Text(
//                   '${totalPrice.toStringAsFixed(2)} DA',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// Widget _buildPriceRow88(String label, String amount, {Color? color}) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             color: color ?? Colors.grey[700],
//           ),
//         ),
//         Text(
//           amount,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: color ?? Colors.grey[800],
//           ),
//         ),
//       ],
//     ),
//   );
// }
//
// String _getDiscountAppliedToLabel88(String appliedTo) {
//   switch (appliedTo) {
//     case 'room':
//       return 'Chambre uniquement';
//     case 'board':
//       return 'Plan de pension uniquement';
//     case 'extras':
//       return 'Services supplémentaires uniquement';
//     case 'total':
//       return 'Total général';
//     case 'specific':
//       return 'Éléments sélectionnés';
//     default:
//       return 'Non défini';
//   }
// }
//
// double _calculateDiscountAmount88(Reservation reservation, double subtotal) {
//   if (reservation.discountPercent > 0) {
//     return subtotal * (reservation.discountPercent / 100);
//   }
//   return reservation.discountAmount;
// }
//
// String _formatDate88(DateTime date) {
//   const months = [
//     '',
//     'Jan',
//     'Fév',
//     'Mar',
//     'Avr',
//     'Mai',
//     'Jun',
//     'Jul',
//     'Aoû',
//     'Sep',
//     'Oct',
//     'Nov',
//     'Déc'
//   ];
//
//   return '${date.day} ${months[date.month]} ${date.year}';
// }
