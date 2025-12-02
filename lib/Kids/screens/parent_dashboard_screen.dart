import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../providers/auth_provider_dart.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/modern_course_card_widget.dart';
import '../widgets/weekly_timeline_widget.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final courseProvider = context.read<CourseProvider>();
    final childProvider = context.read<ChildEnrollmentProvider>();

    if (authProvider.user != null) {
      await Future.wait([
        courseProvider.loadCourses(refresh: true),
        childProvider.loadChildren(authProvider.user!.uid),
        childProvider.loadEnrollments(authProvider.user!.uid),
      ]);
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
        title: const Text('Dashboard Parent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.child_care_outlined),
            selectedIcon: Icon(Icons.child_care),
            label: 'Enfants',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Cours',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showAddChildDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un enfant'),
            )
          : null,
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
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.family_restroom,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Espace Parent',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Accueil'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Planning'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.child_care_outlined),
                selectedIcon: Icon(Icons.child_care),
                label: Text('Mes Enfants'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('Trouver des Cours'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getSelectedPage()),
        ],
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildPlanningPage();
      case 2:
        return _buildChildrenPage();
      case 3:
        return _buildCoursesPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Consumer3<AuthProvider, ChildEnrollmentProvider, CourseProvider>(
      builder: (context, authProvider, childProvider, courseProvider, _) {
        final children = childProvider.children;
        final enrollments = childProvider.enrollments;
        final approvedEnrollments = enrollments
            .where((e) => e.status == EnrollmentStatus.approved)
            .length;

        return ListView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, ${authProvider.user?.name ?? "Parent"}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Bienvenue sur votre espace famille',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
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
                    _buildStatCard(
                      context,
                      title: 'Enfants',
                      value: children.length.toString(),
                      icon: Icons.child_care,
                      color: Colors.blue,
                      width: deviceType == DeviceType.desktop ? 200 : null,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Cours Actifs',
                      value: approvedEnrollments.toString(),
                      icon: Icons.school,
                      color: Colors.green,
                      width: deviceType == DeviceType.desktop ? 200 : null,
                    ),
                    _buildStatCard(
                      context,
                      title: 'En Attente',
                      value: enrollments
                          .where((e) => e.status == EnrollmentStatus.pending)
                          .length
                          .toString(),
                      icon: Icons.hourglass_empty,
                      color: Colors.orange,
                      width: deviceType == DeviceType.desktop ? 200 : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            if (children.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes Enfants',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return _buildChildQuickCard(child);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cours Recommandés',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 3),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...courseProvider.courses.take(3).map((course) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CourseCard(
                    course: course,
                    onTap: () => _showCourseDetails(course),
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildPlanningPage() {
    return Consumer2<ChildEnrollmentProvider, CourseProvider>(
      builder: (context, childProvider, courseProvider, _) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));

        final schedules =
            childProvider.groupSchedulesByDate(weekStart, weekEnd);
        final coursesById = {
          for (var course in courseProvider.courses) course.id: course
        };
        final childrenById = {
          for (var child in childProvider.children) child.id: child
        };

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planning Hebdomadaire',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visualisez tous les cours de la semaine',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WeeklyTimeline(
                schedulesByDate: schedules,
                coursesById: coursesById,
                childrenById: childrenById,
                onSessionTap: (session) => _showSessionDetails(session),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChildrenPage() {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, childProvider, _) {
        final children = childProvider.children;

        if (childProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (children.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.child_care_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Aucun enfant ajouté',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez vos enfants pour gérer leurs cours',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _showAddChildDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un enfant'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveLayout.getResponsivePadding(context),
          itemCount: children.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes Enfants',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showAddChildDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
              );
            }

            final child = children[index - 1];
            return _buildChildDetailCard(child);
          },
        );
      },
    );
  }

  Widget _buildCoursesPage() {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, _) {
        if (courseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: SearchBar(
                hintText: 'Rechercher un cours...',
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  // Implémenter la recherche
                },
              ),
            ),
            Expanded(
              child: ResponsiveBuilder(
                builder: (context, deviceType) {
                  final crossAxisCount =
                      ResponsiveLayout.getCrossAxisCount(context);

                  return GridView.builder(
                    padding: ResponsiveLayout.getResponsivePadding(context),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: courseProvider.courses.length,
                    itemBuilder: (context, index) {
                      final course = courseProvider.courses[index];
                      return CourseCard(
                        course: course,
                        onTap: () => _showCourseDetails(course),
                      );
                    },
                  );
                },
              ),
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

  Widget _buildChildQuickCard(ChildModel child) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  child.photoUrl != null ? NetworkImage(child.photoUrl!) : null,
              child: child.photoUrl == null
                  ? Text(child.firstName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              child.firstName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${child.age} ans',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildDetailCard(ChildModel child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage:
                  child.photoUrl != null ? NetworkImage(child.photoUrl!) : null,
              child: child.photoUrl == null
                  ? Text(
                      child.firstName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${child.age} ans${child.schoolGrade != null ? " • ${child.schoolGrade}" : ""}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditChildDialog(child),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteChild(child),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog() {
    // Navigation vers écran d'ajout d'enfant
  }

  void _showEditChildDialog(ChildModel child) {
    // Navigation vers écran d'édition d'enfant
  }

  Future<void> _confirmDeleteChild(ChildModel child) async {
    // Dialogue de confirmation de suppression
  }

  void _showCourseDetails(CourseModel course) {
    // Navigation vers détails du cours
  }

  void _showSessionDetails(SessionSchedule session) {
    // Navigation vers détails de la session
  }
}
