import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../claude/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../providers/course_provider_complete.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/modern_course_card_widget.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserCourses();
  }

  Future<void> _loadUserCourses() async {
    final authProvider = context.read<AuthProviderV2>();
    final courseProvider = context.read<CourseProvider>();

    if (authProvider.currentUser != null) {
      await courseProvider.loadUserCourses(authProvider.currentUser!.id);
    }
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
        title: const Text('Gestion des Cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateCourse(),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Mes Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
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
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Tableau de bord'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: Text('Mes Cours'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Statistiques'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Paramètres'),
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
              label: const Text('Créer un cours'),
            )
          : null,
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return _buildMyCoursesPage();
      case 2:
        return _buildStatisticsPage();
      case 3:
        return _buildSettingsPage();
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDashboardOverview() {
    return Consumer2<CourseProvider, AuthProviderV2>(
      builder: (context, courseProvider, authProvider, _) {
        final userCourses = courseProvider.userCourses;
        final totalStudents = userCourses.fold<int>(
          0,
          (sum, course) => sum + course.currentStudents,
        );
        final activeCourses = userCourses.where((c) => c.isActive).length;

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            Text(
              'Bienvenue, ${authProvider.currentUser!.role ?? "École"}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ResponsiveBuilder(
              builder: (context, deviceType) {
                final isDesktop = deviceType == DeviceType.desktop;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isDesktop ? 250 : double.infinity,
                      child: _buildStatCard(
                        context,
                        title: 'Total Cours',
                        value: userCourses.length.toString(),
                        icon: Icons.school,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 250 : double.infinity,
                      child: _buildStatCard(
                        context,
                        title: 'Cours Actifs',
                        value: activeCourses.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: isDesktop ? 250 : double.infinity,
                      child: _buildStatCard(
                        context,
                        title: 'Total Élèves',
                        value: totalStudents.toString(),
                        icon: Icons.people,
                        color: Colors.orange,
                      ),
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
                  'Cours Récents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...userCourses.take(3).map((course) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CourseCard(
                    course: course,
                    showActions: true,
                    onTap: () => _navigateToCourseDetails(course),
                    onEdit: () => _navigateToEditCourse(course),
                    onDelete: () => _confirmDeleteCourse(course),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesPage() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        final courses = courseProvider.userCourses;

        if (courseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Aucun cours créé',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre premier cours',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _navigateToCreateCourse(),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un cours'),
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
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  course: course,
                  showActions: true,
                  onTap: () => _navigateToCourseDetails(course),
                  onEdit: () => _navigateToEditCourse(course),
                  onDelete: () => _confirmDeleteCourse(course),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsPage() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        final courses = courseProvider.userCourses;

        final totalRevenue = courses.fold<double>(
          0,
          (sum, course) => sum + ((course.price ?? 0) * course.currentStudents),
        );

        final coursesByCategory = <CourseCategory, int>{};
        for (var course in courses) {
          coursesByCategory[course.category] =
              (coursesByCategory[course.category] ?? 0) + 1;
        }

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenu Total Estimé',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${totalRevenue.toStringAsFixed(2)} EUR',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cours par Catégorie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...coursesByCategory.entries.map((entry) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(entry.key.displayName),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: ResponsiveLayout.getResponsivePadding(context),
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cloud),
                title: const Text('Usage Cloud'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCloudUsageDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleSignOut(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToCreateCourse() {
    // Navigation vers l'écran de création de cours
  }

  void _navigateToEditCourse(CourseModel course) {
    // Navigation vers l'écran d'édition de cours
  }

  void _navigateToCourseDetails(CourseModel course) {
    // Navigation vers les détails du cours
  }

  Future<void> _confirmDeleteCourse(CourseModel course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${course.title}" ?'),
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
      await courseProvider.deleteCourse(course.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours supprimé avec succès')),
        );
      }
    }
  }

  void _showCloudUsageDialog() {
    final courseProvider = context.read<CourseProvider>();
    final stats = courseProvider.cloudUsageStats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usage Cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider actif: ${stats['activeProvider']}'),
            const SizedBox(height: 8),
            Text('Opérations aujourd\'hui: ${stats['operationsToday']}'),
            const SizedBox(height: 8),
            Text(
                'Quota utilisé: ${stats['quotaUsagePercentage'].toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats['quotaUsagePercentage'] / 100,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
