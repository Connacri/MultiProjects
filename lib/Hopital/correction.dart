// import 'package:flutter/material.dart';
//
// class test extends StatefulWidget {
//   const test({super.key});
//
//   @override
//   State<test> createState() => _testState();
// }
//
// class _testState extends State<test> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Wrap(
//           spacing: 8,
//           runSpacing: 4,
//           crossAxisAlignment: WrapCrossAlignment.center,
//           children: [
//             Text('Medical Staff Planning - '),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<int>(
//                   value: _selectedMonth,
//                   style: const TextStyle(color: Colors.white, fontSize: 16),
//                   dropdownColor: Colors.blue.shade700,
//                   items: List.generate(12, (index) {
//                     return DropdownMenuItem<int>(
//                       value: index + 1,
//                       child: Text(
//                         _moisNoms[index],
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     );
//                   }),
//                   onChanged: (value) {
//                     if (value != null) {
//                       setState(() {
//                         _selectedMonth = value;
//                         _editingCells.clear();
//                         _tempValues.clear();
//                       });
//                     }
//                   },
//                 ),
//               ),
//             ),
//             Text('$_selectedYear'),
//           ],
//         ),
//         backgroundColor: Colors.blue.shade700,
//         foregroundColor: Colors.white,
//         actions: [
//           LayoutBuilder(
//             builder: (context, constraints) {
//               if (constraints.maxWidth > 600) {
//                 // ✅ Desktop : toutes les icônes visibles
//                 return Row(
//                   children: [
//                     _buildEditControls(),
//                     IconButton(
//                       icon: const Icon(Icons.delete_forever, color: Colors.red),
//                       tooltip: "Vider toutes les activités",
//                       onPressed: () async {
//                         final confirm = await showDialog<bool>(
//                           context: context,
//                           builder: (context) => AlertDialog(
//                             title: const Text("Confirmation"),
//                             content: const Text(
//                                 "Voulez-vous vraiment supprimer toutes les activités ?"),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, false),
//                                 child: const Text("Annuler"),
//                               ),
//                               ElevatedButton(
//                                 onPressed: () => Navigator.pop(context, true),
//                                 child: const Text("Oui, vider"),
//                               ),
//                             ],
//                           ),
//                         );
//                         if (confirm == true) {
//                           // Appel via le Provider
//                           await context
//                               .read<ActiviteProvider>()
//                               .clearAllActivites(context);
//                           // Feedback utilisateur
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content:
//                                 Text("Toutes les activités ont été supprimées.")),
//                           );
//                         }
//                       },
//                     ),
//                     Tooltip(
//                       message: "Ajouter toutes les activités",
//                       child: IconButton(
//                         icon: const Icon(Icons.add, color: Colors.blue),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: Colors.blue,
//                         ),
//                         onPressed: () async {
//                           // Demander confirmation avant de vider la base
//                           final confirm = await showDialog<bool>(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 title: const Text("Confirmation"),
//                                 content: const Text(
//                                   "Cette action va supprimer toutes les données existantes et les remplacer par les nouvelles. Continuer ?",
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.of(context).pop(false),
//                                     child: const Text("Annuler"),
//                                   ),
//                                   ElevatedButton(
//                                     onPressed: () => Navigator.of(context).pop(true),
//                                     child: const Text("Confirmer"),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//
//                           if (confirm != true) return;
//
//                           try {
//                             final activiteProvider = ActiviteProvider();
//                             await activiteProvider.insertActivites(activites,
//                                 year: _selectedYear, month: _selectedMonth);
//
//                             // Rafraîchir les données
//                             final staffProvider =
//                             Provider.of<StaffProvider>(context, listen: false);
//                             await staffProvider.fetchStaffs();
//
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                     "Toutes les activités ont été ajoutées avec succès !"),
//                                 backgroundColor: Colors.green,
//                               ),
//                             );
//                           } catch (e) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text("Erreur lors de l'insertion: $e"),
//                                 backgroundColor: Colors.red,
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                     Tooltip(
//                       message: 'Fetch Staff',
//                       child: IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: () {
//                           final provider =
//                           Provider.of<StaffProvider>(context, listen: false);
//                           provider.fetchStaffs();
//                         },
//                       ),
//                     )
//                   ],
//                 );
//               } else {
//                 // ✅ Mobile : menu dropdown
//                 return PopupMenuButton<String>(
//                   icon: const Icon(Icons.more_vert, color: Colors.white),
//                   onSelected: (value) async {
//                     switch (value) {
//                       case 'edit':
//                         _buildEditControls(); // ⚠️ si tu veux l’action directe, il faut transformer en fonction
//                         break;
//                       case 'clear':
//                         await context
//                             .read<ActiviteProvider>()
//                             .clearAllActivites(context);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                               content: Text(
//                                   "Toutes les activités ont été supprimées.")),
//                         );
//                         break;
//                       case 'insert':
//                         final activiteProvider = ActiviteProvider();
//                         await activiteProvider.insertActivites(
//                           activites,
//                           year: _selectedYear,
//                           month: _selectedMonth,
//                         );
//                         await context.read<StaffProvider>().fetchStaffs();
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                               content: Text(
//                                   "Toutes les activités ont été ajoutées avec succès !")),
//                         );
//                         break;
//                       case 'refresh':
//                         context.read<StaffProvider>().fetchStaffs();
//                         break;
//                     }
//                   },
//                   itemBuilder: (context) => [
//                     const PopupMenuItem(value: 'edit', child: Text("Modifier")),
//                     const PopupMenuItem(
//                         value: 'clear', child: Text("Vider les activités")),
//                     const PopupMenuItem(
//                         value: 'insert', child: Text("Ajouter les activités")),
//                     const PopupMenuItem(
//                         value: 'refresh', child: Text("Rafraîchir")),
//                   ],
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
