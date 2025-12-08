import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../claude/auth_provider_v2.dart';

// =============================================================================
// CONFIGURATION STYLE GHIBLI
// =============================================================================

class GhibliTheme {
  // Couleurs inspirées des films Ghibli
  static const skyBlue = Color(0xFF87CEEB);
  static const cloudWhite = Color(0xFFF5F5DC);
  static const forestGreen = Color(0xFF90C695);
  static const sunsetOrange = Color(0xFFFFB88C);
  static const lavenderPurple = Color(0xFFB4A7D6);
  static const warmYellow = Color(0xFFFFF4B0);
  static const softPink = Color(0xFFFFB3C1);
  static const earthBrown = Color(0xFFD4A574);

  // Gradients
  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF87CEEB),
      Color(0xFFB0E0E6),
      Color(0xFFFFFACD),
    ],
  );

  static const forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF90C695),
      Color(0xFFA8D5BA),
    ],
  );

  static const sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFB88C),
      Color(0xFFFFD4A3),
      Color(0xFFFFF4B0),
    ],
  );
}

// =============================================================================
// WIDGETS RÉUTILISABLES STYLE GHIBLI
// =============================================================================

/// Nuage animé flottant - VERSION CORRIGÉE
/// Gère lui-même sa position verticale et horizontale
class FloatingCloud extends StatefulWidget {
  final double size;
  final Duration duration;
  final double delay;
  final double topPosition; // ✅ Position verticale passée en paramètre

  const FloatingCloud({
    super.key,
    this.size = 80,
    this.duration = const Duration(seconds: 8),
    this.delay = 0,
    required this.topPosition, // ✅ Obligatoire maintenant
  });

  @override
  State<FloatingCloud> createState() => _FloatingCloudState();
}

class _FloatingCloudState extends State<FloatingCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _animation = Tween<double>(
        begin: -widget.size,
        end: MediaQuery.of(context).size.width + widget.size,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ));

      Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
        if (mounted) {
          _controller.repeat();
        }
      });

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animation == null) {
      return const SizedBox.shrink();
    }

    // ✅ UN SEUL Positioned avec top ET left
    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        return Positioned(
          top: widget.topPosition, // ✅ Position verticale
          left: _animation!.value, // ✅ Position horizontale animée
          child: Opacity(
            opacity: 0.6,
            child: CustomPaint(
              size: Size(widget.size, widget.size * 0.6),
              painter: CloudPainter(),
            ),
          ),
        );
      },
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Nuage composé de cercles
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.5),
      size.height * 0.4,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      size.height * 0.5,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.5),
      size.height * 0.35,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carte style Ghibli avec animation
class GhibliCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final double elevation;

  const GhibliCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.elevation = 4,
  });

  @override
  State<GhibliCard> createState() => _GhibliCardState();
}

