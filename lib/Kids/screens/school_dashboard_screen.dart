import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../claude/auth_provider_v2.dart';
import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/modern_course_card_widget.dart';
import 'ParentDashboard.dart';
import 'course_details_screen.dart';
import 'create_course_screen.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? _user;
  String? _error;

  // Controllers pour édition inline
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();

    // ✅ FIX : Attendre la fin du build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// ✅ Chargement sécurisé avec gestion d'erreurs
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProviderV2>();
      final courseProvider = context.read<CourseProvider>();

      final userData = authProvider.userData;
      final currentUser = authProvider.currentUser;

      if (userData == null || currentUser == null) {
        setState(() {
          _error = 'Aucune donnée utilisateur disponible';
          _isLoading = false;
        });
        return;
      }

      // Construire le UserModel depuis les données brutes
      _user = UserModel.fromSupabase(userData);

      // ✅ FIX CRITIQUE : Charger les cours de l'utilisateur
      await courseProvider.loadUserCourses(currentUser.id);

      // Initialiser les controllers
      _initializeControllers();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ [SchoolDashboard] Erreur _loadData: $e');
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

  String _getErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Le chargement prend trop de temps. Vérifiez votre connexion.';
    }
    return 'Erreur de chargement des données';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Afficher écran d'erreur si problème critique
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return AdaptiveLayout(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  /// ✅ Écran d'erreur avec retry
  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Cours')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Erreur de chargement',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Une erreur est survenue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final authProvider = context.watch<AuthProviderV2>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
        actions: [
          if (!_isLoading) // ✅ Masquer pendant chargement
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToCreateCourse(),
            ),
          _buildIconButton(
            Icons.logout,
            () => authProvider.logout(),
            GhibliTheme.sunsetOrange,
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
    final authProvider = context.watch<AuthProviderV2>();
    return Scaffold(
      appBar: AppBar(
        actions: [
          _buildIconButton(
            Icons.logout,
            () => authProvider.logout(),
            GhibliTheme.sunsetOrange,
          ),
        ],
      ),
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
      floatingActionButton: _selectedIndex == 1 && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateCourse(),
              icon: const Icon(Icons.add),
              label: const Text('Créer un cours'),
            )
          : null,
    );
  }

  Widget _getSelectedPage() {
    // ✅ Afficher loader pendant chargement initial
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des données...'),
          ],
        ),
      );
    }

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
        // ✅ Protection contre états invalides
        if (authProvider.currentUser == null) {
          return const Center(
            child: Text('Session expirée. Veuillez vous reconnecter.'),
          );
        }

        final userCourses = courseProvider.userCourses;
        final totalStudents = userCourses.fold<int>(
          0,
          (sum, course) => sum + course.currentStudents,
        );
        final activeCourses = userCourses.where((c) => c.isActive).length;

        // ✅ Récupérer le nom depuis userData
        final userName = authProvider.userData?['name'] ??
            authProvider.currentUser!.email?.split('@').first ??
            'École';

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            // Header
            Text(
              'Bienvenue, $userName',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
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

            // Section Title
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

            // ✅ FIX CRITIQUE : Gérer proprement les cours
            if (userCourses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun cours créé pour le moment',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _navigateToCreateCourse,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un cours'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // ✅ Utiliser Column au lieu du spread operator
              Column(
                children: userCourses.take(3).map((course) {
                  // ✅ Vérification de sécurité
                  if (course.id.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CourseCard(
                      key: ValueKey(course.id),
                      // ✅ Clé unique
                      course: course,
                      showActions: true,
                      onTap: () => _navigateToCourseDetails(course),
                      onEdit: () => _navigateToEditCourse(course),
                      onDelete: () => _confirmDeleteCourse(course),
                      onShare: () => _shareCourse(course),
                    ),
                  );
                }).toList(),
              ),
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

  // ... reste du code (buildMyCoursesPage, buildStatisticsPage, etc.) identique
  // Je laisse le reste inchangé pour ne pas surcharger

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

  // Statistiques et Settings identiques...
  Widget _buildStatisticsPage() {
    return const Center(child: Text('Statistiques à implémenter'));
  }

  Widget _buildSettingsPage() {
    return const Center(child: Text('Paramètres à implémenter'));
  }

  void _navigateToCreateCourse() {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Création de cours à implémenter')),
    // );
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => CreateCourseScreen()));
  }

  /// ✅ Navigation vers l'édition d'un cours
  void _navigateToEditCourse(CourseModel course) {
    if (!mounted) return;

    print('🔵 [SchoolDashboard] Navigation vers édition: ${course.id}');

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreateCourseScreen(courseToEdit: course),
      ),
    )
        .then((result) {
      print('🔵 [SchoolDashboard] Retour de l\'édition: $result');

      // ✅ Recharger les données après édition
      if (mounted) {
        _loadData();
      }
    });
  }

  /// ✅ Navigation vers les détails d'un cours
  void _navigateToCourseDetails(CourseModel course) {
    if (!mounted) return;

    print('🔵 [SchoolDashboard] Navigation vers détails: ${course.id}');

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    )
        .then((_) {
      print('🔵 [SchoolDashboard] Retour des détails');

      // ✅ Recharger les données au retour
      if (mounted) {
        _loadData();
      }
    });
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

  void _shareCourse(CourseModel course) {
    Share.share(
      'Découvrez ce cours: ${course.title}\n${course.description}',
      subject: course.title,
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
