import 'dart:async';
import 'dart:io' show Platform;
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kenzy/objectBox/pages/home_Carousel.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/provider_hotel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Hopital/StaffProvider.dart';
import '../Hopital/license/MyAppBlackHole.dart';
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
import '../MyListLotties.dart';
import '../checkit/provider.dart';
import '../checkit/providerF.dart';
import 'Entity.dart';
import 'FuturisticConnectionUI.dart';
import 'MyProviders.dart';
import 'Utils/My_widgets.dart';
import 'Utils/excel.dart';
import 'classeObjectBox.dart';
import 'hash.dart';
import 'pages/ClientListScreen.dart';
import 'pages/FournisseurListScreen.dart';
import 'pages/ProduitListScreen.dart';
import 'pages/addProduct.dart';
import 'pages/facturation/FacturePage.dart';
import 'pages/facturation/FacturesListPage.dart';
import 'pages/invoice/FacturationPageUI.dart';
import 'pages/invoice/providers.dart';
import 'tests/cruds.dart' as cruds;

import '../features/planning/presentation/planning_composition.dart';
import '../features/planning/presentation/providers/planning_editor_provider.dart';
import '../features/planning/presentation/providers/planning_provider.dart';
import '../features/planning/presentation/providers/planning_sync_provider.dart';
import '../features/planning/presentation/providers/planning_validation_provider.dart';
import '../features/planning/presentation/providers/rotation_configuration_provider.dart';
import '../features/planning/presentation/widgets/planning_workspace.dart';
import '../features/planning/presentation/widgets/planning_workspace_controller.dart';

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
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: planningComposition.planningProvider),
        ChangeNotifierProvider.value(value: planningComposition.rotationConfigurationProvider),
        ChangeNotifierProvider.value(value: planningComposition.editorProvider),
        ChangeNotifierProvider.value(value: planningComposition.validationProvider),
        ChangeNotifierProvider.value(value: planningComposition.syncProvider),
        Provider.value(value: planningComposition.workspaceController),

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
            home: _PlanningPage(),
          );
        },
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
    final now = DateTime.now();
    context.read<PlanningProvider>().load(year: now.year, month: now.month);
  }
}
