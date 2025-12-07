import 'package:flutter/material.dart';
import 'package:kenzy/Kids/claude/auth_provider_v2.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/modern_course_card_widget.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  UserModel? _user;
  String? _error;

  // Controllers pour édition inline
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // ✅ Attendre la fin du build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProviderV2>();
      final userData = authProvider.userData;

      if (userData == null) {
        setState(() {
          _error = 'Aucune donnée utilisateur disponible';
          _isLoading = false;
        });
        return;
      }

      // Construire le UserModel depuis les données brutes
      _user = UserModel.fromSupabase(userData);

      // Initialiser les controllers
      _initializeControllers();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    if (_user == null) return;

    _controllers['name'] = TextEditingController(text: _user!.name);
    _controllers['email'] = TextEditingController(text: _user!.email);
    _controllers['bio'] = TextEditingController(text: _user!.bio ?? '');
    _controllers['phoneNumber'] =
        TextEditingController(text: _user!.phoneNumber ?? '');
    _controllers['address'] =
        TextEditingController(text: _user!.location?.address ?? '');
    _controllers['city'] =
        TextEditingController(text: _user!.location?.city ?? '');
    _controllers['country'] =
        TextEditingController(text: _user!.location?.country ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToCreateCourse(),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Mes Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Élèves',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Planning',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Accueil'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sports_outlined),
                selectedIcon: Icon(Icons.sports),
                label: Text('Mes Sessions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Élèves'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Planning'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getSelectedPage()),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateCourse(),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle session'),
            )
          : null,
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return _buildSessionsPage();
      case 2:
        return _buildStudentsPage();
      case 3:
        return _buildPlanningPage();
      default:
        return _buildOverviewPage();
    }
  }

  Widget _buildOverviewPage() {
    return Consumer2<CourseProvider, AuthProviderV2>(
      builder: (context, courseProvider, authProvider, _) {
        final sessions = courseProvider.userCourses;
        final activeSessions = sessions.where((s) => s.isActive).length;
        final totalStudents = sessions.fold<int>(
          0,
          (sum, session) => sum + session.currentStudents,
        );

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.sports,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${authProvider.currentUser!.email ?? "Coach"}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Prêt pour de nouvelles sessions ?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _handleSignOut(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ResponsiveBuilder(
              builder: (context, deviceType) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildQuickStatCard(
                      context,
                      title: 'Sessions Actives',
                      value: activeSessions.toString(),
                      icon: Icons.sports,
                      color: Colors.blue,
                      width: deviceType == DeviceType.desktop ? 250 : null,
                    ),
                    _buildQuickStatCard(
                      context,
                      title: 'Total Élèves',
                      value: totalStudents.toString(),
                      icon: Icons.people,
                      color: Colors.green,
                      width: deviceType == DeviceType.desktop ? 250 : null,
                    ),
                    _buildQuickStatCard(
                      context,
                      title: 'Taux de remplissage',
                      value: sessions.isEmpty
                          ? '0%'
                          : '${((totalStudents / sessions.fold<int>(0, (sum, s) => sum + s.maxStudents)) * 100).toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                      width: deviceType == DeviceType.desktop ? 250 : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sessions à venir',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 3),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Voir le planning'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sessions.where((s) => s.isAvailableNow()).take(3).map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.sports,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        title: Text(session.title),
                        subtitle: Text(
                          '${session.currentStudents}/${session.maxStudents} participants',
                        ),
                        trailing: Chip(
                          label: Text(session.category.displayName),
                        ),
                        onTap: () => _navigateToCourseDetails(session),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsPage() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        final sessions = courseProvider.userCourses;

        if (courseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Aucune session créée',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre première session d\'entraînement',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _navigateToCreateCourse(),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une session'),
                ),
              ],
            ),
          );
        }

        return ResponsiveBuilder(
          builder: (context, deviceType) {
            final crossAxisCount = ResponsiveLayout.getCrossAxisCount(context);

            return GridView.builder(
              padding: ResponsiveLayout.getResponsivePadding(context),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return CourseCard(
                  course: session,
                  showActions: true,
                  onTap: () => _navigateToCourseDetails(session),
                  onEdit: () => _navigateToEditCourse(session),
                  onDelete: () => _confirmDeleteSession(session),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStudentsPage() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        final sessions = courseProvider.userCourses;
        final totalStudents = sessions.fold<int>(
          0,
          (sum, session) => sum + session.currentStudents,
        );

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            Text(
              'Gestion des Élèves',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalStudents élèves au total',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 24),
            ...sessions.map((session) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        session.currentStudents.toString(),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(session.title),
                    subtitle: Text(
                      '${session.currentStudents}/${session.maxStudents} participants',
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'La liste des élèves inscrits apparaîtra ici une fois le système d\'inscription implémenté.',
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildPlanningPage() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        final sessions = courseProvider.userCourses;

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            Text(
              'Planning des Sessions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ...CourseSeason.values.map((season) {
              final seasonSessions =
                  sessions.where((s) => s.season == season).toList();

              if (seasonSessions.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            season.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text('${seasonSessions.length} sessions'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...seasonSessions.map((session) => ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                session.isAvailableNow()
                                    ? Icons.check_circle
                                    : Icons.schedule,
                              ),
                            ),
                            title: Text(session.title),
                            subtitle: Text(
                              '${session.seasonStartDate.day}/${session.seasonStartDate.month} - ${session.seasonEndDate.day}/${session.seasonEndDate.month}',
                            ),
                            trailing: Text(
                              '${session.currentStudents}/${session.maxStudents}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            onTap: () => _navigateToCourseDetails(session),
                          )),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _navigateToCreateCourse() {
    // Navigation vers l'écran de création
  }

  void _navigateToEditCourse(CourseModel course) {
    // Navigation vers l'écran d'édition
  }

  void _navigateToCourseDetails(CourseModel course) {
    // Navigation vers les détails
  }

  Future<void> _confirmDeleteSession(CourseModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la session'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer "${session.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.deleteCourse(session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session supprimée avec succès')),
        );
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authProvider = context.read<AuthProviderV2>();
    Object? error;

    // Variable pour stocker le BuildContext du dialogue
    BuildContext? dialogContext;

    // Affiche le loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext innerContext) {
        // <-- On capture le BuildContext du dialogue ici
        dialogContext = innerContext;
        return const Center(
            child: CircularProgressIndicator(
          color: Colors.white70,
        ));
      },
    );

    try {
      // Attendre 3 secondes avant de lancer la déconnexion
      await Future.delayed(const Duration(seconds: 3));
      await authProvider.logout();
    } catch (e) {
      error = e;
    } finally {
      // GUARANTIE : Ferme le loader dans TOUS les cas (succès ou erreur)

      // On utilise le BuildContext interne du dialogue si disponible,
      // sinon on revient au contexte de base.
      final contextToPop = dialogContext ?? context;

      // Vérification de sécurité
      if (contextToPop.mounted) {
        // On vérifie qu'il y a quelque chose à retirer de la pile
        // L'utilisation de rootNavigator: true reste la plus sûre
        if (Navigator.of(contextToPop, rootNavigator: true).canPop()) {
          Navigator.of(contextToPop, rootNavigator: true).pop();
        }
      }
    }

    // Gérer le résultat APRÈS la fermeture du loader
    if (!context.mounted) return;

    if (error == null) {
      // Redirection après succès
      // Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Affiche une snackbar avec l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
