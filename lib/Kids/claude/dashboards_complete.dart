import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider_v2.dart';

// =============================================================================
// PARENT DASHBOARD
// =============================================================================

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ParentHomeScreen(),
    ParentChildrenScreen(),
    ParentCoursesScreen(),
    ParentCalendarScreen(),
    ParentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
            icon: Icon(Icons.child_care_outlined),
            selectedIcon: Icon(Icons.child_care),
            label: 'Enfants',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendrier',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// Parent - Écran d'accueil
class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;
    final firstName = userData?['first_name'] ?? 'Parent';

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, $firstName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigation vers notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(context),
              const SizedBox(height: 24),
              _buildUpcomingClasses(context),
              const SizedBox(height: 24),
              _buildRecentActivity(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.child_care,
            title: 'Enfants',
            value: '2',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.sports,
            title: 'Cours actifs',
            value: '3',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.event,
            title: 'Cette semaine',
            value: '5',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingClasses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prochains cours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Voir tous les cours
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ClassCard(
          childName: 'Emma',
          courseName: 'Football - Débutants',
          coach: 'Coach Martin',
          date: 'Demain à 14h00',
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _ClassCard(
          childName: 'Lucas',
          courseName: 'Basketball - Intermédiaire',
          coach: 'Coach Sarah',
          date: 'Jeudi à 16h30',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _ActivityTile(
          icon: Icons.check_circle,
          title: 'Présence confirmée',
          subtitle: 'Emma - Football (Lundi 14h00)',
          time: 'Il y a 2h',
          color: Colors.green,
        ),
        _ActivityTile(
          icon: Icons.payment,
          title: 'Paiement effectué',
          subtitle: 'Inscription Lucas - Basketball',
          time: 'Hier',
          color: Colors.blue,
        ),
      ],
    );
  }
}

// Parent - Écran enfants
class ParentChildrenScreen extends StatelessWidget {
  const ParentChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes enfants'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ChildCard(
            name: 'Emma Dupont',
            age: 8,
            avatar: 'E',
            courses: ['Football', 'Tennis'],
            color: Colors.pink,
          ),
          const SizedBox(height: 12),
          _ChildCard(
            name: 'Lucas Dupont',
            age: 10,
            avatar: 'L',
            courses: ['Basketball', 'Natation'],
            color: Colors.blue,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Ajouter un enfant
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un enfant'),
      ),
    );
  }
}

// Parent - Écran cours
class ParentCoursesScreen extends StatelessWidget {
  const ParentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours disponibles'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CourseCard(
            name: 'Football - Débutants',
            coach: 'Coach Martin',
            schedule: 'Lundi & Mercredi 14h-15h30',
            price: '50€/mois',
            spots: 3,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _CourseCard(
            name: 'Basketball - Intermédiaire',
            coach: 'Coach Sarah',
            schedule: 'Mardi & Jeudi 16h-17h30',
            price: '55€/mois',
            spots: 5,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

// Parent - Écran calendrier
class ParentCalendarScreen extends StatelessWidget {
  const ParentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
      ),
      body: const Center(
        child: Text('Calendrier - À implémenter avec table_calendar'),
      ),
    );
  }
}

// Parent - Écran profil
class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: ListView(
        children: [
          _ProfileHeader(
            name: '${userData?['first_name']} ${userData?['last_name']}',
            email: userData?['email'] ?? '',
            role: 'Parent',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Moyens de paiement'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des paiements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => authProvider.logout(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COACH DASHBOARD
// =============================================================================

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CoachHomeScreen(),
    CoachClassesScreen(),
    CoachStudentsScreen(),
    CoachAttendanceScreen(),
    CoachProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Mes cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Élèves',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outlined),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Présences',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// Coach - Écran d'accueil
class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;
    final firstName = userData?['first_name'] ?? 'Coach';

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour Coach $firstName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.sports,
                    title: 'Cours actifs',
                    value: '4',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    title: 'Élèves',
                    value: '32',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    title: 'Présence moy.',
                    value: '92%',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event,
                    title: 'Prochains',
                    value: '3',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Prochaines sessions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _CoachClassCard(
              courseName: 'Football - Débutants',
              time: 'Aujourd\'hui 14h00 - 15h30',
              students: 12,
              location: 'Terrain A',
              color: Colors.blue,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nouveau cours'),
      ),
    );
  }
}

// Coach - Mes cours
class CoachClassesScreen extends StatelessWidget {
  const CoachClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes cours'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CoachClassCard(
            courseName: 'Football - Débutants',
            time: 'Lun & Mer 14h-15h30',
            students: 12,
            location: 'Terrain A',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _CoachClassCard(
            courseName: 'Football - Avancés',
            time: 'Mar & Jeu 16h-17h30',
            students: 10,
            location: 'Terrain B',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

// Coach - Élèves
class CoachStudentsScreen extends StatelessWidget {
  const CoachStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes élèves'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StudentTile(
            name: 'Emma Dupont',
            course: 'Football - Débutants',
            attendance: '95%',
          ),
          _StudentTile(
            name: 'Lucas Martin',
            course: 'Football - Débutants',
            attendance: '88%',
          ),
        ],
      ),
    );
  }
}

// Coach - Présences
class CoachAttendanceScreen extends StatelessWidget {
  const CoachAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feuille de présence'),
      ),
      body: const Center(
        child: Text('Feuille de présence - À implémenter'),
      ),
    );
  }
}

