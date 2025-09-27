import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';
import 'ActivitePersonne.dart';
import 'StaffProvider.dart';

class TableauStaffPage extends StatefulWidget {
  @override
  _TableauStaffPageState createState() => _TableauStaffPageState();
}

class _TableauStaffPageState extends State<TableauStaffPage> {
  // ⭐ NOUVEAU : Variables pour la gestion du mois et année
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Variables pour gérer l'édition
  Map<String, bool> _editingCells = {}; // Clé: "staffId-jour"
  Map<String, String> _tempValues = {}; // Valeurs temporaires pendant l'édition

  // Liste des statuts disponibles pour le dropdown
  final List<String> _statutsDisponibles = ['G', "Ré", 'C', 'CM', 'N', '-'];

  // ⭐ NOUVEAU : Liste des mois en français
  final List<String> _moisNoms = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StaffProvider>(context, listen: false);
      provider.fetchStaffs();
    });
  }

  // ⭐ NOUVEAU : Obtenir le nombre de jours dans le mois sélectionné
  int get _daysInSelectedMonth =>
      DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

  // ⭐ NOUVEAU : Obtenir le nom du mois sélectionné
  String get _selectedMonthName => _moisNoms[_selectedMonth - 1];

// 4. Modifier aussi la méthode _saveActiviteModification
  Future<void> _saveActiviteModification(
      Staff staff, int jour, String nouveauStatut) async {
    try {
      final activiteProvider = ActiviteProvider();
      await activiteProvider.updateActivite(staff.id, jour, nouveauStatut,
          year: _selectedYear, month: _selectedMonth);

      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Statut modifié avec succès pour le jour $jour"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la modification: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// // NOUVELLE MÉTHODE à ajouter - Force la mise à jour même sur des congés existants
//   Future<void> _forceUpdateActivite(
//       int staffId, int jour, String statut) async {
//     try {
//       final objectBox = ObjectBox();
//       final staff = objectBox.staffBox.get(staffId);
//       if (staff == null) return;
//
//       final query = objectBox.activiteBox
//           .query(ActiviteJour_.staff.equals(staffId) &
//               ActiviteJour_.jour.equals(jour))
//           .build();
//
//       final activites = query.find();
//       query.close();
//
//       if (activites.isNotEmpty) {
//         final activite = activites.first;
//         activite.statut = statut;
//         objectBox.activiteBox.put(activite);
//         print("🔄 Activité forcée: ${staff.nom} jour $jour = $statut");
//       } else {
//         final nouvelle = ActiviteJour(jour: jour, statut: statut)
//           ..staff.target = staff;
//         objectBox.activiteBox.put(nouvelle);
//         print("➕ Nouvelle activité congé: ${staff.nom} jour $jour = $statut");
//       }
//     } catch (e) {
//       print("Erreur _forceUpdateActivite: $e");
//     }
//   }

  // Fonction pour grouper les staffs
  Map<String, List<dynamic>> _groupStaffs(List<Staff> staffs) {
    Map<String, List<dynamic>> groupedStaffs = {};

    // Définir les groupes dans l'ordre souhaité
    final ordreGroupes = [
      'Personnel Médical',
      'Personnel Administratif (08h-16h)',
      'Personnel Paramédical (08h-08h)',
      'Agents d\'hygiène (08h-12h)',
    ];

    // Initialiser les groupes
    for (String groupe in ordreGroupes) {
      groupedStaffs[groupe] = [];
    }

    int numeroGlobal = 1;

    for (var staff in staffs) {
      String groupeAffichage;

      // Déterminer le groupe d'affichage selon les grades
      if (staff.grade.toLowerCase().contains('médecin') ||
          staff.grade.toLowerCase().contains('rhumatologue')) {
        groupeAffichage = 'Personnel Médical';
      } else if (staff.groupe == '08H-16H') {
        groupeAffichage = 'Personnel Administratif (08h-16h)';
      } else if (staff.groupe == '08H-08H' || staff.groupe == 'Garde 12H') {
        groupeAffichage = 'Personnel Paramédical (08h-08h)';
      } else if (staff.grade.toLowerCase().contains('hygiène')) {
        groupeAffichage = 'Agents d\'hygiène (08h-12h)';
      } else {
        groupeAffichage = 'Personnel Administratif (08h-16h)'; // Par défaut
      }

      // Déterminer l'équipe
      String equipe = staff.equipe ?? '-';

      groupedStaffs[groupeAffichage]!.add({
        'staff': staff,
        'numero': numeroGlobal++,
        'equipe': equipe,
      });
    }

    // Supprimer les groupes vides
    groupedStaffs.removeWhere((key, value) => value.isEmpty);

    return groupedStaffs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Planning du Personnel - '),
            // ⭐ NOUVEAU : Dropdown pour sélectionner le mois
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  dropdownColor: Colors.blue.shade700,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(
                        _moisNoms[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMonth = value;
                        // Nettoyer les états d'édition lors du changement de mois
                        _editingCells.clear();
                        _tempValues.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            Text(' $_selectedYear'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          _buildEditControls(),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Vider toutes les activités",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmation"),
                  content: const Text(
                      "Voulez-vous vraiment supprimer toutes les activités ?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Annuler"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Oui, vider"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Appel via le Provider
                await context
                    .read<ActiviteProvider>()
                    .clearAllActivites(context);
                // Feedback utilisateur
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Toutes les activités ont été supprimées.")),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: "Ajouter toutes les activités",
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              onPressed: () async {
                // Demander confirmation avant de vider la base
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirmation"),
                      content: const Text(
                        "Cette action va supprimer toutes les données existantes et les remplacer par les nouvelles. Continuer ?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Annuler"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Confirmer"),
                        ),
                      ],
                    );
                  },
                );

                if (confirm != true) return;

                try {
                  final activiteProvider = ActiviteProvider();
                  await activiteProvider.insertActivites(activites,
                      year: _selectedYear, month: _selectedMonth);

                  // Rafraîchir les données
                  final staffProvider =
                      Provider.of<StaffProvider>(context, listen: false);
                  await staffProvider.fetchStaffs();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Toutes les activités ont été ajoutées avec succès !"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur lors de l'insertion: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Fetch Staff',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final provider =
                    Provider.of<StaffProvider>(context, listen: false);
                provider.fetchStaffs();
              },
            ),
          )
        ],
      ),
      body: Consumer<StaffProvider>(
        builder: (context, provider, child) {
          final staffs = provider.staffs;

          if (staffs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: Colors.blue.shade300),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun personnel trouvé',
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Appuyez sur "Ajouter toutes les activités" pour commencer',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groupedStaffs = _groupStaffs(staffs);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête général
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'PLANNING DU PERSONNEL MÉDICAL ET PARAMÉDICAL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Branch : ${staffs.first.branch.target!.branchNom.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          // ⭐ MISE À JOUR : Utiliser le mois et année sélectionnés
                          'Mois de $_selectedMonthName $_selectedYear',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Légende des statuts
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Légende des statuts:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app,
                                      size: 14, color: Colors.blue.shade700),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cliquez sur les cellules pour éditer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildLegendItem(
                                      'G', Colors.green, 'Garde 12h'),
                                  _buildLegendItem(
                                      'RÉ', Colors.blue, 'Récupération'),
                                  _buildLegendItem('C', Colors.orange, 'Congé'),
                                  _buildLegendItem(
                                      'CM', Colors.purple, 'Congé Maladie'),
                                  _buildLegendItem('N', Colors.red, 'Normal'),
                                  _buildLegendItem('-', Colors.grey, 'Aucun'),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.auto_awesome,
                                        size: 16),
                                    label:
                                        const Text("Planification automatique"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      // Demander confirmation
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Confirmation"),
                                            content: Text(
                                              "Cette action va :\n"
                                              "• Marquer 'RE' les weekends (vendredi/samedi) pour TOUS\n"
                                              "• Marquer '-' les jours normaux pour les équipes A,B,C,D\n"
                                              "• Marquer 'N' les jours normaux pour les autres staff\n"
                                              "\nMois: $_selectedMonthName $_selectedYear\n"
                                              "Continuer ?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text("Annuler"),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.purple,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text("Confirmer"),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm != true) return;

                                      try {
                                        final staffProvider =
                                            Provider.of<StaffProvider>(context,
                                                listen: false);
                                        final activiteProvider =
                                            ActiviteProvider();

                                        final daysInMonth =
                                            _daysInSelectedMonth;
                                        int weekendDaysCount = 0;
                                        int normalDaysCount = 0;
                                        int totalModifications = 0;
                                        int staffEquipeABCD = 0;
                                        int staffAutres = 0;
                                        int congesIgnores =
                                            0; // NOUVEAU: Compteur des congés

                                        // Parcourir TOUS les staffs
                                        for (final staff
                                            in staffProvider.staffs) {
                                          // 🚫 Ignorer le groupe "08H-08H"
                                          if (staff.groupe == "Garde 12H") {
                                            print(
                                                "⏩ ${staff.nom} ignoré car groupe = 08H-08H");
                                            continue; // passe au staff suivant
                                          }
                                          if (staff.grade ==
                                              "Agent d'hygiène") {
                                            print(
                                                "⏩ ${staff.nom} ignoré car Grade = Agent d'hygiène");
                                            continue; // passe au staff suivant
                                          }
                                          final equipe =
                                              staff.equipe?.toUpperCase();
                                          final isEquipeABCD = equipe != null &&
                                              ['A', 'B', 'C', 'D']
                                                  .contains(equipe);

                                          if (isEquipeABCD) {
                                            staffEquipeABCD++;
                                          } else {
                                            staffAutres++;
                                          }

                                          for (int day = 1;
                                              day <= daysInMonth;
                                              day++) {
                                            final date = DateTime(_selectedYear,
                                                _selectedMonth, day);

                                            // VÉRIFICATION CONGÉS AVANT MODIFICATION
                                            final timeOffs =
                                                staff.timeOff.toList();
                                            bool estEnConge = false;

                                            for (var timeOff in timeOffs) {
                                              if (date.isAfter(timeOff.debut
                                                      .subtract(const Duration(
                                                          days: 1))) &&
                                                  date.isBefore(timeOff.fin.add(
                                                      const Duration(
                                                          days: 1)))) {
                                                estEnConge = true;
                                                congesIgnores++;
                                                break;
                                              }
                                            }

                                            if (estEnConge) {
                                              print(
                                                  "🚫 ${staff.nom} en congé le jour $day - Planification ignorée");
                                              continue; // Ignorer ce jour
                                            }

                                            if (date.weekday ==
                                                    DateTime.friday ||
                                                date.weekday ==
                                                    DateTime.saturday) {
                                              // Week-end : marquer 'RE' pour TOUS
                                              await activiteProvider
                                                  .updateActivite(
                                                staff.id,
                                                day,
                                                "RE",
                                                year: _selectedYear,
                                                month: _selectedMonth,
                                              );
                                              totalModifications++;

                                              if (staff ==
                                                  staffProvider.staffs.first) {
                                                weekendDaysCount++;
                                              }
                                            } else {
                                              // Jours normaux
                                              if (isEquipeABCD) {
                                                await activiteProvider
                                                    .updateActivite(
                                                  staff.id,
                                                  day,
                                                  "-",
                                                  year: _selectedYear,
                                                  month: _selectedMonth,
                                                );
                                              } else {
                                                await activiteProvider
                                                    .updateActivite(
                                                  staff.id,
                                                  day,
                                                  "N",
                                                  year: _selectedYear,
                                                  month: _selectedMonth,
                                                );
                                              }
                                              totalModifications++;

                                              if (staff ==
                                                  staffProvider.staffs.first) {
                                                normalDaysCount++;
                                              }
                                            }
                                          }
                                        }

                                        // Rafraîchir les données
                                        await staffProvider.fetchStaffs();

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.green,
                                            duration:
                                                const Duration(seconds: 5),
                                            content: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Texte principal
                                                Expanded(
                                                  child: Text(
                                                    "✅ Planification automatique terminée!\n"
                                                    "• $weekendDaysCount jours de weekend marqués 'RE'\n"
                                                    "• $normalDaysCount jours normaux traités\n"
                                                    "• $staffEquipeABCD staff équipes A,B,C,D → '-' jours normaux\n"
                                                    "• $staffAutres autres staff → 'N' jours normaux\n"
                                                    "• $congesIgnores jours de congé préservés\n"
                                                    "• $totalModifications modifications totales",
                                                  ),
                                                ),

                                                // Icône close
                                                IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .hideCurrentSnackBar();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                "❌ Erreur lors de la planification: $e"),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.medical_services,
                                        size: 16),
                                    label:
                                        const Text("Planifier gardes médical"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await _showSimplePlanificationDialog();
                                    },
                                  ),
                                  // ElevatedButton.icon(
                                  //   icon: const Icon(Icons.medical_services,
                                  //       size: 16),
                                  //   label:
                                  //       const Text("Planifier gardes médical"),
                                  //   style: ElevatedButton.styleFrom(
                                  //     backgroundColor: Colors.teal,
                                  //     foregroundColor: Colors.white,
                                  //   ),
                                  //   onPressed: () async {
                                  //     // Dialog pour choisir l'équipe et le jour de départ
                                  //     final result = await showDialog<
                                  //         Map<String, dynamic>>(
                                  //       context: context,
                                  //       builder: (BuildContext context) {
                                  //         String? chosenEquipe;
                                  //         int? chosenDay;
                                  //         return StatefulBuilder(
                                  //           builder: (context, setState) {
                                  //             return AlertDialog(
                                  //               title: const Text(
                                  //                   "Planification des gardes médicales"),
                                  //               content: SingleChildScrollView(
                                  //                 child: Column(
                                  //                   crossAxisAlignment:
                                  //                       CrossAxisAlignment
                                  //                           .start,
                                  //                   mainAxisSize:
                                  //                       MainAxisSize.min,
                                  //                   children: [
                                  //                     Text(
                                  //                       "Mois: $_selectedMonthName $_selectedYear\n",
                                  //                       style: const TextStyle(
                                  //                         fontWeight:
                                  //                             FontWeight.bold,
                                  //                         color: Colors.teal,
                                  //                       ),
                                  //                     ),
                                  //
                                  //                     // Sélection du jour de commencement
                                  //                     const Text(
                                  //                         "Jour de commencement:",
                                  //                         style: TextStyle(
                                  //                             fontWeight:
                                  //                                 FontWeight
                                  //                                     .bold)),
                                  //                     const SizedBox(height: 8),
                                  //                     Container(
                                  //                       height: 200,
                                  //                       width: double.maxFinite,
                                  //                       decoration:
                                  //                           BoxDecoration(
                                  //                         border: Border.all(
                                  //                             color: Colors.grey
                                  //                                 .shade300),
                                  //                         borderRadius:
                                  //                             BorderRadius
                                  //                                 .circular(8),
                                  //                       ),
                                  //                       child: GridView.builder(
                                  //                         padding:
                                  //                             const EdgeInsets
                                  //                                 .all(8),
                                  //                         gridDelegate:
                                  //                             const SliverGridDelegateWithFixedCrossAxisCount(
                                  //                           crossAxisCount: 7,
                                  //                           crossAxisSpacing: 4,
                                  //                           mainAxisSpacing: 4,
                                  //                           childAspectRatio: 1,
                                  //                         ),
                                  //                         itemCount:
                                  //                             _daysInSelectedMonth,
                                  //                         itemBuilder:
                                  //                             (context, index) {
                                  //                           final day =
                                  //                               index + 1;
                                  //                           return GestureDetector(
                                  //                             onTap: () =>
                                  //                                 setState(() =>
                                  //                                     chosenDay =
                                  //                                         day),
                                  //                             child: Container(
                                  //                               decoration:
                                  //                                   BoxDecoration(
                                  //                                 color: chosenDay ==
                                  //                                         day
                                  //                                     ? Colors
                                  //                                         .teal
                                  //                                     : Colors
                                  //                                         .grey
                                  //                                         .shade100,
                                  //                                 borderRadius:
                                  //                                     BorderRadius
                                  //                                         .circular(
                                  //                                             4),
                                  //                                 border: Border
                                  //                                     .all(
                                  //                                   color: chosenDay == day
                                  //                                       ? Colors
                                  //                                           .teal
                                  //                                           .shade700
                                  //                                       : Colors
                                  //                                           .grey
                                  //                                           .shade400,
                                  //                                 ),
                                  //                               ),
                                  //                               child: Center(
                                  //                                 child: Text(
                                  //                                   day.toString(),
                                  //                                   style:
                                  //                                       TextStyle(
                                  //                                     color: chosenDay ==
                                  //                                             day
                                  //                                         ? Colors
                                  //                                             .white
                                  //                                         : Colors
                                  //                                             .black87,
                                  //                                     fontWeight: chosenDay ==
                                  //                                             day
                                  //                                         ? FontWeight
                                  //                                             .bold
                                  //                                         : FontWeight
                                  //                                             .normal,
                                  //                                   ),
                                  //                                 ),
                                  //                               ),
                                  //                             ),
                                  //                           );
                                  //                         },
                                  //                       ),
                                  //                     ),
                                  //
                                  //                     const SizedBox(
                                  //                         height: 16),
                                  //
                                  //                     // Sélection de l'équipe de départ
                                  //                     const Text(
                                  //                         "Équipe qui commence:",
                                  //                         style: TextStyle(
                                  //                             fontWeight:
                                  //                                 FontWeight
                                  //                                     .bold)),
                                  //                     const SizedBox(height: 8),
                                  //                     Wrap(
                                  //                       spacing: 8,
                                  //                       children: [
                                  //                         "A",
                                  //                         "B",
                                  //                         "C",
                                  //                         "D"
                                  //                       ].map((equipe) {
                                  //                         return ChoiceChip(
                                  //                           label: Text(
                                  //                               "Équipe $equipe"),
                                  //                           selected:
                                  //                               chosenEquipe ==
                                  //                                   equipe,
                                  //                           onSelected: (bool
                                  //                               selected) {
                                  //                             setState(() {
                                  //                               chosenEquipe =
                                  //                                   selected
                                  //                                       ? equipe
                                  //                                       : null;
                                  //                             });
                                  //                           },
                                  //                           selectedColor:
                                  //                               Colors.teal
                                  //                                   .shade200,
                                  //                         );
                                  //                       }).toList(),
                                  //                     ),
                                  //
                                  //                     const SizedBox(
                                  //                         height: 16),
                                  //                     Container(
                                  //                       padding:
                                  //                           const EdgeInsets
                                  //                               .all(12),
                                  //                       decoration:
                                  //                           BoxDecoration(
                                  //                         color: Colors
                                  //                             .blue.shade50,
                                  //                         borderRadius:
                                  //                             BorderRadius
                                  //                                 .circular(8),
                                  //                         border: Border.all(
                                  //                             color: Colors.blue
                                  //                                 .shade200),
                                  //                       ),
                                  //                       child: Column(
                                  //                         crossAxisAlignment:
                                  //                             CrossAxisAlignment
                                  //                                 .start,
                                  //                         children: [
                                  //                           Text(
                                  //                               "Logique de planification:",
                                  //                               style: TextStyle(
                                  //                                   fontWeight:
                                  //                                       FontWeight
                                  //                                           .bold,
                                  //                                   color: Colors
                                  //                                       .blue
                                  //                                       .shade700)),
                                  //                           const SizedBox(
                                  //                               height: 4),
                                  //                           const Text(
                                  //                               "• L'équipe sélectionnée commence le jour choisi",
                                  //                               style: TextStyle(
                                  //                                   fontSize:
                                  //                                       12)),
                                  //                           const Text(
                                  //                               "• Rotation A → B → C → D",
                                  //                               style: TextStyle(
                                  //                                   fontSize:
                                  //                                       12)),
                                  //                           const Text(
                                  //                               "• Équipe de garde = 'G', autres = 'RE'",
                                  //                               style: TextStyle(
                                  //                                   fontSize:
                                  //                                       12)),
                                  //                           const Text(
                                  //                               "• Les congés sont respectés",
                                  //                               style: TextStyle(
                                  //                                   fontSize:
                                  //                                       12)),
                                  //                         ],
                                  //                       ),
                                  //                     ),
                                  //                   ],
                                  //                 ),
                                  //               ),
                                  //               actions: [
                                  //                 TextButton(
                                  //                   onPressed: () =>
                                  //                       Navigator.of(context)
                                  //                           .pop(null),
                                  //                   child:
                                  //                       const Text("Annuler"),
                                  //                 ),
                                  //                 ElevatedButton(
                                  //                   style: ElevatedButton
                                  //                       .styleFrom(
                                  //                     backgroundColor:
                                  //                         Colors.teal,
                                  //                     foregroundColor:
                                  //                         Colors.white,
                                  //                   ),
                                  //                   onPressed: (chosenEquipe !=
                                  //                               null &&
                                  //                           chosenDay != null)
                                  //                       ? () => Navigator.of(
                                  //                                   context)
                                  //                               .pop({
                                  //                             'equipe':
                                  //                                 chosenEquipe,
                                  //                             'day': chosenDay,
                                  //                           })
                                  //                       : null,
                                  //                   child:
                                  //                       const Text("Confirmer"),
                                  //                 ),
                                  //               ],
                                  //             );
                                  //           },
                                  //         );
                                  //       },
                                  //     );
                                  //
                                  //     if (result == null) return;
                                  //
                                  //     final selectedEquipe =
                                  //         result['equipe'] as String;
                                  //     final selectedDay = result['day'] as int;
                                  //
                                  //     try {
                                  //       final staffProvider =
                                  //           Provider.of<StaffProvider>(context,
                                  //               listen: false);
                                  //       final activiteProvider =
                                  //           ActiviteProvider();
                                  //
                                  //       final daysInMonth =
                                  //           _daysInSelectedMonth;
                                  //       final equipes = ["A", "B", "C", "D"];
                                  //       final startEquipeIndex =
                                  //           equipes.indexOf(selectedEquipe);
                                  //
                                  //       int totalModifications = 0;
                                  //       int joursGarde = 0;
                                  //       Map<String, int> gardesParEquipe = {
                                  //         for (var e in equipes) e: 0
                                  //       };
                                  //
                                  //       // Filtrer personnel médical avec équipes A,B,C,D
                                  //       final personnelMedical =
                                  //           staffProvider.staffs.where((staff) {
                                  //         final hasEquipe = staff.equipe !=
                                  //                 null &&
                                  //             equipes.contains(
                                  //                 staff.equipe!.toUpperCase());
                                  //         return hasEquipe;
                                  //       }).toList();
                                  //
                                  //       if (personnelMedical.isEmpty) {
                                  //         ScaffoldMessenger.of(context)
                                  //             .showSnackBar(
                                  //           const SnackBar(
                                  //             content: Text(
                                  //                 "❌ Aucun personnel médical trouvé avec équipes A,B,C,D"),
                                  //             backgroundColor: Colors.red,
                                  //           ),
                                  //         );
                                  //         return;
                                  //       }
                                  //
                                  //       /// Fonction utilitaire pour tester si staff est en congé
                                  //       bool estEnConge(staff, int day) {
                                  //         return staff.timeOff.any((timeOff) =>
                                  //             DateTime(_selectedYear,
                                  //                     _selectedMonth, day)
                                  //                 .isAfter(timeOff.debut
                                  //                     .subtract(const Duration(
                                  //                         days: 1))) &&
                                  //             DateTime(_selectedYear,
                                  //                     _selectedMonth, day)
                                  //                 .isBefore(timeOff.fin.add(
                                  //                     const Duration(days: 1))));
                                  //       }
                                  //
                                  //       /// Rotation unique (1 → N)
                                  //       for (int i = 0; i < daysInMonth; i++) {
                                  //         final day = ((selectedDay - 1 + i) %
                                  //                 daysInMonth) +
                                  //             1;
                                  //         final equipeIndex =
                                  //             (startEquipeIndex + i) %
                                  //                 equipes.length;
                                  //         final equipeDeGarde =
                                  //             equipes[equipeIndex];
                                  //
                                  //         joursGarde++;
                                  //         gardesParEquipe[equipeDeGarde] =
                                  //             (gardesParEquipe[equipeDeGarde] ??
                                  //                     0) +
                                  //                 1;
                                  //
                                  //         for (final staff
                                  //             in personnelMedical) {
                                  //           final staffEquipe =
                                  //               staff.equipe!.toUpperCase();
                                  //           if (estEnConge(staff, day))
                                  //             continue;
                                  //
                                  //           await activiteProvider
                                  //               .updateActivite(
                                  //             staff.id,
                                  //             day,
                                  //             staffEquipe == equipeDeGarde
                                  //                 ? "G"
                                  //                 : "RE",
                                  //             year: _selectedYear,
                                  //             month: _selectedMonth,
                                  //           );
                                  //           totalModifications++;
                                  //         }
                                  //       }
                                  //
                                  //       await staffProvider.fetchStaffs();
                                  //
                                  //       String resumeGardes = gardesParEquipe
                                  //           .entries
                                  //           .where((e) => e.value > 0)
                                  //           .map((e) =>
                                  //               "${e.key}: ${e.value} jours")
                                  //           .join(", ");
                                  //
                                  //       ScaffoldMessenger.of(context)
                                  //           .showSnackBar(
                                  //         SnackBar(
                                  //           backgroundColor: Colors.green,
                                  //           duration:
                                  //               const Duration(seconds: 6),
                                  //           content: Row(
                                  //             crossAxisAlignment:
                                  //                 CrossAxisAlignment.start,
                                  //             children: [
                                  //               Expanded(
                                  //                 child: Text(
                                  //                   "✅ Gardes médicales planifiées !\n"
                                  //                   "• Début: Jour $selectedDay, Équipe $selectedEquipe\n"
                                  //                   "• $joursGarde jours planifiés\n"
                                  //                   "• Répartition: $resumeGardes\n"
                                  //                   "• ${personnelMedical.length} médecins concernés\n"
                                  //                   "• $totalModifications modifications",
                                  //                 ),
                                  //               ),
                                  //               IconButton(
                                  //                 icon: const Icon(Icons.close,
                                  //                     color: Colors.white),
                                  //                 onPressed: () {
                                  //                   ScaffoldMessenger.of(
                                  //                           context)
                                  //                       .hideCurrentSnackBar();
                                  //                 },
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       );
                                  //     } catch (e) {
                                  //       ScaffoldMessenger.of(context)
                                  //           .showSnackBar(
                                  //         SnackBar(
                                  //           content: Text(
                                  //               "❌ Erreur lors de la planification: $e"),
                                  //           backgroundColor: Colors.red,
                                  //           duration:
                                  //               const Duration(seconds: 3),
                                  //         ),
                                  //       );
                                  //     }
                                  //   },
                                  // ),
                                  // ElevatedButton.icon(
                                  //   icon: const Icon(Icons.medical_services,
                                  //       size: 16),
                                  //   label:
                                  //       const Text("Planifier gardes médical"),
                                  //   style: ElevatedButton.styleFrom(
                                  //     backgroundColor: Colors.teal,
                                  //     foregroundColor: Colors.white,
                                  //   ),
                                  //   onPressed: () async {
                                  //     await _showAdvancedPlanificationDialog();
                                  //   },
                                  // ),
                                  FilledButton.tonalIcon(
                                      onPressed: () => _listStaffWithTimeOff(),
                                      label: Text('List Congé debug'))
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tableaux pour chaque groupe
                  ...groupedStaffs.entries.map((entry) {
                    String groupeName = entry.key;
                    List<dynamic> groupStaffs = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header du groupe
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$groupeName (${groupStaffs.length} personnes)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tableau pour ce groupe
                        Center(
                          child: Container(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DataTable(
                                  columnSpacing: 5,
                                  headingRowHeight: 40,
                                  dataRowHeight: 40,
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.grey.shade300),
                                  border: TableBorder.all(
                                      color: Colors.grey.shade300, width: 0.5),
                                  columns: [
                                    const DataColumn(
                                      label: Text('N°',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const DataColumn(
                                      label: Text('Nom et Prénom',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const DataColumn(
                                      label: Text('Grade/Fonction',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const DataColumn(
                                      label: Text('Équipe',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const DataColumn(
                                      label: Text('OBS',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    // ⭐ MISE À JOUR : Générer les colonnes selon le mois sélectionné
                                    ...List.generate(
                                      _daysInSelectedMonth,
                                      (i) {
                                        final jour = i + 1;
                                        final date = DateTime(_selectedYear,
                                            _selectedMonth, jour);

                                        Color? bgColor;
                                        if (date.weekday == DateTime.friday) {
                                          bgColor = Colors.red.shade100;
                                        } else if (date.weekday ==
                                            DateTime.saturday) {
                                          bgColor = Colors.blue.shade100;
                                        }
                                        String nomDuJour =
                                            DateFormat('EEE', 'fr_FR')
                                                .format(date);
                                        return DataColumn(
                                          label: Container(
                                            width: 28,
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$jour\n${nomDuJour}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  rows: groupStaffs.map<DataRow>((staffData) {
                                    final staff = staffData['staff'] as Staff;
                                    final numero = staffData['numero'] as int;
                                    final equipe =
                                        staffData['equipe'] as String;

                                    // Charger les activités
                                    final activites = staff.activites.toList();
                                    // ⭐ MISE À JOUR : Adapter la taille selon le mois
                                    List<String> jours =
                                        List.filled(_daysInSelectedMonth, '-');
                                    for (var activite in activites) {
                                      if (activite.jour >= 1 &&
                                          activite.jour <=
                                              _daysInSelectedMonth) {
                                        jours[activite.jour - 1] =
                                            activite.statut;
                                      }
                                    }

                                    // Charger les congés
                                    final timeOffs = staff.timeOff.toList();

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith<
                                          Color?>(
                                        (states) => states
                                                .contains(MaterialState.hovered)
                                            ? Colors.blue.shade50
                                            : null,
                                      ),
                                      cells: [
                                        DataCell(Text('$numero',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                fontSize: 14))),
                                        DataCell(InkWell(
                                          onDoubleTap: () async =>
                                              await _showCrudDialog(
                                                  context, staff),
                                          onLongPress: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(
                                                    "Confirmer la suppression"),
                                                content: Text(
                                                    "Voulez-vous vraiment supprimer ${staff.nom} ?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child: Text("Annuler"),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white),
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: Text("Supprimer"),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              final staffProvider =
                                                  Provider.of<StaffProvider>(
                                                      context,
                                                      listen: false);
                                              await staffProvider
                                                  .deleteStaff(staff);
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Text(
                                            staff.nom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                              fontSize: 13,
                                            ),
                                          ),
                                        )),
                                        DataCell(Text(staff.grade,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                        DataCell(Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getEquipeColor(equipe),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(equipe,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                        )),
                                        DataCell(
                                          onDoubleTap: () async {
                                            await _showTimeOffDialog(
                                                context, staff);
                                          },
                                          Text(
                                            staff.obs ?? "-",
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                        ...List.generate(jours.length, (index) {
                                          final jourIndex = index + 1;
                                          final statutJour = jours[index];

                                          // Vérifier si ce jour est un congé
                                          // ⭐ MISE À JOUR : Vérifier les congés selon le mois sélectionné
                                          final dateJour = DateTime(
                                              _selectedYear,
                                              _selectedMonth,
                                              jourIndex);
                                          final estEnConge = timeOffs.any((c) =>
                                              dateJour.isAfter(c.debut.subtract(
                                                  Duration(days: 1))) &&
                                              dateJour.isBefore(c.fin
                                                  .add(Duration(days: 1))));

                                          return DataCell(
                                            Container(
                                              color: estEnConge
                                                  ? Colors.green.shade100
                                                  : Colors.transparent,
                                              child: _buildEditableCell(
                                                  staff, jourIndex, statutJour),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Feedback visuel pendant l'édition
  Widget _buildEditableCell(Staff staff, int jour, String currentValue) {
    final cellKey = "${staff.id}-$jour";
    final isEditing = _editingCells[cellKey] ?? false;

    if (isEditing) {
      return Container(
        width: 28,
        height: 32,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: _tempValues[cellKey] ?? currentValue,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.blue.shade50,
          ),
          items: _statutsDisponibles.map((statut) {
            return DropdownMenuItem<String>(
              value: statut,
              child: Container(
                width: double.infinity,
                child: Text(
                  statut,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(statut),
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _tempValues[cellKey] = newValue;
              });
            }
          },
          icon: Container(),
          isExpanded: true,
          style: TextStyle(fontSize: 11),
          menuMaxHeight: 200,
        ),
      );
    } else {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _editingCells[cellKey] = true;
              _tempValues[cellKey] = currentValue;
            });
          },
          child: Container(
            width: 28,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor(currentValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getStatusColor(currentValue).withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                currentValue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getStatusColor(currentValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // Méthode pour ajouter des boutons de contrôle d'édition
  Widget _buildEditControls() {
    final hasEditing = _editingCells.values.any((editing) => editing);

    if (!hasEditing) return Container();

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit, color: Colors.blue, size: 16),
          SizedBox(width: 8),
          Text(
            'Mode édition actif - Cliquez sur une cellule pour la modifier',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.save, size: 16),
            label: Text('Sauvegarder tout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () async {
              final staffProvider =
                  Provider.of<StaffProvider>(context, listen: false);

              // Sauvegarder toutes les modifications en cours
              for (var entry in _editingCells.entries) {
                if (entry.value) {
                  // Si en cours d'édition
                  final parts = entry.key.split('-');
                  final staffId = int.parse(parts[0]);
                  final jour = int.parse(parts[1]);
                  final newValue = _tempValues[entry.key];

                  if (newValue != null) {
                    final staff =
                        staffProvider.staffs.firstWhere((s) => s.id == staffId);
                    await _saveActiviteModification(staff, jour, newValue);
                  }
                }
              }

              // Nettoyer les états d'édition
              setState(() {
                _editingCells.clear();
                _tempValues.clear();
              });
            },
          ),
          SizedBox(width: 8),
          TextButton.icon(
            icon: Icon(Icons.cancel, size: 16),
            label: Text('Annuler'),
            onPressed: () {
              setState(() {
                _editingCells.clear();
                _tempValues.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String code, Color color, String description) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          description,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getEquipeColor(String equipe) {
    switch (equipe.toUpperCase()) {
      case 'A':
        return Colors.red.shade600;
      case 'B':
        return Colors.green.shade600;
      case 'C':
        return Colors.orange.shade600;
      case 'D':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'G':
        return Colors.green.shade700;
      case 'RE':
      case 'RÉ':
        return Colors.blue.shade700;
      case 'C':
        return Colors.orange.shade700;
      case 'CM':
        return Colors.purple.shade700;
      case 'N':
        return Colors.red.shade700;
      case 'R':
        return Colors.brown.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  Future<void> _showCrudDialog(
    BuildContext context,
    Staff staff, {
    bool equipesActives = true,
  }) async {
    final nomCtrl = TextEditingController(text: staff.nom);
    final gradeCtrl = TextEditingController(text: staff.grade);
    final groupeCtrl = TextEditingController(text: staff.groupe);
    final obsCtrl = TextEditingController(text: staff.obs ?? "");

    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    // Déterminer le groupe d'affichage
    String groupeAffichage;
    if (staff.grade.toLowerCase().contains('médecin') ||
        staff.grade.toLowerCase().contains('rhumatologue')) {
      groupeAffichage = 'Personnel Médical';
    } else if (staff.groupe == '08H-16H') {
      groupeAffichage = 'Personnel Administratif (08h-16h)';
    } else if (staff.groupe == '08H-08H' || staff.groupe == 'Garde 12H') {
      groupeAffichage = 'Personnel Paramédical (08h-08h)';
    } else if (staff.grade.toLowerCase().contains('hygiène')) {
      groupeAffichage = 'Agents d\'hygiène (08h-12h)';
    } else {
      groupeAffichage = 'Personnel Administratif (08h-16h)';
    }

    String? selectedEquipe = staff.equipe;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text("Modifier / Supprimer ${staff.nom}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomCtrl,
                      decoration: const InputDecoration(labelText: "Nom"),
                    ),
                    TextField(
                      controller: gradeCtrl,
                      decoration: const InputDecoration(labelText: "Grade"),
                    ),
                    TextField(
                      controller: groupeCtrl,
                      decoration: const InputDecoration(labelText: "Groupe"),
                    ),

                    // Afficher Équipe uniquement pour le groupe Paramédical
                    if (groupeAffichage == 'Personnel Paramédical (08h-08h)' &&
                        equipesActives) ...[
                      const SizedBox(height: 10),
                      const Text("Équipe :",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: ["A", "B", "C", "D"].map((equipe) {
                          return ChoiceChip(
                            label: Text(equipe),
                            selected: selectedEquipe == equipe,
                            onSelected: (bool selected) {
                              setState(() {
                                selectedEquipe = selected ? equipe : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    TextField(
                      controller: obsCtrl,
                      decoration:
                          const InputDecoration(labelText: "Observation"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Annuler",
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    staff.nom = nomCtrl.text;
                    staff.grade = gradeCtrl.text;
                    staff.groupe = groupeCtrl.text;

                    if (groupeAffichage == 'Personnel Paramédical (08h-08h)' &&
                        equipesActives) {
                      staff.equipe = selectedEquipe;
                    } else {
                      staff.equipe = null;
                    }

                    staff.obs = obsCtrl.text;

                    await staffProvider.updateStaff(staff);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Remplacez votre méthode _showTimeOffDialog par cette version complète :

  Future<void> _showTimeOffDialog(BuildContext context, Staff staff) async {
    // D'abord, récupérer les congés existants
    final timeOffs = staff.timeOff.toList();

    // Variables pour le nouveau congé
    DateTime? dateDebut;
    DateTime? dateFin;
    int? nombreJours;
    String selectedStatut = 'C';
    bool useNombreJours = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Calculer automatiquement selon le mode
            if (useNombreJours && dateDebut != null && nombreJours != null) {
              dateFin = dateDebut!.add(Duration(days: nombreJours! - 1));
            } else if (!useNombreJours &&
                dateDebut != null &&
                dateFin != null) {
              nombreJours = dateFin!.difference(dateDebut!).inDays + 1;
            }

            return AlertDialog(
              title: Text("Gestion des congés - ${staff.nom}"),
              content: Container(
                width: double.maxFinite,
                height: 600, // Hauteur fixe pour éviter le débordement
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1 : Congés existants
                      if (timeOffs.isNotEmpty) ...[
                        Text("Congés existants:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red.shade700)),
                        SizedBox(height: 8),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: timeOffs.length,
                            itemBuilder: (context, index) {
                              final timeOff = timeOffs[index];
                              final duree =
                                  timeOff.fin.difference(timeOff.debut).inDays +
                                      1;

                              return Card(
                                margin: EdgeInsets.all(4),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    child: Text(
                                      timeOff.motif
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'C',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    "${timeOff.motif ?? 'Congé'} ($duree jour${duree > 1 ? 's' : ''})",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    "Du ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Bouton éditer
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue, size: 18),
                                        onPressed: () async {
                                          await _showEditTimeOffDialog(
                                              context, staff, timeOff);
                                          setState(() {
                                            // Refresh de la liste
                                          });
                                        },
                                      ),
                                      // Bouton supprimer
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red, size: 18),
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                  "Confirmer la suppression"),
                                              content: Text(
                                                  "Voulez-vous vraiment supprimer ce congé ?\n\n${timeOff.motif ?? 'Congé'}\nDu ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(false),
                                                  child: Text("Annuler"),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white),
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(true),
                                                  child: Text("Supprimer"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await _deleteTimeOff(
                                                staff, timeOff);
                                            setState(() {
                                              // Refresh de la liste après suppression
                                              timeOffs.removeAt(index);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Divider(thickness: 2),
                        SizedBox(height: 10),
                      ],

                      // SECTION 2 : Nouveau congé
                      Text("Nouveau congé:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade700)),
                      SizedBox(height: 15),

                      // Mode de saisie
                      Row(
                        children: [
                          Text("Mode de saisie:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                    value: false, label: Text("Dates")),
                                ButtonSegment(
                                    value: true, label: Text("Début + Jours")),
                              ],
                              selected: {useNombreJours},
                              onSelectionChanged: (Set<bool> selection) {
                                setState(() {
                                  useNombreJours = selection.first;
                                  nombreJours = null;
                                  dateFin = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Date de début
                      Row(
                        children: [
                          Text("Date début:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.calendar_month),
                              label: Text(dateDebut != null
                                  ? DateFormat('dd/MM/yyyy').format(dateDebut!)
                                  : 'Sélectionner'),
                              onPressed: () async {
                                final firstDate =
                                    DateTime(_selectedYear, _selectedMonth, 1);
                                final lastDate = DateTime(
                                    _selectedYear, _selectedMonth + 1, 0);
                                final now = DateTime.now();

                                DateTime initialDate;
                                if (dateDebut != null) {
                                  initialDate = dateDebut!;
                                } else if (now.isAfter(firstDate) &&
                                    now.isBefore(
                                        lastDate.add(Duration(days: 1)))) {
                                  initialDate = now;
                                } else {
                                  initialDate = firstDate;
                                }

                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: firstDate,
                                  lastDate: lastDate,
                                );
                                if (date != null) {
                                  setState(() {
                                    dateDebut = date;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      // Mode dates : Date de fin OU Mode début + jours : Nombre de jours
                      if (!useNombreJours) ...[
                        Row(
                          children: [
                            Text("Date fin:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.calendar_month),
                                label: Text(dateFin != null
                                    ? DateFormat('dd/MM/yyyy').format(dateFin!)
                                    : 'Sélectionner'),
                                onPressed: dateDebut == null
                                    ? null
                                    : () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: dateFin ??
                                              dateDebut!.add(Duration(days: 1)),
                                          firstDate: dateDebut!,
                                          lastDate: DateTime(_selectedYear,
                                              _selectedMonth + 1, 0),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            dateFin = date;
                                          });
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (useNombreJours) ...[
                        Row(
                          children: [
                            Text("Nb jours:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Ex: 5",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    nombreJours = int.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 15),

                      // Résumé du nouveau congé
                      if (dateDebut != null &&
                          ((dateFin != null && !useNombreJours) ||
                              (nombreJours != null && useNombreJours))) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Résumé du nouveau congé:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700)),
                              Text(
                                  "Du: ${DateFormat('dd/MM/yyyy').format(dateDebut!)}"),
                              Text(
                                  "Au: ${DateFormat('dd/MM/yyyy').format(dateFin!)}"),
                              Text(
                                  "Durée: ${nombreJours!} jour${nombreJours! > 1 ? 's' : ''}"),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                      ],

                      // Type de congé pour le nouveau congé
                      Text("Type de congé:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['C', 'CM', 'G', 'RE', '-'].map((statut) {
                          String label;
                          Color color;
                          switch (statut) {
                            case 'C':
                              label = 'Congé';
                              color = Colors.orange;
                              break;
                            case 'CM':
                              label = 'Congé Maladie';
                              color = Colors.purple;
                              break;
                            case 'G':
                              label = 'Garde';
                              color = Colors.green;
                              break;
                            case 'RE':
                              label = 'Récupération';
                              color = Colors.blue;
                              break;
                            case '-':
                              label = 'Repos';
                              color = Colors.grey;
                              break;
                            default:
                              label = statut;
                              color = Colors.grey;
                          }

                          return ChoiceChip(
                            label: Text("$statut - $label"),
                            selected: selectedStatut == statut,
                            selectedColor: color.withOpacity(0.3),
                            onSelected: (bool selected) {
                              setState(() {
                                selectedStatut = selected ? statut : 'C';
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Fermer"),
                ),
                if (dateDebut != null && dateFin != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await _saveTimeOff(
                          staff, dateDebut!, dateFin!, selectedStatut);
                      Navigator.of(context).pop();
                    },
                    child: Text("Ajouter le congé"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

// NOUVELLES MÉTHODES à ajouter :

// Méthode pour éditer un congé existant
  Future<void> _showEditTimeOffDialog(
      BuildContext context, Staff staff, TimeOff timeOff) async {
    DateTime dateDebut = timeOff.debut;
    DateTime dateFin = timeOff.fin;
    String motif = timeOff.motif ?? 'Congé';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Éditer le congé"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date début
                  Row(
                    children: [
                      Text("Début:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.calendar_month),
                          label:
                              Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dateDebut,
                              firstDate:
                                  DateTime(_selectedYear, _selectedMonth, 1),
                              lastDate: DateTime(
                                  _selectedYear, _selectedMonth + 1, 0),
                            );
                            if (date != null) {
                              setState(() {
                                dateDebut = date;
                                if (dateFin.isBefore(dateDebut)) {
                                  dateFin = dateDebut;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  // Date fin
                  Row(
                    children: [
                      Text("Fin:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.calendar_month),
                          label: Text(DateFormat('dd/MM/yyyy').format(dateFin)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dateFin,
                              firstDate: dateDebut,
                              lastDate: DateTime(
                                  _selectedYear, _selectedMonth + 1, 0),
                            );
                            if (date != null) {
                              setState(() {
                                dateFin = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  // Motif
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Motif",
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: motif),
                    onChanged: (value) => motif = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await _updateTimeOff(
                        staff, timeOff, dateDebut, dateFin, motif);
                    Navigator.of(context).pop();
                  },
                  child: Text("Sauvegarder"),
                ),
              ],
            );
          },
        );
      },
    );
  }

// // Méthode pour supprimer un congé
//   Future<void> _deleteTimeOff(Staff staff, TimeOff timeOff) async {
//     try {
//       final objectBox = ObjectBox();
//       final staffProvider = Provider.of<StaffProvider>(context, listen: false);
//
//       // 1. Supprimer l'entité TimeOff
//       objectBox.timeOffBox.remove(timeOff.id);
//
//       // 2. Remettre les activités journalières à '-' pour les jours concernés
//       DateTime currentDate = timeOff.debut;
//       int joursRestaures = 0;
//
//       while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
//         if (currentDate.year == _selectedYear &&
//             currentDate.month == _selectedMonth) {
//           int jour = currentDate.day;
//           await _forceUpdateActivite(staff.id, jour, '-');
//           joursRestaures++;
//         }
//         currentDate = currentDate.add(Duration(days: 1));
//       }
//
//       // 3. Nettoyer l'observation si elle correspond à ce congé
//       if (staff.obs != null &&
//           staff.obs!.contains(DateFormat('dd/MM/yyyy').format(timeOff.debut))) {
//         staff.obs = null;
//         await staffProvider.updateStaff(staff);
//       }
//
//       // 4. Rafraîchir
//       await staffProvider.fetchStaffs();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "✅ Congé supprimé pour ${staff.nom}\n$joursRestaures jours restaurés"),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ Erreur lors de la suppression: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
// // Méthode pour mettre à jour un congé existant
//   Future<void> _updateTimeOff(Staff staff, TimeOff timeOff,
//       DateTime nouveauDebut, DateTime nouvelleFin, String nouveauMotif) async {
//     try {
//       final objectBox = ObjectBox();
//       final staffProvider = Provider.of<StaffProvider>(context, listen: false);
//
//       // 1. Remettre à '-' les anciens jours
//       DateTime currentDate = timeOff.debut;
//       while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
//         if (currentDate.year == _selectedYear &&
//             currentDate.month == _selectedMonth) {
//           await _forceUpdateActivite(staff.id, currentDate.day, '-');
//         }
//         currentDate = currentDate.add(Duration(days: 1));
//       }
//
//       // 2. Mettre à jour l'entité TimeOff
//       timeOff.debut = nouveauDebut;
//       timeOff.fin = nouvelleFin;
//       timeOff.motif = nouveauMotif;
//       objectBox.timeOffBox.put(timeOff);
//
//       // 3. Appliquer les nouveaux jours
//       currentDate = nouveauDebut;
//       int joursModifies = 0;
//       while (currentDate.isBefore(nouvelleFin.add(Duration(days: 1)))) {
//         if (currentDate.year == _selectedYear &&
//             currentDate.month == _selectedMonth) {
//           await _forceUpdateActivite(staff.id, currentDate.day, 'C');
//           joursModifies++;
//         }
//         currentDate = currentDate.add(Duration(days: 1));
//       }
//
//       // 4. Mettre à jour l'observation
//       staff.obs =
//           "$nouveauMotif du ${DateFormat('dd/MM/yyyy').format(nouveauDebut)} au ${DateFormat('dd/MM/yyyy').format(nouvelleFin)}";
//       await staffProvider.updateStaff(staff);
//
//       // 5. Rafraîchir
//       await staffProvider.fetchStaffs();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "✅ Congé modifié pour ${staff.nom}\n$joursModifies jours mis à jour"),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ Erreur lors de la modification: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _saveTimeOff(
//       Staff staff, DateTime debut, DateTime fin, String statut) async {
//     try {
//       final staffProvider = Provider.of<StaffProvider>(context, listen: false);
//       int joursModifies = 0;
//
//       // 1. CRÉER L'ENTITÉ TIMEOFF DANS LA BASE DE DONNÉES
//       final objectBox = ObjectBox();
//       final timeOff = TimeOff(
//         debut: debut,
//         fin: fin,
//         motif: _getStatutName(statut),
//       )..staff.target = staff;
//
//       objectBox.timeOffBox.put(timeOff);
//       print(
//           "📅 TimeOff créé pour ${staff.nom} du ${DateFormat('dd/MM/yyyy').format(debut)} au ${DateFormat('dd/MM/yyyy').format(fin)}");
//
//       // 2. Marquer chaque jour du congé avec le statut choisi
//       DateTime currentDate = debut;
//       while (currentDate.isBefore(fin.add(Duration(days: 1)))) {
//         // Vérifier si le jour est dans le mois sélectionné
//         if (currentDate.year == _selectedYear &&
//             currentDate.month == _selectedMonth) {
//           int jour = currentDate.day;
//
//           // Forcer la création du congé même si une activité existe déjà
//           await _forceUpdateActivite(staff.id, jour, statut);
//           joursModifies++;
//         }
//         currentDate = currentDate.add(Duration(days: 1));
//       }
//
//       // 3. Mettre à jour l'observation du staff
//       staff.obs =
//           "${_getStatutName(statut)} du ${DateFormat('dd/MM/yyyy').format(debut)} au ${DateFormat('dd/MM/yyyy').format(fin)}";
//       await staffProvider.updateStaff(staff);
//
//       // 4. Rafraîchir les données
//       await staffProvider.fetchStaffs();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "✅ ${_getStatutName(statut)} planifié pour ${staff.nom}\n"
//               "Du ${DateFormat('dd/MM/yyyy').format(debut)} au ${DateFormat('dd/MM/yyyy').format(fin)}\n"
//               "$joursModifies jours modifiés avec le statut '$statut'\n"
//               "TimeOff créé dans la base de données"),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 4),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ Erreur lors de l'enregistrement: $e"),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }
// CORRIGER la méthode _updateTimeOff - utiliser la nouvelle méthode sans vérification
  Future<void> _updateTimeOff(Staff staff, TimeOff timeOff,
      DateTime nouveauDebut, DateTime nouvelleFin, String nouveauMotif) async {
    try {
      final objectBox = ObjectBox();
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider(); // Utiliser le provider

      // 1. Remettre à '-' les anciens jours
      DateTime currentDate = timeOff.debut;
      while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          // UTILISER LA NOUVELLE MÉTHODE
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            currentDate.day,
            '-',
            year: _selectedYear,
            month: _selectedMonth,
          );
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      // 2. Mettre à jour l'entité TimeOff
      timeOff.debut = nouveauDebut;
      timeOff.fin = nouvelleFin;
      timeOff.motif = nouveauMotif;
      objectBox.timeOffBox.put(timeOff);

      // 3. Appliquer les nouveaux jours
      currentDate = nouveauDebut;
      int joursModifies = 0;
      while (currentDate.isBefore(nouvelleFin.add(Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          // UTILISER LA NOUVELLE MÉTHODE pour forcer l'écrasement
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            currentDate.day,
            'C',
            year: _selectedYear,
            month: _selectedMonth,
          );
          joursModifies++;
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      // 4. Mettre à jour l'observation
      staff.obs =
          "$nouveauMotif du ${DateFormat('dd/MM/yyyy').format(nouveauDebut)} au ${DateFormat('dd/MM/yyyy').format(nouvelleFin)}";
      await staffProvider.updateStaff(staff);

      // 5. Rafraîchir
      await staffProvider.fetchStaffs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ Congé modifié pour ${staff.nom}\n$joursModifies jours mis à jour"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la modification: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// CORRIGER la méthode _saveTimeOff - utiliser la nouvelle méthode
  Future<void> _saveTimeOff(
      Staff staff, DateTime debut, DateTime fin, String statut) async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider(); // Utiliser le provider
      int joursModifies = 0;

      // 1. CRÉER L'ENTITÉ TIMEOFF DANS LA BASE DE DONNÉES
      final objectBox = ObjectBox();
      final timeOff = TimeOff(
        debut: debut,
        fin: fin,
        motif: _getStatutName(statut),
      )..staff.target = staff;

      objectBox.timeOffBox.put(timeOff);
      print(
          "📅 TimeOff créé pour ${staff.nom} du ${DateFormat('dd/MM/yyyy').format(debut)} au ${DateFormat('dd/MM/yyyy').format(fin)}");

      // 2. Marquer chaque jour du congé avec le statut choisi
      DateTime currentDate = debut;
      while (currentDate.isBefore(fin.add(Duration(days: 1)))) {
        // Vérifier si le jour est dans le mois sélectionné
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          int jour = currentDate.day;

          // UTILISER LA NOUVELLE MÉTHODE pour forcer l'écrasement
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            jour,
            statut,
            year: _selectedYear,
            month: _selectedMonth,
          );
          joursModifies++;
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      // 3. Mettre à jour l'observation du staff
      staff.obs =
          "${_getStatutName(statut)} du ${DateFormat('dd/MM/yyyy').format(debut)} au ${DateFormat('dd/MM/yyyy').format(fin)}";
      await staffProvider.updateStaff(staff);

      // 4. Rafraîchir les données
      await staffProvider.fetchStaffs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ ${_getStatutName(statut)} planifié pour ${staff.nom}\n"
              "Du ${DateFormat('dd/MM/yyyy').format(debut)} au ${DateFormat('dd/MM/yyyy').format(fin)}\n"
              "$joursModifies jours modifiés avec le statut '$statut'\n"
              "TimeOff créé dans la base de données"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'enregistrement: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// CORRIGER également la méthode _deleteTimeOff si elle existe
  Future<void> _deleteTimeOff(Staff staff, TimeOff timeOff) async {
    try {
      final objectBox = ObjectBox();
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider(); // Utiliser le provider

      // 1. Supprimer l'entité TimeOff
      objectBox.timeOffBox.remove(timeOff.id);

      // 2. Remettre les activités journalières à '-' pour les jours concernés
      DateTime currentDate = timeOff.debut;
      int joursRestaures = 0;

      while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          int jour = currentDate.day;
          // UTILISER LA NOUVELLE MÉTHODE
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            jour,
            '-',
            year: _selectedYear,
            month: _selectedMonth,
          );
          joursRestaures++;
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      // 3. Nettoyer l'observation si elle correspond à ce congé
      if (staff.obs != null &&
          staff.obs!.contains(DateFormat('dd/MM/yyyy').format(timeOff.debut))) {
        staff.obs = null;
        await staffProvider.updateStaff(staff);
      }

      // 4. Rafraîchir
      await staffProvider.fetchStaffs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ Congé supprimé pour ${staff.nom}\n$joursRestaures jours restaurés"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la suppression: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// SUPPRIMER ou REMPLACER l'ancienne méthode _forceUpdateActivite
// Cette méthode doit maintenant utiliser le provider
  Future<void> _forceUpdateActivite(
      int staffId, int jour, String statut) async {
    try {
      final activiteProvider = ActiviteProvider();
      await activiteProvider.forceUpdateActiviteIgnoringLeave(
        staffId,
        jour,
        statut,
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      print("Erreur _forceUpdateActivite: $e");
    }
  }

// Fonction utilitaire pour obtenir le nom du statut
  String _getStatutName(String statut) {
    switch (statut) {
      case 'C':
        return 'Congé';
      case 'CM':
        return 'Congé Maladie';
      case 'G':
        return 'Garde';
      case 'RE':
        return 'Récupération';
      case '-':
        return 'Repos';
      default:
        return statut;
    }
  }

  Future<Map<String, dynamic>?> showPlanificationDialog({
    required BuildContext context,
    required List<String> equipesInit, // ex: ["A", "B", "C", "D"]
    required int year,
    required int month,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        List<String> orderedEquipes = List.from(equipesInit);
        int? selectedDay; // 1 à orderedEquipes.length

        return StatefulBuilder(
          builder: (ctxS, setState) {
            final equipeCount = orderedEquipes.length;
            final dayChoices = List.generate(equipeCount, (i) => i + 1);

            // Fonction pour obtenir le nom court du jour (sam, dim, lun...)
            String shortWeekdayName(int day) {
              final dt = DateTime(year, month, day);
              return DateFormat.E('fr_FR').format(dt);
            }

            return AlertDialog(
              title: const Text("Planification des gardes"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affichage du mois et de l'année
                    Text(
                      "Mois: ${DateFormat.MMMM('fr_FR').format(DateTime(year, month))} $year",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Réorganisation des équipes par drag-and-drop
                    const Text(
                      "Ordre des équipes (glissez pour réorganiser):",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56.0 + (orderedEquipes.length * 12),
                      child: ReorderableListView(
                        buildDefaultDragHandles: true,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = orderedEquipes.removeAt(oldIndex);
                            orderedEquipes.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < orderedEquipes.length; i++)
                            ListTile(
                              key: ValueKey('eq_${orderedEquipes[i]}_$i'),
                              title: Text("Équipe ${orderedEquipes[i]}"),
                              leading: CircleAvatar(child: Text("${i + 1}")),
                              trailing: const Icon(Icons.drag_handle),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sélection du jour de départ (1 à N)
                    const Text(
                      "Jour de départ (choisissez parmi les N premiers jours):",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dayChoices.map((day) {
                        final label = "$day • ${shortWeekdayName(day)}";
                        return ChoiceChip(
                          label: Text(label),
                          selected: selectedDay == day,
                          onSelected: (_) => setState(() => selectedDay = day),
                          selectedColor: Colors.teal.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Légende de la logique
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Logique de planification:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                              "• L'équipe en 1ère position commence le jour sélectionné."),
                          Text(
                              "• Rotation circulaire selon l'ordre réorganisé."),
                          Text(
                              "• Les congés (TimeOff/activités C/CM) sont respectés."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: (selectedDay != null)
                      ? () => Navigator.of(ctx).pop({
                            'orderedEquipes': orderedEquipes,
                            'selectedDay': selectedDay,
                          })
                      : null,
                  child: const Text("Confirmer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAdvancedPlanificationDialog() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    // 1. Identifier les équipes médicales disponibles
    final equipesDisponibles = staffProvider.staffs
        .where((staff) =>
            staff.equipe != null &&
            ['A', 'B', 'C', 'D'].contains(staff.equipe!.toUpperCase()))
        .map((staff) => staff.equipe!.toUpperCase())
        .toSet()
        .toList();

    equipesDisponibles.sort();

    if (equipesDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Aucune équipe médicale trouvée (A,B,C,D)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Calculer les jours disponibles selon le nombre d'équipes
    final nombreEquipes = equipesDisponibles.length;
    final joursDisponibles = List.generate(nombreEquipes, (i) => i + 1);

    // 3. Afficher le dialog de planification
    final result = await _showPlanificationAvanceeDialog(
      equipesDisponibles: equipesDisponibles,
      joursDisponibles: joursDisponibles,
    );

    if (result == null) return;

    // 4. Exécuter la planification
    await _executerPlanificationGardes(
      equipesOrdonnees: result['equipesOrdonnees'],
      jourDepart: result['jourDepart'],
    );
  }

// NOUVELLE MÉTHODE : Dialog de planification avancé
  Future<Map<String, dynamic>?> _showPlanificationAvanceeDialog({
    required List<String> equipesDisponibles,
    required List<int> joursDisponibles,
  }) async {
    List<String> equipesOrdonnees = List.from(equipesDisponibles);
    int? jourDepart;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.teal),
                  SizedBox(width: 8),
                  Text("Planification des Gardes",
                      style: TextStyle(color: Colors.teal.shade700)),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 600),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Informations du mois
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade50, Colors.teal.shade100],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Mois: $_selectedMonthName $_selectedYear",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${equipesDisponibles.length} équipes détectées: ${equipesDisponibles.join(', ')}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.teal.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Ordre des équipes avec drag & drop
                      Text(
                        "1. Ordre de rotation des équipes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Glissez pour réorganiser l'ordre de rotation :",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: equipesOrdonnees.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = equipesOrdonnees.removeAt(oldIndex);
                              equipesOrdonnees.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            return Container(
                              key: ValueKey(
                                  'equipe_${equipesOrdonnees[index]}_$index'),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Card(
                                elevation: 1,
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _getEquipeColor(
                                          equipesOrdonnees[index]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${index + 1}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    "Équipe ${equipesOrdonnees[index]}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    index == 0
                                        ? "Première à faire la garde"
                                        : "Position ${index + 1}",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  trailing: Icon(Icons.drag_handle,
                                      color: Colors.grey.shade400),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 24),

                      // Sélection du jour de départ
                      Text(
                        "2. Jour de commencement",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Choisissez le jour où l'équipe en 1ère position commence sa garde :",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 12),

                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: joursDisponibles.map((jour) {
                            final date =
                                DateTime(_selectedYear, _selectedMonth, jour);
                            final nomJour = _getNomJourCourt(date.weekday);
                            final isSelected = jourDepart == jour;

                            return GestureDetector(
                              onTap: () => setState(() => jourDepart = jour),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected ? Colors.teal : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.teal.shade700
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.teal.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Jour $jour",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      nomJour,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Aperçu de la rotation
                      if (jourDepart != null) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.preview,
                                      color: Colors.blue.shade700, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Aperçu de la rotation",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              ...List.generate(
                                math.min(equipesOrdonnees.length, 4),
                                (index) {
                                  final jour = jourDepart! + index;
                                  final equipe = equipesOrdonnees[index];
                                  final date = DateTime(
                                      _selectedYear, _selectedMonth, jour);
                                  final nomJour =
                                      _getNomJourComplet(date.weekday);

                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: _getEquipeColor(equipe),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              equipe,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Jour $jour ($nomJour) → Équipe $equipe",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (equipesOrdonnees.length > 4)
                                Text(
                                  "... et ainsi de suite pour le reste du mois",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 16),

                      // Note importante
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber.shade700, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Les congés et activités existantes (C, CM) seront préservés automatiquement.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text("Annuler"),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.schedule, size: 16),
                  label: Text("Planifier les gardes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: (jourDepart != null)
                      ? () => Navigator.of(context).pop({
                            'equipesOrdonnees': equipesOrdonnees,
                            'jourDepart': jourDepart,
                          })
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

// NOUVELLE MÉTHODE : Exécution de la planification des gardes
  Future<void> _executerPlanificationGardes({
    required List<String> equipesOrdonnees,
    required int jourDepart,
  }) async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();

      final daysInMonth = _daysInSelectedMonth;
      int totalModifications = 0;
      Map<String, int> gardesParEquipe = {for (var e in equipesOrdonnees) e: 0};
      Map<String, int> recuperationsParEquipe = {
        for (var e in equipesOrdonnees) e: 0
      };
      int congesRespectes = 0;

      // Personnel médical avec équipes
      final personnelMedical = staffProvider.staffs
          .where((staff) =>
              staff.equipe != null &&
              equipesOrdonnees.contains(staff.equipe!.toUpperCase()))
          .toList();

      if (personnelMedical.isEmpty) {
        throw Exception(
            "Aucun personnel médical trouvé avec les équipes sélectionnées");
      }

      // Fonction pour vérifier les congés (TimeOff + activités C/CM)
      bool estEnCongeOuActivite(Staff staff, int jour) {
        final dateJour = DateTime(_selectedYear, _selectedMonth, jour);

        // Vérifier TimeOff
        final timeOffs = staff.timeOff.toList();
        bool enCongeTimeOff = timeOffs.any((timeOff) =>
            dateJour.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
            dateJour.isBefore(timeOff.fin.add(Duration(days: 1))));

        // Vérifier activités existantes C/CM
        final activites = staff.activites.toList();
        bool enCongeActivite = activites.any((activite) =>
            activite.jour == jour &&
            (activite.statut == 'C' || activite.statut == 'CM'));

        return enCongeTimeOff || enCongeActivite;
      }

      // ROTATION CORRECTE : Calculer l'équipe de garde pour chaque jour
      for (int day = 1; day <= daysInMonth; day++) {
        // Calculer l'index de l'équipe selon la rotation
        int joursEcoules = (day - jourDepart + daysInMonth) % daysInMonth;
        int equipeIndex = joursEcoules % equipesOrdonnees.length;
        String equipeDeGarde = equipesOrdonnees[equipeIndex];

        // Planifier pour chaque membre du personnel médical
        for (final staff in personnelMedical) {
          final staffEquipe = staff.equipe!.toUpperCase();

          // Vérifier si en congé
          if (estEnCongeOuActivite(staff, day)) {
            congesRespectes++;
            continue;
          }

          // Déterminer le statut selon l'équipe
          String nouveauStatut;
          if (staffEquipe == equipeDeGarde) {
            nouveauStatut = "G"; // Garde
            gardesParEquipe[staffEquipe] =
                (gardesParEquipe[staffEquipe] ?? 0) + 1;
          } else {
            nouveauStatut = "RE"; // Récupération
            recuperationsParEquipe[staffEquipe] =
                (recuperationsParEquipe[staffEquipe] ?? 0) + 1;
          }

          // Mettre à jour l'activité
          await activiteProvider.updateActivite(
            staff.id,
            day,
            nouveauStatut,
            year: _selectedYear,
            month: _selectedMonth,
          );
          totalModifications++;
        }
      }

      // Rafraîchir les données
      await staffProvider.fetchStaffs();

      // Préparer le résumé
      String resumeGardes = gardesParEquipe.entries
          .map((e) => "${e.key}: ${e.value}G")
          .join(", ");

      String resumeRecuperations = recuperationsParEquipe.entries
          .map((e) => "${e.key}: ${e.value}RE")
          .join(", ");

      // Afficher le résultat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Gardes planifiées avec succès !",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text("📅 Période: $_selectedMonthName $_selectedYear",
                    style: TextStyle(color: Colors.white)),
                Text(
                    "🎯 Début: Jour $jourDepart, Équipe ${equipesOrdonnees[0]}",
                    style: TextStyle(color: Colors.white)),
                Text("👥 ${personnelMedical.length} médecins concernés",
                    style: TextStyle(color: Colors.white)),
                Text("✅ $totalModifications modifications effectuées",
                    style: TextStyle(color: Colors.white)),
                Text("🚫 $congesRespectes congés préservés",
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 4),
                Text("Gardes: $resumeGardes",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                Text("Récupérations: $resumeRecuperations",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la planification: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

// MÉTHODES UTILITAIRES pour les noms des jours
  String _getNomJourCourt(int weekday) {
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return jours[weekday - 1];
  }

  String _getNomJourComplet(int weekday) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return jours[weekday - 1];
  }

// NOUVELLE MÉTHODE : Dialog simplifié - ordre des équipes seulement
  Future<void> _showSimplePlanificationDialog() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    // 1. Identifier les équipes médicales disponibles
    final equipesDisponibles = staffProvider.staffs
        .where((staff) =>
            staff.equipe != null &&
            ['A', 'B', 'C', 'D'].contains(staff.equipe!.toUpperCase()))
        .map((staff) => staff.equipe!.toUpperCase())
        .toSet()
        .toList();

    equipesDisponibles.sort();

    if (equipesDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucune équipe médicale trouvée (A,B,C,D)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Afficher le dialog de planification simplifié
    final equipesOrdonnees = await _showOrderEquipesDialog(equipesDisponibles);

    if (equipesOrdonnees == null) return;

    // 3. Exécuter la planification (commence automatiquement au jour 1)
    await _executerPlanificationGardesSimple(equipesOrdonnees);
  }

// NOUVELLE MÉTHODE : Dialog pour ordonner les équipes uniquement
  Future<List<String>?> _showOrderEquipesDialog(
      List<String> equipesDisponibles) async {
    List<String> equipesOrdonnees = List.from(equipesDisponibles);

    return await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Ordre des Gardes Médicales",
                      style: TextStyle(color: Colors.teal.shade700),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 500),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Informations du mois
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade50, Colors.teal.shade100],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Mois: $_selectedMonthName $_selectedYear",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${equipesDisponibles.length} équipes détectées: ${equipesDisponibles.join(', ')}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.teal.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info,
                                      size: 14, color: Colors.blue.shade700),
                                  SizedBox(width: 4),
                                  Text(
                                    "La rotation commence automatiquement le 1er jour",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Instructions
                      Text(
                        "Organisez l'ordre de rotation :",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Glissez les équipes pour définir l'ordre de rotation. L'équipe en première position commencera sa garde le 1er jour du mois.",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 12),

                      // Liste réorganisable des équipes
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: equipesOrdonnees.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = equipesOrdonnees.removeAt(oldIndex);
                              equipesOrdonnees.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final equipe = equipesOrdonnees[index];
                            final isFirst = index == 0;

                            return Container(
                              key: ValueKey('equipe_${equipe}_$index'),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Card(
                                elevation: isFirst ? 3 : 1,
                                color: isFirst
                                    ? Colors.teal.shade50
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isFirst
                                        ? Colors.teal.shade300
                                        : Colors.grey.shade200,
                                    width: isFirst ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: _getEquipeColor(equipe),
                                      shape: BoxShape.circle,
                                      boxShadow: isFirst
                                          ? [
                                              BoxShadow(
                                                color: _getEquipeColor(equipe)
                                                    .withOpacity(0.4),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        equipe,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        "Équipe $equipe",
                                        style: TextStyle(
                                          fontWeight: isFirst
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isFirst
                                              ? Colors.teal.shade700
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      if (isFirst) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade200,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "1ère",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.teal.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    isFirst
                                        ? "Commence la garde le 1er jour"
                                        : "Jour ${index + 1} de rotation",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isFirst
                                          ? Colors.teal.shade600
                                          : Colors.grey.shade500,
                                      fontWeight: isFirst
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.drag_handle,
                                    color: isFirst
                                        ? Colors.teal.shade400
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // Aperçu de la rotation
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.preview,
                                    color: Colors.blue.shade700, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Aperçu des premiers jours",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            ...List.generate(
                              math.min(equipesOrdonnees.length, 4),
                              (index) {
                                final jour = index + 1;
                                final equipe = equipesOrdonnees[index];
                                final date = DateTime(
                                    _selectedYear, _selectedMonth, jour);
                                final nomJour =
                                    DateFormat('EEEE', 'fr_FR').format(date);

                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _getEquipeColor(equipe),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            equipe,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Jour $jour ($nomJour) → Équipe $equipe en garde",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (equipesOrdonnees.length > 4)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  "... rotation continue pour le reste du mois",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // Note importante
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber.shade700, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Les congés existants (TimeOff et activités C/CM) seront automatiquement préservés.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text("Annuler"),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.schedule, size: 16),
                  label: Text("Planifier les gardes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(equipesOrdonnees),
                ),
              ],
            );
          },
        );
      },
    );
  }

// // NOUVELLE MÉTHODE : Exécution simplifiée (commence au jour 1)
//   Future<void> _executerPlanificationGardesSimple(
//       List<String> equipesOrdonnees) async {
//     try {
//       final staffProvider = Provider.of<StaffProvider>(context, listen: false);
//       final activiteProvider = ActiviteProvider();
//
//       final daysInMonth = _daysInSelectedMonth;
//       int totalModifications = 0;
//       Map<String, int> gardesParEquipe = {for (var e in equipesOrdonnees) e: 0};
//       Map<String, int> recuperationsParEquipe = {
//         for (var e in equipesOrdonnees) e: 0
//       };
//       int congesRespectes = 0;
//
//       // Personnel médical avec équipes
//       final personnelMedical = staffProvider.staffs
//           .where((staff) =>
//               staff.equipe != null &&
//               equipesOrdonnees.contains(staff.equipe!.toUpperCase()))
//           .toList();
//
//       if (personnelMedical.isEmpty) {
//         throw Exception(
//             "Aucun personnel médical trouvé avec les équipes sélectionnées");
//       }
//
//       // Fonction pour vérifier les congés (TimeOff + activités C/CM)
//       bool estEnCongeOuActivite(Staff staff, int jour) {
//         final dateJour = DateTime(_selectedYear, _selectedMonth, jour);
//
//         // Vérifier TimeOff
//         final timeOffs = staff.timeOff.toList();
//         bool enCongeTimeOff = timeOffs.any((timeOff) =>
//             dateJour.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
//             dateJour.isBefore(timeOff.fin.add(Duration(days: 1))));
//
//         // Vérifier activités existantes C/CM
//         final activites = staff.activites.toList();
//         bool enCongeActivite = activites.any((activite) =>
//             activite.jour == jour &&
//             (activite.statut == 'C' || activite.statut == 'CM'));
//
//         return enCongeTimeOff || enCongeActivite;
//       }
//
//       // ROTATION SIMPLE : Commence au jour 1
//       for (int day = 1; day <= daysInMonth; day++) {
//         // L'équipe de garde pour ce jour (rotation simple depuis le jour 1)
//         int equipeIndex = (day - 1) % equipesOrdonnees.length;
//         String equipeDeGarde = equipesOrdonnees[equipeIndex];
//
//         // Planifier pour chaque membre du personnel médical
//         for (final staff in personnelMedical) {
//           final staffEquipe = staff.equipe!.toUpperCase();
//
//           // Vérifier si en congé
//           if (estEnCongeOuActivite(staff, day)) {
//             congesRespectes++;
//             continue;
//           }
//
//           // Déterminer le statut selon l'équipe
//           String nouveauStatut;
//           if (staffEquipe == equipeDeGarde) {
//             nouveauStatut = "G"; // Garde
//             gardesParEquipe[staffEquipe] =
//                 (gardesParEquipe[staffEquipe] ?? 0) + 1;
//           } else {
//             nouveauStatut = "RE"; // Récupération
//             recuperationsParEquipe[staffEquipe] =
//                 (recuperationsParEquipe[staffEquipe] ?? 0) + 1;
//           }
//
//           // Mettre à jour l'activité
//           await activiteProvider.updateActivite(
//             staff.id,
//             day,
//             nouveauStatut,
//             year: _selectedYear,
//             month: _selectedMonth,
//           );
//           totalModifications++;
//         }
//       }
//
//       // Rafraîchir les données
//       await staffProvider.fetchStaffs();
//
//       // Préparer le résumé
//       String resumeGardes = gardesParEquipe.entries
//           .map((e) => "${e.key}: ${e.value}G")
//           .join(", ");
//
//       String resumeRecuperations = recuperationsParEquipe.entries
//           .map((e) => "${e.key}: ${e.value}RE")
//           .join(", ");
//
//       // Afficher le résultat
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 6),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.white, size: 20),
//                     SizedBox(width: 8),
//                     Text(
//                       "Gardes planifiées avec succès !",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Text("Période: $_selectedMonthName $_selectedYear",
//                     style: TextStyle(color: Colors.white)),
//                 Text("Ordre: ${equipesOrdonnees.join(' → ')}",
//                     style: TextStyle(color: Colors.white)),
//                 Text("${personnelMedical.length} médecins concernés",
//                     style: TextStyle(color: Colors.white)),
//                 Text("$totalModifications modifications effectuées",
//                     style: TextStyle(color: Colors.white)),
//                 Text("$congesRespectes congés préservés",
//                     style: TextStyle(color: Colors.white)),
//                 SizedBox(height: 4),
//                 Text("Gardes: $resumeGardes",
//                     style: TextStyle(color: Colors.white, fontSize: 12)),
//                 Text("Récupérations: $resumeRecuperations",
//                     style: TextStyle(color: Colors.white, fontSize: 12)),
//               ],
//             ),
//           ),
//           action: SnackBarAction(
//             label: "OK",
//             textColor: Colors.white,
//             onPressed: () =>
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar(),
//           ),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Erreur lors de la planification: $e"),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     }
//   }
// NOUVELLE MÉTHODE : Exécution avec override des congés
// NOUVELLE VERSION avec débogage pour la Phase 2
//   Future<void> _executerPlanificationGardesSimple(
//       List<String> equipesOrdonnees) async {
//     try {
//       final staffProvider = Provider.of<StaffProvider>(context, listen: false);
//       final activiteProvider = ActiviteProvider();
//
//       final daysInMonth = _daysInSelectedMonth;
//       int totalModifications = 0;
//       int gardesEcrasees = 0;
//       Map<String, int> gardesParEquipe = {for (var e in equipesOrdonnees) e: 0};
//       Map<String, int> recuperationsParEquipe = {
//         for (var e in equipesOrdonnees) e: 0
//       };
//       Map<String, int> congesAppliques = {for (var e in equipesOrdonnees) e: 0};
//
//       // Personnel médical avec équipes
//       final personnelMedical = staffProvider.staffs
//           .where((staff) =>
//               staff.equipe != null &&
//               equipesOrdonnees.contains(staff.equipe!.toUpperCase()))
//           .toList();
//
//       if (personnelMedical.isEmpty) {
//         throw Exception(
//             "Aucun personnel médical trouvé avec les équipes sélectionnées");
//       }
//
//       print(
//           "🔄 PHASE 1: Attribution des gardes (${personnelMedical.length} staffs)");
//
//       // 1. Collecter TOUS les congés (TimeOff + activités C/CM) pour chaque staff
//       Map<int, Map<int, String>> congesParStaff =
//           {}; // {staffId: {jour: statut}}
//
//       for (final staff in personnelMedical) {
//         congesParStaff[staff.id] = {};
//
//         // 1a. Congés depuis TimeOff
//         for (var timeOff in staff.timeOff) {
//           DateTime currentDate = timeOff.debut;
//           while (
//               currentDate.isBefore(timeOff.fin.add(const Duration(days: 1)))) {
//             if (currentDate.year == _selectedYear &&
//                 currentDate.month == _selectedMonth) {
//               String statutConge = _getStatutCongeFromTimeOff(timeOff);
//               congesParStaff[staff.id]![currentDate.day] = statutConge;
//             }
//             currentDate = currentDate.add(const Duration(days: 1));
//           }
//         }
//
//         // 1b. Congés depuis Activités (C/CM)
//         for (var activite in staff.activites) {
//           if ((activite.statut == 'C' || activite.statut == 'CM') &&
//               activite.jour >= 1 &&
//               activite.jour <= daysInMonth) {
//             congesParStaff[staff.id]![activite.jour] = activite.statut;
//           }
//         }
//       }
//       // PHASE 1: ATTRIBUTION COMPLÈTE DES GARDES (ignorer les congés)
//       for (int day = 1; day <= daysInMonth; day++) {
//         int equipeIndex = (day - 1) % equipesOrdonnees.length;
//         String equipeDeGarde = equipesOrdonnees[equipeIndex];
//
//         for (final staff in personnelMedical) {
//           final staffEquipe = staff.equipe!.toUpperCase();
//
//           String nouveauStatut;
//           if (staffEquipe == equipeDeGarde) {
//             nouveauStatut = "G";
//             gardesParEquipe[staffEquipe] =
//                 (gardesParEquipe[staffEquipe] ?? 0) + 1;
//           } else {
//             nouveauStatut = "RE";
//             recuperationsParEquipe[staffEquipe] =
//                 (recuperationsParEquipe[staffEquipe] ?? 0) + 1;
//           }
//
//           await activiteProvider.forceUpdateActiviteIgnoringLeave(
//             staff.id,
//             day,
//             nouveauStatut,
//             year: _selectedYear,
//             month: _selectedMonth,
//           );
//           totalModifications++;
//         }
//       }
//
//       print("🔄 PHASE 2: Application des congés (analyse détaillée)");
//
//       // PHASE 2: APPLIQUER LES CONGÉS PAR-DESSUS (écraser les gardes)
//       for (final staff in personnelMedical) {
//         final staffEquipe = staff.equipe!.toUpperCase();
//
//         print("\n--- ANALYSE CONGÉS POUR ${staff.nom} (ID: ${staff.id}) ---");
//
//         // 🔍 DÉBOGAGE: Vérifier les TimeOff
//         final timeOffs = staff.timeOff.toList();
//         print("📅 TimeOffs trouvés: ${timeOffs.length}");
//
//         if (timeOffs.isNotEmpty) {
//           for (int i = 0; i < timeOffs.length; i++) {
//             var timeOff = timeOffs[i];
//             print(
//                 "  TimeOff $i: ${timeOff.debut} → ${timeOff.fin} (${timeOff.motif ?? 'sans motif'})");
//
//             // Vérifier si le congé intersecte avec le mois sélectionné
//             bool intersecte = false;
//             DateTime currentDate = timeOff.debut;
//             List<int> joursIntersection = [];
//
//             while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
//               if (currentDate.year == _selectedYear &&
//                   currentDate.month == _selectedMonth) {
//                 intersecte = true;
//                 joursIntersection.add(currentDate.day);
//               }
//               currentDate = currentDate.add(Duration(days: 1));
//             }
//
//             if (intersecte) {
//               print(
//                   "    ✅ Intersecte avec $_selectedMonthName $_selectedYear aux jours: ${joursIntersection.join(', ')}");
//
//               // Appliquer le congé aux jours concernés
//               for (int jour in joursIntersection) {
//                 // Vérifier le statut actuel avant écrasement
//                 final query = activiteProvider.activiteBox
//                     .query(ActiviteJour_.staff.equals(staff.id) &
//                         ActiviteJour_.jour.equals(jour))
//                     .build();
//                 final activites = query.find();
//                 query.close();
//
//                 String? statutActuel;
//                 if (activites.isNotEmpty) {
//                   statutActuel = activites.first.statut;
//                   print("      Jour $jour: $statutActuel → C (congé TimeOff)");
//
//                   if (statutActuel == 'G') {
//                     gardesEcrasees++;
//                     gardesParEquipe[staffEquipe] =
//                         (gardesParEquipe[staffEquipe] ?? 1) - 1;
//                   } else if (statutActuel == 'RE') {
//                     recuperationsParEquipe[staffEquipe] =
//                         (recuperationsParEquipe[staffEquipe] ?? 1) - 1;
//                   }
//                 } else {
//                   print("      Jour $jour: vide → C (congé TimeOff)");
//                 }
//
//                 // Déterminer le statut de congé selon le motif
//                 String statutConge = _getStatutCongeFromTimeOff(timeOff);
//
//                 await activiteProvider.forceUpdateActiviteIgnoringLeave(
//                   staff.id,
//                   jour,
//                   statutConge,
//                   year: _selectedYear,
//                   month: _selectedMonth,
//                 );
//
//                 congesAppliques[staffEquipe] =
//                     (congesAppliques[staffEquipe] ?? 0) + 1;
//               }
//             } else {
//               print(
//                   "    ❌ N'intersecte PAS avec $_selectedMonthName $_selectedYear");
//             }
//           }
//         } else {
//           print("  Aucun TimeOff trouvé pour ce staff");
//         }
//
//         // 🔍 DÉBOGAGE: Vérifier les activités de congé existantes
//         print("📋 Vérification des activités de congé existantes...");
//         final activites = staff.activites.toList();
//         print("  Total activités: ${activites.length}");
//
//         List<ActiviteJour> congesActivites = activites
//             .where((activite) =>
//                 (activite.statut == 'C' || activite.statut == 'CM') &&
//                 activite.jour >= 1 &&
//                 activite.jour <= daysInMonth)
//             .toList();
//
//         if (congesActivites.isNotEmpty) {
//           print("  Congés d'activités trouvés: ${congesActivites.length}");
//           for (var activite in congesActivites) {
//             print("    Jour ${activite.jour}: ${activite.statut}");
//
//             // Réappliquer le congé pour s'assurer qu'il n'a pas été écrasé
//             await activiteProvider.forceUpdateActiviteIgnoringLeave(
//               staff.id,
//               activite.jour,
//               activite.statut,
//               year: _selectedYear,
//               month: _selectedMonth,
//             );
//
//             congesAppliques[staffEquipe] =
//                 (congesAppliques[staffEquipe] ?? 0) + 1;
//             print("      → Congé activité réappliqué");
//           }
//         } else {
//           print("  Aucun congé d'activité trouvé");
//         }
//       }
//
//       // PHASE 3: Vérification finale
//       print("\n🔍 PHASE 3: Vérification finale");
//       for (final staff in personnelMedical) {
//         final activitesFinal = staff.activites.toList();
//         final congesFinal = activitesFinal
//             .where((a) => a.statut == 'C' || a.statut == 'CM')
//             .length;
//         final gardesFinal = activitesFinal.where((a) => a.statut == 'G').length;
//
//         print("${staff.nom}: ${gardesFinal}G, ${congesFinal}C");
//       }
//
//       // Rafraîchir les données
//       await staffProvider.fetchStaffs();
//
//       // Préparer le résumé
//       String resumeGardes = gardesParEquipe.entries
//           .where((e) => e.value > 0)
//           .map((e) => "${e.key}: ${e.value}G")
//           .join(", ");
//
//       String resumeRecuperations = recuperationsParEquipe.entries
//           .where((e) => e.value > 0)
//           .map((e) => "${e.key}: ${e.value}RE")
//           .join(", ");
//
//       String resumeConges = congesAppliques.entries
//           .where((e) => e.value > 0)
//           .map((e) => "${e.key}: ${e.value}C")
//           .join(", ");
//
//       // Afficher le résultat détaillé
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 10),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.white, size: 20),
//                     SizedBox(width: 8),
//                     Text(
//                       "Planification terminée !",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Text("📅 Période: $_selectedMonthName $_selectedYear",
//                     style: TextStyle(color: Colors.white)),
//                 Text("🔄 Ordre: ${equipesOrdonnees.join(' → ')}",
//                     style: TextStyle(color: Colors.white)),
//                 Text("👥 ${personnelMedical.length} médecins concernés",
//                     style: TextStyle(color: Colors.white)),
//                 SizedBox(height: 6),
//                 Text(
//                   "Phase 1 - Gardes attribuées:",
//                   style: TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.w600),
//                 ),
//                 if (resumeGardes.isNotEmpty)
//                   Text(
//                     "  Gardes: $resumeGardes",
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 if (resumeRecuperations.isNotEmpty)
//                   Text(
//                     "  Récupérations: $resumeRecuperations",
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 SizedBox(height: 4),
//                 Text(
//                   "Phase 2 - Congés appliqués:",
//                   style: TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.w600),
//                 ),
//                 if (gardesEcrasees > 0)
//                   Text(
//                     "  🚫 $gardesEcrasees gardes écrasées par des congés",
//                     style:
//                         TextStyle(color: Colors.yellow.shade200, fontSize: 12),
//                   ),
//                 if (resumeConges.isNotEmpty)
//                   Text(
//                     "  Congés: $resumeConges",
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   )
//                 else
//                   Text(
//                     "  ⚠️ Aucun congé appliqué - vérifiez les logs",
//                     style:
//                         TextStyle(color: Colors.yellow.shade200, fontSize: 12),
//                   ),
//                 SizedBox(height: 4),
//                 Text(
//                   "✅ Total: $totalModifications modifications",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//           action: SnackBarAction(
//             label: "OK",
//             textColor: Colors.white,
//             onPressed: () =>
//                 ScaffoldMessenger.of(context).hideCurrentSnackBar(),
//           ),
//         ),
//       );
//     } catch (e) {
//       print("❌ ERREUR PLANIFICATION: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ Erreur lors de la planification: $e"),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     }
//   }
  Future<void> _executerPlanificationGardesSimple(
      List<String> equipesOrdonnees) async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();
      final objectBox = ObjectBox();
      final daysInMonth = _daysInSelectedMonth;
      int totalModifications = 0;
      int gardesEcrasees = 0;
      Map<String, int> gardesParEquipe = {for (var e in equipesOrdonnees) e: 0};
      Map<String, int> recuperationsParEquipe = {
        for (var e in equipesOrdonnees) e: 0
      };
      Map<String, int> congesAppliques = {for (var e in equipesOrdonnees) e: 0};

      // Personnel médical avec équipes
      final personnelMedical = staffProvider.staffs
          .where((staff) =>
              staff.equipe != null &&
              equipesOrdonnees.contains(staff.equipe!.toUpperCase()))
          .toList();

      if (personnelMedical.isEmpty) {
        throw Exception(
            "Aucun personnel médical trouvé avec les équipes sélectionnées");
      }

      // 1. Collecter TOUS les congés (TimeOff + activités C/CM) pour chaque staff
      Map<int, Map<int, String>> congesParStaff =
          {}; // {staffId: {jour: statut}}

      // Récupérer tous les TimeOffs
      final allTimeOffs = objectBox.timeOffBox.getAll();
      for (var timeOff in allTimeOffs) {
        // Vérifier que la relation staff est chargée
        if (timeOff.staff.target != null) {
          final staff = timeOff.staff.target!;
          final staffId = staff.id;
          if (!congesParStaff.containsKey(staffId)) {
            congesParStaff[staffId] = {};
          }

          // Calculer les jours de congé
          DateTime currentDate = timeOff.debut;
          while (
              currentDate.isBefore(timeOff.fin.add(const Duration(days: 1)))) {
            if (currentDate.year == _selectedYear &&
                currentDate.month == _selectedMonth) {
              String statutConge = _getStatutCongeFromTimeOff(timeOff);
              congesParStaff[staffId]![currentDate.day] = statutConge;
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      }

      // 2. Ajouter les congés depuis les Activités (C/CM)
      for (final staff in personnelMedical) {
        if (!congesParStaff.containsKey(staff.id)) {
          congesParStaff[staff.id] = {};
        }

        for (var activite in staff.activites) {
          if ((activite.statut == 'C' || activite.statut == 'CM') &&
              activite.jour >= 1 &&
              activite.jour <= daysInMonth) {
            congesParStaff[staff.id]![activite.jour] = activite.statut;
          }
        }
      }

      // 3. Planifier les gardes en ignorant les jours de congé
      for (int day = 1; day <= daysInMonth; day++) {
        int equipeIndex = (day - 1) % equipesOrdonnees.length;
        String equipeDeGarde = equipesOrdonnees[equipeIndex];

        for (final staff in personnelMedical) {
          // Sauter si le jour est un congé
          if (congesParStaff[staff.id]!.containsKey(day)) {
            continue;
          }

          // Déterminer le statut (G ou RE)
          String nouveauStatut =
              (staff.equipe!.toUpperCase() == equipeDeGarde) ? "G" : "RE";

          // Mettre à jour l'activité
          await activiteProvider.updateActivite(
            staff.id,
            day,
            nouveauStatut,
            year: _selectedYear,
            month: _selectedMonth,
          );

          // Mettre à jour les compteurs
          if (nouveauStatut == "G") {
            gardesParEquipe[staff.equipe!.toUpperCase()] =
                (gardesParEquipe[staff.equipe!.toUpperCase()] ?? 0) + 1;
          } else {
            recuperationsParEquipe[staff.equipe!.toUpperCase()] =
                (recuperationsParEquipe[staff.equipe!.toUpperCase()] ?? 0) + 1;
          }
          totalModifications++;
        }
      }

      // 4. Appliquer les congés (écraser les gardes si nécessaire)
      for (final staff in personnelMedical) {
        for (var entry in congesParStaff[staff.id]!.entries) {
          int jour = entry.key;
          String statutConge = entry.value;

          // Vérifier le statut actuel avant écrasement
          final query = activiteProvider.activiteBox
              .query(ActiviteJour_.staff.equals(staff.id) &
                  ActiviteJour_.jour.equals(jour))
              .build();
          final activites = query.find();
          query.close();

          if (activites.isNotEmpty) {
            String? statutActuel = activites.first.statut;
            if (statutActuel == 'G') {
              gardesEcrasees++;
              gardesParEquipe[staff.equipe!.toUpperCase()] =
                  (gardesParEquipe[staff.equipe!.toUpperCase()] ?? 1) - 1;
            } else if (statutActuel == 'RE') {
              recuperationsParEquipe[staff.equipe!.toUpperCase()] =
                  (recuperationsParEquipe[staff.equipe!.toUpperCase()] ?? 1) -
                      1;
            }
          }

          // Appliquer le congé
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            jour,
            statutConge,
            year: _selectedYear,
            month: _selectedMonth,
          );
          congesAppliques[staff.equipe!.toUpperCase()] =
              (congesAppliques[staff.equipe!.toUpperCase()] ?? 0) + 1;
        }
      }

      // 5. Rafraîchir les données
      await staffProvider.fetchStaffs();

      // 6. Préparer le résumé
      String resumeGardes = gardesParEquipe.entries
          .where((e) => e.value > 0)
          .map((e) => "${e.key}: ${e.value}G")
          .join(", ");

      String resumeRecuperations = recuperationsParEquipe.entries
          .where((e) => e.value > 0)
          .map((e) => "${e.key}: ${e.value}RE")
          .join(", ");

      String resumeConges = congesAppliques.entries
          .where((e) => e.value > 0)
          .map((e) => "${e.key}: ${e.value}C")
          .join(", ");

      // 7. Afficher le résultat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 10),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Planification terminée !",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text("📅 Période: $_selectedMonthName $_selectedYear",
                    style: TextStyle(color: Colors.white)),
                Text("🔄 Ordre: ${equipesOrdonnees.join(' → ')}",
                    style: TextStyle(color: Colors.white)),
                Text("👥 ${personnelMedical.length} médecins concernés",
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 6),
                Text(
                  "Phase 1 - Gardes attribuées:",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (resumeGardes.isNotEmpty)
                  Text(
                    "  Gardes: $resumeGardes",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                if (resumeRecuperations.isNotEmpty)
                  Text(
                    "  Récupérations: $resumeRecuperations",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                SizedBox(height: 4),
                Text(
                  "Phase 2 - Congés appliqués:",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (gardesEcrasees > 0)
                  Text(
                    "  🚫 $gardesEcrasees gardes écrasées par des congés",
                    style:
                        TextStyle(color: Colors.yellow.shade200, fontSize: 12),
                  ),
                if (resumeConges.isNotEmpty)
                  Text(
                    "  Congés: $resumeConges",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  )
                else
                  Text(
                    "  ⚠️ Aucun congé appliqué - vérifiez les logs",
                    style:
                        TextStyle(color: Colors.yellow.shade200, fontSize: 12),
                  ),
                SizedBox(height: 4),
                Text(
                  "✅ Total: $totalModifications modifications",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    } catch (e) {
      print("❌ ERREUR PLANIFICATION: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la planification: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Détermine le statut de congé à partir d'un TimeOff
  String _getStatutCongeFromTimeOff(TimeOff timeOff) {
    if (timeOff.motif == null) return 'C';

    final motif = timeOff.motif!.toLowerCase();
    if (motif.contains('maladie') || motif.contains('medical')) {
      return 'CM';
    } else if (motif.contains('garde')) {
      return 'G';
    } else if (motif.contains('récupération') ||
        motif.contains('recuperation')) {
      return 'RE';
    } else {
      return 'C'; // Congé par défaut
    }
  }

  Future<void> _listStaffWithTimeOff() async {
    try {
      final objectBox = ObjectBox();
      final staffs = objectBox.staffBox.getAll();
      final timeOffs = objectBox.timeOffBox.getAll();

      // Grouper les TimeOff par staffId
      Map<int, List<TimeOff>> timeOffsByStaff = {};
      for (var timeOff in timeOffs) {
        if (timeOff.staff.target != null) {
          final staffId = timeOff.staff.target!.id;
          if (!timeOffsByStaff.containsKey(staffId)) {
            timeOffsByStaff[staffId] = [];
          }
          timeOffsByStaff[staffId]!.add(timeOff);
        }
      }

      // Afficher les résultats
      String result = "=== Liste des congés (TimeOff) ===\n";
      for (var staff in staffs) {
        final staffTimeOffs = timeOffsByStaff[staff.id] ?? [];
        result += "\n👤 ${staff.nom} (ID: ${staff.id})\n";
        if (staffTimeOffs.isEmpty) {
          result += "   - Aucun congé enregistré.\n";
        } else {
          for (var timeOff in staffTimeOffs) {
            final debut = DateFormat('dd/MM/yyyy').format(timeOff.debut);
            final fin = DateFormat('dd/MM/yyyy').format(timeOff.fin);
            final motif = timeOff.motif ?? "Congé";
            result += "   - $motif : du $debut au $fin\n";
          }
        }
      }

      // Afficher dans la console
      print(result);

      // Afficher dans un dialog (optionnel)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Liste des congés (TimeOff)"),
          content: SingleChildScrollView(
            child: Text(result),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Erreur lors de la récupération des congés : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
