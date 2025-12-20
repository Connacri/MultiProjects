import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';
import '1.dart';
import 'AboutAppPage.dart';
import 'ActivitePersonne.dart';
import 'PlanningHebdoWidget.dart';
import 'Planning_pdf.dart';
import 'StaffProvider.dart';
import 'license/LicenseInfoPage.dart';
import 'p2p/connection_manager.dart';
import 'p2p/messenger/messaging_manager.dart';
import 'p2p/messenger/select_node.dart';
import 'p2p/objectbox_sync_observer.dart';
import 'p2p/p2p_manager.dart';
import 'p2p/p2p_status_widgets.dart';
import 'pdf_options_dialog.dart';
import 'print_planning_grouped_final.dart';
import 'widgets.dart';

/// Widget qui permet le drag-to-scroll pour desktop
class DragScrollWrapper extends StatefulWidget {
  final Widget child;
  final Axis scrollDirection;

  const DragScrollWrapper({
    Key? key,
    required this.child,
    this.scrollDirection = Axis.horizontal,
  }) : super(key: key);

  @override
  State<DragScrollWrapper> createState() => _DragScrollWrapperState();
}

class _DragScrollWrapperState extends State<DragScrollWrapper> {
  Offset? _dragStart;
  ScrollController? _horizontalController;
  ScrollController? _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController?.dispose();
    _verticalController?.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    // Vérifier si c'est un clic souris (pas touch)
    if (event.kind == PointerDeviceKind.mouse) {
      _dragStart = event.position;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragStart != null && event.kind == PointerDeviceKind.mouse) {
      final delta = event.position - _dragStart!;
      _dragStart = event.position;

      // Scroll horizontal
      if (_horizontalController != null && _horizontalController!.hasClients) {
        final newOffset = _horizontalController!.offset - delta.dx;
        _horizontalController!.jumpTo(
          newOffset.clamp(
            0.0,
            _horizontalController!.position.maxScrollExtent,
          ),
        );
      }

      // Scroll vertical
      if (_verticalController != null && _verticalController!.hasClients) {
        final newOffset = _verticalController!.offset - delta.dy;
        _verticalController!.jumpTo(
          newOffset.clamp(
            0.0,
            _verticalController!.position.maxScrollExtent,
          ),
        );
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _dragStart = null,
      child: MouseRegion(
        cursor: _dragStart != null
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
            scrollbars: true,
          ),
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alternative : Utiliser InteractiveViewer (plus simple)
class InteractiveTableWrapper extends StatelessWidget {
  final Widget child;

  const InteractiveTableWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      // Permet le pan/zoom avec la souris
      panEnabled: true,
      scaleEnabled: false,
      // Désactiver le zoom si non souhaité
      minScale: 1.0,
      maxScale: 1.0,
      // Limites de défilement
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      child: child,
    );
  }
}

class TableauStaffPage extends StatefulWidget {
  @override
  _TableauStaffPageState createState() => _TableauStaffPageState();
}

class _TableauStaffPageState extends State<TableauStaffPage> {
  // ⭐ NOUVEAU : Variables pour la gestion du mois et année
  int _selectedMonth = DateTime.now().month;
  int _selectedMonthNext = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

// 1. Ajoutez ces variables d'état dans _TableauStaffPageState
  int _previousMonth = DateTime.now().month;
  int _previousYear = DateTime.now().year;
  bool _isNavigatingForward = false;

  // Variables pour gérer l'édition
  Map<String, bool> _editingCells = {}; // Clé: "staffId-jour"
  Map<String, String> _tempValues = {}; // Valeurs temporaires pendant l'édition

  // Liste des statuts disponibles pour le dropdown
  final List<String> _statutsDisponibles = ['G', "RE", 'C', 'CM', 'N', '-'];

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

    // Utiliser les capacités de DateTime pour calculer automatiquement
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month, 1);

    _selectedMonth = nextMonth.month;
    _selectedYear = nextMonth.year;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<StaffProvider>(context, listen: false);
      // quickGroupCorrection();
      await provider.fetchStaffs();
      await _loadMonth(_selectedYear, _selectedMonth);
    });
  }

  // ⭐ NOUVEAU : Obtenir le nombre de jours dans le mois sélectionné
  int get _daysInSelectedMonth =>
      DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

  // ⭐ NOUVEAU : Obtenir le nom du mois sélectionné
  String get _selectedMonthName => _moisNoms[_selectedMonth - 1];

// 2. Remplacez la méthode _onMonthChanged par cette version améliorée
  Future<void> _onMonthChanged(int? value) async {
    if (value == null || value == _selectedMonth) return;

    // Déterminer la direction de navigation
    final isForward = _isMonthForward(value, _selectedMonth, _selectedYear);
    _isNavigatingForward = isForward;

    // Sauvegarder l'ancien mois
    await _saveCurrentMonth();

    // Mémoriser l'ancien mois
    _previousMonth = _selectedMonth;
    _previousYear = _selectedYear;

    // Changer de mois
    setState(() {
      _selectedMonth = value;
      _editingCells.clear();
      _tempValues.clear();
    });

    // Charger le nouveau mois avec logique intelligente
    await _loadMonthWithIntelligentLogic(
      _selectedYear,
      value,
      isForward: isForward,
    );
  }

// 3. Nouvelle méthode pour déterminer si on avance ou recule
  bool _isMonthForward(int newMonth, int oldMonth, int year) {
    if (newMonth > oldMonth) return true;
    if (newMonth < oldMonth) return false;
    return false;
  }

// 4. Méthode principale de chargement intelligent
  Future<void> _loadMonthWithIntelligentLogic(
    int year,
    int month, {
    required bool isForward,
  }) async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final objectBox = ObjectBox();

      // Vérifier si le mois existe déjà
      final query = objectBox.planificationBox
          .query(Planification_.mois.equals(month) &
              Planification_.annee.equals(year))
          .build();
      final existingPlanif = query.findFirst();
      query.close();

      final monthExists = existingPlanif != null;

      print(
          "📅 Navigation vers $month/$year (${isForward ? 'Avance' : 'Recul'})");
      print("   Mois existe: $monthExists");

      if (!isForward) {
        // ⬅️ RECULER : Afficher ce qui existe ou laisser vide
        if (monthExists) {
          await staffProvider.loadMonthActivities(year, month);
          // ✅ FORCER le refresh de l'interface
          await staffProvider.forceRefresh();

          _showSnackbar(
            "📂 Mois ${_moisNoms[month - 1]} $year chargé",
            Colors.blue,
          );
        } else {
          // Tableau vide
          await _clearCurrentMonthDataSilently();
          _showEmptyMonthDialog(month, year, isRecul: true);
        }
      } else {
        // ➡️ AVANCER : Logique intelligente
        if (monthExists) {
          // Mois existe : afficher ce qui est enregistré
          await staffProvider.loadMonthActivities(year, month);
          // ✅ FORCER le refresh de l'interface
          await staffProvider.forceRefresh();

          // Vérifier si des tableaux sont vides
          await _checkAndNotifyEmptyGroups(month, year);

          _showSnackbar(
            "📂 Mois ${_moisNoms[month - 1]} $year chargé",
            Colors.blue,
          );
        } else {
          // Nouveau mois : remplissage automatique intelligent
          await _autoFillNewMonth(year, month);
        }
      }

      // ✅ CRITIQUE : Forcer plusieurs refresh pour garantir la MAJ
      await staffProvider.fetchStaffs();
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() {}); // Force rebuild du widget
      }
    } catch (e) {
      print("❌ Erreur _loadMonthWithIntelligentLogic: $e");
      _showSnackbar("❌ Erreur: $e", Colors.red);
    }
  }

// 5. Remplissage automatique d'un nouveau mois
  Future<void> _autoFillNewMonth(int year, int month) async {
    try {
      print("🆕 Remplissage automatique du mois $month/$year");

      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();
      final objectBox = ObjectBox();

      final daysInMonth = DateUtils.getDaysInMonth(year, month);
      int modifications = 0;

      // 1️⃣ PERSONNEL MÉDICAL ET ADMINISTRATIF : Remplissage automatique
      final personnelMedicalAdmin = staffProvider.staffs.where((staff) {
        return (staff.grade.toLowerCase().contains('médecin') ||
                staff.groupe == '08H-16H') &&
            staff.groupe != 'Garde 24H' &&
            staff.grade != "Agent d'hygiène";
      }).toList();

      for (final staff in personnelMedicalAdmin) {
        final equipe = staff.equipe?.toUpperCase();
        final isEquipeABCD =
            equipe != null && ['A', 'B', 'C', 'D'].contains(equipe);

        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(year, month, day);

          // Vérifier congés
          if (_isStaffOnLeaveForDate(staff, date)) {
            await activiteProvider.forceUpdateActiviteIgnoringLeave(
              staff.id,
              day,
              'C',
              year: year,
              month: month,
            );
            continue;
          }

          // Déterminer le statut
          String statut;
          if (date.weekday == DateTime.friday ||
              date.weekday == DateTime.saturday) {
            statut = "RE";
          } else {
            statut = isEquipeABCD ? "-" : "N";
          }

          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            day,
            statut,
            year: year,
            month: month,
          );
          modifications++;
        }
      }

      print("✅ $modifications modifications pour personnel médical/admin");

      // 2️⃣ PERSONNEL PARAMÉDICAL : Copier l'ordre du mois précédent
      await _copyParamedicalRotation(
          _previousYear, _previousMonth, year, month);

      // 3️⃣ AGENTS D'HYGIÈNE : Copier l'ordre du mois précédent
      await _copyHygieneRotation(_previousYear, _previousMonth, year, month);

      // 4️⃣ Sauvegarder la planification
      await staffProvider.saveMonthActivities(year, month);

      _showSnackbar(
        "✅ Mois ${_moisNoms[month - 1]} $year créé automatiquement",
        Colors.green,
        duration: 4,
      );
    } catch (e) {
      print("❌ Erreur _autoFillNewMonth: $e");
      _showSnackbar("❌ Erreur: $e", Colors.red);
    }
  }

// 6. Copier la rotation paramédical du mois précédent
  Future<void> _copyParamedicalRotation(
    int fromYear,
    int fromMonth,
    int toYear,
    int toMonth,
  ) async {
    try {
      print(
          "🔄 Copie rotation paramédical: $fromMonth/$fromYear → $toMonth/$toYear");

      final objectBox = ObjectBox();
      final activiteProvider = ActiviteProvider();
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);

      // Récupérer la planification du mois précédent
      final query = objectBox.planificationBox
          .query(Planification_.mois.equals(fromMonth) &
              Planification_.annee.equals(fromYear))
          .build();
      final previousPlanif = query.findFirst();
      query.close();

      if (previousPlanif == null || previousPlanif.ordreEquipes.isEmpty) {
        print("⚠️ Pas de planification paramédical dans le mois précédent");
        return;
      }

      // Récupérer l'ordre des équipes
      final equipesOrdonnees =
          previousPlanif.ordreEquipes.split(',').map((e) => e.trim()).toList();
      print("   Ordre trouvÃ©: ${equipesOrdonnees.join(' â†')}");
// âœ… CALCULER quelle Ã©quipe doit commencer dans le nouveau mois
      final daysInPreviousMonth = DateUtils.getDaysInMonth(fromYear, fromMonth);

      // Trouver quelle Ã©quipe Ã©tait de garde le dernier jour du mois prÃ©cÃ©dent
      int lastDayEquipeIndex =
          (daysInPreviousMonth - 1) % equipesOrdonnees.length;

      // L'Ã©quipe suivante commence le nouveau mois
      int startEquipeIndex = (lastDayEquipeIndex + 1) % equipesOrdonnees.length;

      // RÃ©organiser l'ordre pour que cette Ã©quipe soit en premier
      final newOrder = <String>[];
      for (int i = 0; i < equipesOrdonnees.length; i++) {
        int index = (startEquipeIndex + i) % equipesOrdonnees.length;
        newOrder.add(equipesOrdonnees[index]);
      }

      print("   Nouvel ordre (continuitÃ©): ${newOrder.join(' â†')}");
      print("   Ã‰quipe ${newOrder[0]} commence le jour 1");

      // Appliquer au nouveau mois avec le nouvel ordre
      await _executerPlanificationGardesSimple(newOrder);

      print("âœ… Rotation paramÃ©dical copiÃ©e avec continuitÃ©");
    } catch (e) {
      print("❌ Erreur _copyParamedicalRotation: $e");
    }
  }

// 7. Copier la rotation hygiène du mois précédent
  Future<void> _copyHygieneRotation(
    int fromYear,
    int fromMonth,
    int toYear,
    int toMonth,
  ) async {
    try {
      print(
          "🧹 Copie rotation hygiène: $fromMonth/$fromYear → $toMonth/$toYear");

      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final objectBox = ObjectBox();

      // Identifier les agents d'hygiène
      final agentsHygiene = staffProvider.staffs
          .where((s) =>
              s.grade.toLowerCase().contains('hygiène') ||
              s.groupe == '08H-12H')
          .toList();

      if (agentsHygiene.isEmpty) {
        print("⚠️ Aucun agent d'hygiène trouvé");
        return;
      }

      // Récupérer l'ordre du mois précédent (premier jour ouvrable)
      final joursOuvrablesPrecedent = <int>[];
      final daysInPreviousMonth = DateUtils.getDaysInMonth(fromYear, fromMonth);

      for (int day = 1; day <= daysInPreviousMonth; day++) {
        final date = DateTime(fromYear, fromMonth, day);
        if (date.weekday != DateTime.friday &&
            date.weekday != DateTime.saturday) {
          joursOuvrablesPrecedent.add(day);
        }
      }

      if (joursOuvrablesPrecedent.isEmpty) return;

      // Trouver l'ordre des agents dans le mois précédent
      final ordreAgents = <Staff>[];
      for (final jourOuvrable in joursOuvrablesPrecedent) {
        for (final agent in agentsHygiene) {
          final activites =
              agent.activites.where((a) => a.jour == jourOuvrable).toList();
          if (activites.isNotEmpty && activites.first.statut == 'N') {
            if (!ordreAgents.contains(agent)) {
              ordreAgents.add(agent);
            }
            break;
          }
        }
      }

      if (ordreAgents.isEmpty) {
        print("⚠️ Impossible de déterminer l'ordre du mois précédent");
        return;
      }

      print("   Ordre trouvé: ${ordreAgents.map((a) => a.nom).join(' → ')}");

      // Calculer les jours ouvrables du nouveau mois
      final joursOuvrables = <int>[];
      final daysInMonth = DateUtils.getDaysInMonth(toYear, toMonth);

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(toYear, toMonth, day);
        if (date.weekday != DateTime.friday &&
            date.weekday != DateTime.saturday) {
          joursOuvrables.add(day);
        }
      }

      // Analyser les congés du nouveau mois
      final congesParAgent = await _analyserCongesAgents(agentsHygiene);

      // Appliquer la rotation
      await _executerPlanificationAgentsHygiene(
        ordreAgents,
        joursOuvrables,
        congesParAgent,
      );

      print("✅ Rotation hygiène copiée");
    } catch (e) {
      print("❌ Erreur _copyHygieneRotation: $e");
    }
  }

// 8. Vérifier si un staff est en congé à une date
  bool _isStaffOnLeaveForDate(Staff staff, DateTime date) {
    final objectBox = ObjectBox();

    // TimeOff
    final timeOffs = objectBox.timeOffBox
        .query(TimeOff_.staff.equals(staff.id))
        .build()
        .find();

    for (var timeOff in timeOffs) {
      if (date.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
          date.isBefore(timeOff.fin.add(Duration(days: 1)))) {
        return true;
      }
    }

    return false;
  }

// 9. Vérifier et notifier les groupes vides
  Future<void> _checkAndNotifyEmptyGroups(int month, int year) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final groupedStaffs = _groupStaffs(staffProvider.staffs);

    final emptyGroups = <String>[];

    for (var entry in groupedStaffs.entries) {
      final groupeName = entry.key;
      final groupStaffs = entry.value;

      bool hasActivities = false;
      for (var staffData in groupStaffs) {
        final staff = staffData['staff'] as Staff;
        if (staff.activites.isNotEmpty) {
          hasActivities = true;
          break;
        }
      }

      if (!hasActivities) {
        emptyGroups.add(groupeName);
      }
    }

    if (emptyGroups.isNotEmpty) {
      _showEmptyGroupsDialog(emptyGroups, month, year);
    }
  }

