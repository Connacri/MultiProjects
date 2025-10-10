import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import 'StaffProvider.dart';

/// Widget pour afficher le planning hebdomadaire médical
/// Format : Tableau avec jours de la semaine en colonnes (Dimanche à Jeudi)
class PlanningHebdoWidget extends StatefulWidget {
  const PlanningHebdoWidget({Key? key}) : super(key: key);

  @override
  State<PlanningHebdoWidget> createState() => _PlanningHebdoWidgetState();
}

class _PlanningHebdoWidgetState extends State<PlanningHebdoWidget> {
  // Liste des jours de la semaine (Dimanche à Jeudi)
  final List<String> joursLong = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi'
  ];

  String? _selectedEquipeFilter;
  List<int> _selectedStaffIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Charger toutes les données nécessaires - VERSION CORRIGÉE
  Future<void> _loadData() async {
    final planningProvider = context.read<PlanningHebdoProvider>();
    final staffProvider = context.read<StaffProvider>();
    final typeActiviteProvider = context.read<TypeActiviteProvider>();

    if (!staffProvider.isInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    await planningProvider.fetchPlannings();
    await typeActiviteProvider.fetchTypesActivites();

    // ✅ Nettoyer les doublons AVANT de créer de nouveaux plannings
    await _cleanDuplicatePlannings();

    // Créer les plannings manquants
    await _createMissingPlannings();
  }

  /// Créer automatiquement les plannings manquants pour les médecins existants
  Future<void> _createMissingPlannings() async {
    try {
      final planningProvider = context.read<PlanningHebdoProvider>();
      final staffProvider = context.read<StaffProvider>();

      final medecins = staffProvider.staffs
          .where((s) =>
              s.grade.toLowerCase().contains('médecin') ||
              s.grade.toLowerCase().contains('medecin') ||
              s.grade.toLowerCase().contains('docteur') ||
              s.grade.toLowerCase().contains('rhumatologue'))
          .toList();

      int created = 0;
      for (var medecin in medecins) {
        // ✅ Vérifier TOUS les plannings existants pour ce médecin
        final existingPlannings = planningProvider.plannings
            .where((p) => p.staff.targetId == medecin.id)
            .toList();

        if (existingPlannings.isEmpty) {
          // Créer un nouveau planning seulement s'il n'existe aucun planning
          await planningProvider.createPlanning(staffId: medecin.id);
          created++;
        } else if (existingPlannings.length > 1) {
          // ✅ CORRECTION: Supprimer les doublons en gardant le premier
          print(
              '⚠️ ${existingPlannings.length} plannings trouvés pour ${medecin.nom}');
          for (int i = 1; i < existingPlannings.length; i++) {
            await planningProvider.deletePlanning(existingPlannings[i].id);
            print('🗑️ Planning dupliqué supprimé pour ${medecin.nom}');
          }
        }
      }

      if (created > 0) {
        print('✅ $created plannings créés automatiquement pour les médecins');
        await planningProvider.fetchPlannings();
      }
    } catch (e) {
      print('❌ Erreur création plannings manquants: $e');
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Nettoyer tous les doublons
  Future<void> _cleanDuplicatePlannings() async {
    try {
      final planningProvider = context.read<PlanningHebdoProvider>();
      final staffProvider = context.read<StaffProvider>();

      int cleaned = 0;

      // Grouper les plannings par staffId
      final Map<int, List<PlanningHebdo>> planningsByStaff = {};

      for (var planning in planningProvider.plannings) {
        final staffId = planning.staff.targetId;
        if (staffId != null) {
          planningsByStaff.putIfAbsent(staffId, () => []).add(planning);
        }
      }

      // Supprimer les doublons pour chaque staff
      for (var entry in planningsByStaff.entries) {
        if (entry.value.length > 1) {
          final staffId = entry.key;
          final staff = staffProvider.staffs.firstWhere(
            (s) => s.id == staffId,
            orElse: () => Staff(nom: 'Inconnu', grade: '', groupe: ''),
          );

          print('⚠️ ${entry.value.length} plannings trouvés pour ${staff.nom}');

          // Garder le premier, supprimer les autres
          for (int i = 1; i < entry.value.length; i++) {
            await planningProvider.deletePlanning(entry.value[i].id);
            cleaned++;
          }
        }
      }

      if (cleaned > 0) {
        print('✅ $cleaned plannings dupliqués supprimés');
        await planningProvider.fetchPlannings();
        if (mounted) {
          _showSuccessSnackbar('$cleaned plannings dupliqués supprimés');
        }
      }
    } catch (e) {
      print('❌ Erreur nettoyage doublons: $e');
    }
  }

// ✅ Ajouter ce bouton dans l'AppBar pour nettoyer manuellement
  Widget buildAppBarWithCleanup() {
    return AppBar(
      title: const Text('Planning Médical Hebdomadaire'),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      actions: [
        // Nouveau bouton pour nettoyer les doublons
        IconButton(
          icon: const Icon(Icons.cleaning_services),
          tooltip: 'Nettoyer les doublons',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Nettoyer les doublons'),
                content: const Text(
                  'Cette action va supprimer tous les plannings en double pour chaque médecin.\n\nContinuer ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Nettoyer'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _cleanDuplicatePlannings();
            }
          },
        ),
        // Bouton Clear Activités
        IconButton(
          icon: const Icon(Icons.clear_all),
          tooltip: 'Effacer toutes les activités',
          onPressed: () => _confirmClearAllActivities(),
        ),
        // Gérer les types d'activités
        IconButton(
          icon: const Icon(Icons.category),
          tooltip: 'Types d\'activités',
          onPressed: () => _showTypesActivitesDialog(),
        ),
        // Actualiser
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
          onPressed: () => _loadData(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Médical Hebdomadaire'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Bouton Clear Activités
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Effacer toutes les activités',
            onPressed: () => _confirmClearAllActivities(),
          ),
          // Gérer les types d'activités
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Types d\'activités',
            onPressed: () => _showTypesActivitesDialog(),
          ),
          // Actualiser
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body:
          Consumer3<PlanningHebdoProvider, StaffProvider, TypeActiviteProvider>(
        builder: (context, planningProvider, staffProvider,
            typeActiviteProvider, child) {
          if (!staffProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtrer uniquement les médecins (avec différentes orthographes)
          final medecins = staffProvider.staffs
              .where((s) =>
                  s.grade.toLowerCase().contains('médecin') ||
                  s.grade.toLowerCase().contains('medecin') ||
                  s.grade.toLowerCase().contains('docteur') ||
                  s.grade.toLowerCase().contains('rhumatologue'))
              .toList();

          if (medecins.isEmpty) {
            return _buildNoMedecins();
          }

          // Filtrer les plannings des médecins
          var filteredPlannings = planningProvider.plannings.where((p) {
            final staff = p.staff.target;
            return staff != null &&
                (staff.grade.toLowerCase().contains('médecin') ||
                    staff.grade.toLowerCase().contains('medecin') ||
                    staff.grade.toLowerCase().contains('docteur') ||
                    staff.grade.toLowerCase().contains('rhumatologue'));
          }).toList();

          // Filtre par équipe
          if (_selectedEquipeFilter != null) {
            filteredPlannings = filteredPlannings.where((p) {
              return p.staff.target?.equipe == _selectedEquipeFilter;
            }).toList();
          }

          if (filteredPlannings.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(filteredPlannings.length),
                const SizedBox(height: 24),
                _buildWeeklyTable(filteredPlannings, typeActiviteProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'PLANNING MÉDICAL HEBDOMADAIRE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$count médecin(s) • Du Dimanche au Jeudi',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTable(List<PlanningHebdo> plannings,
      TypeActiviteProvider typeActiviteProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          headingRowHeight: 56,
          dataRowHeight: 80,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
            borderRadius: BorderRadius.circular(12),
          ),
          columns: [
            DataColumn(
              label: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Médecin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Grade - Équipe',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...List.generate(5, (index) {
              return DataColumn(
                label: Container(
                  width: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        joursLong[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          rows: plannings.map((planning) {
            final staff = planning.staff.target;
            if (staff == null) return const DataRow(cells: []);

            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 180,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff.grade,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (staff.equipe != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Équipe ${staff.equipe}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ...List.generate(5, (index) {
                  final activite = planning.getActiviteJour(index);
                  return DataCell(
                    InkWell(
                      onTap: () => _showEditDialog(staff, index, activite,
                          planning, typeActiviteProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 120,
                        height: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              _getActiviteColor(activite, typeActiviteProvider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Text(
                            //   _getActiviteLabel(activite, typeActiviteProvider),
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     fontWeight: activite != null
                            //         ? FontWeight.w600
                            //         : FontWeight.normal,
                            //     color: activite != null
                            //         ? Colors.grey.shade800
                            //         : Colors.grey.shade400,
                            //   ),
                            //   textAlign: TextAlign.center,
                            //   maxLines: 3,
                            //   overflow: TextOverflow.ellipsis,
                            // ),
                            Text(
                              _getActiviteDescription(
                                  activite, typeActiviteProvider),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: activite != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: activite != null
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (activite == null)
                              Icon(
                                Icons.add_circle_outline,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Obtenir le libellé d'une activité depuis le Provider
  String _getActiviteLabel(
      String? code, TypeActiviteProvider typeActiviteProvider) {
    if (code == null) return 'À définir';
    final type = typeActiviteProvider.getTypeByCode(code);
    return type?.libelle ?? code;
  }

  /// Obtenir le libellé d'une activité depuis le Provider
  String _getActiviteDescription(
      String? code, TypeActiviteProvider typeActiviteProvider) {
    if (code == null) return '';
    final type = typeActiviteProvider.getTypeByCode(code);
    return type?.description ?? '';
  }

  /// Obtenir la couleur depuis le Provider
  Color _getActiviteColor(
      String? code, TypeActiviteProvider typeActiviteProvider) {
    if (code == null) return Colors.grey.shade50;
    final type = typeActiviteProvider.getTypeByCode(code);
    if (type?.couleurHex != null) {
      return Color(type!.couleurHex!);
    }
    // Couleurs par défaut si non trouvé
    final codeLower = code.toLowerCase();
    if (codeLower.contains('dmo')) return Colors.blue.shade300;
    if (codeLower.contains('vg')) return Colors.green.shade300;
    if (codeLower.contains('consult')) return Colors.purple.shade300;
    if (codeLower.contains('serv')) return Colors.grey.shade300;
    if (codeLower == 'ped') return Colors.amber.shade300;
    if (codeLower == 'bio') return Colors.blueGrey.shade300;
    if (codeLower == 'c' || codeLower == 'cm') return Colors.red.shade300;
    if (codeLower == 'n') return Colors.indigo.shade300;
    return Colors.grey.shade200;
  }

  /// Dialog pour éditer une activité - MODIFIÉ pour utiliser le Provider
  void _showEditDialog(Staff staff, int jourSemaine, String? activiteActuelle,
      PlanningHebdo planning, TypeActiviteProvider typeActiviteProvider) {
    String? selectedCode = activiteActuelle;
    final planningProvider = context.read<PlanningHebdoProvider>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier activité'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.nom,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(staff.grade,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const Divider(),
                      Text(
                        joursLong[jourSemaine],
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sélectionner une activité :',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: typeActiviteProvider.typesActivites.map((type) {
                    final isSelected = selectedCode == type.code;
                    return ChoiceChip(
                      label: Text(type.libelle),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedCode = selected ? type.code : null;
                        });
                      },
                      backgroundColor: type.couleurHex != null
                          ? Color(type.couleurHex!)
                          : null,
                      selectedColor: type.couleurHex != null
                          ? Color(type.couleurHex!).withOpacity(0.8)
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (activiteActuelle != null)
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label:
                    const Text('Effacer', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  await planningProvider.updateActiviteJour(
                    staffId: staff.id,
                    jourSemaine: jourSemaine,
                    activite: null,
                  );
                  Navigator.pop(context);
                  _showSuccessSnackbar('Activité effacée');
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  await planningProvider.updateActiviteJour(
                    staffId: staff.id,
                    jourSemaine: jourSemaine,
                    activite: selectedCode,
                  );
                  Navigator.pop(context);
                  _showSuccessSnackbar('Activité mise à jour');
                } catch (e) {
                  _showErrorSnackbar('Erreur: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmer l'effacement de toutes les activités
  void _confirmClearAllActivities() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les activités'),
        content: const Text(
          'Voulez-vous vraiment effacer toutes les activités de la semaine pour tous les médecins ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _clearAllActivities();
                Navigator.pop(context);
                _showSuccessSnackbar('Toutes les activités ont été effacées');
              } catch (e) {
                _showErrorSnackbar('Erreur: $e');
              }
            },
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
  }

  /// Effacer toutes les activités de la semaine
  Future<void> _clearAllActivities() async {
    try {
      final planningProvider = context.read<PlanningHebdoProvider>();
      await planningProvider.clearAllActivities();
    } catch (e) {
      print('❌ Erreur effacement activités: $e');
      rethrow;
    }
  }

  /// NOUVELLE METHODE : Dialog CRUD pour les types d'activités
  void _showTypesActivitesDialog() {
    // ✅ RÉCUPÉRER LE PROVIDER AVANT D'OUVRIR LE DIALOG
    final typeActiviteProvider = context.read<TypeActiviteProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gestion des Types d\'Activités'),
        content: SizedBox(
          width: double.maxFinite,
          // ❌ NE PAS UTILISER Consumer ICI - utiliser directement le provider
          child: ListenableBuilder(
            listenable: typeActiviteProvider,
            builder: (context, child) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton pour créer un nouveau type
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Nouveau Type'),
                        onPressed: () =>
                            _showAddTypeDialog(typeActiviteProvider),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Liste des types existants
                    typeActiviteProvider.typesActivites.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Aucun type d\'activité défini',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                typeActiviteProvider.typesActivites.length,
                            itemBuilder: (context, index) {
                              final type =
                                  typeActiviteProvider.typesActivites[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: type.couleurHex != null
                                          ? Color(type.couleurHex!)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        type.code,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(type.libelle),
                                  subtitle: type.description != null
                                      ? Text(type.description!)
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showEditTypeDialog(
                                            type, typeActiviteProvider),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        onPressed: () => _confirmDeleteType(
                                            type, typeActiviteProvider),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Dialog pour ajouter un nouveau type
  void _showAddTypeDialog(TypeActiviteProvider provider) {
    final codeController = TextEditingController();
    final libelleController = TextEditingController();
    final descriptionController = TextEditingController();
    int? selectedColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau Type d\'Activité'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code*',
                    hintText: 'Ex: DMO, CONSULT, SERV...',
                  ),
                  maxLength: 10,
                ),
                TextField(
                  controller: libelleController,
                  decoration: const InputDecoration(
                    labelText: 'Libellé*',
                    hintText: 'Ex: Demi-journée, Consultation...',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Description détaillée...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Couleur :'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildColorOption(
                        0xFFBBDEFB, 'Bleu', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFC8E6C9, 'Vert', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFE1BEE7, 'Violet', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFFFE0B2, 'Orange', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFB2DFDB, 'Turquoise', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFFFCDD2, 'Rouge', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty ||
                    libelleController.text.isEmpty) {
                  _showErrorSnackbar('Le code et le libellé sont obligatoires');
                  return;
                }

                try {
                  await provider.createTypeActivite(
                    code: codeController.text,
                    libelle: libelleController.text,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                    couleurHex: selectedColor,
                  );
                  Navigator.pop(dialogContext);
                  _showSuccessSnackbar('Type d\'activité créé avec succès');
                } catch (e) {
                  _showErrorSnackbar('Erreur: $e');
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog pour modifier un type existant
  void _showEditTypeDialog(TypeActivite type, TypeActiviteProvider provider) {
    final libelleController = TextEditingController(text: type.libelle);
    final descriptionController =
        TextEditingController(text: type.description ?? '');
    int? selectedColor = type.couleurHex;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier ${type.code}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Code: ${type.code}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: libelleController,
                  decoration: const InputDecoration(labelText: 'Libellé*'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Couleur :'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildColorOption(
                        0xFFBBDEFB, 'Bleu', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFC8E6C9, 'Vert', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFE1BEE7, 'Violet', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFFFE0B2, 'Orange', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFB2DFDB, 'Turquoise', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                    _buildColorOption(
                        0xFFFFCDD2, 'Rouge', selectedColor, setDialogState,
                        (color) {
                      selectedColor = color;
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (libelleController.text.isEmpty) {
                  _showErrorSnackbar('Le libellé est obligatoire');
                  return;
                }

                try {
                  type.libelle = libelleController.text;
                  type.description = descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null;
                  type.couleurHex = selectedColor;

                  await provider.updateTypeActivite(type);
                  Navigator.pop(dialogContext);
                  _showSuccessSnackbar('Type d\'activité modifié avec succès');
                } catch (e) {
                  _showErrorSnackbar('Erreur: $e');
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmer la suppression d'un type
  void _confirmDeleteType(TypeActivite type, TypeActiviteProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer le type "${type.libelle}" (${type.code}) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await provider.deleteTypeActivite(type.id);
                Navigator.pop(dialogContext);
                _showSuccessSnackbar('Type d\'activité supprimé');
              } catch (e) {
                _showErrorSnackbar('Erreur: $e');
              }
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Aucun planning disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Commencez par ajouter des médecins',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildNoMedecins() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Aucun médecin trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Ajoutez des médecins pour créer les plannings',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message))
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message))
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Widget pour les options de couleur - VERSION CORRIGÉE
  Widget _buildColorOption(
    int colorValue,
    String label,
    int? selectedColor,
    Function setDialogState,
    Function(int) onColorSelected,
  ) {
    final isSelected = selectedColor == colorValue;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          onColorSelected(colorValue);
        });
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(colorValue),
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected ? Border.all(color: Colors.blue, width: 3) : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