class _GhibliCardState extends State<GhibliCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () {
              setState(() => _isPressed = false);
              _controller.reverse();
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: widget.elevation * 2,
                offset: Offset(0, widget.elevation),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: widget.elevation,
                offset: Offset(-widget.elevation / 2, -widget.elevation / 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Avatar style Ghibli avec bordure animée
class GhibliAvatar extends StatelessWidget {
  final String initial;
  final double size;
  final Color color;

  const GhibliAvatar({
    super.key,
    required this.initial,
    this.size = 60,
    this.color = GhibliTheme.lavenderPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PARENT DASHBOARD - STYLE GHIBLI
// =============================================================================

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ParentHomeScreen(),
      const ParentChildrenScreen(),
      const ParentCoursesScreen(),
      const ParentCalendarScreen(),
      const ParentProfileScreen(),
    ];

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            _fadeController.reset();
            _fadeController.forward();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: GhibliTheme.skyBlue.withOpacity(0.3),
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
      ),
    );
  }
}

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userData = authProvider.userData;
    final firstName = userData?['first_name'] ?? 'Parent';

    return Scaffold(
      body: Stack(
        children: [
          // Fond style ciel Ghibli
          Container(
            decoration: const BoxDecoration(
              gradient: GhibliTheme.skyGradient,
            ),
          ),

          // ✅ Nuages animés - plus de Positioned externe !
          FloatingCloud(
            size: 100,
            delay: 0,
            topPosition: 60, // ✅ Position verticale en paramètre
          ),
          FloatingCloud(
            size: 80,
            delay: 2,
            duration: const Duration(seconds: 12),
            topPosition: 120, // ✅
          ),
          FloatingCloud(
            size: 120,
            delay: 4,
            duration: const Duration(seconds: 15),
            topPosition: 200, // ✅
          ),

          // Contenu
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Refresh data
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, firstName, authProvider),
                      const SizedBox(height: 30),
                      _buildWelcomeCard(context, firstName),
                      const SizedBox(height: 24),
                      _buildStatsCards(context),
                      const SizedBox(height: 30),
                      _buildUpcomingClasses(context),
                      const SizedBox(height: 30),
                      _buildRecentActivity(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String firstName, AuthProviderV2 authProvider) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                Icons.notifications_outlined,
                () {},
                Colors.white,
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                Icons.logout,
                () => authProvider.logout(),
                GhibliTheme.sunsetOrange,
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildWelcomeCard(BuildContext context, String firstName) {
    return GhibliCard(
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            GhibliAvatar(
              initial: firstName.isNotEmpty ? firstName[0] : 'P',
              size: 70,
              color: GhibliTheme.lavenderPurple,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue dans votre espace',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Suivez la progression de vos enfants',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    final stats = [
      {
        'icon': Icons.child_care,
        'label': 'Enfants',
        'value': '2',
        'color': GhibliTheme.softPink,
      },
      {
        'icon': Icons.sports_soccer,
        'label': 'Cours actifs',
        'value': '3',
        'color': GhibliTheme.forestGreen,
      },
      {
        'icon': Icons.event_available,
        'label': 'Cette semaine',
        'value': '5',
        'color': GhibliTheme.sunsetOrange,
      },
      {
        'icon': Icons.star,
        'label': 'Présences',
        'value': '94%',
        'color': GhibliTheme.warmYellow,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _AnimatedStatCard(
          icon: stat['icon'] as IconData,
          label: stat['label'] as String,
          value: stat['value'] as String,
          color: stat['color'] as Color,
          delay: index * 0.1,
        );
      },
    );
  }

  Widget _buildUpcomingClasses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prochains cours',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 10,
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Voir tout'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildClassCard(
          childName: 'Emma',
          courseName: 'Football - Débutants',
          coach: 'Coach Martin',
          date: 'Demain à 14h00',
          color: GhibliTheme.forestGreen,
        ),
        const SizedBox(height: 12),
        _buildClassCard(
          childName: 'Lucas',
          courseName: 'Basketball - Intermédiaire',
          coach: 'Coach Sarah',
          date: 'Jeudi à 16h30',
          color: GhibliTheme.sunsetOrange,
        ),
      ],
    );
  }

  Widget _buildClassCard({
    required String childName,
    required String courseName,
    required String coach,
    required String date,
    required Color color,
  }) {
    return GhibliCard(
      color: Colors.white.withOpacity(0.95),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    childName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$coach • $date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityTile(
          icon: Icons.check_circle,
          title: 'Présence confirmée',
          subtitle: 'Emma - Football (Lundi 14h00)',
          time: 'Il y a 2h',
          color: GhibliTheme.forestGreen,
        ),
        const SizedBox(height: 12),
        _buildActivityTile(
          icon: Icons.payment,
          title: 'Paiement effectué',
          subtitle: 'Inscription Lucas - Basketball',
          time: 'Hier',
          color: GhibliTheme.sunsetOrange,
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return GhibliCard(
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour ☀️';
    if (hour < 18) return 'Bon après-midi 🌤️';
    return 'Bonsoir 🌙';
  }
}

// Widget de statistique animé
class _AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double delay;

  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.delay = 0,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GhibliCard(
          color: Colors.white.withOpacity(0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder pour les autres écrans
class ParentChildrenScreen extends StatelessWidget {
  const ParentChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Écran Enfants - À implémenter'));
  }
}

class ParentCoursesScreen extends StatelessWidget {
  const ParentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Écran Cours - À implémenter'));
  }
}

class ParentCalendarScreen extends StatelessWidget {
  const ParentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Écran Calendrier - À implémenter'));
  }
}

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Écran Profil - À implémenter'));
  }
}