// Coach - Profil
class CoachProfileScreen extends StatelessWidget {
  const CoachProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: ListView(
        children: [
          _ProfileHeader(
            name: '${userData?['first_name']} ${userData?['last_name']}',
            email: userData?['email'] ?? '',
            role: 'Coach',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Licences & Certifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Disponibilités'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => authProvider.logout(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCHOOL DASHBOARD
// =============================================================================

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});

  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SchoolHomeScreen(),
    SchoolCoachesScreen(),
    SchoolCoursesScreen(),
    SchoolEnrollmentsScreen(),
    SchoolProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Vue d\'ensemble',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_outlined),
            selectedIcon: Icon(Icons.sports),
            label: 'Coachs',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Cours',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Inscriptions',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Club',
          ),
        ],
      ),
    );
  }
}

// School - Vue d'ensemble
class SchoolHomeScreen extends StatelessWidget {
  const SchoolHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;
    final clubName = userData?['organization_name'] ?? 'Club';

    return Scaffold(
      appBar: AppBar(
        title: Text(clubName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.sports,
                    title: 'Coachs',
                    value: '8',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.school,
                    title: 'Cours',
                    value: '15',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    title: 'Élèves',
                    value: '127',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.euro,
                    title: 'Revenus',
                    value: '6.2k€',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Activité récente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _ActivityTile(
              icon: Icons.person_add,
              title: 'Nouvelle inscription',
              subtitle: 'Emma Dupont - Football Débutants',
              time: 'Il y a 1h',
              color: Colors.green,
            ),
            _ActivityTile(
              icon: Icons.payment,
              title: 'Paiement reçu',
              subtitle: '50€ - Inscription mensuelle',
              time: 'Il y a 3h',
              color: Colors.blue,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Actions rapides'),
      ),
    );
  }
}

// School - Coachs
class SchoolCoachesScreen extends StatelessWidget {
  const SchoolCoachesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coachs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CoachTile(
            name: 'Martin Dubois',
            specialty: 'Football',
            courses: 3,
            students: 24,
          ),
          _CoachTile(
            name: 'Sarah Laurent',
            specialty: 'Basketball',
            courses: 2,
            students: 18,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Ajouter coach'),
      ),
    );
  }
}

// School - Cours
class SchoolCoursesScreen extends StatelessWidget {
  const SchoolCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les cours'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SchoolCourseCard(
            name: 'Football - Débutants',
            coach: 'Coach Martin',
            students: 12,
            maxStudents: 15,
            revenue: '600€/mois',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nouveau cours'),
      ),
    );
  }
}

// School - Inscriptions
class SchoolEnrollmentsScreen extends StatelessWidget {
  const SchoolEnrollmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscriptions'),
      ),
      body: const Center(
        child: Text('Gestion des inscriptions - À implémenter'),
      ),
    );
  }
}

// School - Profil
class SchoolProfileScreen extends StatelessWidget {
  const SchoolProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil du club'),
      ),
      body: ListView(
        children: [
          _ProfileHeader(
            name: userData?['organization_name'] ?? 'Club',
            email: userData?['email'] ?? '',
            role: 'Administration',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier les informations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Tarifs et abonnements'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Terrains et salles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => authProvider.logout(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGETS RÉUTILISABLES
// =============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String childName;
  final String courseName;
  final String coach;
  final String date;
  final Color color;

  const _ClassCard({
    required this.childName,
    required this.courseName,
    required this.coach,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            childName[0],
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(courseName),
        subtitle: Text('$coach • $date'),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: () {},
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final String name;
  final int age;
  final String avatar;
  final List<String> courses;
  final Color color;

  const _ChildCard({
    required this.name,
    required this.age,
    required this.avatar,
    required this.courses,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    avatar,
                    style: TextStyle(
                      fontSize: 24,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '$age ans',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: courses
                  .map((course) => Chip(
                        label: Text(course),
                        backgroundColor: color.withOpacity(0.1),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String name;
  final String coach;
  final String schedule;
  final String price;
  final int spots;
  final Color color;

  const _CourseCard({
    required this.name,
    required this.coach,
    required this.schedule,
    required this.price,
    required this.spots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sports, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        coach,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(schedule, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.euro, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(price, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: spots / 15,
                    backgroundColor: Colors.grey[200],
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$spots places',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: color,
              ),
              child: const Text('Inscrire mon enfant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachClassCard extends StatelessWidget {
  final String courseName;
  final String time;
  final int students;
  final String location;
  final Color color;

  const _CoachClassCard({
    required this.courseName,
    required this.time,
    required this.students,
    required this.location,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.sports, color: color),
        ),
        title: Text(courseName),
        subtitle: Text('$time • $location\n$students élèves'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final String name;
  final String course;
  final String attendance;

  const _StudentTile({
    required this.name,
    required this.course,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name[0]),
        ),
        title: Text(name),
        subtitle: Text(course),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              attendance,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Présence',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  final String name;
  final String specialty;
  final int courses;
  final int students;

  const _CoachTile({
    required this.name,
    required this.specialty,
    required this.courses,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Text(specialty),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$courses cours',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$students élèves',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class _SchoolCourseCard extends StatelessWidget {
  final String name;
  final String coach;
  final int students;
  final int maxStudents;
  final String revenue;

  const _SchoolCourseCard({
    required this.name,
    required this.coach,
    required this.students,
    required this.maxStudents,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        coach,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  revenue,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: students / maxStudents,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$students/$maxStudents',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 40,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(role),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}
