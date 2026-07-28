import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../objectBox/Entity.dart';
import '../../../../../objectBox/classeObjectBox.dart';
import '../../../../../objectbox.g.dart';
import '../../../../StaffProvider.dart';
import '../../../planning/domain/entities/rotation_configuration.dart';
import '../../../planning/domain/entities/staff_availability.dart';
import '../../../planning/domain/enums/shift_type.dart';
import '../../../planning/presentation/providers/planning_editor_provider.dart';
import '../../../planning/presentation/providers/planning_provider.dart';
import '../../../planning/presentation/providers/planning_sync_provider.dart';
import '../../../planning/presentation/providers/planning_validation_provider.dart';
import '../../../planning/presentation/providers/rotation_configuration_provider.dart';
import '../../../planning/presentation/widgets/planning_workspace.dart';
import '../../../planning/presentation/widgets/planning_workspace_controller.dart';

class NewArchitectureTestPage extends StatefulWidget {
  const NewArchitectureTestPage({super.key});

  @override
  State<NewArchitectureTestPage> createState() => _NewArchitectureTestPageState();
}

class _NewArchitectureTestPageState extends State<NewArchitectureTestPage> {
  static bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlanning());
    }
  }

  Future<void> _loadPlanning() async {
    final now = DateTime.now();
    final targetYear = now.year;
    final targetMonth = now.month;
    final provider = context.read<PlanningProvider>();

    // 1) Essayer le mois courant dans les nouveaux snapshots
    await provider.load(year: targetYear, month: targetMonth);
    if (provider.current != null || provider.draft != null) return;

    // 2) Chercher le dernier planification existant (ancienne archi)
    final objectBox = context.read<ObjectBox>();
    final latest = objectBox.planificationBox
        .query()
        .order(Planification_.annee, flags: Order.descending)
        .order(Planification_.mois, flags: Order.descending)
        .build()
        .findFirst();
    if (latest != null) {
      // Essayer de charger un nouveau snapshot pour ce mois
      await provider.load(year: latest.annee, month: latest.mois);
      if (provider.current != null || provider.draft != null) return;

      // Pas de nouveau snapshot → générer à partir de l'ancien planification
      print('[NewArchitecture] Migration ancien planification ${latest.annee}/${latest.mois}');
      await _createDefaultPlanning(provider, objectBox, latest.annee, latest.mois, ancien: latest);
      if (provider.current != null || provider.draft != null) return;
    }

    // 3) Rien du tout → créer un planning par défaut pour le mois courant
    await _createDefaultPlanning(provider, objectBox, targetYear, targetMonth);
    if (mounted) setState(() {});
  }

  Future<void> _createDefaultPlanning(
    PlanningProvider provider,
    ObjectBox objectBox,
    int year,
    int month, {
    Planification? ancien,
  }) async {
    final isMigration = ancien != null;
    print('[NewArchitecture] ${isMigration ? "Migration" : "Création"} planning $year/$month');

    final staffProvider = context.read<StaffProvider>();

    // Lire l'ordre des équipes depuis l'ancien planification si disponible
    final teamOrder = isMigration
        ? ancien.ordreEquipes.isEmpty
            ? ['Tous', 'Équipe A', 'Équipe B', 'Équipe C', 'Équipe D']
            : ancien.ordreEquipes.split(',').map((s) => s.trim()).toList()
        : ['Tous', 'Équipe A', 'Équipe B', 'Équipe C', 'Équipe D'];

    final config = RotationConfiguration(
      id: 'default-auto',
      version: 1,
      teamOrder: teamOrder,
      cycle: const [ShiftType.day, ShiftType.night, ShiftType.rest, ShiftType.rest],
    );

    final staffs = staffProvider.staffs;
    final staffIds = staffs.map((s) => s.id).toList();
    final staffTeams = <int, String>{};
    for (final s in staffs) {
      final team = _resolveTeam(s, teamOrder, isMigration);
      staffTeams[s.id] = team;
    }

    final availability = <StaffAvailability>[];
    for (final timeOff in objectBox.timeOffBox.getAll()) {
      if (timeOff.fin.isBefore(DateTime(year, month, 1))) continue;
      if (timeOff.debut.isAfter(DateTime(year, month + 1, 0))) continue;
      availability.add(StaffAvailability(
        staffId: timeOff.staff.targetId,
        startDate: timeOff.debut,
        endDate: timeOff.fin,
        type: StaffAvailabilityType.leave,
        note: timeOff.motif,
      ));
    }

    try {
      await provider.generate(
        year: year,
        month: month,
        configuration: config,
        staffIds: staffIds,
        staffTeams: staffTeams,
        availability: availability,
      );
      print('[NewArchitecture] Planning créé');
    } catch (e) {
      print('[NewArchitecture] Erreur création planning: $e');
    }
  }

  String _resolveTeam(Staff s, List<String> teamOrder, bool isMigration) {
    if (isMigration) {
      if (s.groupe.isNotEmpty) {
        final match = teamOrder.firstWhere(
          (t) => t.toLowerCase().contains(s.groupe.toLowerCase()),
          orElse: () => '',
        );
        if (match.isNotEmpty) return match;
      }
      final equipe = s.equipe ?? '';
      if (equipe.isNotEmpty) {
        final match = teamOrder.firstWhere(
          (t) => t.toLowerCase().contains(equipe.toLowerCase()),
          orElse: () => '',
        );
        if (match.isNotEmpty) return match;
      }
      return teamOrder.first;
    }
    final equipe = s.equipe ?? '';
    return equipe.isNotEmpty ? 'Équipe $equipe' : 'Tous';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle architecture'),
      ),
      body: Consumer3<PlanningProvider, RotationConfigurationProvider,
          PlanningSyncProvider>(
        builder: (context, planningProvider, rotationProvider, syncProvider, _) {
          return PlanningWorkspace(
            planningProvider: planningProvider,
            rotationProvider: rotationProvider,
            editorProvider: context.read<PlanningEditorProvider>(),
            validationProvider: context.read<PlanningValidationProvider>(),
            workspaceController: context.read<PlanningWorkspaceController>(),
            syncProvider: syncProvider,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _loaded = false;
    super.dispose();
  }
}
