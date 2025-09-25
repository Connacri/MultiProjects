import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import 'ActivitePersonne.dart';
import 'StaffProvider.dart';

class TableauStaffPage extends StatefulWidget {
  @override
  _TableauStaffPageState createState() => _TableauStaffPageState();
}

class _TableauStaffPageState extends State<TableauStaffPage> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StaffProvider>(context, listen: false);
      provider.fetchStaffs();
    });
  }

  // Fonction supprimée - l'équipe vient maintenant directement des données

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
        title: const Text('Planning du Personnel - Octobre 2025'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.blue),
            label: const Text("Ajouter toutes les activités"),
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
                await activiteProvider.insertActivites(activites);

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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider =
                  Provider.of<StaffProvider>(context, listen: false);
              provider.fetchStaffs();
            },
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
                          'Mois d\'Octobre 2025 - Horaires: DE 8H À 16H',
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
                        const Text(
                          'Légende des statuts:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildLegendItem('G', Colors.green, 'Garde'),
                            const SizedBox(width: 16),
                            _buildLegendItem('RE/RÉ', Colors.blue, 'Repos'),
                            const SizedBox(width: 16),
                            _buildLegendItem('C', Colors.orange, 'Congé'),
                            const SizedBox(width: 16),
                            _buildLegendItem('N', Colors.red, 'Normal'),
                            const SizedBox(width: 16),
                            _buildLegendItem('R', Colors.brown, 'Récupération'),
                          ],
                        ),
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DataTable(
                              columnSpacing: 12,
                              headingRowHeight: 50,
                              dataRowHeight: 45,
                              headingRowColor:
                                  WidgetStateProperty.all(Colors.grey.shade300),
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
                                ...List.generate(
                                  31,
                                  (i) {
                                    final jour = i + 1;

                                    // Calcul du jour de la semaine (1 Octobre 2025 = Mercredi, tu peux ajuster)
                                    final date = DateTime(2025, 10, jour);
                                    final isSamedi =
                                        date.weekday == DateTime.saturday;
                                    final isDimanche =
                                        date.weekday == DateTime.sunday;

                                    Color? bgColor;
                                    if (isSamedi) bgColor = Colors.red.shade100;
                                    if (isDimanche)
                                      bgColor = Colors.blue.shade100;

                                    return DataColumn(
                                      label: Container(
                                        width: 28,
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$jour',
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
                                final equipe = staffData['equipe'] as String;

                                // Charger et organiser les activités pour chaque staff
                                final activites = staff.activites.toList();

                                // Créer un tableau de 31 jours initialisé avec des tirets
                                List<String> jours = List.filled(31, '-');

                                // Remplir avec les vraies activités
                                for (var activite in activites) {
                                  if (activite.jour >= 1 &&
                                      activite.jour <= 31) {
                                    jours[activite.jour - 1] = activite.statut;
                                  }
                                }

                                return DataRow(
                                  color:
                                      MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.hovered)) {
                                        return Colors.blue.shade50;
                                      }
                                      return null;
                                    },
                                  ),
                                  cells: [
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(
                                          '$numero',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        constraints:
                                            const BoxConstraints(minWidth: 140),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(
                                          staff.nom.isEmpty
                                              ? 'NOM VIDE'
                                              : staff.nom,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: staff.nom.isEmpty
                                                ? Colors.red
                                                : Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        constraints:
                                            const BoxConstraints(minWidth: 120),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(
                                          staff.grade.isEmpty
                                              ? 'GRADE VIDE'
                                              : staff.grade,
                                          style: TextStyle(
                                            color: staff.grade.isEmpty
                                                ? Colors.red
                                                : Colors.black87,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: 50,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getEquipeColor(equipe),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            equipe,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        constraints:
                                            const BoxConstraints(minWidth: 100),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Tooltip(
                                          message:
                                              staff.obs ?? 'Aucune observation',
                                          child: Text(
                                            staff.obs?.isEmpty != false
                                                ? '-'
                                                : (staff.obs!.length > 12
                                                    ? '${staff.obs!.substring(0, 12)}...'
                                                    : staff.obs!),
                                            style: TextStyle(
                                              color: staff.obs?.isEmpty != false
                                                  ? Colors.grey
                                                  : Colors.orange.shade700,
                                              fontSize: 11,
                                              fontStyle: staff.obs != null
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...jours.map((jour) => DataCell(
                                          Container(
                                            width: 28,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(jour)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _getStatusColor(jour)
                                                    .withOpacity(0.3),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                jour,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: _getStatusColor(jour),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )),
                                  ],
                                );
                              }).toList(),
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

  Widget _buildLegendItem(String code, Color color, String description) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
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
}
