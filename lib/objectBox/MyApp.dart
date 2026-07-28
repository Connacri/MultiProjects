import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:provider/provider.dart';

import '../Hopital/StaffProvider.dart';
import '../Hopital/TableauStaff.dart';
import '../Hopital/features/app/presentation/pages/new_architecture_test_page.dart';
import '../Hopital/features/app/presentation/pages/supabase_data_viewer_page.dart';
import '../Hopital/features/planning/domain/entities/rotation_configuration.dart';
import '../Hopital/features/planning/domain/entities/staff_availability.dart';
import '../Hopital/features/planning/domain/enums/shift_type.dart';
import '../Hopital/features/planning/presentation/planning_composition.dart';
import '../Hopital/features/planning/presentation/providers/planning_editor_provider.dart';
import '../Hopital/features/planning/presentation/providers/planning_provider.dart';
import '../Hopital/features/planning/presentation/providers/planning_sync_provider.dart';
import '../Hopital/features/planning/presentation/providers/planning_validation_provider.dart';
import '../Hopital/features/planning/presentation/providers/rotation_configuration_provider.dart';
import '../Hopital/features/planning/presentation/widgets/planning_workspace.dart';
import '../Hopital/features/planning/presentation/widgets/planning_workspace_controller.dart';
import '../Hopital/p2p/auto_connect_service.dart';
import '../Hopital/p2p/connection_manager.dart';
import '../Hopital/p2p/delta_generator_real.dart';
import '../Hopital/p2p/discovery_manager_broadcast.dart';
import '../Hopital/p2p/messenger/messaging_integration.dart';
import '../Hopital/p2p/messenger/messaging_manager.dart';
import '../Hopital/p2p/messenger/messaging_provider.dart';
import '../Hopital/p2p/p2p_integration.dart';
import '../Hopital/p2p/p2p_manager.dart';
import '../Hopital/p2p/sync_manager.dart';
import '../Hopital/p2p/udp_broadcast_discovery.dart';
import '../Kids/claude/auth_provider_v2.dart';
import '../Kids/providers/child_enrollment_provider.dart';
import '../Kids/providers/course_provider_complete.dart';
import '../Kids/providers/locale_provider.dart';
import '../checkit/provider.dart';
import '../checkit/providerF.dart';
import '../objectbox.g.dart';
import 'Entity.dart';
import 'MyProviders.dart';
import 'classeObjectBox.dart';
import 'pages/invoice/providers.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/provider_hotel.dart';

class MyMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final objectBox = ObjectBox();

    return Provider<ObjectBox>.value(
      value: objectBox,
      child: MyApp9(),
    );
  }
}

const int maxFailedLoadAttempts = 3;

class MyApp9 extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final objectBox = context.read<ObjectBox>();

    final planningComposition = PlanningComposition.fromStore(
      store: objectBox.store,
      snapshotBox: objectBox.planningSnapshotBox,
      assignmentBox: objectBox.planningAssignmentBox,
      rotationStateBox: objectBox.rotationStateSnapshotBox,
      planificationBox: objectBox.planificationBox,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: planningComposition.planningProvider),
        ChangeNotifierProvider.value(value: planningComposition.rotationConfigurationProvider),
        ChangeNotifierProvider.value(value: planningComposition.editorProvider),
        ChangeNotifierProvider.value(value: planningComposition.validationProvider),
        ChangeNotifierProvider.value(value: planningComposition.syncProvider),
        ChangeNotifierProvider.value(value: planningComposition.workspaceController),

        ChangeNotifierProvider(create: (_) => CrudProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => CommerceProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => CartProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => ClientProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderV2()),
        ChangeNotifierProvider(create: (_) => ChildEnrollmentProvider()),
        Provider<ObjectBox>.value(value: objectBox),
        ChangeNotifierProvider(create: (_) => ConnectionStatusProvider()),
        ChangeNotifierProvider(create: (_) => FacturationProvider()),
        ChangeNotifierProvider(create: (_) => EditableFieldProvider()),
        ChangeNotifierProvider(create: (_) => SignalementProvider()),
        ChangeNotifierProvider(create: (_) => SignalementProviderSupabase()),
        ChangeNotifierProvider(create: (_) => HotelProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => StaffProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => ActiviteProvider()),
        ChangeNotifierProvider(create: (_) => TimeOffProvider()..fetchTimeOffs()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => TypeActiviteProvider(objectBox)),
        ChangeNotifierProvider(create: (_) => PlanningHebdoProvider(objectBox)),
        ChangeNotifierProvider<P2PManager>(create: (_) => P2PManager()),
        ChangeNotifierProvider<ConnectionManager>(create: (_) => ConnectionManager()),
        ChangeNotifierProvider<SyncManager>(create: (_) => SyncManager()),
        ChangeNotifierProvider<P2PIntegration>(create: (_) => P2PIntegration()),
        ChangeNotifierProvider<DiscoveryManagerBroadcast>(create: (_) => DiscoveryManagerBroadcast()),
        ChangeNotifierProvider<MessagingManager>(create: (_) => MessagingManager()),
        ChangeNotifierProvider<AutoConnectService>(create: (_) => AutoConnectService()),
        ChangeNotifierProvider<DeltaGenerator>(create: (_) => DeltaGenerator()),
        ChangeNotifierProvider<DiscoveryManager>(create: (_) => DiscoveryManager()),
        ChangeNotifierProvider<MessagingP2PIntegration>(create: (_) => MessagingP2PIntegration()),
        ChangeNotifierProvider<MessagingProvider>(create: (_) => MessagingProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'POS',
            navigatorKey: navigatorKey,
            theme: ThemeData(
              fontFamily: 'oswald',
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData(
              fontFamily: 'oswald',
              brightness: Brightness.dark,
              primaryColor: Colors.blueGrey,
            ),
            home: const ArchitectureChoiceScreen(),
          );
        },
      ),
    );
  }
}

class ArchitectureChoiceScreen extends StatelessWidget {
  const ArchitectureChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choix de l\'architecture'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.architecture, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 24),
            Text(
              'Choisissez l\'interface',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TableauStaffPage()),
                ),
                icon: const Icon(Icons.assignment, size: 32),
                label: const Text('Ancienne architecture', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NewArchitectureTestPage()),
                ),
                icon: const Icon(Icons.explore, size: 32),
                label: const Text('Nouvelle architecture (features)', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupabaseDataViewerPage()),
                ),
                icon: const Icon(Icons.cloud, size: 32),
                label: const Text('Données Supabase', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _scheduleLoad(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning des équipes'),
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

  static bool _loaded = false;
  static void _scheduleLoad(BuildContext context) {
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

      await _createDefaultPlanning(
        context, provider, objectBox, targetYear, targetMonth);
    });
  }

  static Future<void> _createDefaultPlanning(
    BuildContext context,
    PlanningProvider provider,
    ObjectBox objectBox,
    int year,
    int month,
  ) async {
    print('[Planning] Auto-création planning par défaut $year/$month');

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
      print('[Planning] ✅ Planning par défaut créé');
    } catch (e) {
      print('[Planning] ❌ Erreur création planning par défaut: $e');
    }
  }
}
