import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    await provider.load(year: targetYear, month: targetMonth);
    if (provider.current != null || provider.draft != null) return;

    final objectBox = context.read<ObjectBox>();
    final query = objectBox.planificationBox
        .query()
        .order(Planification_.annee, flags: Order.descending)
        .order(Planification_.mois, flags: Order.descending)
        .build();
    final latest = query.findFirst();
    query.close();
    if (latest != null) {
      await provider.load(year: latest.annee, month: latest.mois);
      if (provider.current != null || provider.draft != null) return;
    }

    await _createDefaultPlanning(provider, objectBox, targetYear, targetMonth);
    if (mounted) setState(() {});
  }

  Future<void> _createDefaultPlanning(
    PlanningProvider provider,
    ObjectBox objectBox,
    int year,
    int month,
  ) async {
    print('[NewArchitecture] Auto-création planning par défaut $year/$month');

    final staffProvider = context.read<StaffProvider>();

    final config = RotationConfiguration(
      id: 'default-auto',
      version: 1,
      teamOrder: const ['Tous', 'Équipe A', 'Équipe B', 'Équipe C', 'Équipe D'],
      cycle: const [ShiftType.day, ShiftType.night, ShiftType.rest, ShiftType.rest],
    );

    final staffs = staffProvider.staffs;
    final staffIds = staffs.map((s) => s.id).toList();
    final staffTeams = <int, String>{};
    for (final s in staffs) {
      final team = s.equipe != null && s.equipe!.isNotEmpty
          ? 'Équipe ${s.equipe}'
          : 'Tous';
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
      print('[NewArchitecture] Planning par défaut créé');
    } catch (e) {
      print('[NewArchitecture] Erreur création planning: $e');
    }
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
