import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Hopital/StaffProvider.dart';
import '../Hopital/TableauStaff.dart';
import '../Hopital/features/app/presentation/pages/new_architecture_test_page.dart';
import '../Hopital/features/app/presentation/pages/supabase_data_viewer_page.dart';
import '../Hopital/features/app/presentation/pages/objectbox_data_viewer_page.dart';
import '../Hopital/features/planning/presentation/planning_composition.dart';
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

class ArchitectureChoiceScreen extends StatefulWidget {
  const ArchitectureChoiceScreen({super.key});

  @override
  State<ArchitectureChoiceScreen> createState() =>
      _ArchitectureChoiceScreenState();
}

class _ArchitectureChoiceScreenState extends State<ArchitectureChoiceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animations = List.generate(_cardData.length, (i) {
      final begin = i * 0.15;
      final end = (0.5 + i * 0.15).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(begin, end, curve: Curves.easeOutCubic),
          ),
        ),
        curve: Curves.easeOutCubic,
      );
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade800,
              Colors.indigo.shade900,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    _buildDesktopCards()
                  else
                    _buildMobileCards(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animations[0],
          builder: (context, child) => Opacity(
            opacity: _animations[0].value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _animations[0].value)),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.architecture, size: 56, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _animations[0],
          builder: (context, child) => Opacity(
            opacity: _animations[0].value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - _animations[0].value)),
              child: child,
            ),
          ),
          child: Text(
            'Kenzy Planning',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _animations[0],
          builder: (context, child) => Opacity(
            opacity: _animations[0].value,
            child: child,
          ),
          child: Text(
            'Choisissez votre interface',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _cardData.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: _buildCard(i, _cardData[i])),
        ],
      ],
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: [
        for (var i = 0; i < _cardData.length; i++) ...[
          _buildCard(i, _cardData[i]),
          if (i < _cardData.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCard(int index, _CardData data) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) => Opacity(
        opacity: _animations[index].value,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - _animations[index].value)),
          child: child,
        ),
      ),
      child: Card(
        elevation: 8,
        shadowColor: data.color.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: data.color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigate(data.page),
          child: Container(
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.color.withValues(alpha: 0.1),
                  Colors.white,
                  data.color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(data.icon, size: 40, color: data.color),
                ),
                const SizedBox(height: 20),
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: data.color.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    data.action,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _CardData {
  final MaterialColor color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final Widget page;

  const _CardData({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.page,
  });
}

final _cardData = [
  _CardData(
    color: Colors.brown,
    icon: Icons.history,
    title: 'Ancienne architecture',
    subtitle: 'Interface classique avec tableau de staff',
    action: 'Ouvrir',
    page: TableauStaffPage(),
  ),
  _CardData(
    color: Colors.indigo,
    icon: Icons.explore,
    title: 'Nouvelle architecture',
    subtitle: 'Planning par fonctionnalités (features)',
    action: 'Explorer',
    page: NewArchitectureTestPage(),
  ),
  _CardData(
    color: Colors.teal,
    icon: Icons.cloud,
    title: 'Données Supabase',
    subtitle: 'Visualiser et gérer les données distantes',
    action: 'Consulter',
    page: SupabaseDataViewerPage(),
  ),
  _CardData(
    color: Colors.orange,
    icon: Icons.storage,
    title: 'Base locale ObjectBox',
    subtitle: 'Inspecter et gérer toutes les tables locales',
    action: 'Ouvrir',
    page: ObjectBoxDataViewerPage(),
  ),
];