// 10. Dialog pour mois vide (recul)
  void _showEmptyMonthDialog(int month, int year, {bool isRecul = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text("Mois vide"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Le mois de ${_moisNoms[month - 1]} $year est vide",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              isRecul
                  ? "Aucune planification n'a été enregistrée pour ce mois."
                  : "Ce mois n'a pas encore été planifié.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

// 11. Dialog pour groupes vides
  void _showEmptyGroupsDialog(List<String> emptyGroups, int month, int year) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text("Tableaux incomplets")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Les groupes suivants sont vides pour ${_moisNoms[month - 1]} $year :",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...emptyGroups.map((group) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group,
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Planifiez ces groupes pour compléter le mois",
                      style:
                          TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

// 12. Nettoyer silencieusement le mois actuel
  Future<void> _clearCurrentMonthDataSilently() async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
    } catch (e) {
      print("❌ Erreur _clearCurrentMonthDataSilently: $e");
    }
  }

// 13. Snackbar helper
  void _showSnackbar(String message, Color color, {int duration = 3}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

// 4. Modifier aussi la méthode _saveActiviteModification
  Future<void> _saveActiviteModification(
      Staff staff, int jour, String nouveauStatut) async {
    try {
      final activiteProvider = ActiviteProvider();
      await activiteProvider.updateActivite(staff.id, jour, nouveauStatut,
          year: _selectedYear, month: _selectedMonth);

      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
      await staffProvider.saveMonthActivities(_selectedYear, _selectedMonth);

      // ✅ AJOUT CRITIQUE : Forcer le rebuild de tout le widget
      if (mounted) {
        setState(() {
          // Vider les états d'édition APRÈS la mise à jour des données
          _editingCells.clear();
          _tempValues.clear();
        });
      }

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

  // Map<String, List<dynamic>> _groupStaffs(List<Staff> staffs) {
  //   Map<String, List<dynamic>> groupedStaffs = {};
  //
  //   // Définir les groupes dans l'ordre souhaité
  //   final ordreGroupes = [
  //     'Personnel Médical',
  //     'Personnel Administratif (08h-16h)',
  //     'Personnel Paramédical (08h-08h)',
  //     'Agents d\'hygiène (08h-12h)',
  //   ];
  //
  //   // Initialiser les groupes
  //   for (String groupe in ordreGroupes) {
  //     groupedStaffs[groupe] = [];
  //   }
  //
  //   int numeroGlobal = 1;
  //
  //   for (var staff in staffs) {
  //     String groupeAffichage;
  //
  //     if (staff.grade.toLowerCase().contains('médecin') ||
  //         staff.grade.toLowerCase().contains('rhumatologue')) {
  //       groupeAffichage = 'Personnel Médical';
  //     } else if (staff.groupe == '08H-12H' ||
  //         staff.grade.toLowerCase().contains('hygiène')) {
  //       groupeAffichage =
  //           'Agents d\'hygiène (08h-12h)'; // 🔥 AVANT le else if 08H-16H
  //     } else if (staff.groupe == '08H-16H') {
  //       groupeAffichage = 'Personnel Administratif (08h-16h)';
  //     } else if (staff.groupe == '08H-08H' || staff.groupe == 'Garde 12H') {
  //       groupeAffichage = 'Personnel Paramédical (08h-08h)';
  //     } else {
  //       groupeAffichage = 'Personnel Administratif (08h-16h)';
  //     }
  //
  //     // Déterminer l'équipe
  //     String equipe = staff.equipe ?? '-';
  //
  //     groupedStaffs[groupeAffichage]!.add({
  //       'staff': staff,
  //       'numero': numeroGlobal++,
  //       'equipe': equipe,
  //     });
  //   }
  //
  //   // ✅ NOUVEAU : Trier chaque groupe par équipe (A, B, C, D d'abord, puis les autres)
  //   for (var groupe in groupedStaffs.keys) {
  //     groupedStaffs[groupe]!.sort((a, b) {
  //       String equipeA = a['equipe'] as String;
  //       String equipeB = b['equipe'] as String;
  //
  //       // Définir l'ordre de priorité : A=1, B=2, C=3, D=4, autres=5
  //       int getPriority(String equipe) {
  //         switch (equipe.toUpperCase()) {
  //           case 'A':
  //             return 1;
  //           case 'B':
  //             return 2;
  //           case 'C':
  //             return 3;
  //           case 'D':
  //             return 4;
  //           default:
  //             return 5;
  //         }
  //       }
  //
  //       int priorityA = getPriority(equipeA);
  //       int priorityB = getPriority(equipeB);
  //
  //       // Si même priorité, trier par nom
  //       if (priorityA == priorityB) {
  //         Staff staffA = a['staff'] as Staff;
  //         Staff staffB = b['staff'] as Staff;
  //         return staffA.nom.compareTo(staffB.nom);
  //       }
  //
  //       return priorityA.compareTo(priorityB);
  //     });
  //   }
  //
  //   // Supprimer les groupes vides
  //   groupedStaffs.removeWhere((key, value) => value.isEmpty);
  //
  //   return groupedStaffs;
  // }
  // Quelque part dans votre code où vous avez accès au provider
  void quickGroupCorrection() async {
    try {
      final provider = Provider.of<StaffProvider>(context, listen: false);
      final results = await provider.correctStaffGroups();

      print('✅ Correction rapide terminée: $results');

      // Afficher un snackbar de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Groupes corrigés: ${results['totalModified']} modifications'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erreur correction rapide: $e');
    }
  }

// 3. Modifiez votre méthode _groupStaffs pour utiliser l'ordre sauvegardé
  Map<String, List<dynamic>> _groupStaffs(List<Staff> staffs) {
    Map<String, List<dynamic>> groupedStaffs = {};

    final ordreGroupes = [
      'Personnel Médical',
      'Personnel Administratif (08h-16h)',
      'Personnel Paramédical (24h)',
      'Agents d\'hygiène (12h)',
    ];

    for (String groupe in ordreGroupes) {
      groupedStaffs[groupe] = [];
    }

    int numeroGlobal = 1;

    for (var staff in staffs) {
      String groupeAffichage;

      if (staff.grade.toLowerCase().contains('médecin') ||
          staff.grade.toLowerCase().contains('rhumatologue')) {
        groupeAffichage = 'Personnel Médical';
      } else if (staff.groupe == '12H' ||
          staff.grade.toLowerCase().contains('hygiène')) {
        groupeAffichage = 'Agents d\'hygiène (12h)';
      } else if (staff.groupe == '08H-16H') {
        groupeAffichage = 'Personnel Administratif (08h-16h)';
      } else if (staff.groupe == '24H' ||
          staff.groupe.toLowerCase() == 'Garde 24H' ||
          staff.groupe.toLowerCase() == 'garde 24h') {
        groupeAffichage = 'Personnel Paramédical (24h)';
      } else {
        groupeAffichage = 'Personnel Administratif (08h-16h)';
      }

      String equipe = staff.equipe ?? '-';

      groupedStaffs[groupeAffichage]!.add({
        'staff': staff,
        'numero': staff.ordre ?? numeroGlobal++,
        'equipe': equipe,
      });
    }

    // ✅ NOUVEAU : Trier par ordre sauvegardé OU par équipe/nom
    for (var groupe in groupedStaffs.keys) {
      groupedStaffs[groupe]!.sort((a, b) {
        Staff staffA = a['staff'] as Staff;
        Staff staffB = b['staff'] as Staff;

        // Si les deux ont un ordre défini, utiliser cet ordre
        if (staffA.ordre != null && staffB.ordre != null) {
          return staffA.ordre!.compareTo(staffB.ordre!);
        }

        // Sinon, trier par équipe puis par nom (comportement par défaut)
        String equipeA = a['equipe'] as String;
        String equipeB = b['equipe'] as String;

        int getPriority(String equipe) {
          switch (equipe.toUpperCase()) {
            case 'A':
              return 1;
            case 'B':
              return 2;
            case 'C':
              return 3;
            case 'D':
              return 4;
            default:
              return 5;
          }
        }

        int priorityA = getPriority(equipeA);
        int priorityB = getPriority(equipeB);

        if (priorityA == priorityB) {
          return staffA.nom.compareTo(staffB.nom);
        }

        return priorityA.compareTo(priorityB);
      });
    }

    groupedStaffs.removeWhere((key, value) => value.isEmpty);

    return groupedStaffs;
  }

  // 🆕 NOUVELLE MÉTHODE : Charger un mois
// 🆕 NOUVELLE MÉTHODE : Charger un mois
  Future<bool> _loadMonth(int year, int month) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    // Essayer de charger depuis la sauvegarde
    final loaded = await staffProvider.loadMonthActivities(year, month);

    if (!loaded) {
      // Nouveau mois = tableau vide
      print("ℹ️ Nouveau mois détecté : $month/$year - Tableau vide");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.new_releases, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Nouveau mois ${_moisNoms[month - 1]} $year - Tableau vide",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Mois existant chargé
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Mois ${_moisNoms[month - 1]} $year chargé - Vous pouvez modifier",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return loaded; // ✅ Renvoie le booléen
  }

  // 🆕 NOUVELLE MÉTHODE : Sauvegarder avant de changer de mois
  Future<void> _saveCurrentMonth() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    await staffProvider.saveMonthActivities(_selectedYear, _selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context, listen: true);

    return Scaffold(
      key: ValueKey(
          'staff_table_${staffProvider.lastUpdateTimestamp}_${staffProvider.staffs.length}'),
      appBar: AppBar(
        title: Tooltip(
            message: 'Hospital Planning (Decentralized Storage Database)',
            child: Text('Hospital Planning (Decentralized Storage Database)')),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Force Refresh (${staffProvider.remoteChangesReceived})',
            onPressed: () async {
              print('[UI] 🔄 Force refresh manuel...');
              await staffProvider.forceRefresh();
              setState(() {}); // Force rebuild local aussi
            },
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: 'Vérifier classification',
            onPressed: () {
              final staffProvider =
                  Provider.of<StaffProvider>(context, listen: false);
              final grouped = _groupStaffs(staffProvider.staffs);

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Classification des staffs'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: grouped.entries.map((e) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key} (${e.value.length})',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...e.value.map((s) {
                              final staff = s['staff'] as Staff;
                              return Text(
                                  '  • ${staff.id} ${staff.ordre} ${staff.nom} - ${staff.groupe}');
                            }),
                            Divider(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          CorrectionGroupsButton(),
          // IconButton(
          //   icon: Icon(Icons.message),
          //   color: Colors.white,
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             HomeScreenEnhanced(), // HomeScreenWithMessaging(),
          //       ),
          //     );
          //   },
          // ),
          // Dans un widget sous MultiProvider
          Consumer3<MessagingManager, P2PManager, ConnectionManager>(
            builder: (context, messagingManager, p2p, conn, _) {
              final isReady = p2p.nodeId.isNotEmpty;
              final isConnected = conn.isRunning && conn.neighbors.isNotEmpty;
              if (!isReady || !isConnected) return SizedBox.shrink();
              return BadgeIcon(
                icon: FontAwesomeIcons.message,
                count: messagingManager.totalUnreadCount,
                badgeColor: Colors.red,
                tooltip:
                    'Messages (${messagingManager.totalUnreadCount} non lus)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectNodePage(),
                    ),
                  );
                },
              );
            },
          ),

          // MessengerIconWithBadge(
          //   onPressed: () {
          //     showModalBottomSheet(
          //       context: context,
          //       isScrollControlled: true,
          //       builder: (_) => const ConversationsBottomSheet(),
          //     );
          //   },
          // ),
          // ✅ Indicateur P2P compact
          // Consumer<P2PManager>(
          //   builder: (context, p2p, _) {
          //     return IconButton(
          //       icon: Icon(
          //         p2p.nodeId.isNotEmpty ? Icons.cloud_done : Icons.cloud_off,
          //         color: p2p.nodeId.isNotEmpty ? Colors.green : Colors.grey,
          //       ),
          //       onPressed: () => Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => P2PDiagnosticPage(),
          //         ),
          //       ),
          //     );
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.account_balance),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutAppPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.verified_user),
            color: Colors.yellowAccent,
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => LicenseInfoPage()));
            },
          ),
          _buildSavePdfButton(context),
          _buildSavePdfButtonWithOption(context),
          staffProvider.staffs.isEmpty
              ? SizedBox.shrink()
              : IconButton(
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlanningHebdoWidget(),
                        ),
                      ),
                  icon: Icon(Icons.calendar_month)),
          staffProvider.staffs.isEmpty
              ? IconButton(
                  onPressed: () => _insertActivitiesWithConfirmation(context),
                  icon: Icon(Icons.add_road_outlined))
              : _buildMobileActions(context),

          SizedBox(
            width: 20,
          ),
          //  _buildDesktopActions(context),
        ],
      ),
      body: Consumer2<StaffProvider, BranchProvider>(
        key: ValueKey('consumer_${staffProvider.lastUpdateTimestamp}'),
        // ✅ Force rebuild

        builder: (context, provider, branchProvider, child) {
          final staffs = provider.staffs;

          if (staffs.isEmpty) {
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.people_outline,
                    //     size: 80, color: Colors.blue.shade300),
                    const SizedBox(height: 24),
                    Text(
                      'Blockchain-Powered Decentralized Storage Database',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    // ✅ Banner de statut en haut
                    P2PStatusBanner(),
                    // Banner de statut P2P

                    Text(
                      'Aucun personnel trouvé',
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Appuyez sur "Ajouter Le Staff Au Dessous" pour commencer',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 500,
                      height: 500,
                      child: CardBtn(
                          title: 'Ajouter Le Staff',
                          onPressed: () =>
                              _insertActivitiesWithConfirmation(context),
                          imageUrl: 'assets/photos/hopital/w (3).jpg',
                          overlayColors: [Colors.transparent, Colors.black12],
                          buttonLabel: 'Add'),
                    )
                  ],
                ),
              ),
            );
          }

          final groupedStaffs = _groupStaffs(staffs);
          Map<String, String> groupNameToImage = {
            "Personnel Médical": "assets/photos/hopital/d (1).jpg",
            "Personnel Paramédical (24h)": "assets/photos/hopital/d (8).jpg",
            "Agents d'hygiène (12h)": "assets/photos/hopital/q (1).jpg",
            "Personnel Administratif (08h-16h)":
                "assets/photos/hopital/s2 (10).jpg",
          };
          Map<String, List<Color>> groupNameToGradient = {
            "Personnel Médical": [Color(0x6636E3FF), Color(0x6613D6B4)],
            "Personnel Paramédical (24h)": [
              Color(0x66FF9A9E),
              Color(0x66FAD0C4)
            ],
            "Agents d'hygiène (12h)": [Color(0x66A8E6CF), Color(0x66FFD3A5)],
            "Personnel Administratif (08h-16h)": [
              Color(0x66FFB75E),
              Color(0x66ED8F03)
            ],
          };
          Map<String, VoidCallback> groupNameToOnPressed = {
            "Personnel Médical": () async {
              await runPlanificationAutomatique(context);
            },
            "Personnel Paramédical (24h)": () =>
                _showSimplePlanificationDialog(),
            "Agents d'hygiène (12h)": () async {
              await _showPlanificationAgentsHygieneDialog();
            },
            "Personnel Administratif (08h-16h)": () async {
              await runPlanificationAutomatique(context);
            },
          };

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  //  if (kDebugMode) P2PSyncDebugWidget(),
                  // ✅ Widget de debug
                  const SizedBox(height: 24),
                  // const SizedBox(height: 24),
                  // ElevatedButton(
                  //     onPressed: () => Navigator.of(context).push(
                  //         MaterialPageRoute(builder: (c) => SimpleP2PTest())),
                  //     child: Text('Observ Sync')),
                  // const SizedBox(height: 24),
                  // ✅ Banner de statut en haut
                  P2PStatusBanner(),
                  // const SizedBox(height: 24),
                  // ElevatedButton(
                  //     onPressed: () => Navigator.of(context).push(
                  //         MaterialPageRoute(
                  //             builder: (c) => SyncObserverMonitoringPage())),
                  //     child: Text('Observ Sync')),
                  const SizedBox(height: 8),
                  const Text(
                    '@Blockchain-Powered Decentralized Storage & Messaging',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                  // Dans votre HomeScreen ou page de test
                  // Column(
                  //   children: [
                  //     P2PConnectionTestWidget(), // Widget précédent
                  //     MessageDebugWidget(), // ✅ NOUVEAU
                  //   ],
                  // ),
                  // En-tête général
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          // 'République Algérienne Démocratique Et Populaire\n'
                          // 'Ministère De La Sante De Population Et De Réforme Hospitalier\n'
                          'Etablissement Hospitalier D’Aîn El Türck Dr Medjber Tami',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
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
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              '${staffs.length} Personnes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.lightBlueAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        // const SizedBox(height: 8),
                        // Text(
                        //   'Service : ${(staffs.first.branch.target?.branchNom ?? 'non identifié').toUpperCase()}',
                        //   style: TextStyle(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.blue.shade800,
                        //   ),
                        //   textAlign: TextAlign.center,
                        // ),
                        StaffBranchText(
                          staff: staffs.first,
                          provider: branchProvider, // 👈 on le passe ici
                        ),
                        // const SizedBox(height: 8),
                        Text(
                          'Mois ${monthPrefix}${_selectedMonthName.capitalize} $_selectedYear',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildAppBarTitle(),

                      // Légende des statuts
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Wrap(
                              runSpacing: 8,
                              children: [
                                const Text(
                                  'Légende des statuts:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
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
                                          size: 14,
                                          color: Colors.blue.shade700),
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
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // IconButton.filledTonal(
                                //     onPressed: () => Navigator.of(context)
                                //         .push(MaterialPageRoute(
                                //             builder: (ctx) => CardsPage())),
                                //     icon: Icon(Icons.dangerous_rounded)),
                                _buildLegendItem(
                                    'G', _getStatusColor('G'), 'Garde 24h'),
                                _buildLegendItem('RÉ', _getStatusColor('RE'),
                                    'Récupération'),
                                _buildLegendItem(
                                    'C', _getStatusColor('C'), 'Congé'),
                                _buildLegendItem('CM', _getStatusColor('CM'),
                                    'Congé Maladie'),
                                _buildLegendItem(
                                    'N', _getStatusColor('N'), 'Normal'),
                                _buildLegendItem(
                                    '-', _getStatusColor('-'), 'Aucun'),
                                // ElevatedButton.icon(
                                //   icon: const Icon(Icons.auto_awesome, size: 16),
                                //   label: const Text("Planification automatique"),
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.purple,
                                //     foregroundColor: Colors.white,
                                //   ),
                                //   onPressed: () =>
                                //       runPlanificationAutomatique(context),
                                //   // onPressed: () async {
                                //   //   // Demander confirmation
                                //   //   final confirm = await showDialog<bool>(
                                //   //     context: context,
                                //   //     builder: (BuildContext context) {
                                //   //       return AlertDialog(
                                //   //         title: const Text("Confirmation"),
                                //   //         content: Text(
                                //   //           "Cette action va :\n"
                                //   //           "PHASE 1 - Attribution initiale :\n"
                                //   //           "• Marquer 'RE' les weekends (vendredi/samedi) pour TOUS\n"
                                //   //           "• Marquer '-' les jours normaux pour les équipes A,B,C,D\n"
                                //   //           "• Marquer 'N' les jours normaux pour les autres staff\n"
                                //   //           "\nPHASE 2 - Application des congés :\n"
                                //   //           "• Les congés existants vont ÉCRASER les planifications\n"
                                //   //           "• Aucun congé ne sera perdu\n"
                                //   //           "\nMois: $_selectedMonthName $_selectedYear\n"
                                //   //           "Continuer ?",
                                //   //         ),
                                //   //         actions: [
                                //   //           TextButton(
                                //   //             onPressed: () =>
                                //   //                 Navigator.of(context)
                                //   //                     .pop(false),
                                //   //             child: const Text("Annuler"),
                                //   //           ),
                                //   //           ElevatedButton(
                                //   //             style: ElevatedButton.styleFrom(
                                //   //               backgroundColor:
                                //   //                   Colors.purple,
                                //   //               foregroundColor: Colors.white,
                                //   //             ),
                                //   //             onPressed: () =>
                                //   //                 Navigator.of(context)
                                //   //                     .pop(true),
                                //   //             child: const Text("Confirmer"),
                                //   //           ),
                                //   //         ],
                                //   //       );
                                //   //     },
                                //   //   );
                                //   //
                                //   //   if (confirm != true) return;
                                //   //
                                //   //   try {
                                //   //     final staffProvider =
                                //   //         Provider.of<StaffProvider>(context,
                                //   //             listen: false);
                                //   //     final activiteProvider =
                                //   //         ActiviteProvider();
                                //   //     final objectBox = ObjectBox();
                                //   //
                                //   //     final daysInMonth =
                                //   //         _daysInSelectedMonth;
                                //   //     int weekendDaysCount = 0;
                                //   //     int normalDaysCount = 0;
                                //   //     int totalModifications = 0;
                                //   //     int staffEquipeABCD = 0;
                                //   //     int staffAutres = 0;
                                //   //     int congesAppliques = 0;
                                //   //     int gardesEcrasees = 0;
                                //   //
                                //   //     print(
                                //   //         "🔄 PHASE 1: Attribution automatique (ignorant les congés)");
                                //   //
                                //   //     // PHASE 1: ATTRIBUTION AUTOMATIQUE (ignorer les congés temporairement)
                                //   //     for (final staff
                                //   //         in staffProvider.staffs) {
                                //   //       // Ignorer certains groupes
                                //   //       if (staff.groupe == "Garde 12H") {
                                //   //         print(
                                //   //             "⏩ ${staff.nom} ignoré car groupe = Garde 12H");
                                //   //         continue;
                                //   //       }
                                //   //       if (staff.grade ==
                                //   //           "Agent d'hygiène") {
                                //   //         print(
                                //   //             "⏩ ${staff.nom} ignoré car Grade = Agent d'hygiène");
                                //   //         continue;
                                //   //       }
                                //   //
                                //   //       final equipe =
                                //   //           staff.equipe?.toUpperCase();
                                //   //       final isEquipeABCD = equipe != null &&
                                //   //           ['A', 'B', 'C', 'D']
                                //   //               .contains(equipe);
                                //   //
                                //   //       if (isEquipeABCD) {
                                //   //         staffEquipeABCD++;
                                //   //       } else {
                                //   //         staffAutres++;
                                //   //       }
                                //   //
                                //   //       for (int day = 1;
                                //   //           day <= daysInMonth;
                                //   //           day++) {
                                //   //         final date = DateTime(_selectedYear,
                                //   //             _selectedMonth, day);
                                //   //
                                //   //         String statutAAffecter;
                                //   //         if (date.weekday ==
                                //   //                 DateTime.friday ||
                                //   //             date.weekday ==
                                //   //                 DateTime.saturday) {
                                //   //           // Week-end : marquer 'RE' pour TOUS
                                //   //           statutAAffecter = "RE";
                                //   //           if (staff ==
                                //   //               staffProvider.staffs.first) {
                                //   //             weekendDaysCount++;
                                //   //           }
                                //   //         } else {
                                //   //           // Jours normaux
                                //   //           if (isEquipeABCD) {
                                //   //             statutAAffecter = "-";
                                //   //           } else {
                                //   //             statutAAffecter = "N";
                                //   //           }
                                //   //           if (staff ==
                                //   //               staffProvider.staffs.first) {
                                //   //             normalDaysCount++;
                                //   //           }
                                //   //         }
                                //   //
                                //   //         // UTILISER forceUpdateActiviteIgnoringLeave pour ignorer les congés
                                //   //         await activiteProvider
                                //   //             .forceUpdateActiviteIgnoringLeave(
                                //   //           staff.id,
                                //   //           day,
                                //   //           statutAAffecter,
                                //   //           year: _selectedYear,
                                //   //           month: _selectedMonth,
                                //   //         );
                                //   //         totalModifications++;
                                //   //       }
                                //   //     }
                                //   //
                                //   //     print(
                                //   //         "🔄 PHASE 2: Application des congés (écrasement)");
                                //   //
                                //   //     // PHASE 2: APPLIQUER LES CONGÉS PAR-DESSUS (écraser les planifications)
                                //   //     for (final staff
                                //   //         in staffProvider.staffs) {
                                //   //       // Ignorer les mêmes groupes que dans la Phase 1
                                //   //       if (staff.groupe == "Garde 12H"
                                //   //           // ||
                                //   //           // staff.grade ==
                                //   //           //     "Agent d'hygiène"
                                //   //           ) {
                                //   //         continue;
                                //   //       }
                                //   //
                                //   //       print(
                                //   //           "  Traitement congés pour ${staff.nom}...");
                                //   //
                                //   //       // Récupérer TimeOff via requête directe
                                //   //       final timeOffQuery = objectBox
                                //   //           .timeOffBox
                                //   //           .query(TimeOff_.staff
                                //   //               .equals(staff.id))
                                //   //           .build();
                                //   //       final timeOffs = timeOffQuery.find();
                                //   //       timeOffQuery.close();
                                //   //
                                //   //       if (timeOffs.isNotEmpty) {
                                //   //         print(
                                //   //             "    ${timeOffs.length} TimeOff(s) trouvé(s)");
                                //   //
                                //   //         for (var timeOff in timeOffs) {
                                //   //           DateTime currentDate =
                                //   //               timeOff.debut;
                                //   //           while (currentDate.isBefore(
                                //   //               timeOff.fin.add(
                                //   //                   Duration(days: 1)))) {
                                //   //             if (currentDate.year ==
                                //   //                     _selectedYear &&
                                //   //                 currentDate.month ==
                                //   //                     _selectedMonth) {
                                //   //               int jour = currentDate.day;
                                //   //
                                //   //               // Vérifier si c'était une planification qui va être écrasée
                                //   //               final activiteQuery =
                                //   //                   objectBox.activiteBox
                                //   //                       .query(ActiviteJour_
                                //   //                               .staff
                                //   //                               .equals(staff
                                //   //                                   .id) &
                                //   //                           ActiviteJour_.jour
                                //   //                               .equals(jour))
                                //   //                       .build();
                                //   //               final activites =
                                //   //                   activiteQuery.find();
                                //   //               activiteQuery.close();
                                //   //
                                //   //               if (activites.isNotEmpty) {
                                //   //                 String ancienStatut =
                                //   //                     activites.first.statut;
                                //   //                 if (ancienStatut != 'C' &&
                                //   //                     ancienStatut != 'CM') {
                                //   //                   gardesEcrasees++;
                                //   //                   print(
                                //   //                       "      Jour $jour: $ancienStatut → C (TimeOff)");
                                //   //                 }
                                //   //               }
                                //   //
                                //   //               // Déterminer le statut de congé
                                //   //               String statutConge =
                                //   //                   _getStatutCongeFromTimeOff(
                                //   //                       timeOff);
                                //   //
                                //   //               // Écraser avec le congé
                                //   //               await activiteProvider
                                //   //                   .forceUpdateActiviteIgnoringLeave(
                                //   //                 staff.id,
                                //   //                 jour,
                                //   //                 statutConge,
                                //   //                 year: _selectedYear,
                                //   //                 month: _selectedMonth,
                                //   //               );
                                //   //               congesAppliques++;
                                //   //             }
                                //   //             currentDate = currentDate
                                //   //                 .add(Duration(days: 1));
                                //   //           }
                                //   //         }
                                //   //       }
                                //   //
                                //   //       // Récupérer et réappliquer les activités de congé existantes
                                //   //       final activiteQuery = objectBox
                                //   //           .activiteBox
                                //   //           .query(ActiviteJour_.staff
                                //   //               .equals(staff.id))
                                //   //           .build();
                                //   //       final activites =
                                //   //           activiteQuery.find();
                                //   //       activiteQuery.close();
                                //   //
                                //   //       List<ActiviteJour> congesActivites =
                                //   //           activites
                                //   //               .where((activite) =>
                                //   //                   (activite.statut == 'C' ||
                                //   //                       activite.statut ==
                                //   //                           'CM') &&
                                //   //                   activite.jour >= 1 &&
                                //   //                   activite.jour <=
                                //   //                       daysInMonth)
                                //   //               .toList();
                                //   //
                                //   //       for (var activite
                                //   //           in congesActivites) {
                                //   //         await activiteProvider
                                //   //             .forceUpdateActiviteIgnoringLeave(
                                //   //           staff.id,
                                //   //           activite.jour,
                                //   //           activite.statut,
                                //   //           year: _selectedYear,
                                //   //           month: _selectedMonth,
                                //   //         );
                                //   //         congesAppliques++;
                                //   //         print(
                                //   //             "      Congé activité réappliqué: J${activite.jour}=${activite.statut}");
                                //   //       }
                                //   //     }
                                //   //
                                //   //     // Rafraîchir les données
                                //   //     await staffProvider.fetchStaffs();
                                //   //
                                //   //     ScaffoldMessenger.of(context)
                                //   //         .showSnackBar(
                                //   //       SnackBar(
                                //   //         backgroundColor: Colors.green,
                                //   //         duration:
                                //   //             const Duration(seconds: 8),
                                //   //         content: SingleChildScrollView(
                                //   //           child: Column(
                                //   //             crossAxisAlignment:
                                //   //                 CrossAxisAlignment.start,
                                //   //             children: [
                                //   //               Row(
                                //   //                 children: [
                                //   //                   Icon(Icons.check_circle,
                                //   //                       color: Colors.white,
                                //   //                       size: 20),
                                //   //                   SizedBox(width: 8),
                                //   //                   Text(
                                //   //                     "Planification automatique terminée !",
                                //   //                     style: TextStyle(
                                //   //                       fontWeight:
                                //   //                           FontWeight.bold,
                                //   //                       fontSize: 16,
                                //   //                       color: Colors.white,
                                //   //                     ),
                                //   //                   ),
                                //   //                 ],
                                //   //               ),
                                //   //               SizedBox(height: 8),
                                //   //               Text(
                                //   //                 "Phase 1 - Attribution initiale :",
                                //   //                 style: TextStyle(
                                //   //                     color: Colors.white,
                                //   //                     fontWeight:
                                //   //                         FontWeight.w600),
                                //   //               ),
                                //   //               Text(
                                //   //                   "• $weekendDaysCount jours de weekend marqués 'RE'",
                                //   //                   style: TextStyle(
                                //   //                       color: Colors.white,
                                //   //                       fontSize: 12)),
                                //   //               Text(
                                //   //                   "• $normalDaysCount jours normaux traités",
                                //   //                   style: TextStyle(
                                //   //                       color: Colors.white,
                                //   //                       fontSize: 12)),
                                //   //               Text(
                                //   //                   "• $staffEquipeABCD staff équipes A,B,C,D → '-' jours normaux",
                                //   //                   style: TextStyle(
                                //   //                       color: Colors.white,
                                //   //                       fontSize: 12)),
                                //   //               Text(
                                //   //                   "• $staffAutres autres staff → 'N' jours normaux",
                                //   //                   style: TextStyle(
                                //   //                       color: Colors.white,
                                //   //                       fontSize: 12)),
                                //   //               SizedBox(height: 4),
                                //   //               Text(
                                //   //                 "Phase 2 - Congés appliqués :",
                                //   //                 style: TextStyle(
                                //   //                     color: Colors.white,
                                //   //                     fontWeight:
                                //   //                         FontWeight.w600),
                                //   //               ),
                                //   //               if (gardesEcrasees > 0)
                                //   //                 Text(
                                //   //                     "• $gardesEcrasees planifications écrasées par des congés",
                                //   //                     style: TextStyle(
                                //   //                         color: Colors.yellow
                                //   //                             .shade200,
                                //   //                         fontSize: 12)),
                                //   //               Text(
                                //   //                   "• $congesAppliques jours de congé appliqués",
                                //   //                   style: TextStyle(
                                //   //                       color: Colors.white,
                                //   //                       fontSize: 12)),
                                //   //               SizedBox(height: 4),
                                //   //               Text(
                                //   //                   "✅ Total: $totalModifications modifications",
                                //   //                   style: TextStyle(
                                //   //                       color: Colors.white)),
                                //   //             ],
                                //   //           ),
                                //   //         ),
                                //   //         action: SnackBarAction(
                                //   //           label: "OK",
                                //   //           textColor: Colors.white,
                                //   //           onPressed: () =>
                                //   //               ScaffoldMessenger.of(context)
                                //   //                   .hideCurrentSnackBar(),
                                //   //         ),
                                //   //       ),
                                //   //     );
                                //   //   } catch (e) {
                                //   //     ScaffoldMessenger.of(context)
                                //   //         .showSnackBar(
                                //   //       SnackBar(
                                //   //         content: Text(
                                //   //             "❌ Erreur lors de la planification: $e"),
                                //   //         backgroundColor: Colors.red,
                                //   //         duration: Duration(seconds: 3),
                                //   //       ),
                                //   //     );
                                //   //   }
                                //   // },
                                // ),
                                // ElevatedButton.icon(
                                //   icon:
                                //       const Icon(Icons.medical_services, size: 16),
                                //   label: const Text("Planifier gardes médical"),
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.teal,
                                //     foregroundColor: Colors.white,
                                //   ),
                                //   onPressed: () async {
                                //     await _showSimplePlanificationDialog();
                                //   },
                                // ),
                                // // ElevatedButton.icon(
                                // //   icon: Icon(Icons.edit, color: Colors.white),
                                // //   label: Text("Éditer planification"),
                                // //   style: ElevatedButton.styleFrom(
                                // //       backgroundColor: Colors.blue),
                                // //   onPressed: () async {
                                // //     await _showEditPlanificationDialog(
                                // //         context,
                                // //         _selectedMonth,
                                // //         _selectedYear);
                                // //   },
                                // // ),
                                // ElevatedButton.icon(
                                //   icon:
                                //       const Icon(Icons.cleaning_services, size: 16),
                                //   label: const Text("Planifier agents d'hygiène"),
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Colors.brown,
                                //     foregroundColor: Colors.white,
                                //   ),
                                //   onPressed: () async {
                                //     await _showPlanificationAgentsHygieneDialog();
                                //   },
                                // ),
                                // FilledButton.tonalIcon(
                                //     onPressed: () => _listStaffWithTimeOff(),
                                //     label: Text('List Congé debug')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isMobile = constraints.maxWidth < 600;
                      final double cardHeight = isMobile
                          ? 300
                          : 400; // 🔹 moitié moins haut sur mobile
                      final double cardWidth =
                          isMobile ? constraints.maxWidth / 1.1 : 320;
                      return SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: groupedStaffs.entries.map((entry) {
                              String groupeName = entry.key;
                              String imageUrl = groupNameToImage[groupeName] ??
                                  "assets/photos/hopital/q (2).jpg";
                              List<Color> overlayColors =
                                  groupNameToGradient[groupeName] ??
                                      [Color(0x6636E3FF), Colors.black87];
                              // Récupère la méthode onPressed
                              VoidCallback? onPressed =
                                  groupNameToOnPressed[groupeName] ??
                                      () {
                                        print(
                                            "Aucune action définie pour $groupeName");
                                      };

                              return SizedBox(
                                width: cardWidth,
                                height: cardHeight,
                                child: CardBtn(
                                  title: groupeName,
                                  nombrePersonne: entry.value.length,
                                  imageUrl: imageUrl,
                                  overlayColors: overlayColors,
                                  buttonLabel: 'Planifier',
                                  imageAlignment: Alignment.centerLeft,
                                  onPressed: onPressed,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tableaux pour chaque groupe
                  ...groupedStaffs.entries.map((entry) {
                    String groupeName = entry.key;
                    List<dynamic> groupStaffs = entry.value;
                    groupStaffs.sort((a, b) {
                      final numeroA = a['numero'] as int;
                      final numeroB = b['numero'] as int;
                      return numeroA.compareTo(numeroB);
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header du groupe

                        // Container(
                        //   width: double.infinity,
                        //   padding: const EdgeInsets.symmetric(
                        //       vertical: 12, horizontal: 16),
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       colors: [
                        //         Colors.blue.shade600,
                        //         Colors.blue.shade400
                        //       ],
                        //     ),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: Text(
                        //     '$groupeName (${groupStaffs.length} personnes)',
                        //     style: const TextStyle(
                        //       fontSize: 18,
                        //       fontWeight: FontWeight.bold,
                        //       color: Colors.white,
                        //     ),
                        //   ),
                        // ),

                        // NOUVEAU CODE AVEC BOUTON :
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                ),
                                tooltip: 'Ajouter un nouveau staff',
                                onPressed: () => _showAddStaffDialog(),
                              ),
                              Expanded(
                                child: Text(
                                  '$groupeName (${groupStaffs.length} personnes)',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // ⭐ NOUVEAU BOUTON
                              IconButton(
                                icon: Icon(Icons.reorder,
                                    color: Colors.white, size: 22),
                                tooltip: 'Réorganiser l\'ordre d\'affichage',
                                onPressed: () => _showReorderStaffDialog(
                                  context,
                                  groupeName,
                                  groupStaffs,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGroupTable(groupeName, groupStaffs),
                        // Tableau pour ce groupe
                        // Center(
                        //   child: DragScrollWrapper(
                        //     scrollDirection: Axis.horizontal,
                        //     child: Container(
                        //       decoration: BoxDecoration(
                        //         border: Border.all(color: Colors.grey.shade300),
                        //         borderRadius: BorderRadius.circular(8),
                        //       ),
                        //       child: DataTable(
                        //         columnSpacing: 5,
                        //         headingRowHeight: 40,
                        //         dataRowHeight: 40,
                        //         headingRowColor: WidgetStateProperty.all(
                        //             Colors.grey.shade300),
                        //         border: TableBorder.all(
                        //             color: Colors.grey.shade300, width: 0.5),
                        //         columns: [
                        //           const DataColumn(
                        //             label: Center(
                        //               child: Text('N°',
                        //                   style: TextStyle(
                        //                       fontWeight: FontWeight.bold,
                        //                       fontSize: 14)),
                        //             ),
                        //           ),
                        //           const DataColumn(
                        //             label: Text('Nom et Prénom',
                        //                 style: TextStyle(
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 14)),
                        //           ),
                        //           const DataColumn(
                        //             label: Text('Grade/Fonction',
                        //                 style: TextStyle(
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 14)),
                        //           ),
                        //           const DataColumn(
                        //             label: Text('Équipe',
                        //                 style: TextStyle(
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 14)),
                        //           ),
                        //           const DataColumn(
                        //             label: Text('OBS',
                        //                 style: TextStyle(
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 14)),
                        //           ),
                        //           // NOUVELLE COLONNE : Congés
                        //           const DataColumn(
                        //             label: Row(
                        //               mainAxisSize: MainAxisSize.min,
                        //               children: [
                        //                 Icon(Icons.event_busy,
                        //                     size: 14, color: Colors.orange),
                        //                 SizedBox(width: 4),
                        //                 Text('Congés',
                        //                     style: TextStyle(
                        //                         fontWeight: FontWeight.bold,
                        //                         fontSize: 14)),
                        //               ],
                        //             ),
                        //           ),
                        //           // ⭐ MISE À JOUR : Générer les colonnes selon le mois sélectionné
                        //           ...List.generate(
                        //             _daysInSelectedMonth,
                        //             (i) {
                        //               final jour = i + 1;
                        //               final date = DateTime(
                        //                   _selectedYear, _selectedMonth, jour);
                        //
                        //               Color? bgColor;
                        //               if (date.weekday == DateTime.friday) {
                        //                 bgColor = Colors.blueAccent.shade100;
                        //               } else if (date.weekday ==
                        //                   DateTime.saturday) {
                        //                 bgColor = Colors.blue.shade100;
                        //               }
                        //               String nomDuJour =
                        //                   DateFormat('EEE', 'fr_FR')
                        //                       .format(date);
                        //               return DataColumn(
                        //                 label: Container(
                        //                   width: 28,
                        //                   decoration: BoxDecoration(
                        //                     color: bgColor,
                        //                     borderRadius:
                        //                         BorderRadius.circular(4),
                        //                   ),
                        //                   child: Text(
                        //                     '$jour\n${nomDuJour}',
                        //                     style: const TextStyle(
                        //                       fontWeight: FontWeight.w500,
                        //                       fontSize: 14,
                        //                     ),
                        //                     textAlign: TextAlign.center,
                        //                   ),
                        //                 ),
                        //               );
                        //             },
                        //           ),
                        //         ],
                        //         // Dans la méthode build() qui génère les DataRow
                        //         rows: groupStaffs.map<DataRow>((staffData) {
                        //           final staff = staffData['staff'] as Staff;
                        //           final numero = staffData['numero'] as int;
                        //           final equipe = staffData['equipe'] as String;
                        //           // groupStaffs.sort((a, b) {
                        //           //   final numeroA = a['numero'] as int;
                        //           //   final numeroB = b['numero'] as int;
                        //           //   return numeroA.compareTo(numeroB);
                        //           // });
                        //
                        //           // ⭐ CORRECTION : Charger les activités ET filtrer les TimeOff par mois
                        //           final activites = staff.activites.toList();
                        //           List<String> jours =
                        //               List.filled(_daysInSelectedMonth, '-');
                        //
                        //           // Remplir avec les activités existantes
                        //           for (var activite in activites) {
                        //             if (activite.jour >= 1 &&
                        //                 activite.jour <= _daysInSelectedMonth) {
                        //               jours[activite.jour - 1] =
                        //                   activite.statut;
                        //             }
                        //           }
                        //
                        //           // ⭐ CORRECTION CRITIQUE : Filtrer les congés par le mois sélectionné
                        //           final timeOffs = staff.timeOff.toList();
                        //
                        //           return DataRow(
                        //             color:
                        //                 WidgetStateProperty.resolveWith<Color?>(
                        //               (states) =>
                        //                   states.contains(WidgetState.hovered)
                        //                       ? Colors.blue.shade50
                        //                       : null,
                        //             ),
                        //             cells: [
                        //               DataCell(Text('$numero',
                        //                   style: const TextStyle(
                        //                       fontWeight: FontWeight.bold,
                        //                       color: Colors.blue,
                        //                       fontSize: 14))),
                        //               DataCell(InkWell(
                        //                 onDoubleTap: () async =>
                        //                     await _showCrudDialog(
                        //                         context, staff),
                        //                 onLongPress: () async {
                        //                   final confirm =
                        //                       await showDialog<bool>(
                        //                     context: context,
                        //                     builder: (ctx) => AlertDialog(
                        //                       title: Text(
                        //                           "Confirmer la suppression"),
                        //                       content: Text(
                        //                           "Voulez-vous vraiment supprimer ${staff.nom} ?"),
                        //                       actions: [
                        //                         TextButton(
                        //                           onPressed: () =>
                        //                               Navigator.of(ctx)
                        //                                   .pop(false),
                        //                           child: Text("Annuler"),
                        //                         ),
                        //                         ElevatedButton(
                        //                           style:
                        //                               ElevatedButton.styleFrom(
                        //                                   backgroundColor:
                        //                                       Colors.red,
                        //                                   foregroundColor:
                        //                                       Colors.white),
                        //                           onPressed: () =>
                        //                               Navigator.of(ctx)
                        //                                   .pop(true),
                        //                           child: Text("Supprimer"),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   );
                        //
                        //                   if (confirm == true) {
                        //                     final staffProvider =
                        //                         Provider.of<StaffProvider>(
                        //                             context,
                        //                             listen: false);
                        //                     await staffProvider
                        //                         .deleteStaff(staff);
                        //                     //  Navigator.pop(context);
                        //                   }
                        //                 },
                        //                 child: Text(
                        //                   staff.nom,
                        //                   style: const TextStyle(
                        //                     fontWeight: FontWeight.w400,
                        //                     color: Colors.black87,
                        //                     fontSize: 15,
                        //                   ),
                        //                 ),
                        //               )),
                        //               DataCell(Text(staff.grade,
                        //                   style: const TextStyle(
                        //                     fontSize: 14,
                        //                     fontWeight: FontWeight.w500,
                        //                   ))),
                        //               DataCell(Container(
                        //                 padding: const EdgeInsets.symmetric(
                        //                     horizontal: 8, vertical: 4),
                        //                 decoration: BoxDecoration(
                        //                   color: _getEquipeColor(equipe),
                        //                   borderRadius:
                        //                       BorderRadius.circular(12),
                        //                 ),
                        //                 child: Text(equipe,
                        //                     style: const TextStyle(
                        //                         color: Colors.white,
                        //                         fontWeight: FontWeight.bold,
                        //                         fontSize: 14)),
                        //               )),
                        //               DataCell(
                        //                 GestureDetector(
                        //                   onTap: () async {
                        //                     await _showObservationDialog(
                        //                         context, staff);
                        //                   },
                        //                   child: Container(
                        //                     padding: EdgeInsets.symmetric(
                        //                         horizontal: 6, vertical: 4),
                        //                     decoration: BoxDecoration(
                        //                       color: (staff.obs?.isNotEmpty ??
                        //                               false)
                        //                           ? Colors.blue.shade50
                        //                           : Colors.grey.shade50,
                        //                       borderRadius:
                        //                           BorderRadius.circular(4),
                        //                       border: Border.all(
                        //                         color: (staff.obs?.isNotEmpty ??
                        //                                 false)
                        //                             ? Colors.blue.shade200
                        //                             : Colors.grey.shade300,
                        //                       ),
                        //                     ),
                        //                     child: Row(
                        //                       mainAxisSize: MainAxisSize.min,
                        //                       children: [
                        //                         Icon(
                        //                           Icons.note,
                        //                           size: 12,
                        //                           color: (staff.obs
                        //                                       ?.isNotEmpty ??
                        //                                   false)
                        //                               ? Colors.blue.shade600
                        //                               : Colors.grey.shade400,
                        //                         ),
                        //                         SizedBox(width: 4),
                        //                         Text(
                        //                           (staff.obs?.isNotEmpty ??
                        //                                   false)
                        //                               ? "OBS"
                        //                               : "-",
                        //                           style: TextStyle(
                        //                             fontSize: 12,
                        //                             fontWeight: FontWeight.w500,
                        //                             color: (staff.obs
                        //                                         ?.isNotEmpty ??
                        //                                     false)
                        //                                 ? Colors.blue.shade600
                        //                                 : Colors.grey.shade400,
                        //                           ),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //               DataCell(
                        //                 GestureDetector(
                        //                   onTap: () async {
                        //                     await _showCongesManagementDialog(
                        //                         context, staff,
                        //                         parentContext: context);
                        //                   },
                        //                   child: _buildCongesIndicator(staff),
                        //                 ),
                        //               ),
                        //
                        //               // ⭐ CORRECTION : Générer les cellules avec vérification du mois
                        //               ...List.generate(jours.length, (index) {
                        //                 final jourIndex = index + 1;
                        //                 final statutJour = jours[index];
                        //
                        //                 // ⭐ VÉRIFICATION CORRECTE : Ne vérifier que les congés du mois actuel
                        //                 final dateJour = DateTime(_selectedYear,
                        //                     _selectedMonth, jourIndex);
                        //
                        //                 // Filtrer les TimeOff qui chevauchent ce jour précis
                        //                 final estEnConge =
                        //                     timeOffs.any((timeOff) {
                        //                   // Vérifier si dateJour est entre debut et fin
                        //                   return dateJour.isAfter(timeOff.debut
                        //                           .subtract(
                        //                               Duration(days: 1))) &&
                        //                       dateJour.isBefore(timeOff.fin
                        //                           .add(Duration(days: 1)));
                        //                 });
                        //
                        //                 return DataCell(
                        //                   Container(
                        //                     color: Colors.transparent,
                        //                     child: _buildEditableCell(
                        //                         staff, jourIndex, statutJour),
                        //                   ),
                        //                 );
                        //               }),
                        //             ],
                        //           );
                        //         }).toList(),
                        //       ),
                        //     ),
                        //   ),
                        // ),

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

  Widget _buildGroupTable(String groupeName, List<dynamic> groupStaffs) {
    // ✅ Calculer dynamiquement le nombre de jours
    final int daysInMonth =
        DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

    return Center(
      child: DragScrollWrapper(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 5,
            headingRowHeight: 40,
            dataRowHeight: 40,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade300),
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            columns: [
              const DataColumn(
                label: Center(
                  child: Text('N°',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const DataColumn(
                label: Text('Nom et Prénom',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const DataColumn(
                label: Text('Grade/Fonction',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const DataColumn(
                label: Text('Équipe',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const DataColumn(
                label: Text('OBS',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const DataColumn(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Congés',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              // ✅ CORRECTION : Générer les colonnes selon le mois sélectionné
              ...List.generate(daysInMonth, (i) {
                final jour = i + 1;
                final date = DateTime(_selectedYear, _selectedMonth, jour);

                Color? bgColor;
                if (date.weekday == DateTime.friday) {
                  bgColor = Colors.blueAccent.shade100;
                } else if (date.weekday == DateTime.saturday) {
                  bgColor = Colors.blue.shade100;
                }

                String nomDuJour = DateFormat('EEE', 'fr_FR').format(date);

                return DataColumn(
                  label: Container(
                    width: 28,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$jour\n$nomDuJour',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
            rows: groupStaffs.map<DataRow>((staffData) {
              final staff = staffData['staff'] as Staff;
              final numero = staffData['numero'] as int;
              final equipe = staffData['equipe'] as String;

              // ✅ Charger les activités avec la bonne longueur
              final activites = staff.activites.toList();
              List<String> jours = List.filled(daysInMonth, '-');

              for (var activite in activites) {
                if (activite.jour >= 1 && activite.jour <= daysInMonth) {
                  jours[activite.jour - 1] = activite.statut;
                }
              }

              final timeOffs = staff.timeOff.toList();

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.hovered)
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
                        await _showCrudDialog(context, staff),
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text("Confirmer la suppression"),
                          content: Text(
                              "Voulez-vous vraiment supprimer ${staff.nom} ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text("Annuler"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text("Supprimer"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final staffProvider =
                            Provider.of<StaffProvider>(context, listen: false);
                        await staffProvider.deleteStaff(staff);
                      }
                    },
                    child: Text(
                      staff.nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                          fontSize: 15),
                    ),
                  )),
                  DataCell(Text(staff.grade,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500))),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEquipeColor(equipe),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(equipe,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  )),
                  // 3️⃣ DANS LA DATATABLE : Remplacez la cellule OBS par :
                  DataCell(
                    _buildObservationCell(staff),
                  ),
                  // DataCell(GestureDetector(
                  //   onTap: () async =>
                  //       await _showObservationDialog(context, staff),
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  //     decoration: BoxDecoration(
                  //       color: (staff.obs?.isNotEmpty ?? false)
                  //           ? Colors.blue.shade50
                  //           : Colors.grey.shade50,
                  //       borderRadius: BorderRadius.circular(4),
                  //       border: Border.all(
                  //         color: (staff.obs?.isNotEmpty ?? false)
                  //             ? Colors.blue.shade200
                  //             : Colors.grey.shade300,
                  //       ),
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(Icons.note,
                  //             size: 12,
                  //             color: (staff.obs?.isNotEmpty ?? false)
                  //                 ? Colors.blue.shade600
                  //                 : Colors.grey.shade400),
                  //         SizedBox(width: 4),
                  //         Text(
                  //           (staff.obs?.isNotEmpty ?? false) ? "OBS" : "-",
                  //           style: TextStyle(
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.w500,
                  //             color: (staff.obs?.isNotEmpty ?? false)
                  //                 ? Colors.blue.shade600
                  //                 : Colors.grey.shade400,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // )),
                  DataCell(GestureDetector(
                    onTap: () async => await _showCongesManagementDialog(
                        context, staff,
                        parentContext: context),
                    child: _buildCongesIndicator(staff),
                  )),
                  // ✅ Générer les cellules selon le mois
                  ...List.generate(jours.length, (index) {
                    final jourIndex = index + 1;
                    final statutJour = jours[index];
                    final dateJour =
                        DateTime(_selectedYear, _selectedMonth, jourIndex);

                    final estEnConge = timeOffs.any((timeOff) {
                      return dateJour.isAfter(
                              timeOff.debut.subtract(Duration(days: 1))) &&
                          dateJour.isBefore(timeOff.fin.add(Duration(days: 1)));
                    });

                    return DataCell(
                      Container(
                        color: Colors.transparent,
                        child: _buildEditableCell(staff, jourIndex, statutJour),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Affiche un dialog pour réorganiser manuellement l'ordre des staffs d'un groupe
  Future<void> _showReorderStaffDialog(
    BuildContext context,
    String groupeName,
    List<dynamic> groupStaffs,
  ) async {
    List<dynamic> reorderedStaffs = List.from(groupStaffs);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.reorder, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Réorganiser - $groupeName",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.minPositive,
                height: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instructions
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.blue.shade700),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Glissez pour réorganiser l'ordre d'affichage",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Liste réorganisable
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: reorderedStaffs.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = reorderedStaffs.removeAt(oldIndex);
                            reorderedStaffs.insert(newIndex, item);

                            // Mettre à jour les numéros
                            for (int i = 0; i < reorderedStaffs.length; i++) {
                              reorderedStaffs[i]['numero'] = i + 1;
                            }
                          });
                        },
                        itemBuilder: (context, index) {
                          final staffData = reorderedStaffs[index];
                          final staff = staffData['staff'] as Staff;
                          final numero = staffData['numero'] as int;
                          final equipe = staffData['equipe'] as String;

                          return Container(
                            key: ValueKey('staff_${staff.id}_$index'),
                            margin: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Card(
                              elevation: 1,
                              child: ListTile(
                                // Numéro
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$numero',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),

                                // Nom et grade
                                title: Text(
                                  staff.nom,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff.grade,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    if (equipe != '-')
                                      Text(
                                        'Équipe $equipe',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getEquipeColor(equipe),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),

                                // Icône de drag
                                // trailing: Icon(
                                //   Icons.drag_handle,
                                //   color: Colors.grey.shade400,
                                // ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Annuler"),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.save, size: 16),
                  label: Text("Enregistrer l'ordre"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  // onPressed: () async {
                  //   // Sauvegarder l'ordre dans la base de données
                  //   await _saveStaffOrder(groupeName, reorderedStaffs);
                  //   Navigator.of(context).pop();
                  //
                  //   // Rafraîchir l'affichage
                  //   setState(() {});
                  // },
                  onPressed: () async {
                    // Sauvegarder l'ordre dans la base de données
                    await _saveStaffOrder(groupeName, reorderedStaffs);

                    // ✅ CRITIQUE : Forcer le rechargement depuis ObjectBox
                    final staffProvider =
                        Provider.of<StaffProvider>(context, listen: false);
                    await staffProvider.fetchStaffs();

                    Navigator.of(context).pop();

                    // Rafraîchir l'affichage
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

// 2. Ajoutez cette méthode pour sauvegarder l'ordre
  Future<void> _saveStaffOrder(
    String groupeName,
    List<dynamic> orderedStaffs,
  ) async {
    try {
      final objectBox = ObjectBox();

      // Mettre à jour l'ordre de tri pour chaque staff
      for (int i = 0; i < orderedStaffs.length; i++) {
        final staffData = orderedStaffs[i];
        final staff = staffData['staff'] as Staff;

        // Ajouter/mettre à jour un champ 'ordre' dans votre entité Staff
        staff.ordre = i; // ⚠️ Vous devrez ajouter ce champ à votre entité
        objectBox.staffBox.put(staff);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Ordre sauvegardé pour $groupeName"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Rafraîchir les données
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la sauvegarde: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Construit le titre de l'AppBar avec le sélecteur de mois
  Widget _buildAppBarTitle() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Medical Staff Planning - '),
        _buildMonthSelector(),
        _buildYearSelector(),
        //  Text('$_selectedYear'),
      ],
    );
  }

  /// Construit le sélecteur de mois
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          //  style: const TextStyle(color: Colors.black, fontSize: 16),
          // dropdownColor: Colors.blue.shade700,
          items: _buildMonthDropdownItems(),
          onChanged: _onMonthChanged,
        ),
      ),
    );
  }

  /// Construit le sélecteur d'année
  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - 5 + index);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: Colors.blue.shade700,
          items: years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(
                '$year',
              ),
            );
          }).toList(),
          onChanged: _onYearChanged,
        ),
      ),
    );
  }

  Future<void> _onYearChanged(int? value) async {
    if (value != null && value != _selectedYear) {
      // Sauvegarder l'ancien mois/année
      await _saveCurrentMonth();

      // Changer d'année
      setState(() {
        _selectedYear = value;
        _editingCells.clear();
        _tempValues.clear();
      });

      // Charger le mois avec la nouvelle année
      await _loadMonth(value, _selectedMonth);
    }
  }

  /// Génère les éléments du dropdown de mois
  List<DropdownMenuItem<int>> _buildMonthDropdownItems() {
    return List.generate(12, (index) {
      return DropdownMenuItem<int>(
        value: index + 1,
        child: Text(
          _moisNoms[index],
        ),
      );
    });
  }

  /// Gère le changement de mois
  // Future<void> _onMonthChanged(int? value) async {
  //   if (value != null && value != _selectedMonth) {
  //     // Sauvegarder l'ancien mois
  //     await _saveCurrentMonth();
  //
  //     // Changer de mois
  //     setState(() {
  //       _selectedMonth = value;
  //       _editingCells.clear();
  //       _tempValues.clear();
  //     });
  //
  //     // Charger le nouveau mois
  //     await _loadMonth(_selectedYear, value);
  //     //////////////////////////////////////////////////////////
  //     final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  //     final objectBox = ObjectBox();
  //
  //     // int activitesSupprimes = 0;
  //     // int congesSupprimes = 0;
  //     //
  //     // // 1. Supprimer les activités du mois
  //     // for (final staff in staffProvider.staffs) {
  //     //   final activitesToDelete = staff.activites
  //     //       .where((a) => a.jour >= 1 && a.jour <= _daysInSelectedMonth)
  //     //       .toList();
  //     //
  //     //   for (var activite in activitesToDelete) {
  //     //     objectBox.activiteBox.remove(activite.id);
  //     //     activitesSupprimes++;
  //     //   }
  //     // }
  //     //
  //     // // 2. Supprimer les TimeOff qui chevauchent le mois
  //     // final debutMois = DateTime(_selectedYear, _selectedMonth, 1);
  //     // final finMois = DateTime(_selectedYear, _selectedMonth + 1, 0);
  //     //
  //     // final allTimeOffs = objectBox.timeOffBox.getAll();
  //     // for (var timeOff in allTimeOffs) {
  //     //   // Vérifier si le TimeOff chevauche le mois sélectionné
  //     //   if (timeOff.debut.isBefore(finMois.add(Duration(days: 1))) &&
  //     //       timeOff.fin.isAfter(debutMois.subtract(Duration(days: 1)))) {
  //     //     objectBox.timeOffBox.remove(timeOff.id);
  //     //     congesSupprimes++;
  //     //   }
  //     // }
  //
  //     // 3. Supprimer la planification du mois
  //     final planifQuery = objectBox.planificationBox
  //         .query(Planification_.mois.equals(_selectedMonth) &
  //             Planification_.annee.equals(_selectedYear))
  //         .build();
  //     final existingPlanif = planifQuery.findFirst();
  //     planifQuery.close();
  //
  //     if (existingPlanif != null) {
  //       objectBox.planificationBox.remove(existingPlanif.id);
  //     }
  //
  //     // // 4. Nettoyer les obs des staffs
  //     // for (final staff in staffProvider.staffs) {
  //     //   if (staff.obs != null && staff.obs!.isNotEmpty) {
  //     //     staff.obs = null;
  //     //     objectBox.staffBox.put(staff);
  //     //   }
  //     // }
  //
  //     // 5. Rafraîchir
  //     await staffProvider.fetchStaffs();
  //     ///////////////////////////////////////////////////
  //   }
  // }
  /// ✅ MÉTHODE CORRIGÉE : Changement de mois avec sauvegarde
  // Future<void> _onMonthChanged(int? value) async {
  //   if (value != null && value != _selectedMonth) {
  //     // 1️⃣ Sauvegarder l'ancien mois
  //     await _saveCurrentMonth();
  //
  //     // 2️⃣ Changer de mois
  //     setState(() {
  //       _selectedMonth = value;
  //       _editingCells.clear();
  //       _tempValues.clear();
  //     });
  //
  //     // 3️⃣ Charger le nouveau mois
  //     final loaded = await _loadMonth(_selectedYear, value);
  //
  //     // 4️⃣ Si pas de données, créer un mois vierge AVEC RESPECT DES CONGÉS
  //     if (!loaded) {
  //       await _creerMoisVierge(_selectedYear, value);
  //     }
  //   }
  // }

  /// ✅ NOUVELLE MÉTHODE : Créer un mois vierge avec congés et obs
  Future<void> _creerMoisVierge(int year, int month) async {
    try {
      print('🆕 Création du mois vierge $month/$year...');

      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();
      final objectBox = ObjectBox();

      final daysInMonth = DateUtils.getDaysInMonth(year, month);

      for (final staff in staffProvider.staffs) {
        // Récupérer les congés du staff pour ce mois
        final timeOffs = objectBox.timeOffBox
            .query(TimeOff_.staff.equals(staff.id))
            .build()
            .find();

        for (int day = 1; day <= daysInMonth; day++) {
          final dateJour = DateTime(year, month, day);

          // Vérifier si en congé
          bool enConge = timeOffs.any((timeOff) =>
              dateJour.isAfter(timeOff.debut.subtract(Duration(days: 1))) &&
              dateJour.isBefore(timeOff.fin.add(Duration(days: 1))));

          String statut = enConge ? 'C' : '-';

          // Créer l'activité
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            day,
            statut,
            year: year,
            month: month,
          );
        }
      }

      await staffProvider.fetchStaffs();
      print('✅ Mois vierge créé avec respect des congés');
    } catch (e) {
      print('❌ Erreur création mois vierge: $e');
    }
  }

  /// ✅ MÉTHODE CORRIGÉE : Vider le mois avec préservation des métadonnées
  Future<void> _clearCurrentMonthData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange),
            SizedBox(width: 8),
            Text("Vider ${_moisNoms[_selectedMonth - 1]} $_selectedYear"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cette action va supprimer pour ce mois uniquement :"),
            SizedBox(height: 8),
            Text("• Toutes les activités (G, RE, C, CM, N)"),
            Text("• Tous les congés (TimeOff)"),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "✅ Seront conservés :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("• L'ordre des staffs"),
                  Text("• Les observations"),
                  Text("• L'ordre des équipes"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Vider et recréer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final objectBox = ObjectBox();

      final debutMois = DateTime(_selectedYear, _selectedMonth, 1);
      final finMois = DateTime(_selectedYear, _selectedMonth + 1, 0);
      final daysInMonth = finMois.day;

      // 1️⃣ Supprimer activités du mois
      for (final staff in staffProvider.staffs) {
        final activitesToDelete = staff.activites
            .where((a) => a.jour >= 1 && a.jour <= daysInMonth)
            .toList();

        for (var activite in activitesToDelete) {
          objectBox.activiteBox.remove(activite.id);
        }
      }

      // 2️⃣ Supprimer TimeOff du mois
      final allTimeOffs = objectBox.timeOffBox.getAll();
      for (var timeOff in allTimeOffs) {
        if (timeOff.debut.isBefore(finMois.add(Duration(days: 1))) &&
            timeOff.fin.isAfter(debutMois.subtract(Duration(days: 1)))) {
          objectBox.timeOffBox.remove(timeOff.id);
        }
      }

      // 3️⃣ Recréer le mois vierge avec respect des congés restants
      await _creerMoisVierge(_selectedYear, _selectedMonth);

      // 4️⃣ Rafraîchir
      await staffProvider.fetchStaffs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ Mois vidé et recréé avec respect des congés et observations"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Construit les actions pour Desktop
  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      children: [
        _buildSavePdfButton(context),
        _buildClearMonthButton(context),
        _buildClearAllActivitiesButton(context),
        _buildClearDatabaseButton(context),
        _buildInsertActivitiesButton(context),
        _buildRefreshButton(context),
      ],
    );
  }

  /// Construit les actions pour Mobile (menu dropdown)
  Widget _buildMobileActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) => _handleMobileMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'save_pdf',
          child: Row(
            children: [
              Icon(Icons.save_alt, size: 20),
              SizedBox(width: 8),
              Text("Sauvegarder en PDF"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clear_month',
          child: Row(
            children: [
              Icon(Icons.delete_sweep, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text("Vider le mois actuel"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clear_all',
          child: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text("Vider toutes les activités"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clear_db',
          child: Row(
            children: [
              Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text("Vider DB"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'insert',
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text("Ajouter les activités"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text("Rafraîchir"),
            ],
          ),
        ),
      ],
    );
  }

  /// Gère les actions du menu mobile
  Future<void> _handleMobileMenuAction(
      BuildContext context, String value) async {
    switch (value) {
      case 'save_pdf':
        await _savePlanningToPdf(context);
        break;
      case 'clear_month':
        await _clearCurrentMonthData();
        break;
      case 'clear_all':
        await _clearAllActivitiesWithConfirmation(context);
        break;
      case 'clear_db':
        await _clearDatabaseWithConfirmation(context);
        break;
      case 'insert':
        await _insertActivitiesWithConfirmation(context);
        break;
      case 'refresh':
        await context.read<StaffProvider>().fetchStaffs();
        break;
    }
  }

// ═══════════════════════════════════════════════════════════════
// 🔘 BOUTONS D'ACTION DESKTOP
// ═══════════════════════════════════════════════════════════════

  /// Bouton de sauvegarde PDF
  Widget _buildSavePdfButtonWithOption(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.save_as,
        color: Colors.lightGreenAccent,
      ),
      tooltip: 'Sauvegarder un planning en PDF Spécifique',
      onPressed: () =>
          _showPdfOptionsAndGenerate(context), //_savePlanningToPdf2(context),
    );
  }

  Widget _buildSavePdfButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.save_alt),
      tooltip: 'Sauvegarder le planning en PDF',
      onPressed: () => _savePlanningToPdf2(context),
    );
  }

  Future<void> _savePlanningToPdf2(BuildContext context) async {
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dContext) {
        dialogContext = dContext;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final filePath = await generateAndSaveMonthPlanningPDF(
        context,
        year: _selectedYear,
        month: _selectedMonth,
      );

      final path = await generatePersonnelListsPDF(
        context,
        year: _selectedYear,
        month: _selectedMonth,
      );

      // ✅ Fermer le bon dialogue
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      if (context.mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ PDF sauvegardé avec succès !\n📁 $filePath'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OUVRIR',
                onPressed: () {
                  _openFileLocation(filePath);
                },
              ),
            ),
          );

          _openFileLocation(filePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de la sauvegarde du PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPdfOptionsAndGenerate(BuildContext context) async {
    // ⭐ CORRECTION : Liste de chemins d'assets (String) au lieu de File
    final List<String> availableImagePaths = [
      'assets/photos/hopital/pitol/stamps (1).webp',
      'assets/photos/hopital/pitol/stamps (2).webp',
      'assets/photos/hopital/pitol/stamps (3).webp',
      'assets/photos/hopital/pitol/stamps (4).webp',
      'assets/photos/hopital/pitol/stamps (5).webp',
      'assets/photos/hopital/pitol/stamps (6).webp',
      'assets/photos/hopital/pitol/stamps (7).webp',
      'assets/photos/hopital/pitol/stamps (8).webp',
      'assets/photos/hopital/pitol/stamps (9).webp',
      'assets/photos/hopital/pitol/stamps (10).webp',
      'assets/photos/hopital/pitol/stamps (11).webp',
      'assets/photos/hopital/pitol/stamps (12).webp',
      'assets/photos/hopital/pitol/stamps (13).webp',
      'assets/photos/hopital/pitol/stamps (14).webp',
      'assets/photos/hopital/pitol/stamps (15).webp',
      'assets/photos/hopital/pitol/stamps (16).webp',
      'assets/photos/hopital/pitol/stamps (17).webp',
      'assets/photos/hopital/pitol/stamps (18).webp',
      'assets/photos/hopital/pitol/stamps (19).webp',
      'assets/photos/hopital/pitol/stamps (20).webp',
      'assets/photos/hopital/pitol/stamps (21).webp',
      'assets/photos/hopital/pitol/stamps (22).webp',
    ];

    // Afficher le dialog avec les chemins d'assets
    final selectedOptions = await showPdfOptionsDialog(
      context,
      monthName: _selectedMonthName,
      year: _selectedYear,
      availableImagePaths: availableImagePaths, // ⭐ CORRIGÉ
    );

    if (selectedOptions == null) return;

    // Générer les PDFs selon les options sélectionnées
    await _generatePdfWithOptions(context, selectedOptions);
  }

  Future<void> _generatePdfWithOptions(
    BuildContext context,
    List<PdfPageOption> options,
  ) async {
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dContext) {
        dialogContext = dContext;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      String? filePath;
      String? path;

      // ✅ EXTRACTION du stamp AVANT de générer les PDFs
      String? stampImagePath;
      for (var option in options) {
        if (option.selectedImagePath != null &&
            option.selectedImagePath!.isNotEmpty) {
          stampImagePath = option.selectedImagePath;
          print("🖼️ Stamp sélectionné : $stampImagePath");
          break;
        }
      }

      // Générer le PDF principal (tableaux d'activité) avec les options
      final hasActiviteTableau = options.any(
        (opt) =>
            opt.type == PdfPageType.activiteTableauMedical ||
            opt.type == PdfPageType.activiteTableauAdministratif ||
            opt.type == PdfPageType.activiteTableauParamedical ||
            opt.type == PdfPageType.activiteTableauHygiene,
      );

      if (hasActiviteTableau || options.isEmpty) {
        filePath = await generateAndSaveMonthPlanningPDFWithOptions(
          context,
          year: _selectedYear,
          month: _selectedMonth,
          options: options,
        );
      }

      // Générer les pages personnel (médecins et paramédicaux) avec les options
      final hasPersonnelPages = options.any(
        (opt) =>
            opt.type == PdfPageType.medecinPlanning ||
            opt.type == PdfPageType.medecinListe ||
            opt.type == PdfPageType.paramedicalPlanning,
      );

      if (hasPersonnelPages || options.isEmpty) {
        path = await generatePersonnelListsPDFWithOptions(
          context,
          year: _selectedYear,
          month: _selectedMonth,
          options: options,
        );
      }

      // Fermer le dialog de chargement
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      if (context.mounted) {
        // Déterminer quel fichier afficher
        final mainFilePath = filePath ?? path;

        if (mainFilePath != null) {
          // Compter combien de PDFs ont été générés
          int pdfCount = 0;
          if (filePath != null) pdfCount++;
          if (path != null) pdfCount++;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${pdfCount == 1 ? "PDF sauvegardé" : "$pdfCount PDFs sauvegardés"} avec succès !\n📁 $mainFilePath',
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OUVRIR',
                onPressed: () {
                  _openFileLocation(mainFilePath);
                },
              ),
            ),
          );
          _openFileLocation(mainFilePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de la sauvegarde du PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Bouton de suppression du mois actuel
  Widget _buildClearMonthButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_sweep, color: Colors.orange),
      tooltip: 'Vider les données du mois sélectionné',
      onPressed: () => _clearCurrentMonthData(),
    );
  }

  /// Bouton de suppression de toutes les activités
  Widget _buildClearAllActivitiesButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      tooltip: "Vider toutes les activités",
      onPressed: () => _clearAllActivitiesWithConfirmation(context),
    );
  }

  /// Bouton de suppression de la base de données
  Widget _buildClearDatabaseButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
      tooltip: "Vider DB",
      onPressed: () => _clearDatabaseWithConfirmation(context),
    );
  }

  /// Bouton d'insertion des activités
  Widget _buildInsertActivitiesButton(BuildContext context) {
    return Tooltip(
      message: "Ajouter toutes les activités",
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.blue),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
        ),
        onPressed: () => _insertActivitiesWithConfirmation(context),
      ),
    );
  }

  /// Bouton de rafraîchissement
  Widget _buildRefreshButton(BuildContext context) {
    return Tooltip(
      message: 'Fetch Staff',
      child: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          context.read<StaffProvider>().fetchStaffs();
        },
      ),
    );
  }

// ═══════════════════════════════════════════════════════════════
// ⚙️ ACTIONS MÉTIERS
// ═══════════════════════════════════════════════════════════════

  /// Sauvegarde le planning en PDF
  Future<void> _savePlanningToPdf(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Liste d'options vide = génère tous les PDFs par défaut (sans modifications)
      final List<PdfPageOption> defaultOptions = [];

      // Générer le planning principal (tableaux d'activité) avec options
      final filePath = await generateAndSaveMonthPlanningPDFWithOptions(
        context,
        year: _selectedYear,
        month: _selectedMonth,
        options: defaultOptions,
      );

      // Générer les pages 2 et 3 (personnel médical et paramédical) avec options
      final path = await generatePersonnelListsPDFWithOptions(
        context,
        year: _selectedYear,
        month: _selectedMonth,
        options: defaultOptions,
      );

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        // Déterminer quel fichier afficher
        final mainFilePath = filePath ?? path;

        if (mainFilePath != null) {
          // Compter combien de PDFs ont été générés
          int pdfCount = 0;
          if (filePath != null) pdfCount++;
          if (path != null) pdfCount++;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${pdfCount == 1 ? "PDF sauvegardé" : "$pdfCount PDFs sauvegardés"} avec succès !\n📁 $mainFilePath',
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OUVRIR',
                onPressed: () {
                  _openFileLocation(mainFilePath);
                },
              ),
            ),
          );

          // Ouvrir automatiquement le dossier après la sauvegarde
          _openFileLocation(mainFilePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de la sauvegarde du PDF'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Ouvre l'emplacement du fichier dans l'explorateur de fichiers
  void _openFileLocation(String filePath) async {
    try {
      final file = File(filePath);
      final directory = file.parent;

      if (await directory.exists()) {
        // Utiliser le package url_launcher pour ouvrir le dossier
        final uri = directory.uri.toString();
        if (await canLaunchUrl(Uri.parse(uri))) {
          await launchUrl(Uri.parse(uri));
        } else {
          print('Impossible d\'ouvrir le dossier: $uri');
        }
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du dossier: $e');
    }
  }

  // Feedback visuel pendant l'édition
  Widget _buildEditableCell(Staff staff, int jour, String currentValue) {
    final cellKey = "${staff.id}-$jour";
    final isEditing = _editingCells[cellKey] ?? false;

    // ✅ AJOUT : Clé unique basée sur le timestamp
    final uniqueKey =
        ValueKey('cell_${cellKey}_${DateTime.now().millisecondsSinceEpoch}');

    if (isEditing) {
      return Container(
        key: uniqueKey,
        // ✅ Force le rebuild
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
          // onChanged: (newValue) {
          //   if (newValue != null) {
          //     setState(() {
          //       _tempValues[cellKey] = newValue;
          //     });
          //   }
          // },
          onChanged: (newValue) async {
            if (newValue != null) {
              // ✅ Sauvegarder immédiatement
              await _saveActiviteModification(staff, jour, newValue);

              // // ✅ Nettoyer les états d'édition
              // setState(() {
              //   _editingCells.remove(cellKey);
              //   _tempValues.remove(cellKey);
              // });
            }
          },
          icon: Container(),
          isExpanded: true,
          style: TextStyle(fontSize: 14),
          menuMaxHeight: 200,
        ),
      );
    } else {
      return MouseRegion(
        key: uniqueKey, // ✅ Force le rebuild
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
              color: _getStatusColor(currentValue).withOpacity(0.2),
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
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  // Méthode pour ajouter des boutons de contrôle d'édition
  Widget _buildEditControls2() {
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
          width: 28,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: color),
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
        return Colors.blueAccent.shade700;
      case 'RE':
      case 'RÉ':
        return Colors.black87;
      case 'C':
        return Colors.deepOrange.shade700;
      case 'CM':
        return Colors.purple.shade700;
      case 'N':
        return Colors.green.shade500;
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

    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    // Récupérer l'observation actuelle du mois chargé
    final currentObs = staffProvider.getObservationForStaff(staff.id) ?? "";
    final obsCtrl = TextEditingController(text: currentObs);

    // ⭐ Récupérer les groupes existants
    final Set<String> groupesExistants = staffProvider.staffs
        .where((s) => s.groupe != null && s.groupe!.isNotEmpty)
        .map((s) => s.groupe!)
        .toSet();

    final List<String> groupesDisponibles = groupesExistants.toList()..sort();
    groupesDisponibles.add("➕ Nouveau groupe...");

    String? selectedGroupe = staff.groupe;
    String? selectedEquipe = staff.equipe;
    bool isCreatingNewGroupe = false;
    final newGroupeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            // Déterminer si on affiche l'équipe
            bool showEquipe = false;
            if (!isCreatingNewGroupe && selectedGroupe != null) {
              showEquipe = selectedGroupe!.toUpperCase().contains('08H-08H') ||
                  selectedGroupe!.toUpperCase().contains('GARDE 24H');
            } else if (isCreatingNewGroupe) {
              final newText = newGroupeCtrl.text.toUpperCase();
              showEquipe =
                  newText.contains('08H-08H') || newText.contains('GARDE 24H');
            }

            return AlertDialog(
              title: Text("Modifier ${staff.nom}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    TextField(
                      controller: nomCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nom",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grade
                    TextField(
                      controller: gradeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Grade",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ⭐ GROUPE
                    if (!isCreatingNewGroupe)
                      DropdownButtonFormField<String>(
                        value: selectedGroupe,
                        decoration: const InputDecoration(
                          labelText: "Groupe",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: groupesDisponibles.map((groupe) {
                          return DropdownMenuItem(
                            value: groupe,
                            child: Text(
                              groupe,
                              style: groupe.startsWith("➕")
                                  ? const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)
                                  : null,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            if (value == "➕ Nouveau groupe...") {
                              isCreatingNewGroupe = true;
                              selectedGroupe = null;
                            } else {
                              selectedGroupe = value;
                              if (!value!.toUpperCase().contains('08H-08H') &&
                                  !value.toUpperCase().contains('GARDE 24H')) {
                                selectedEquipe = null;
                              }
                            }
                          });
                        },
                      ),

                    if (isCreatingNewGroupe)
                      TextField(
                        controller: newGroupeCtrl,
                        decoration: InputDecoration(
                          labelText: "Nom du nouveau groupe",
                          hintText: "Ex: 08H-16H, 08H-08H...",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.group_add),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              setStateDialog(() {
                                isCreatingNewGroupe = false;
                                newGroupeCtrl.clear();
                                selectedGroupe = staff.groupe;
                              });
                            },
                          ),
                        ),
                        onChanged: (_) => setStateDialog(() {}),
                      ),

                    const SizedBox(height: 12),

                    // Équipe
                    if (showEquipe && equipesActives)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Équipe :",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ["A", "B", "C", "D"].map((equipe) {
                              return ChoiceChip(
                                label: Text(equipe),
                                selected: selectedEquipe == equipe,
                                selectedColor: _getEquipeColor(equipe),
                                onSelected: (selected) {
                                  setStateDialog(() {
                                    selectedEquipe = selected ? equipe : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    // Observations
                    TextField(
                      controller: obsCtrl,
                      decoration: const InputDecoration(
                        labelText: "Observation",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Mise à jour temporaire en mémoire
                        staffProvider.setTemporaryObservation(
                          staff.id,
                          value.trim().isEmpty ? null : value.trim(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Groupe final
                    String? finalGroupe;
                    if (isCreatingNewGroupe) {
                      if (newGroupeCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Le nom du groupe est obligatoire"),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      finalGroupe = newGroupeCtrl.text.trim();
                    } else {
                      finalGroupe = selectedGroupe;
                    }

                    // Mise à jour du staff
                    staff.nom = nomCtrl.text.trim();
                    staff.grade = gradeCtrl.text.trim();
                    staff.groupe = finalGroupe!;
                    staff.equipe =
                        showEquipe && equipesActives ? selectedEquipe : null;

                    try {
                      await staffProvider.updateStaff(
                          staff); // Met à jour les champs permanents
                      await staffProvider.saveMonthActivities(_selectedYear,
                          _selectedMonth); // Sauvegarde obs + activités

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("✅ ${staff.nom} modifié avec succès"),
                              backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("❌ Erreur: $e"),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
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
    // ✅ Utiliser un callback pour rafraîchir le parent
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _TimeOffDialogContent(
          staff: staff,
          selectedYear: _selectedYear,
          selectedMonth: _selectedMonth,
          onUpdate: () {
            // ✅ Rafraîchir le state parent après chaque opération
            if (mounted) setState(() {});
          },
        );
      },
    );

    // ✅ Rafraîchissement final après fermeture du dialog
    if (mounted) {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs();
      setState(() {});
    }
  }

// Méthode pour éditer un congé existant
  Future<void> _showEditTimeOffDialog(
      BuildContext context, Staff staff, TimeOff timeOff) async {
    DateTime dateDebut = timeOff.debut;
    DateTime dateFin = timeOff.fin;
    String motif = timeOff.motif ?? 'Congé';

    // 🔹 Liste de motifs possibles (à personnaliser selon ton besoin)
    final List<String> motifsDisponibles = [
      'Congé',
      'Congé annuel',
      'Congé maladie',
      'Absence justifiée',
      'Autre'
    ];

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

                  // 🔹 Dropdown Motif
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Motif",
                      border: OutlineInputBorder(),
                    ),
                    value: motifsDisponibles.contains(motif) ? motif : 'Congé',
                    items: motifsDisponibles
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          motif = value;
                        });
                      }
                    },
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
                    // Fermer le dialog AVANT
                    Navigator.of(context).pop();

                    // Utiliser le contexte parent (le state de ta page) pour lancer l’update
                    if (mounted) {
                      await _updateTimeOff(
                          staff, timeOff, dateDebut, dateFin, motif);
                    }
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

// SOLUTION 1 : Forcer le rechargement du cache ToMany après chaque opération

// Dans _saveTimeOff - AJOUTER après objectBox.timeOffBox.put(timeOff)
  Future<void> _saveTimeOff(
      Staff staff, DateTime debut, DateTime fin, String statut) async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();
      final objectBox = ObjectBox();
      int joursModifies = 0;

      // 1. CRÉER L'ENTITÉ TIMEOFF
      final timeOff = TimeOff(
        debut: debut,
        fin: fin,
        motif: _getStatutName(statut),
      )..staff.target = staff;

      objectBox.timeOffBox.put(timeOff);
      print("📅 TimeOff créé ID:${timeOff.id} pour ${staff.nom}");

      // 2. ⭐ FORCER LE RECHARGEMENT DU CACHE ToMany
      await _refreshStaffTimeOffCache(staff);

      // 3. Marquer les jours...
      DateTime currentDate = debut;
      while (currentDate.isBefore(fin.add(Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          int jour = currentDate.day;
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

      // 4. Rafraîchir les données
      await staffProvider.fetchStaffs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${_getStatutName(statut)} ajouté pour ${staff.nom}\n"
              "Cache actualisé : ${staff.timeOff.length} congé(s) total\n"
              "$joursModifies jours modifiés"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print("❌ Erreur _saveTimeOff: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'enregistrement: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTimeOff(Staff staff, TimeOff timeOff) async {
    try {
      final objectBox = ObjectBox();
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();

      print(
          "🗑️ AVANT suppression : staff.timeOff (cache) = ${staff.timeOff.length}");

      // 1. Supprimer le TimeOff de la base
      objectBox.timeOffBox.remove(timeOff.id);
      print("🗑️ TimeOff supprimé de la base");

      // 2. Forcer le rechargement du cache ToMany
      await _refreshStaffTimeOffCache(staff);
      print(
          "🔄 APRÈS rechargement : staff.timeOff (cache) = ${staff.timeOff.length}");

      // 3. Restaurer les jours impactés avec le statut approprié
      DateTime currentDate = timeOff.debut;
      int joursRestaures = 0;

      while (currentDate.isBefore(timeOff.fin.add(const Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          final jour = currentDate.day;
          final statutARestaurer =
              _determinerStatutApresSuppressionConge(staff, currentDate);

          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            jour,
            statutARestaurer,
            year: _selectedYear,
            month: _selectedMonth,
          );
          joursRestaures++;
          print("   Jour $jour restauré → $statutARestaurer");
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 4. Nettoyer l'observation du mois si elle contenait ce congé
      final currentObs = staffProvider.getObservationForStaff(staff.id) ?? '';
      if (currentObs.contains(DateFormat('dd/MM/yyyy').format(timeOff.debut)) ||
          currentObs.contains(timeOff.motif ?? '')) {
        staffProvider.setTemporaryObservation(
            staff.id, null); // Efface l'obs du mois
      }

      // 5. Sauvegarder le snapshot (pour persister la suppression d'obs)
      await staffProvider.saveMonthActivities(_selectedYear, _selectedMonth);

      // 6. Rafraîchir les données
      await staffProvider.fetchStaffs();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Congé supprimé pour ${staff.nom}\n"
              "Cache actualisé : ${staff.timeOff.length} congé(s) restant(s)\n"
              "$joursRestaures jours restaurés",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur _deleteTimeOff: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur lors de la suppression: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ NOUVELLE MÉTHODE : Déterminer le statut à restaurer après suppression d'un congé
  String _determinerStatutApresSuppressionConge(Staff staff, DateTime date) {
    // 1. Vérifier si c'est un weekend
    if (date.weekday == DateTime.friday || date.weekday == DateTime.saturday) {
      return "RE"; // Récupération pour tout le monde
    }

    // 2. Vérifier si le staff a d'autres congés ce jour-là
    final autresConges = staff.timeOff.toList().where((t) {
      return date.isAfter(t.debut.subtract(Duration(days: 1))) &&
          date.isBefore(t.fin.add(Duration(days: 1)));
    }).toList();

    if (autresConges.isNotEmpty) {
      return 'C'; // Il reste un autre congé
    }

    // 3. Déterminer selon le groupe
    final groupe = staff.groupe.toUpperCase() ?? '';
    final equipe = staff.equipe?.toUpperCase();

    // Agents d'hygiène (12H)
    if (groupe.contains('08H-12H') ||
        staff.grade.toLowerCase().contains('hygiène')) {
      // Vérifier la rotation en cours
      return _getStatutAgentHygiene(staff, date);
    }

    // Personnel médical avec équipes (08H-08H ou Garde 12H)
    if ((groupe.contains('08H-08H') || groupe.contains('GARDE 24H')) &&
        equipe != null &&
        ['A', 'B', 'C', 'D'].contains(equipe)) {
      // Vérifier la rotation en cours
      return _getStatutEquipeMedicale(staff, date);
    }

    // Personnel administratif (08H-16H) ou autres
    if (groupe.contains('08H-16H')) {
      return 'N'; // Normal
    }

    // Médecins sans équipe ou autres cas
    if (staff.grade.toLowerCase().contains('médecin')) {
      return 'N'; // Normal
    }

    // Par défaut
    return '-';
  }

// ✅ MÉTHODE HELPER : Obtenir le statut pour agent d'hygiène
  String _getStatutAgentHygiene(Staff staff, DateTime date) {
    try {
      final objectBox = ObjectBox();

      // Récupérer la planification du mois
      final query = objectBox.planificationBox
          .query(Planification_.mois.equals(date.month) &
              Planification_.annee.equals(date.year))
          .build();
      final planif = query.findFirst();
      query.close();

      if (planif == null || planif.ordreEquipes.isEmpty) {
        return 'RE'; // Pas de planification = repos
      }

      // Récupérer tous les agents d'hygiène
      final agentsHygiene = objectBox.staffBox
          .getAll()
          .where((s) =>
              s.grade.toLowerCase().contains('hygiène') ||
              s.groupe == '08H-12H')
          .toList();

      if (agentsHygiene.isEmpty) return 'RE';

      // Calculer les jours ouvrables jusqu'à cette date
      int joursOuvrablesAvant = 0;
      for (int d = 1; d < date.day; d++) {
        final testDate = DateTime(date.year, date.month, d);
        if (testDate.weekday != DateTime.friday &&
            testDate.weekday != DateTime.saturday) {
          joursOuvrablesAvant++;
        }
      }

      // Déterminer quel agent travaille ce jour
      final agentIndex = joursOuvrablesAvant % agentsHygiene.length;
      final agentQuiTravaille = agentsHygiene[agentIndex];

      return (agentQuiTravaille.id == staff.id) ? 'N' : 'RE';
    } catch (e) {
      print("⚠️ Erreur _getStatutAgentHygiene: $e");
      return 'RE';
    }
  }

// ✅ MÉTHODE HELPER : Obtenir le statut pour équipe médicale
  String _getStatutEquipeMedicale(Staff staff, DateTime date) {
    try {
      final objectBox = ObjectBox();

      // Récupérer la planification du mois
      final query = objectBox.planificationBox
          .query(Planification_.mois.equals(date.month) &
              Planification_.annee.equals(date.year))
          .build();
      final planif = query.findFirst();
      query.close();

      if (planif == null || planif.ordreEquipes.isEmpty) {
        return '-'; // Pas de planification
      }

      // Récupérer l'ordre des équipes
      final equipesOrdonnees = planif.ordreEquipes
          .split(',')
          .map((e) => e.trim().toUpperCase())
          .toList();

      if (equipesOrdonnees.isEmpty) return '-';

      // Calculer quelle équipe est de garde ce jour
      final joursEcoules =
          (date.day - 1) % DateTime(date.year, date.month + 1, 0).day;
      final equipeIndex = joursEcoules % equipesOrdonnees.length;
      final equipeDeGarde = equipesOrdonnees[equipeIndex];

      // Comparer avec l'équipe du staff
      return (staff.equipe?.toUpperCase() == equipeDeGarde) ? 'G' : 'RE';
    } catch (e) {
      print("⚠️ Erreur _getStatutEquipeMedicale: $e");
      return '-';
    }
  }

// ⭐ MÉTHODE CLÉE : Forcer le rechargement du cache ToMany
  Future<void> _refreshStaffTimeOffCache(Staff staff) async {
    try {
      final objectBox = ObjectBox();

      print("🔄 Rechargement cache ToMany pour ${staff.nom}...");

      // Méthode 1 : Vider et recharger explicitement
      staff.timeOff.clear(); // Vider le cache

      // Recharger depuis la base
      final freshTimeOffs = objectBox.timeOffBox
          .query(TimeOff_.staff.equals(staff.id))
          .build()
          .find();

      // Reconstruire le cache
      for (var timeOff in freshTimeOffs) {
        staff.timeOff.add(timeOff);
      }

      print("✅ Cache rechargé : ${staff.timeOff.length} congés dans le cache");

      // Optionnel : forcer la sauvegarde du staff pour synchroniser
      objectBox.staffBox.put(staff);
    } catch (e) {
      print("❌ Erreur _refreshStaffTimeOffCache: $e");
    }
  }

// SOLUTION 2 : Modifier _buildCongesListView pour lire DIRECTEMENT depuis la base
  Widget _buildCongesListView(Staff staff, StateSetter setState) {
    final objectBox = ObjectBox();

    // ⭐ CORRECTION : Filtrer les TimeOff par mois/année sélectionnés
    final freshTimeOffs = objectBox.timeOffBox
        .query(TimeOff_.staff.equals(staff.id))
        .build()
        .find()
        .where((timeOff) {
      // Vérifier si le congé chevauche le mois sélectionné
      final debutMois = DateTime(_selectedYear, _selectedMonth, 1);
      final finMois = DateTime(_selectedYear, _selectedMonth + 1, 0);

      return (timeOff.debut.isBefore(finMois.add(Duration(days: 1))) &&
          timeOff.fin.isAfter(debutMois.subtract(Duration(days: 1))));
    }).toList();

    print(
        "📊 _buildCongesListView : ${freshTimeOffs.length} congés pour $_selectedMonthName $_selectedYear");

    // Récupérer les activités de congé pour le mois sélectionné uniquement
    final congesActivites = staff.activites
        .where((a) =>
            (a.statut == 'C' || a.statut == 'CM') &&
            a.jour >= 1 &&
            a.jour <= _daysInSelectedMonth)
        .toList();

    final groupedConges =
        _groupActiviteConges(congesActivites, _selectedYear, _selectedMonth);

    return SingleChildScrollView(
      child: Column(
        children: [
          // TimeOff congés - filtrés par mois
          if (freshTimeOffs.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month,
                      size: 16, color: Colors.blue.shade600),
                  SizedBox(width: 8),
                  Text(
                    "Congés planifiés\n${freshTimeOffs.length} - $_selectedMonthName $_selectedYear",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            ...freshTimeOffs
                .map((timeOff) => _buildTimeOffCard(timeOff, staff, setState)),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

// MÉTHODE DE DEBUG AMÉLIORÉE
  Future<void> _listStaffWithTimeOff() async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      await staffProvider.fetchStaffs(); // Rafraîchir d'abord
      final objectBox = ObjectBox();
      final staffs = objectBox.staffBox.getAll();
      final allTimeOffs = objectBox.timeOffBox.getAll();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Analyse Cache vs Base"),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 500, // limite verticale
            ),
            child: IntrinsicWidth(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title:
                          Text("Total TimeOff en base: ${allTimeOffs.length}"),
                      subtitle: Text("Timestamp: ${DateTime.now()}"),
                    ),
                    const Divider(),
                    ...staffs.map((staff) {
                      final cacheCount = staff.timeOff.length;
                      final baseTimeOffs = objectBox.timeOffBox
                          .query(TimeOff_.staff.equals(staff.id))
                          .build()
                          .find();
                      final baseCount = baseTimeOffs.length;

                      if (cacheCount == 0 && baseCount == 0) {
                        return const SizedBox.shrink();
                      }

                      final syncOk = cacheCount == baseCount;

                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Text(
                            "$cacheCount",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w300),
                          ),
                        ),
                        title: Text(staff.nom,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$cacheCount Congé(s)"),
                        children: [
                          ListTile(title: Text("🗄️ Base directe: $baseCount")),
                          ListTile(
                            title: Text(
                              "🔄 Synchronisé ? ${syncOk ? '✅ OUI' : '❌ NON - PROBLÈME !'}",
                              style: TextStyle(
                                color: syncOk ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (!syncOk)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "⚠️ Désynchronisation détectée !",
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ...baseTimeOffs.map((timeOff) {
                            final debut =
                                DateFormat('dd/MM/yyyy').format(timeOff.debut);
                            final fin =
                                DateFormat('dd/MM/yyyy').format(timeOff.fin);
                            return ListTile(
                              leading: const Icon(Icons.event_note),
                              title: Text(timeOff.motif ?? 'Congé'),
                              subtitle: Text("$debut → $fin"),
                              trailing: Text("ID:${timeOff.id}"),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                for (var staff in staffs) {
                  await _refreshStaffTimeOffCache(staff);
                }
                Navigator.pop(context);
                await _listStaffWithTimeOff();
              },
              label: const Text("Forcer Sync"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Erreur debug: $e");
    }
  }

  Future<void> _updateTimeOff(
    Staff staff,
    TimeOff timeOff,
    DateTime nouveauDebut,
    DateTime nouvelleFin,
    String nouveauMotif,
  ) async {
    try {
      final objectBox = ObjectBox();
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();

      // 1. Remettre à '-' les anciens jours
      DateTime currentDate = timeOff.debut;
      while (currentDate.isBefore(timeOff.fin.add(const Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            currentDate.day,
            '-',
            year: _selectedYear,
            month: _selectedMonth,
          );
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 2. Mettre à jour l'entité TimeOff
      timeOff.debut = nouveauDebut;
      timeOff.fin = nouvelleFin;
      timeOff.motif = nouveauMotif;
      objectBox.timeOffBox.put(timeOff);

      // 3. Synchroniser la relation (au cas où)
      objectBox.staffBox.put(staff);

      // 4. Appliquer les nouveaux jours avec 'C'
      currentDate = nouveauDebut;
      int joursModifies = 0;
      while (currentDate.isBefore(nouvelleFin.add(const Duration(days: 1)))) {
        if (currentDate.year == _selectedYear &&
            currentDate.month == _selectedMonth) {
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            currentDate.day,
            'C',
            year: _selectedYear,
            month: _selectedMonth,
          );
          joursModifies++;
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 5. Mettre à jour l'observation du mois courant
      final nouvelleObs =
          "$nouveauMotif du ${DateFormat('dd/MM/yyyy').format(nouveauDebut)} "
          "au ${DateFormat('dd/MM/yyyy').format(nouvelleFin)}";
      staffProvider.setTemporaryObservation(staff.id, nouvelleObs);

      // 6. Sauvegarder le snapshot du mois (obs + activités)
      await staffProvider.saveMonthActivities(_selectedYear, _selectedMonth);

      // 7. Rafraîchir
      await staffProvider.fetchStaffs();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Congé modifié pour ${staff.nom}\n"
              "$joursModifies jours mis à jour\n"
              "Relations OK : ${staff.timeOff.length} congé(s)",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur _updateTimeOff: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur lors de la modification: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  mainAxisSize: MainAxisSize.min,
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
                    FittedBox(
                      child: const Text(
                        "Jour de départ (choisissez parmi les N premiers jours):",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

// NOUVELLE MÉTHODE : Dialog de planification avancé
  Future<Map<String, dynamic>?> _showPlanificationAvanceeDialog3({
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
                // SizedBox(height: 8),
                // Text("📅 Période: $_selectedMonthName $_selectedYear",
                //     style: TextStyle(color: Colors.white)),
                // Text(
                //     "🎯 Début: Jour $jourDepart, Équipe ${equipesOrdonnees[0]}",
                //     style: TextStyle(color: Colors.white)),
                // Text("👥 ${personnelMedical.length} médecins concernés",
                //     style: TextStyle(color: Colors.white)),
                // Text("✅ $totalModifications modifications effectuées",
                //     style: TextStyle(color: Colors.white)),
                // Text("🚫 $congesRespectes congés préservés",
                //     style: TextStyle(color: Colors.white)),
                // SizedBox(height: 4),
                // Text("Gardes: $resumeGardes",
                //     style: TextStyle(color: Colors.white, fontSize: 12)),
                // Text("Récupérations: $resumeRecuperations",
                //     style: TextStyle(color: Colors.white, fontSize: 12)),
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

//NOUVELLE MÉTHODE : Dialog simplifié - ordre des équipes seulement
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

  Future<void> _showEditPlanificationDialog(
      BuildContext context, int mois, int annee) async {
    final objectBox = ObjectBox();

    // Charger la planification existante
    final query = objectBox.planificationBox
        .query(Planification_.mois.equals(mois) &
            Planification_.annee.equals(annee))
        .build();
    Planification? planifExistante = query.findFirst();
    query.close();

    List<String> equipesExistantes = [];
    if (planifExistante != null) {
      equipesExistantes = planifExistante.ordreEquipes.split(",");
    }

    // Ouvrir le dialog avec l’ordre existant
    final equipesOrdonnees = await _showOrderEquipesDialog(
      equipesExistantes.isNotEmpty ? equipesExistantes : ['A', 'B', 'C', 'D'],
    );

    if (equipesOrdonnees == null) return;

    // Mettre à jour ou créer
    if (planifExistante != null) {
      planifExistante.ordreEquipes = equipesOrdonnees.join(',');
      objectBox.planificationBox.put(planifExistante);
    } else {
      final planif = Planification(
        mois: mois,
        annee: annee,
        ordreEquipes: equipesOrdonnees.join(','),
      );
      objectBox.planificationBox.put(planif);
    }

    // Relancer la planification
    await _executerPlanificationGardesSimple(equipesOrdonnees);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Planification mise à jour pour $mois/$annee")),
    );
  }

//NOUVELLE MÉTHODE : Dialog pour ordonner les équipes uniquement
  Future<List<String>?> _showOrderEquipesDialog(
      List<String> equipesDisponibles) async {
    final objectBox = ObjectBox();

    // // 🧹 Correction temporaire des planifications vides
    // final allPlanifs = objectBox.planificationBox.getAll();
    // for (var p in allPlanifs) {
    //   if (p.ordreEquipes.isEmpty) {
    //     // Tu peux aussi utiliser List.from(equipesDisponibles).join(',')
    //     p.ordreEquipes = equipesDisponibles.join(',');
    //     objectBox.planificationBox.put(p);
    //     print("✅ Correction appliquée à la planification ${p.id}");
    //   }
    // }
    // Vérifier si une planification existe déjà
    final query = objectBox.planificationBox
        .query(Planification_.mois.equals(_selectedMonth) &
            Planification_.annee.equals(_selectedYear))
        .build();

    final existingPlanif = query.findFirst();
    query.close();

    List<String> equipesOrdonnees;

    if (existingPlanif != null &&
        existingPlanif.ordreEquipes.isNotEmpty &&
        existingPlanif.ordreEquipes.contains(',')) {
      equipesOrdonnees = existingPlanif.ordreEquipes
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (existingPlanif != null &&
        existingPlanif.ordreEquipes.isNotEmpty &&
        !existingPlanif.ordreEquipes.contains(',')) {
      // Cas où il y a une seule équipe sauvegardée sans virgule
      equipesOrdonnees = [existingPlanif.ordreEquipes.trim()];
    } else {
      equipesOrdonnees = List.from(equipesDisponibles);
    }
    // List<String> equipesOrdonnees = List.from(equipesDisponibles);
    print(equipesDisponibles.length);
    print(
      equipesOrdonnees.length,
    );
    print(equipesDisponibles);
    print(
      equipesOrdonnees,
    );
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
              content: SizedBox(
                width: 420, // 👈 largeur fixe pour éviter le bug
                height: 500,
                child: IntrinsicWidth(
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
                              colors: [
                                Colors.teal.shade50,
                                Colors.teal.shade100
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: Text(
                                          "La rotation commence automatiquement le 1er jour",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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
                                final item =
                                    equipesOrdonnees.removeAt(oldIndex);
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
                                    // trailing: Icon(
                                    //   Icons.drag_handle,
                                    //   color: isFirst
                                    //       ? Colors.teal.shade400
                                    //       : Colors.grey.shade400,
                                    // ),
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

      // ✅ 1. Sauvegarder l'ordre des équipes
      final query = objectBox.planificationBox
          .query(
            Planification_.mois.equals(_selectedMonth) &
                Planification_.annee.equals(_selectedYear),
          )
          .build();
      Planification? existingPlanif = query.findFirst();
      query.close();

      if (existingPlanif != null) {
        existingPlanif.ordreEquipes = equipesOrdonnees.join(',');
        objectBox.planificationBox.put(existingPlanif);
      } else {
        final planif = Planification(
          mois: _selectedMonth,
          annee: _selectedYear,
          ordreEquipes: equipesOrdonnees.join(','),
        );
        objectBox.planificationBox.put(planif);
      }

      // ✅ 2. Sélectionner le personnel médical concerné
      final personnelMedical = staffProvider.staffs
          .where((staff) =>
              staff.equipe != null &&
              equipesOrdonnees.contains(staff.equipe!.toUpperCase()))
          .toList();

      if (personnelMedical.isEmpty) {
        throw Exception(
            "Aucun personnel médical trouvé avec les équipes sélectionnées");
      }

      // ✅ 3. Collecter TOUS les congés (TimeOff + activités C/CM) pour le mois sélectionné
      Map<int, Map<int, String>> congesParStaff =
          {}; // {staffId: {jour: statut}}

      // --- TimeOff : ⭐ CORRECTION - Ne traiter que les congés du mois sélectionné
      final allTimeOffs = objectBox.timeOffBox.getAll();
      for (var timeOff in allTimeOffs) {
        if (timeOff.staff.target != null) {
          final staff = timeOff.staff.target!;
          congesParStaff.putIfAbsent(staff.id, () => {});

          DateTime currentDate = timeOff.debut;
          while (
              currentDate.isBefore(timeOff.fin.add(const Duration(days: 1)))) {
            // ⭐ FILTRE CRUCIAL : Vérifier année ET mois
            if (currentDate.year == _selectedYear &&
                currentDate.month == _selectedMonth) {
              congesParStaff[staff.id]![currentDate.day] =
                  _getStatutCongeFromTimeOff(timeOff);
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      }

      // --- Congés depuis ActiviteJour (C/CM)
      for (final staff in personnelMedical) {
        congesParStaff.putIfAbsent(staff.id, () => {});
        for (var activite in staff.activites) {
          if ((activite.statut == 'C' || activite.statut == 'CM') &&
              activite.jour >= 1 &&
              activite.jour <= daysInMonth) {
            congesParStaff[staff.id]![activite.jour] = activite.statut;
          }
        }
      }

      // ✅ 4. Planifier les gardes et récupérations
      for (int day = 1; day <= daysInMonth; day++) {
        int equipeIndex = (day - 1) % equipesOrdonnees.length;
        String equipeDeGarde = equipesOrdonnees[equipeIndex];

        for (final staff in personnelMedical) {
          if (congesParStaff[staff.id]!.containsKey(day)) continue;

          String nouveauStatut =
              (staff.equipe!.toUpperCase() == equipeDeGarde) ? "G" : "RE";

          await activiteProvider.updateActivite(
            staff.id,
            day,
            nouveauStatut,
            year: _selectedYear,
            month: _selectedMonth,
          );

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

      // ✅ 5. Appliquer les congés et écraser si nécessaire
      for (final staff in personnelMedical) {
        for (var entry in congesParStaff[staff.id]!.entries) {
          int jour = entry.key;
          String statutConge = entry.value;

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
                  (gardesParEquipe[staff.equipe!.toUpperCase()] ?? 0) - 1;
            } else if (statutActuel == 'RE') {
              recuperationsParEquipe[staff.equipe!.toUpperCase()] =
                  (recuperationsParEquipe[staff.equipe!.toUpperCase()] ?? 0) -
                      1;
            }
          }

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

      // ✅ 6. Rafraîchir les données
      await staffProvider.fetchStaffs();
      // ✅ 7. Résumés
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
// À la fin, sauvegarder

      await staffProvider.saveMonthActivities(_selectedYear, _selectedMonth);

      // ✅ 8. Affichage
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
                // SizedBox(height: 8),
                // Text("📅 Période: $_selectedMonthName $_selectedYear",
                //     style: TextStyle(color: Colors.white)),
                // Text("🔄 Ordre: ${equipesOrdonnees.join(' → ')}",
                //     style: TextStyle(color: Colors.white)),
                // Text("👥 ${personnelMedical.length} médecins concernés",
                //     style: TextStyle(color: Colors.white)),
                // SizedBox(height: 6),
                // Text("Phase 1 - Gardes attribuées:",
                //     style: TextStyle(
                //         color: Colors.white, fontWeight: FontWeight.w600)),
                // if (resumeGardes.isNotEmpty)
                //   Text("  Gardes: $resumeGardes",
                //       style: TextStyle(color: Colors.white, fontSize: 12)),
                // if (resumeRecuperations.isNotEmpty)
                //   Text("  Récupérations: $resumeRecuperations",
                //       style: TextStyle(color: Colors.white, fontSize: 12)),
                // SizedBox(height: 4),
                // Text("Phase 2 - Congés appliqués:",
                //     style: TextStyle(
                //         color: Colors.white, fontWeight: FontWeight.w600)),
                // if (gardesEcrasees > 0)
                //   Text("  🚫 $gardesEcrasees gardes écrasées par des congés",
                //       style: TextStyle(
                //           color: Colors.yellow.shade200, fontSize: 12)),
                // if (resumeConges.isNotEmpty)
                //   Text("  Congés: $resumeConges",
                //       style: TextStyle(color: Colors.white, fontSize: 12))
                // else
                //   Text("  ⚠️ Aucun congé appliqué - vérifiez les logs",
                //       style: TextStyle(
                //           color: Colors.yellow.shade200, fontSize: 12)),
                // SizedBox(height: 4),
                // Text("✅ Total: $totalModifications modifications",
                //     style: TextStyle(color: Colors.white)),
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

  /// Fonction utilitaire pour déterminer le statut de congé (si pas déjà définie)
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

// NOUVELLE MÉTHODE : Dialog de planification des agents d'hygiène
  Future<void> _showPlanificationAgentsHygieneDialog() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    // 1. Identifier les agents d'hygiène
    final agentsHygiene = staffProvider.staffs
        .where((staff) =>
            staff.grade.toLowerCase().contains('hygiène') ||
            staff.grade.toLowerCase().contains('hygiene'))
        .toList();

    if (agentsHygiene.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun agent d'hygiène trouvé"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Calculer les jours de travail disponibles (exclure weekends)
    final joursOuvrables = <int>[];
    for (int day = 1; day <= _daysInSelectedMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      if (date.weekday != DateTime.friday &&
          date.weekday != DateTime.saturday) {
        joursOuvrables.add(day);
      }
    }

    // 3. Analyser les congés existants
    final congesParAgent = await _analyserCongesAgents(agentsHygiene);

    // 4. Calculer la répartition optimale
    final repartitionOptimale = _calculerRepartitionOptimale(
        agentsHygiene, joursOuvrables, congesParAgent);

    // 5. Afficher le dialog de planification
    final ordreAgents = await _showOrderAgentsHygieneDialog(
      agentsHygiene,
      repartitionOptimale,
      joursOuvrables.length,
    );

    if (ordreAgents == null) return;

    // 6. Exécuter la planification intelligente
    await _executerPlanificationAgentsHygiene(
        ordreAgents, joursOuvrables, congesParAgent);
  }

// MÉTHODE : Analyser les congés des agents
// MÉTHODE : Analyser les congés des agents pour le mois sélectionné
  Future<Map<Staff, List<int>>> _analyserCongesAgents(
      List<Staff> agents) async {
    final objectBox = ObjectBox();
    final congesParAgent = <Staff, List<int>>{};

    for (final agent in agents) {
      final joursConge = <int>[];

      // ⭐ CORRECTION : Filtrer TimeOff par année/mois
      final timeOffQuery =
          objectBox.timeOffBox.query(TimeOff_.staff.equals(agent.id)).build();
      final timeOffs = timeOffQuery.find();
      timeOffQuery.close();

      for (var timeOff in timeOffs) {
        DateTime currentDate = timeOff.debut;
        while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
          // ⭐ Ne garder que les jours du mois sélectionné
          if (currentDate.year == _selectedYear &&
              currentDate.month == _selectedMonth) {
            joursConge.add(currentDate.day);
          }
          currentDate = currentDate.add(Duration(days: 1));
        }
      }

      // Activités de congé - déjà filtrées par le nombre de jours du mois
      final activiteQuery = objectBox.activiteBox
          .query(ActiviteJour_.staff.equals(agent.id))
          .build();
      final activites = activiteQuery.find();
      activiteQuery.close();

      for (var activite in activites) {
        if ((activite.statut == 'C' || activite.statut == 'CM') &&
            activite.jour >= 1 &&
            activite.jour <= _daysInSelectedMonth &&
            !joursConge.contains(activite.jour)) {
          joursConge.add(activite.jour);
        }
      }

      congesParAgent[agent] = joursConge;
    }

    return congesParAgent;
  }

// MÉTHODE : Calculer la répartition optimale
  Map<String, dynamic> _calculerRepartitionOptimale(List<Staff> agents,
      List<int> joursOuvrables, Map<Staff, List<int>> congesParAgent) {
    final nombreAgents = agents.length;
    final nombreJoursOuvrables = joursOuvrables.length;

    // Calculer les jours disponibles par agent
    final joursDisponiblesParAgent = <Staff, int>{};
    for (final agent in agents) {
      final conges = congesParAgent[agent] ?? [];
      final joursCongeOuvrables =
          conges.where((jour) => joursOuvrables.contains(jour)).length;
      joursDisponiblesParAgent[agent] =
          nombreJoursOuvrables - joursCongeOuvrables;
    }

    // Répartition théorique
    final joursParAgent = nombreJoursOuvrables ~/ nombreAgents;
    final joursSupplementaires = nombreJoursOuvrables % nombreAgents;

    return {
      'nombreAgents': nombreAgents,
      'nombreJoursOuvrables': nombreJoursOuvrables,
      'joursParAgent': joursParAgent,
      'joursSupplementaires': joursSupplementaires,
      'joursDisponiblesParAgent': joursDisponiblesParAgent,
    };
  }

// MÉTHODE : Dialog pour ordonner les agents
  Future<List<Staff>?> _showOrderAgentsHygieneDialog(
    List<Staff> agents,
    Map<String, dynamic> repartition,
    int nombreJoursOuvrables,
  ) async {
    List<Staff> agentsOrdonnes = List.from(agents);

    return await showDialog<List<Staff>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.cleaning_services, color: Colors.brown),
                  SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      child: Text(
                        "Planification Agents d'Hygiène",
                        style: TextStyle(color: Colors.brown.shade700),
                      ),
                    ),
                  ),
                ],
              ),
              content: Center(
                child: Container(
                  width: double.maxFinite,
                  constraints: BoxConstraints(
                    minWidth: 300, // Largeur minimale
                    maxWidth: 300, // Largeur maximale (optionnel)
                    maxHeight: 600,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Informations générales
                        Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                "Mois: $_selectedMonthName $_selectedYear",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                  "${agents.length} agents d'hygiène détectés"),
                              Text(
                                  "$nombreJoursOuvrables jours ouvrables (hors weekends)"),
                              Text(
                                  "${repartition['joursParAgent']} jours/agent + ${repartition['joursSupplementaires']} jour(s) supplémentaire(s)"),
                              SizedBox(height: 8),
                              Container(
                                width: double.maxFinite,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FittedBox(
                                  child: Text(
                                    "Règle: Un seul agent travaille par jour (statut N)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Ordre des agents
                        Text(
                          "Ordre de rotation :",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Glissez pour réorganiser. Le 1er agent commence au 1er jour ouvrable.",
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 12),

                        // Liste réorganisable
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: agentsOrdonnes.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = agentsOrdonnes.removeAt(oldIndex);
                                agentsOrdonnes.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final agent = agentsOrdonnes[index];
                              final conges =
                                  repartition['joursDisponiblesParAgent']
                                          [agent] ??
                                      0;
                              final isFirst = index == 0;

                              return Container(
                                key: ValueKey('agent_${agent.id}_$index'),
                                margin: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Card(
                                  elevation: isFirst ? 2 : 1,
                                  color: isFirst
                                      ? Colors.brown.shade50
                                      : Colors.white,
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.brown.shade400,
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
                                      agent.nom,
                                      style: TextStyle(
                                        fontWeight: isFirst
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "$conges jours disponibles",
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isFirst)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.brown.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "1er",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.brown.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: 8),
                                        // Icon(Icons.drag_handle,
                                        //     color: Colors.grey.shade400),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Aperçu de la répartition
                        Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Logique de répartition intelligente :",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text("• Un seul agent par jour ouvrable",
                                  style: TextStyle(fontSize: 12)),
                              Text("• Weekends: tous en 'RE'",
                                  style: TextStyle(fontSize: 12)),
                              Text("• Congés automatiquement exclus",
                                  style: TextStyle(fontSize: 12)),
                              Text("• Répartition équitable malgré les congés",
                                  style: TextStyle(fontSize: 12)),
                              Text("• Rotation cyclique selon l'ordre défini",
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  label: Text("Planifier"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(agentsOrdonnes),
                ),
              ],
            );
          },
        );
      },
    );
  }

// MÉTHODE : Exécution de la planification intelligente
  Future<void> _executerPlanificationAgentsHygiene(
    List<Staff> agentsOrdonnes,
    List<int> joursOuvrables,
    Map<Staff, List<int>> congesParAgent,
  ) async {
    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();

      int totalModifications = 0;
      int weekendsTraites = 0;
      int joursAssignes = 0;
      int congesRespected = 0;
      Map<Staff, int> assignationParAgent = {};

      print("🔄 PHASE 1: Attribution des weekends (RE pour tous)");

      // PHASE 1: Weekends - tous les agents en 'RE'
      for (final agent in agentsOrdonnes) {
        for (int day = 1; day <= _daysInSelectedMonth; day++) {
          final date = DateTime(_selectedYear, _selectedMonth, day);
          if (date.weekday == DateTime.friday ||
              date.weekday == DateTime.saturday) {
            await activiteProvider.forceUpdateActiviteIgnoringLeave(
              agent.id,
              day,
              "RE",
              year: _selectedYear,
              month: _selectedMonth,
            );
            totalModifications++;
            if (agent == agentsOrdonnes.first) weekendsTraites++;
          }
        }
      }

      print("🔄 PHASE 2: Attribution intelligente des jours ouvrables");

      // PHASE 2: Répartition intelligente des jours ouvrables
      int agentIndex = 0;

      for (final jourOuvrable in joursOuvrables) {
        bool jourAssigne = false;
        int tentatives = 0;

        // Essayer d'assigner ce jour en évitant les congés
        while (!jourAssigne && tentatives < agentsOrdonnes.length) {
          final agentCandadat = agentsOrdonnes[agentIndex];
          final congesAgent = congesParAgent[agentCandadat] ?? [];

          if (!congesAgent.contains(jourOuvrable)) {
            // Agent disponible - assigner 'N' à lui, '-' aux autres
            for (final agent in agentsOrdonnes) {
              String statut = (agent == agentCandadat) ? "N" : "RE";
              await activiteProvider.forceUpdateActiviteIgnoringLeave(
                agent.id,
                jourOuvrable,
                statut,
                year: _selectedYear,
                month: _selectedMonth,
              );
              totalModifications++;
            }

            assignationParAgent[agentCandadat] =
                (assignationParAgent[agentCandadat] ?? 0) + 1;
            jourAssigne = true;
            joursAssignes++;

            print("  Jour $jourOuvrable: ${agentCandadat.nom} (N)");
          } else {
            congesRespected++;
            print(
                "  Jour $jourOuvrable: ${agentCandadat.nom} en congé, passage au suivant");
          }

          // Passer à l'agent suivant dans la rotation
          agentIndex = (agentIndex + 1) % agentsOrdonnes.length;
          tentatives++;
        }

        if (!jourAssigne) {
          // Tous les agents sont en congé ce jour-là - assigner '-' à tous
          print("  Jour $jourOuvrable: tous les agents en congé");
          for (final agent in agentsOrdonnes) {
            await activiteProvider.forceUpdateActiviteIgnoringLeave(
              agent.id,
              jourOuvrable,
              "-",
              year: _selectedYear,
              month: _selectedMonth,
            );
            totalModifications++;
          }
        }
      }

      print("🔄 PHASE 3: Application finale des congés");

      // PHASE 3: Application des congés (écrasement)
      final objectBox = ObjectBox();
      int congesAppliques = 0;

      for (final agent in agentsOrdonnes) {
        // TimeOff
        final timeOffQuery =
            objectBox.timeOffBox.query(TimeOff_.staff.equals(agent.id)).build();
        final timeOffs = timeOffQuery.find();
        timeOffQuery.close();

        for (var timeOff in timeOffs) {
          DateTime currentDate = timeOff.debut;
          while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
            if (currentDate.year == _selectedYear &&
                currentDate.month == _selectedMonth) {
              String statutConge = _getStatutCongeFromTimeOff(timeOff);
              await activiteProvider.forceUpdateActiviteIgnoringLeave(
                agent.id,
                currentDate.day,
                statutConge,
                year: _selectedYear,
                month: _selectedMonth,
              );
              congesAppliques++;
            }
            currentDate = currentDate.add(Duration(days: 1));
          }
        }
      }

      // Rafraîchir les données
      await staffProvider.fetchStaffs();
      // Afficher le résultat
      final repartitionDetails = assignationParAgent.entries
          .map((e) => "${e.key.nom}: ${e.value}j")
          .join(", ");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Agents d'hygiène planifiés !",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // SizedBox(height: 8),
                // Text(
                //     "📅 ${agentsOrdonnes.length} agents pour $_selectedMonthName $_selectedYear",
                //     style: TextStyle(color: Colors.white)),
                // Text("🏢 $joursAssignes jours ouvrables assignés",
                //     style: TextStyle(color: Colors.white)),
                // Text("🌴 $weekendsTraites weekends en 'RE'",
                //     style: TextStyle(color: Colors.white)),
                // Text("🚫 $congesRespected jours évités (congés)",
                //     style: TextStyle(color: Colors.white)),
                // Text("✅ $congesAppliques congés appliqués",
                //     style: TextStyle(color: Colors.white)),
                // SizedBox(height: 4),
                // Text("Répartition: $repartitionDetails",
                //     style: TextStyle(color: Colors.white, fontSize: 12)),
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

// NOUVELLE MÉTHODE : Indicateur de congés filtré par mois
  Widget _buildCongesIndicator(Staff staff) {
    // ⭐ CORRECTION : Compter seulement les congés du mois sélectionné
    final timeOffs = staff.timeOff.toList();
    final activites = staff.activites.toList();

    // Filtrer TimeOff qui chevauchent le mois sélectionné
    final debutMois = DateTime(_selectedYear, _selectedMonth, 1);
    final finMois = DateTime(_selectedYear, _selectedMonth + 1, 0);

    final timeOffsDuMois = timeOffs.where((timeOff) {
      return timeOff.debut.isBefore(finMois.add(Duration(days: 1))) &&
          timeOff.fin.isAfter(debutMois.subtract(Duration(days: 1)));
    }).length;

    // Compter les congés activités du mois
    final congesActivites = activites
        .where((a) =>
            (a.statut == 'C' || a.statut == 'CM') &&
            a.jour >= 1 &&
            a.jour <= _daysInSelectedMonth)
        .length;

    final totalConges = timeOffsDuMois + congesActivites;
    final hasConges = totalConges > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasConges ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasConges ? Colors.orange.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasConges ? Icons.event_busy : Icons.event_available,
            size: 14,
            color: hasConges ? Colors.orange.shade600 : Colors.grey.shade400,
          ),
          if (hasConges) ...[
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalConges',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Future<void> _showObservationDialog(BuildContext context, Staff staff) async {
  //   final obsController = TextEditingController(text: staff.obs ?? '');
  //
  //   // ✅ Capturer le provider avant d’ouvrir le dialog
  //   final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  //
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         title: Row(
  //           children: [
  //             Icon(Icons.note, color: Colors.blue),
  //             SizedBox(width: 8),
  //             Text("Observations - ${staff.nom}"),
  //           ],
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: obsController,
  //               maxLines: 3,
  //               decoration: InputDecoration(
  //                 labelText: "Observations",
  //                 hintText: "Saisir les observations pour ce staff...",
  //                 border: OutlineInputBorder(),
  //                 prefixIcon: Icon(Icons.edit_note),
  //                 // ✅ Icône pour vider le champ
  //                 suffixIcon: obsController.text.isNotEmpty
  //                     ? IconButton(
  //                         icon: Icon(Icons.clear),
  //                         tooltip: "Effacer le texte",
  //                         onPressed: () {
  //                           obsController.clear();
  //                         },
  //                       )
  //                     : null,
  //               ),
  //               onChanged: (_) {
  //                 // ✅ Redessine le widget pour faire apparaître/disparaître l’icône
  //                 (dialogContext as Element).markNeedsBuild();
  //               },
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(dialogContext).pop(),
  //             child: Text("Annuler"),
  //           ),
  //           ElevatedButton.icon(
  //             icon: Icon(Icons.save, size: 16),
  //             label: Text("Sauvegarder"),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blue,
  //               foregroundColor: Colors.white,
  //             ),
  //             onPressed: () async {
  //               staff.obs = obsController.text.trim().isEmpty
  //                   ? null
  //                   : obsController.text.trim();
  //               await staffProvider.updateStaff(staff);
  //               Navigator.of(dialogContext).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
// ============================================================================
// CORRECTIF CRUD OBSERVATIONS - TableauStaff.dart
// ============================================================================

// ============================================================================
// CORRECTION COMPLÈTE - _showObservationDialog
// Remplacez votre méthode existante par celle-ci
// ============================================================================

// ---------------------------------------------------------------------------
// _showObservationDialog - Corrigé
// ---------------------------------------------------------------------------
  Future<void> _showObservationDialog(BuildContext context, Staff staff) async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final currentObs = staffProvider.getObservationForStaff(staff.id) ?? '';
    final obsController = TextEditingController(text: currentObs);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.note, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text("Observations - ${staff.nom}",
                          style: const TextStyle(fontSize: 16))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.blue),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Les observations seront sauvegardées automatiquement",
                            style: TextStyle(fontSize: 11, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: "Observations",
                      hintText: "Saisir les observations pour ce staff...",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.edit_note),
                      suffixIcon: obsController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: "Effacer",
                              onPressed: () {
                                // setState(() {
                                obsController.clear();
                                //   staffProvider.setTemporaryObservation(
                                //       staff.id, null);
                                // });
                              },
                            )
                          : null,
                    ),
                    // onChanged: (value) {
                    //   setState(() {});
                    //   staffProvider.setTemporaryObservation(
                    //       staff.id, value.trim().isEmpty ? null : value.trim());
                    // },
                  ),
                  const SizedBox(height: 8),
                  Text('${obsController.text.length}/500 caractères',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Fermer")),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text("Sauvegarder"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
                      staffProvider.setTemporaryObservation(
                          staff.id,
                          obsController.text.trim().isEmpty
                              ? null
                              : obsController.text.trim());
                      await staffProvider.saveMonthActivities(
                          _selectedYear, _selectedMonth);
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        setState(() {}); // Rebuild tableau
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("✅ Observations sauvegardées"),
                              backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("❌ Erreur: $e"),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

// NOUVELLE MÉTHODE : Dialog complet de gestion des congés
  Future<void> _showCongesManagementDialog(BuildContext context, Staff staff,
      {required BuildContext parentContext}) async {
    await showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.event_busy, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("Gestion des congés - ${staff.nom}"),
                  ),
                ],
              ),
              content: Container(
                height: 600,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SECTION 1: Liste des congés existants
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Congés existants",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add, size: 16),
                          label: Text("Nouveau"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            // ✅ NE PAS FERMER, juste ouvrir par-dessus
                            await _showTimeOffDialog(context, staff);

                            // ✅ Après la fermeture du dialog de création, rafraîchir la liste
                            setState(() {
                              // Ceci va rebuild le _buildCongesListView avec les nouvelles données
                            });

                            // Rafraîchir le provider
                            final staffProvider = Provider.of<StaffProvider>(
                                parentContext,
                                listen: false);
                            await staffProvider.fetchStaffs();
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Liste des congés
                    Expanded(
                      child: _buildCongesListView(staff, setState),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Fermer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Regroupe les ActiviteJour consécutifs en périodes (du .. au ..)
  List<Map<String, dynamic>> _groupActiviteConges(
      List<ActiviteJour> activites, int year, int month) {
    final List<Map<String, dynamic>> groupes = [];
    if (activites.isEmpty) return groupes;

    activites.sort((a, b) => a.jour.compareTo(b.jour));

    ActiviteJour debut = activites.first;
    ActiviteJour precedent = activites.first;

    for (int i = 1; i < activites.length; i++) {
      final current = activites[i];

      if (current.jour == precedent.jour + 1 &&
          current.statut == precedent.statut) {
        // étend la plage
        precedent = current;
      } else {
        groupes.add({
          'statut': debut.statut,
          'start': DateTime(year, month, debut.jour),
          'end': DateTime(year, month, precedent.jour),
        });
        debut = current;
        precedent = current;
      }
    }

    // ajout du dernier groupe
    groupes.add({
      'statut': debut.statut,
      'start': DateTime(year, month, debut.jour),
      'end': DateTime(year, month, precedent.jour),
    });

    return groupes;
  }

// Card qui affiche une période (du .. au ..) + actions edit/delete
  Widget _buildActivitePeriodeCard(
      Map<String, dynamic> groupe, Staff staff, StateSetter setState) {
    final DateTime start = groupe['start'] as DateTime;
    final DateTime end = groupe['end'] as DateTime;
    final String statut = groupe['statut'] as String;

    final int duree = end.difference(start).inDays + 1;
    final String label = (statut == 'CM') ? "Congé Maladie" : "Congé";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: (statut == 'CM')
              ? Colors.purple.shade600
              : Colors.orange.shade600,
          radius: 18,
          child: Text(
            statut,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          "$label (${duree} jour${duree > 1 ? 's' : ''})",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          "Du ${DateFormat('dd/MM/yyyy').format(start)} "
          "au ${DateFormat('dd/MM/yyyy').format(end)}",
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Éditer
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              tooltip: "Modifier",
              onPressed: () async {
                final changed = await _showEditActivitePeriodeDialog(
                  context,
                  staff,
                  start,
                  end,
                  statut,
                );
                if (changed == true) {
                  final staffProvider =
                      Provider.of<StaffProvider>(context, listen: false);
                  await staffProvider.fetchStaffs();
                  setState(() {});
                }
              },
            ),

            // Supprimer (remet les jours à '-')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              tooltip: "Supprimer",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Confirmer la suppression"),
                    content: Text(
                      "Supprimer le congé du "
                      "${DateFormat('dd/MM/yyyy').format(start)} "
                      "au ${DateFormat('dd/MM/yyyy').format(end)} ?",
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text("Annuler")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text("Supprimer"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final activiteProvider = ActiviteProvider();
                  for (int d = start.day; d <= end.day; d++) {
                    await activiteProvider.forceUpdateActiviteIgnoringLeave(
                      staff.id,
                      d,
                      '-',
                      year: _selectedYear,
                      month: _selectedMonth,
                    );
                  }
                  final staffProvider =
                      Provider.of<StaffProvider>(context, listen: false);
                  await staffProvider.fetchStaffs();
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

// Dialog d'édition d'une période (retourne true si modifié)
  Future<bool?> _showEditActivitePeriodeDialog(
    BuildContext ctx,
    Staff staff,
    DateTime oldStart,
    DateTime oldEnd,
    String oldStatut,
  ) {
    int startDay = oldStart.day;
    int endDay = oldEnd.day;
    String statut = oldStatut;

    return showDialog<bool>(
      context: ctx,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                Text("Modifier période - ${staff.nom}"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Choix du statut (C ou CM)
                Row(
                  children: [
                    const Text("Type: "),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: statut,
                      items: ['C', 'CM'].map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s == 'CM' ? 'Congé Maladie' : 'Congé'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => statut = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Jour de début / fin (Dropdown de jours du mois)
                Row(
                  children: [
                    const Text("Du"),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: startDay,
                      items: List.generate(_daysInSelectedMonth, (i) => i + 1)
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(d.toString())))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          startDay = v;
                          if (startDay > endDay) endDay = startDay;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text("au"),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: endDay,
                      items: List.generate(_daysInSelectedMonth, (i) => i + 1)
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(d.toString())))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          endDay = v;
                          if (endDay < startDay) startDay = endDay;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Annuler")),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: const Text("Enregistrer"),
                onPressed: () async {
                  final activiteProvider = ActiviteProvider();

                  // 1) Supprimer l'ancienne plage (remettre '-')
                  for (int d = oldStart.day; d <= oldEnd.day; d++) {
                    await activiteProvider.forceUpdateActiviteIgnoringLeave(
                      staff.id,
                      d,
                      '-',
                      year: _selectedYear,
                      month: _selectedMonth,
                    );
                  }

                  // 2) Appliquer la nouvelle plage avec le statut choisi
                  for (int d = startDay; d <= endDay; d++) {
                    await activiteProvider.forceUpdateActiviteIgnoringLeave(
                      staff.id,
                      d,
                      statut,
                      year: _selectedYear,
                      month: _selectedMonth,
                    );
                  }

                  // 3) Rafraîchir les données
                  // final staffProvider =
                  //     Provider.of<StaffProvider>(context, listen: false);
                  // await staffProvider.fetchStaffs();

                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
      },
    );
  }

// MÉTHODE : Card pour TimeOff
  Widget _buildTimeOffCard(TimeOff timeOff, Staff staff, StateSetter setState) {
    final duree = timeOff.fin.difference(timeOff.debut).inDays + 1;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade600,
          radius: 16,
          child: Icon(
            Icons.event_busy,
            size: 16,
            color: Colors.white,
          ),
        ),
        title: Text(
          timeOff.motif ?? 'Congé',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Du ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}",
              style: TextStyle(fontSize: 11),
            ),
            Text(
              "$duree jour${duree > 1 ? 's' : ''}",
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () async {
          await _showTimeOffOptionsDialog(timeOff, staff, setState);
        },
        onLongPress: () async {
          await _showTimeOffOptionsDialog(timeOff, staff, setState);
        },
      ),
    );
  }

  Future<void> _showTimeOffOptionsDialog(
      TimeOff timeOff, Staff staff, StateSetter setState) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Choisir une action"),
        content: Text(
            "${timeOff.motif ?? 'Congé'}\nDu ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop("edit"),
            child: Text("Modifier"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop("delete"),
            child: Text("Supprimer"),
          ),
        ],
      ),
    );

    if (choice == "edit") {
      Navigator.of(context).pop();
      await _showEditTimeOffDialog(context, staff, timeOff);
      await _showCongesManagementDialog(context, staff, parentContext: context);
    } else if (choice == "delete") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Confirmer la suppression"),
          content: Text(
              "Voulez-vous vraiment supprimer ce congé ?\n\n${timeOff.motif ?? 'Congé'}\nDu ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text("Supprimer"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _deleteTimeOff(staff, timeOff);
        // await runPlanificationAutomatique(context);
        // await _showPlanificationAgentsHygieneDialog();
        // await _showSimplePlanificationDialog();
        setState(() {}); // Rafraîchir la liste
      }
    }
  }

  Future<void> runPlanificationAutomatique(BuildContext context) async {
    // Demander confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: FittedBox(
            child: Text(
              "Cette action va :\n"
              "PHASE 1 - Attribution initiale :\n"
              "• Planification Réussite pour Tout Le STaff\n"
              "PHASE 2 - Application des congés :\n"
              "• Les congés existants vont etre assigné\n"
              "• Aucun congé ne sera perdu\n"
              "\nMois: $_selectedMonthName $_selectedYear\n",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirmer"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();
      final objectBox = ObjectBox();

      final daysInMonth = _daysInSelectedMonth;
      int weekendDaysCount = 0;
      int normalDaysCount = 0;
      int totalModifications = 0;
      int staffEquipeABCD = 0;
      int staffAutres = 0;
      int congesAppliques = 0;
      int gardesEcrasees = 0;

      print("🔄 PHASE 1: Attribution automatique (ignorant les congés)");

      // PHASE 1: ATTRIBUTION AUTOMATIQUE
      for (final staff in staffProvider.staffs) {
        if (staff.groupe == "Garde 24") {
          print("⏩ ${staff.nom} ignoré car groupe = Garde 24H");
          continue;
        }
        if (staff.grade == "Agent d'hygiène") {
          print("⏩ ${staff.nom} ignoré car Grade = Agent d'hygiène");
          continue;
        }

        final equipe = staff.equipe?.toUpperCase();
        final isEquipeABCD =
            equipe != null && ['A', 'B', 'C', 'D'].contains(equipe);

        if (isEquipeABCD) {
          staffEquipeABCD++;
        } else {
          staffAutres++;
        }

        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(_selectedYear, _selectedMonth, day);

          String statutAAffecter;
          if (date.weekday == DateTime.friday ||
              date.weekday == DateTime.saturday) {
            statutAAffecter = "RE";
            if (staff == staffProvider.staffs.first) {
              weekendDaysCount++;
            }
          } else {
            statutAAffecter = isEquipeABCD ? "-" : "N";
            if (staff == staffProvider.staffs.first) {
              normalDaysCount++;
            }
          }

          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            staff.id,
            day,
            statutAAffecter,
            year: _selectedYear,
            month: _selectedMonth,
          );
          totalModifications++;
        }
      }

      print("🔄 PHASE 2: Application des congés (écrasement)");

      // PHASE 2: APPLIQUER LES CONGÉS
      for (final staff in staffProvider.staffs) {
        if (staff.groupe == "Garde 24H") continue;

        print("  Traitement congés pour ${staff.nom}...");

        final timeOffQuery =
            objectBox.timeOffBox.query(TimeOff_.staff.equals(staff.id)).build();
        final timeOffs = timeOffQuery.find();
        timeOffQuery.close();

        if (timeOffs.isNotEmpty) {
          print("    ${timeOffs.length} TimeOff(s) trouvé(s)");

          for (var timeOff in timeOffs) {
            DateTime currentDate = timeOff.debut;
            while (currentDate.isBefore(timeOff.fin.add(Duration(days: 1)))) {
              // ⭐ CORRECTION CRUCIALE : Vérifier année ET mois
              if (currentDate.year == _selectedYear &&
                  currentDate.month == _selectedMonth) {
                int jour = currentDate.day;

                final activiteQuery = objectBox.activiteBox
                    .query(ActiviteJour_.staff.equals(staff.id) &
                        ActiviteJour_.jour.equals(jour))
                    .build();
                final activites = activiteQuery.find();
                activiteQuery.close();

                if (activites.isNotEmpty) {
                  String ancienStatut = activites.first.statut;
                  if (ancienStatut != 'C' && ancienStatut != 'CM') {
                    gardesEcrasees++;
                    print("      Jour $jour: $ancienStatut → C (TimeOff)");
                  }
                }

                String statutConge = _getStatutCongeFromTimeOff(timeOff);

                await activiteProvider.forceUpdateActiviteIgnoringLeave(
                  staff.id,
                  jour,
                  statutConge,
                  year: _selectedYear,
                  month: _selectedMonth,
                );
                congesAppliques++;
              }
              currentDate = currentDate.add(Duration(days: 1));
            }
          }
        }
      }

      await staffProvider.fetchStaffs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Planification automatique terminée !",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // ... afficher les compteurs comme dans ton code
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la planification: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showAddStaffDialog() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final branchProvider = Provider.of<BranchProvider>(context, listen: false);

    // 🔥 SOLUTION : FORCER LE RECHARGEMENT AVANT LE DIALOG
    await branchProvider.fetchBranches();

    // Maintenant que les branches sont chargées, on peut continuer
    final nomCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final newGroupeCtrl = TextEditingController();
    final newBranchCtrl = TextEditingController();

    // Groupes existants
    final groupesExistants = staffProvider.staffs
        .where((s) => s.groupe.isNotEmpty)
        .map((s) => s.groupe)
        .toSet()
        .toList()
      ..sort();

    groupesExistants.add("➕ Nouveau groupe...");

    String? selectedGroupe =
        groupesExistants.isNotEmpty ? groupesExistants.first : null;
    String? selectedEquipe;
    String? selectedCategorie08h16h;
    bool isCreatingNewGroupe = false;

    // Branches existantes - 🔄 CORRECTION
    bool noBranches = branchProvider.branches.isEmpty;
    Branch? selectedBranch = noBranches ? null : branchProvider.branches.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            // Déterminer les options d'affichage dynamiques
            final groupeTexte = isCreatingNewGroupe
                ? newGroupeCtrl.text.toUpperCase()
                : (selectedGroupe ?? "").toUpperCase();

            final showEquipe = groupeTexte.contains('08H-08H') ||
                groupeTexte.contains('GARDE 24H');
            final show08h16hCategorie = groupeTexte.contains('08H-16H');
            final show08h12h = groupeTexte.contains('08H-12H'); // 🆕 AJOUTT

            // Widget principal
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.person_add, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Ajouter un nouveau staff"),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOM
                    _buildTextField(nomCtrl, "Nom et Prénom *",
                        icon: Icons.person),
                    const SizedBox(height: 12),

                    // GRADE
                    _buildTextField(gradeCtrl, "Grade/Fonction *",
                        icon: Icons.work),
                    const SizedBox(height: 12),

                    // GROUPE EXISTANT / NOUVEAU
                    if (!isCreatingNewGroupe)
                      DropdownButtonFormField<String>(
                        value: selectedGroupe,
                        decoration: const InputDecoration(
                          labelText: "Groupe *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: groupesExistants.map((g) {
                          final isNew = g.startsWith("➕");
                          return DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: TextStyle(
                                color: isNew ? Colors.green : null,
                                fontWeight:
                                    isNew ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            if (val == "➕ Nouveau groupe...") {
                              isCreatingNewGroupe = true;
                              selectedGroupe = null;
                            } else {
                              selectedGroupe = val;
                            }
                          });
                        },
                      )
                    else
                      _buildTextField(newGroupeCtrl, "Nom du nouveau groupe *",
                          icon: Icons.group_add,
                          hint: "Ex: 08H-16H, 24H...",
                          suffix: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                isCreatingNewGroupe = false;
                                newGroupeCtrl.clear();
                                selectedGroupe = groupesExistants.first;
                              });
                            },
                          )),
                    const SizedBox(height: 12),

                    // Catégorie 08H-16H
                    if (show08h16hCategorie)
                      _buildCategorieSelector(
                        selectedCategorie08h16h,
                        (v) => setState(() => selectedCategorie08h16h = v),
                      ),
                    if (show08h16hCategorie) const SizedBox(height: 12),

                    // Équipe
                    if (showEquipe)
                      _buildEquipeSelector(
                        selectedEquipe,
                        (v) => setState(() => selectedEquipe = v),
                      ),
                    if (showEquipe) const SizedBox(height: 12),

                    // BRANCHE
                    if (!noBranches)
                      DropdownButtonFormField<Branch>(
                        value: selectedBranch,
                        decoration: const InputDecoration(
                          labelText: 'Branche *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_tree),
                        ),
                        items: branchProvider.branches.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(b.branchNom),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedBranch = val),
                      )
                    else
                      _buildTextField(
                          newBranchCtrl, "Créer une nouvelle branche *",
                          icon: Icons.account_tree),
                    const SizedBox(height: 12),

                    // OBSERVATIONS
                    _buildTextField(obsCtrl, "Observations",
                        icon: Icons.note, lines: 2),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text("Ajouter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // ✅ VALIDATION
                    if (nomCtrl.text.trim().isEmpty ||
                        gradeCtrl.text.trim().isEmpty) {
                      _showError("Nom et grade sont obligatoires");
                      return;
                    }

                    final groupeFinal = isCreatingNewGroupe
                        ? newGroupeCtrl.text.trim()
                        : selectedGroupe;

                    if (groupeFinal == null || groupeFinal.isEmpty) {
                      _showError("Le groupe est obligatoire");
                      return;
                    }

                    if (show08h16hCategorie &&
                        selectedCategorie08h16h == null) {
                      _showError(
                          "Choisissez une catégorie (Médical ou Administratif)");
                      return;
                    }

                    // 📹 Ajuster le grade si Médical
                    String finalGrade = gradeCtrl.text.trim();
                    if (show08h16hCategorie &&
                        selectedCategorie08h16h == 'medical' &&
                        !finalGrade.toUpperCase().contains('MÉDECIN')) {
                      finalGrade = "Médecin $finalGrade";
                    }

// 🆕 AJOUT : Forcer le grade pour 08H-12H
                    if (show08h12h &&
                        !finalGrade.toLowerCase().contains('hygiène')) {
                      finalGrade = "Agent d'hygiène $finalGrade";
                    }
                    // 🔹 Déterminer la branche
                    Branch branchToAssign;
                    if (noBranches) {
                      final name = newBranchCtrl.text.trim();
                      if (name.isEmpty) {
                        _showError("Veuillez entrer le nom de la branche");
                        return;
                      }
                      await branchProvider.addBranch(name);
                      branchToAssign = branchProvider.branches.last;
                    } else {
                      branchToAssign = selectedBranch!;
                    }

                    // 🔹 Création du staff
                    final newStaff = Staff(
                      nom: nomCtrl.text.trim(),
                      grade: finalGrade,
                      groupe: groupeFinal,
                      equipe: selectedEquipe,
                    )..branch.target = branchToAssign;

                    await staffProvider.addStaff(newStaff, []);
                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✅ ${newStaff.nom} ajouté avec succès"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nomCtrl.dispose();
    gradeCtrl.dispose();
    obsCtrl.dispose();
    newGroupeCtrl.dispose();
    newBranchCtrl.dispose();
  }

  /// 🔸 Helper - TextField standardisé
  Widget _buildTextField(TextEditingController ctrl, String label,
      {IconData? icon, String? hint, Widget? suffix, int lines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffix,
      ),
    );
  }

  /// 🔸 Helper - Sélecteur de catégorie
  Widget _buildCategorieSelector(String? selected, Function(String?) onChange) {
    final cats = [
      {
        'label': 'Médecins',
        'value': 'medical',
        'icon': Icons.medical_services,
        'color': Colors.blue
      },
      {
        'label': 'P/Administratif',
        'value': 'administratif',
        'icon': Icons.admin_panel_settings,
        'color': Colors.orange
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Catégorie (08H-16H) :",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: cats.map((c) {
            final isSelected = selected == c['value'];
            return FilterChip(
              avatar: Icon(c['icon'] as IconData,
                  color: isSelected ? Colors.white : c['color'] as Color),
              label: Text(c['label'] as String),
              selected: isSelected,
              selectedColor: c['color'] as Color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (v) => onChange(v ? c['value'] as String : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🔸 Helper - Sélecteur d’équipe
  Widget _buildEquipeSelector(String? selected, Function(String?) onChange) {
    const equipes = ['A', 'B', 'C', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Équipe :", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: equipes.map((e) {
            final isSelected = selected == e;
            return ChoiceChip(
              label: Text(e),
              selected: isSelected,
              selectedColor: _getEquipeColor(e),
              onSelected: (v) => onChange(v ? e : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🔸 Snackbar d’erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Future<void> _clearCurrentMonthData() async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: Row(
  //         children: [
  //           Icon(Icons.delete_sweep, color: Colors.orange),
  //           SizedBox(width: 8),
  //           Text("Vider ${_moisNoms[_selectedMonth - 1]} $_selectedYear"),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             "Cette action va supprimer pour ce mois uniquement :",
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           SizedBox(height: 8),
  //           Text("• Toutes les activités (G, RE, C, CM, N)"),
  //           Text("• Tous les congés (TimeOff)"),
  //           Text("• La planification sauvegardée"),
  //           SizedBox(height: 12),
  //           Container(
  //             padding: EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: Colors.blue.shade50,
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Row(
  //               children: [
  //                 Icon(Icons.info_outline, size: 16, color: Colors.blue),
  //                 SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     "Les staffs seront conservés",
  //                     style:
  //                         TextStyle(fontSize: 12, color: Colors.blue.shade700),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(ctx).pop(false),
  //           child: Text("Annuler"),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.orange,
  //             foregroundColor: Colors.white,
  //           ),
  //           onPressed: () => Navigator.of(ctx).pop(true),
  //           child: Text("Vider ce mois"),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirm != true) return;
  //
  //   try {
  //     final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  //     final objectBox = ObjectBox();
  //
  //     int activitesSupprimes = 0;
  //     int congesSupprimes = 0;
  //
  //     // 1. Supprimer les activités du mois
  //     for (final staff in staffProvider.staffs) {
  //       final activitesToDelete = staff.activites
  //           .where((a) => a.jour >= 1 && a.jour <= _daysInSelectedMonth)
  //           .toList();
  //
  //       for (var activite in activitesToDelete) {
  //         objectBox.activiteBox.remove(activite.id);
  //         activitesSupprimes++;
  //       }
  //     }
  //
  //     // 2. Supprimer les TimeOff qui chevauchent le mois
  //     final debutMois = DateTime(_selectedYear, _selectedMonth, 1);
  //     final finMois = DateTime(_selectedYear, _selectedMonth + 1, 0);
  //
  //     final allTimeOffs = objectBox.timeOffBox.getAll();
  //     for (var timeOff in allTimeOffs) {
  //       // Vérifier si le TimeOff chevauche le mois sélectionné
  //       if (timeOff.debut.isBefore(finMois.add(Duration(days: 1))) &&
  //           timeOff.fin.isAfter(debutMois.subtract(Duration(days: 1)))) {
  //         objectBox.timeOffBox.remove(timeOff.id);
  //         congesSupprimes++;
  //       }
  //     }
  //
  //     // 3. Supprimer la planification du mois
  //     final planifQuery = objectBox.planificationBox
  //         .query(Planification_.mois.equals(_selectedMonth) &
  //             Planification_.annee.equals(_selectedYear))
  //         .build();
  //     final existingPlanif = planifQuery.findFirst();
  //     planifQuery.close();
  //
  //     if (existingPlanif != null) {
  //       objectBox.planificationBox.remove(existingPlanif.id);
  //     }
  //
  //     // // 4. Nettoyer les obs des staffs
  //     // for (final staff in staffProvider.staffs) {
  //     //   if (staff.obs != null && staff.obs!.isNotEmpty) {
  //     //     staff.obs = null;
  //     //     objectBox.staffBox.put(staff);
  //     //   }
  //     // }
  //
  //     // 5. Rafraîchir
  //     await staffProvider.fetchStaffs();
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 5),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Données de ${_moisNoms[_selectedMonth - 1]} $_selectedYear supprimées",
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             SizedBox(height: 4),
  //             Text("$activitesSupprimes activités supprimées"),
  //             Text("$congesSupprimes congés supprimés"),
  //           ],
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Erreur : $e"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  /// Supprime toutes les activités avec confirmation
  Future<void> _clearAllActivitiesWithConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content:
            const Text("Voulez-vous vraiment supprimer toutes les activités ?"),
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

    if (confirm == true && context.mounted) {
      await context.read<ActiviteProvider>().clearAllActivites(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Toutes les activités ont été supprimées.")),
        );
      }
    }
  }

  /// Supprime la base de données avec confirmation
  Future<void> _clearDatabaseWithConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content:
            const Text("Voulez-vous vraiment supprimer la base de données ?"),
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

    if (confirm == true && context.mounted) {
      await context.read<ActiviteProvider>().clearAllDB(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La base de données a été vidée.")),
        );
      }
    }
  }

  /// Insère les activités avec confirmation
  Future<void> _insertActivitiesWithConfirmation(BuildContext context) async {
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
      await activiteProvider.insertActivites(
        activites,
        year: _selectedYear,
        month: _selectedMonth,
      );

      if (context.mounted) {
        final staffProvider =
            Provider.of<StaffProvider>(context, listen: false);
        await staffProvider.fetchStaffs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Toutes les activités ont été ajoutées avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'insertion: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String get monthPrefix {
    final vowels = ['a', 'e', 'i', 'o', 'u', 'h'];
    final firstLetter = _selectedMonthName[0].toLowerCase();
    if (vowels.contains(firstLetter)) {
      return "d’"; // apostrophe typographique
    } else {
      return "de ";
    }
  }

// 2️⃣ CORRECTION : Widget d'affichage des observations dans le tableau
// ============================================================================
// CORRECTION - _buildObservationCell
// Remplacez votre méthode dans TableauStaff.dart (vers ligne 3850)
// ============================================================================

// ---------------------------------------------------------------------------
// _buildObservationCell - Corrigé
// ---------------------------------------------------------------------------
  Widget _buildObservationCell(Staff staff) {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final obs = staffProvider.getObservationForStaff(staff.id) ?? '';
    final hasObs = obs.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        await _showObservationDialog(context, staff);
        if (mounted) setState(() {});
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          key: ValueKey('obs_${staff.id}_$obs'), // Force rebuild si obs change
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: hasObs ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: hasObs ? Colors.blue.shade200 : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hasObs ? Icons.note : Icons.note_add,
                  size: 12,
                  color: hasObs ? Colors.blue.shade600 : Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(hasObs ? "OBS" : "-",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasObs
                          ? Colors.blue.shade600
                          : Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const _StatRow(this.label, this.value, this.isOk);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.warning,
            color: isOk ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isOk ? Colors.black87 : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class SyncObserverMonitoringPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final observer = ObjectBoxSyncObserver();

    return Scaffold(
      appBar: AppBar(title: Text('Sync Observer Monitoring')),
      body: StreamBuilder(
        stream: Stream.periodic(Duration(seconds: 1)),
        builder: (context, snapshot) {
          final stats = observer.getStats();

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text('État'),
                  trailing: Icon(
                    stats['isRunning'] ? Icons.check_circle : Icons.cancel,
                    color: stats['isRunning'] ? Colors.green : Colors.red,
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text('Throttles actifs'),
                  trailing: Text('${stats['activeThrottles']}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text('Modifications trackées'),
                  trailing: Text('${stats['trackedChanges']}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text('Mode delta distant'),
                  trailing: Icon(
                    stats['isApplyingRemote']
                        ? Icons.cloud_download
                        : Icons.cloud_off,
                    color:
                        stats['isApplyingRemote'] ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              Divider(),
              Text('Détail par entité',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...((stats['entities'] as Map<String, int>).entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.key),
                    trailing: Text('${entry.value} modifications'),
                  ),
                );
              }).toList()),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// WIDGET STATEFUL POUR LE CONTENU DU DIALOG
// ============================================================================

class _TimeOffDialogContent extends StatefulWidget {
  final Staff staff;
  final int selectedYear;
  final int selectedMonth;
  final VoidCallback onUpdate;

  const _TimeOffDialogContent({
    required this.staff,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onUpdate,
  });

  @override
  State<_TimeOffDialogContent> createState() => _TimeOffDialogContentState();
}

class _TimeOffDialogContentState extends State<_TimeOffDialogContent> {
  // Variables pour le nouveau congé
  DateTime? dateDebut;
  DateTime? dateFin;
  int? nombreJours;
  String selectedStatut = 'C';
  bool useNombreJours = false;

  // ✅ Clé pour forcer le rebuild de la liste
  int _listRebuildKey = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ Récupérer les congés à chaque build (données fraîches)
    final timeOffs = widget.staff.timeOff.toList();

    // Calcul automatique
    if (useNombreJours && dateDebut != null && nombreJours != null) {
      dateFin = dateDebut!.add(Duration(days: nombreJours! - 1));
    } else if (!useNombreJours && dateDebut != null && dateFin != null) {
      nombreJours = dateFin!.difference(dateDebut!).inDays + 1;
    }

    return AlertDialog(
      title: Text("Gestion des congés - ${widget.staff.nom}"),
      content: SizedBox(
        width: double.minPositive, // ✅ Contrainte explicite
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ============================================================
              // SECTION 1 : LISTE DES CONGÉS EXISTANTS
              // ============================================================
              if (timeOffs.isNotEmpty) ...[
                Text(
                  "Congés existants:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200, // ✅ Hauteur fixe pour éviter les overflow
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    key: ValueKey(_listRebuildKey), // ✅ Force rebuild
                    shrinkWrap: true,
                    itemCount: timeOffs.length,
                    itemBuilder: (context, index) {
                      final timeOff = timeOffs[index];
                      final duree =
                          timeOff.fin.difference(timeOff.debut).inDays + 1;

                      return Card(
                        margin: EdgeInsets.all(4),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              timeOff.motif?.substring(0, 1).toUpperCase() ??
                                  'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            "${timeOff.motif ?? 'Congé'} ($duree jour${duree > 1 ? 's' : ''})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            "Du ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} "
                            "au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}",
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bouton éditer
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: Colors.blue, size: 18),
                                onPressed: () => _handleEdit(context, timeOff),
                              ),
                              // Bouton supprimer
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                onPressed: () =>
                                    _handleDelete(context, timeOff, index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],

              // ============================================================
              // SECTION 2 : NOUVEAU CONGÉ
              // ============================================================
              Center(
                child: Text(
                  "Nouveau congé",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
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
                        ButtonSegment(value: false, label: Text("Date à Date")),
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
              SizedBox(height: 15),

              // Sélection des dates
              _buildDateSelectors(),

              SizedBox(height: 15),

              // Type de congé
              _buildTypeSelector(),

              SizedBox(height: 15),

              // Résumé
              if (dateDebut != null && dateFin != null) _buildSummary(),
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
            onPressed: () => _handleSave(context),
            child: Text("Ajouter le congé"),
          ),
      ],
    );
  }

  // ==========================================================================
  // WIDGETS HELPERS
  // ==========================================================================

  Widget _buildDateSelectors() {
    return Row(
      children: [
        // Date début
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Date début:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              OutlinedButton.icon(
                icon: Icon(Icons.calendar_month),
                label: Text(
                  dateDebut != null
                      ? DateFormat('dd/MM/yyyy').format(dateDebut!)
                      : 'Sélectionner',
                ),
                onPressed: () async {
                  final firstDate =
                      DateTime(widget.selectedYear, widget.selectedMonth, 1);
                  final lastDate = DateTime(
                      widget.selectedYear, widget.selectedMonth + 1, 0);
                  final now = DateTime.now();

                  DateTime initialDate;
                  if (dateDebut != null) {
                    initialDate = dateDebut!;
                  } else if (now.isAfter(firstDate) &&
                      now.isBefore(lastDate.add(Duration(days: 1)))) {
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
                      if (dateFin != null && dateFin!.isBefore(date)) {
                        dateFin = date;
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 8),

        // Date fin OU Nombre de jours
        Expanded(
          child: !useNombreJours
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date fin:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    OutlinedButton.icon(
                      icon: Icon(Icons.calendar_month),
                      label: Text(
                        dateFin != null
                            ? DateFormat('dd/MM/yyyy').format(dateFin!)
                            : 'Sélectionner',
                      ),
                      onPressed: dateDebut == null
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: dateFin ??
                                    dateDebut!.add(Duration(days: 1)),
                                firstDate: dateDebut!,
                                lastDate: DateTime(widget.selectedYear,
                                    widget.selectedMonth + 1, 0),
                              );
                              if (date != null) {
                                setState(() {
                                  dateFin = date;
                                });
                              }
                            },
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nb jours:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Ex: 5",
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          nombreJours = int.tryParse(value);
                        });
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Text("Type de congé:", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['C', 'CM'].map((statut) {
            String label;
            switch (statut) {
              case 'C':
                label = 'Congé';
                break;
              case 'CM':
                label = 'Congé Maladie';
                break;
              default:
                label = statut;
            }

            return ChoiceChip(
              label: Text(
                "$statut - $label",
                style: TextStyle(
                  color: selectedStatut == statut ? Colors.white : null,
                ),
              ),
              selected: selectedStatut == statut,
              selectedColor: Theme.of(context).colorScheme.primary,
              onSelected: (bool selected) {
                setState(() {
                  selectedStatut = selected ? statut : 'C';
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Résumé du nouveau congé $selectedStatut:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Du: ${DateFormat('dd/MM/yyyy').format(dateDebut!)}"),
              Text("Au: ${DateFormat('dd/MM/yyyy').format(dateFin!)}"),
              Text("Durée: ${nombreJours!} jour${nombreJours! > 1 ? 's' : ''}"),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HANDLERS - Gestion des actions
  // ==========================================================================

  Future<void> _handleSave(BuildContext context) async {
    if (dateDebut == null || dateFin == null) return;

    try {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      final activiteProvider = ActiviteProvider();
      final objectBox = ObjectBox();

      // 1. Créer le TimeOff
      final timeOff = TimeOff(
        debut: dateDebut!,
        fin: dateFin!,
        motif: _getStatutName(selectedStatut),
      )..staff.target = widget.staff;

      objectBox.timeOffBox.put(timeOff);

      // 2. ✅ Forcer le rechargement du cache ToMany
      widget.staff.timeOff.applyToDb();

      // 3. Marquer les jours
      DateTime currentDate = dateDebut!;
      int joursModifies = 0;
      while (currentDate.isBefore(dateFin!.add(Duration(days: 1)))) {
        if (currentDate.year == widget.selectedYear &&
            currentDate.month == widget.selectedMonth) {
          await activiteProvider.forceUpdateActiviteIgnoringLeave(
            widget.staff.id,
            currentDate.day,
            selectedStatut,
            year: widget.selectedYear,
            month: widget.selectedMonth,
          );
          joursModifies++;
        }
        currentDate = currentDate.add(Duration(days: 1));
      }
      final _selectedMonth = widget.selectedMonth;
      final _selectedYear = widget.selectedYear;
      // 4. Rafraîchir
      await staffProvider.fetchStaffs();
      // 5. ✅ Rafraîchir le state du dialog
      setState(() {
        dateDebut = null;
        dateFin = null;
        nombreJours = null;
        _listRebuildKey++; // Force rebuild de la liste
      });

      // 6. Notifier le parent
      widget.onUpdate();

      // 7. Feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ ${_getStatutName(selectedStatut)} ajouté pour ${widget.staff.nom}\n"
              "$joursModifies jours modifiés",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur _handleSave: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(BuildContext context, TimeOff timeOff) async {
    await showDialog(
      context: context,
      builder: (BuildContext ctx) => _EditTimeOffDialog(
        staff: widget.staff,
        timeOff: timeOff,
        selectedYear: widget.selectedYear,
        selectedMonth: widget.selectedMonth,
      ),
    );

    // ✅ Rafraîchir après édition
    setState(() {
      _listRebuildKey++;
    });
    widget.onUpdate();
  }

  Future<void> _handleDelete(
      BuildContext context, TimeOff timeOff, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirmer la suppression"),
        content: Text(
          "Voulez-vous vraiment supprimer ce congé ?\n\n"
          "${timeOff.motif ?? 'Congé'}\n"
          "Du ${DateFormat('dd/MM/yyyy').format(timeOff.debut)} "
          "au ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final staffProvider =
            Provider.of<StaffProvider>(context, listen: false);
        final objectBox = ObjectBox();

        // Supprimer de la DB
        objectBox.timeOffBox.remove(timeOff.id);
        final _selectedYear = widget.selectedYear;
        final _selectedMonth = widget.selectedMonth;
        // Recharger
        await staffProvider.fetchStaffs();
        // ✅ Rafraîchir le state
        setState(() {
          _listRebuildKey++;
        });
        widget.onUpdate();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Congé supprimé"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("❌ Erreur suppression: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Erreur: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getStatutName(String statut) {
    switch (statut) {
      case 'C':
        return 'Congé';
      case 'CM':
        return 'Congé Maladie';
      default:
        return statut;
    }
  }
}

// ============================================================================
// DIALOG D'ÉDITION - Widget séparé
// ============================================================================

class _EditTimeOffDialog extends StatefulWidget {
  final Staff staff;
  final TimeOff timeOff;
  final int selectedYear;
  final int selectedMonth;

  const _EditTimeOffDialog({
    required this.staff,
    required this.timeOff,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<_EditTimeOffDialog> createState() => _EditTimeOffDialogState();
}

class _EditTimeOffDialogState extends State<_EditTimeOffDialog> {
  late DateTime dateDebut;
  late DateTime dateFin;
  late String motif;

  final List<String> motifsDisponibles = [
    'Congé',
    'Congé annuel',
    'Congé maladie',
    'Absence justifiée',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    dateDebut = widget.timeOff.debut;
    dateFin = widget.timeOff.fin;
    motif = widget.timeOff.motif ?? 'Congé';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Éditer le congé"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date début
          Row(
            children: [
              Text("Début:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.calendar_month),
                  label: Text(DateFormat('dd/MM/yyyy').format(dateDebut)),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateDebut,
                      firstDate: DateTime(
                          widget.selectedYear, widget.selectedMonth, 1),
                      lastDate: DateTime(
                          widget.selectedYear, widget.selectedMonth + 1, 0),
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
              Text("Fin:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          widget.selectedYear, widget.selectedMonth + 1, 0),
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
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Motif",
              border: OutlineInputBorder(),
            ),
            value: motifsDisponibles.contains(motif) ? motif : 'Congé',
            items: motifsDisponibles
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  motif = value;
                });
              }
            },
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
            try {
              final staffProvider =
                  Provider.of<StaffProvider>(context, listen: false);
              final objectBox = ObjectBox();

              // Mettre à jour
              widget.timeOff.debut = dateDebut;
              widget.timeOff.fin = dateFin;
              widget.timeOff.motif = motif;
              final _selectedYear = widget.selectedYear;
              final _selectedMonth = widget.selectedMonth;
              objectBox.timeOffBox.put(widget.timeOff);
              await staffProvider.fetchStaffs();
              // ✅ Fermer APRÈS l'update
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ Congé modifié"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              print("❌ Erreur update: $e");
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Erreur: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text("Sauvegarder"),
        ),
      ],
    );
  }
}

// ============================================================================
// EXTENSION UTILITAIRE (si nécessaire)
// ============================================================================

extension DateTimeExtension on DateTime {
  DateTime get previousMonth {
    return DateTime(year, month - 1, 1);
  }
}
