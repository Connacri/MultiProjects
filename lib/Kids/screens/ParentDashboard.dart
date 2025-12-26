import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/user_model.dart';
import '../providers/auth_provider_dart.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/weekly_timeline_widget.dart';

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

  // Gradients jour/nuit
  static final dayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF87CEEB), // Sky blue
      Color(0xFFB0E0E6),
      Color(0xFFFFFACD), // Warm light
    ],
  );

  static final sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFB88C), // Sunset orange
      Color(0xFFFFD4A3),
      Color(0xFFB4A7D6).withOpacity(0.8), // Lavender touch
      Color(0xFF87CEEB).withOpacity(0.4),
    ],
  );

  static final nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF191970), // Midnight blue
      Color(0xFF2C3E50),
      Color(0xFF34495E),
      Color(0xFF1B263B).withOpacity(0.9),
    ],
  );
}

class DynamicSkyBackground extends StatefulWidget {
  final Widget child;

  const DynamicSkyBackground({required this.child, super.key});

  @override
  State<DynamicSkyBackground> createState() => _DynamicSkyBackgroundState();
}

class _DynamicSkyBackgroundState extends State<DynamicSkyBackground> {
  LinearGradient _currentGradient = GhibliTheme.dayGradient;

  @override
  void initState() {
    super.initState();
    _updateGradientBasedOnTime();

    Timer.periodic(const Duration(minutes: 30), (_) {
      if (mounted) _updateGradientBasedOnTime();
    });
  }

  void _updateGradientBasedOnTime() {
    final hour = DateTime.now().hour;
    LinearGradient target;

    if (hour >= 6 && hour < 18) {
      target = GhibliTheme.dayGradient;
    } else if (hour >= 18 && hour < 20) {
      target = GhibliTheme.sunsetGradient;
    } else {
      target = GhibliTheme.nightGradient;
    }

    if (target != _currentGradient && mounted) {
      setState(() => _currentGradient = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 30),
      decoration: BoxDecoration(gradient: _currentGradient),
      child: widget.child,
    );
  }
}

// =============================================================================
// WIDGETS RÉUTILISABLES STYLE GHIBLI
// =============================================================================

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
        child: Card(
          elevation: _isPressed ? widget.elevation - 2 : widget.elevation,
          color: widget.color ?? GhibliTheme.cloudWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// =============================================================================
// PARENT DASHBOARD PRINCIPAL OPTIMISÉ
// =============================================================================

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final ImageStorageService _imageService = ImageStorageService();

  bool _isLoadingLocation = false;
  AppLocation? _userLocation;
  List<CourseModel> _nearbyCourses = [];
  String? _errorMessage;

  // Onglets
  int _selectedTabIndex = 0;
  late TabController _tabController;

  // Filtres cours
  CourseCategory? _selectedCategory;
  double _selectedRadius = 50.0; // km
  bool _showAvailableOnly = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ============================================================================
  /// INITIALISATION DU DASHBOARD
  /// ============================================================================

  Future<void> _initializeDashboard() async {
    try {
      // 1. Charger les données utilisateur via AuthProvider
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
        });
        return;
      }

      // 2. Charger les enfants via ChildEnrollmentProvider
      final childProvider = context.read<ChildEnrollmentProvider>();
      await childProvider.loadChildren(currentUser.uid);

      // 3. Récupérer la localisation
      await _loadUserLocation(currentUser);

      // 4. Charger les cours proches
      await _loadNearbyCourses();

      // 5. Charger les horaires (timeline)
      await childProvider.loadAllSchedulesForParent(currentUser.uid);
    } catch (e) {
      print('❌ Erreur initialisation dashboard: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
      });
    }
  }

  /// ============================================================================
  /// GESTION DE LA LOCALISATION
  /// ============================================================================

  Future<void> _loadUserLocation(UserModel user) async {
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Vérifier si l'utilisateur a une localisation enregistrée
      if (user.location != null && user.location!.hasLocation) {
        _userLocation = user.location;
        print('✅ Localisation utilisateur: ${_userLocation!.address}');
      } else {
        // 2. Obtenir la localisation actuelle via LocationService
        final currentLocation = await _locationService.getCurrentUserLocation();

        if (currentLocation != null) {
          _userLocation = currentLocation;
          print('✅ Localisation actuelle: ${_userLocation!.address}');

          // 3. Proposer de sauvegarder la localisation
          if (mounted) {
            _promptToSaveLocation(currentLocation, user);
          }
        } else {
          // 4. Fallback : Position par défaut
          _userLocation = AppLocation(
            latitude: LocationService.defaultLatitude,
            longitude: LocationService.defaultLongitude,
            address: LocationService.defaultAddress,
            city: LocationService.defaultCity,
            country: LocationService.defaultCountry,
          );
          print('⚠️ Utilisation localisation par défaut');
        }
      }
    } catch (e) {
      print('❌ Erreur chargement localisation: $e');
      _userLocation = AppLocation(
        latitude: LocationService.defaultLatitude,
        longitude: LocationService.defaultLongitude,
        address: LocationService.defaultAddress,
        city: LocationService.defaultCity,
        country: LocationService.defaultCountry,
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _promptToSaveLocation(AppLocation location, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder votre localisation'),
        content: Text(
          'Votre localisation actuelle est : ${location.address}\n\n'
          'Voulez-vous la sauvegarder dans votre profil pour faciliter '
          'la recherche de cours à proximité ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveUserLocation(location, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GhibliTheme.forestGreen,
            ),
            child: const Text(
              'Sauvegarder',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserLocation(AppLocation location, UserModel user) async {
    try {
      final authProvider = context.read<AuthProvider>();
      // La méthode updateUserProfile existe dans AuthService
      // et est utilisée par AuthProvider
      // Vous devrez ajouter cette méthode dans AuthProvider si elle n'existe pas

      // Pour l'instant, on stocke juste localement
      setState(() {
        _userLocation = location;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localisation sauvegardée avec succès'),
            backgroundColor: GhibliTheme.forestGreen,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur sauvegarde localisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ============================================================================
  /// CHARGEMENT DES COURS PROCHES
  /// ============================================================================

  Future<void> _loadNearbyCourses() async {
    if (_userLocation == null) {
      print('⚠️ Localisation non disponible');
      return;
    }

    try {
      final courseProvider = context.read<CourseProvider>();

      // Utiliser loadCoursesNearby qui appelle getCoursesNearby de SupabaseCourseService
      await courseProvider.loadCoursesNearby(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radiusKm: _selectedRadius,
      );

      // Filtrer par catégorie si sélectionnée
      List<CourseModel> filteredCourses = courseProvider.courses;

      if (_selectedCategory != null) {
        filteredCourses = filteredCourses
            .where((course) => course.category == _selectedCategory)
            .toList();
      }

      // Filtrer par disponibilité si activé
      if (_showAvailableOnly) {
        filteredCourses =
            filteredCourses.where((course) => course.isAvailableNow()).toList();
      }

      // Calculer et trier par distance
      final coursesWithDistance = filteredCourses.map((course) {
        final distance = _locationService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          course.location.latitude,
          course.location.longitude,
        );
        return {'course': course, 'distance': distance};
      }).toList();

      coursesWithDistance.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      setState(() {
        _nearbyCourses = coursesWithDistance
            .map((item) => item['course'] as CourseModel)
            .toList();
      });

      print('✅ ${_nearbyCourses.length} cours chargés à proximité');
    } catch (e) {
      print('❌ Erreur chargement cours: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement cours: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ============================================================================
  /// GESTION DES ENFANTS
  /// ============================================================================

  void _showAddChildDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChildEnrollmentDialog(),
    ).then((_) {
      // Recharger après ajout
      _initializeDashboard();
    });
  }

  void _showEditChildDialog(ChildModel child) {
    showDialog(
      context: context,
      builder: (context) => ChildEnrollmentDialog(existingChild: child),
    ).then((_) {
      // Recharger après modification
      _initializeDashboard();
    });
  }

  Future<void> _confirmDeleteChild(ChildModel child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer ${child.firstName} ${child.lastName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<ChildEnrollmentProvider>();
      final success = await provider.deleteChild(child.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Enfant supprimé' : 'Erreur lors de la suppression',
            ),
            backgroundColor: success ? GhibliTheme.forestGreen : Colors.red,
          ),
        );
      }

      if (success) {
        _initializeDashboard();
      }
    }
  }

  /// ============================================================================
  /// GESTION DES INSCRIPTIONS
  /// ============================================================================

  void _showEnrollmentDialog(CourseModel course) {
    final childProvider = context.read<ChildEnrollmentProvider>();
    final children = childProvider.children;

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ajouter un enfant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EnrollmentDialog(
        course: course,
        children: children,
      ),
    );
  }

  /// ============================================================================
  /// FILTRES
  /// ============================================================================

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres de recherche'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie
                const Text(
                  'Catégorie',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CourseCategory?>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Toutes les catégories'),
                    ),
                    ...CourseCategory.values.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.displayName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),

                // Rayon de recherche
                const Text(
                  'Rayon de recherche',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _selectedRadius,
                        min: 5,
                        max: 100,
                        divisions: 19,
                        label: '${_selectedRadius.round()} km',
                        onChanged: (value) {
                          setDialogState(() => _selectedRadius = value);
                        },
                      ),
                    ),
                    Text('${_selectedRadius.round()} km'),
                  ],
                ),
                const SizedBox(height: 16),

                // Disponibilité
                CheckboxListTile(
                  title: const Text('Cours disponibles uniquement'),
                  value: _showAvailableOnly,
                  onChanged: (value) {
                    setDialogState(() => _showAvailableOnly = value ?? true);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadNearbyCourses();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GhibliTheme.forestGreen,
            ),
            child: const Text(
              'Appliquer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================================
  /// UI - BUILD
  /// ============================================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final childProvider = context.watch<ChildEnrollmentProvider>();
    final courseProvider = context.watch<CourseProvider>();

    final currentUser = authProvider.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Utilisateur non connecté'),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard Parent')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: DynamicSkyBackground(
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Bonjour, ${currentUser.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image de couverture ou gradient
                        if (currentUser.profileImages.coverImage != null)
                          Image.network(
                            currentUser.profileImages.coverImage!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  GhibliTheme.skyBlue,
                                  GhibliTheme.lavenderPurple.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        // Overlay sombre
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    // Localisation
                    IconButton(
                      icon: Icon(
                        _userLocation != null
                            ? Icons.location_on
                            : Icons.location_off,
                        color: Colors.white,
                      ),
                      onPressed: () => _loadUserLocation(currentUser),
                      tooltip: 'Actualiser localisation',
                    ),
                    // Filtres
                    IconButton(
                      icon: Badge(
                        isLabelVisible:
                            _selectedCategory != null || !_showAvailableOnly,
                        child: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _showFiltersDialog,
                      tooltip: 'Filtres',
                    ),
                    // Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            // Naviguer vers profil
                            break;
                          case 'settings':
                            // Naviguer vers paramètres
                            break;
                          case 'logout':
                            authProvider.signOut();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person),
                              SizedBox(width: 8),
                              Text('Mon profil'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings),
                              SizedBox(width: 8),
                              Text('Paramètres'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Déconnexion',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(icon: Icon(Icons.home), text: 'Accueil'),
                      Tab(icon: Icon(Icons.school), text: 'Cours'),
                      Tab(icon: Icon(Icons.child_care), text: 'Enfants'),
                      Tab(icon: Icon(Icons.calendar_today), text: 'Planning'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Accueil
                _buildHomeTab(currentUser, childProvider),

                // TAB 2: Cours
                _buildCoursesTab(),

                // TAB 3: Enfants
                _buildChildrenTab(childProvider),

                // TAB 4: Planning
                _buildPlanningTab(childProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// TAB 1: ACCUEIL - Vue d'ensemble
  Widget _buildHomeTab(UserModel user, ChildEnrollmentProvider childProvider) {
    final children = childProvider.children;

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final padding = ResponsiveLayout.getResponsivePadding(context);

        return RefreshIndicator(
          onRefresh: _initializeDashboard,
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats rapides
                _buildQuickStats(children),
                const SizedBox(height: 24),

                // Localisation
                if (_userLocation != null) _buildLocationCard(),
                const SizedBox(height: 24),

                // Cours proches
                _buildNearbyCoursesList(),
                const SizedBox(height: 24),

                // Prochaines sessions
                _buildUpcomingSessions(childProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(List<ChildModel> children) {
    return Row(
      children: [
        Expanded(
          child: GhibliCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.child_care,
                    size: 32,
                    color: GhibliTheme.softPink,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${children.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Enfants'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GhibliCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    size: 32,
                    color: GhibliTheme.forestGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_nearbyCourses.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Cours proches'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GhibliCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 32,
                    color: GhibliTheme.sunsetOrange,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Inscriptions'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return GhibliCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GhibliTheme.skyBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: GhibliTheme.skyBlue,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre localisation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userLocation!.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Ouvrir dialogue de modification de localisation
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyCoursesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cours à proximité',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_nearbyCourses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.explore_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cours trouvé à proximité',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyCourses.take(5).length,
              itemBuilder: (context, index) {
                final course = _nearbyCourses[index];
                final distance = _userLocation != null
                    ? _locationService.calculateDistance(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                        course.location.latitude,
                        course.location.longitude,
                      )
                    : 0.0;

                return _buildCourseCard(course, distance);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course, double distance) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: GhibliCard(
        onTap: () => _showCourseDetails(course),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: course.images.isNotEmpty
                  ? Image.network(
                      course.images.first.supabaseUrl ?? '',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.school, size: 48),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.school, size: 48),
                      ),
                    ),
            ),

            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Catégorie
                    Chip(
                      label: Text(
                        course.category.displayName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: GhibliTheme.warmYellow.withOpacity(0.3),
                    ),

                    const Spacer(),

                    // Distance et places
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: GhibliTheme.skyBlue),
                            const SizedBox(width: 4),
                            Text(
                              _locationService.formatDistance(distance),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.people,
                                size: 16, color: GhibliTheme.forestGreen),
                            const SizedBox(width: 4),
                            Text(
                              '${course.currentStudents}/${course.maxStudents}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessions(ChildEnrollmentProvider childProvider) {
    final schedules = childProvider.schedules;
    final today = DateTime.now();
    final upcomingSessions = schedules
        .where((s) =>
            s.isScheduledFor(today) &&
            !s.isCancelled &&
            s.timeSlot.startTime.hour >= today.hour)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prochaines sessions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (upcomingSessions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Aucune session prévue aujourd\'hui',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ...upcomingSessions.map((session) {
            return GhibliCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: GhibliTheme.forestGreen.withOpacity(0.2),
                  child: const Icon(
                    Icons.event,
                    color: GhibliTheme.forestGreen,
                  ),
                ),
                title: Text(session.timeSlot.displayTime),
                subtitle: Text('Cours ID: ${session.courseId}'),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            );
          }).toList(),
      ],
    );
  }

  /// TAB 2: COURS - Liste complète des cours
  Widget _buildCoursesTab() {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return RefreshIndicator(
          onRefresh: _loadNearbyCourses,
          child: _nearbyCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun cours disponible',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showFiltersDialog,
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Modifier les filtres'),
                      ),
                    ],
                  ),
                )
              : ResponsiveLayout.isMobile(context)
                  ? _buildCoursesListView()
                  : _buildCoursesGridView(),
        );
      },
    );
  }

  Widget _buildCoursesListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyCourses.length,
      itemBuilder: (context, index) {
        final course = _nearbyCourses[index];
        final distance = _userLocation != null
            ? _locationService.calculateDistance(
                _userLocation!.latitude,
                _userLocation!.longitude,
                course.location.latitude,
                course.location.longitude,
              )
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GhibliCard(
            onTap: () => _showCourseDetails(course),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: course.images.isNotEmpty
                      ? Image.network(
                          course.images.first.supabaseUrl ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.school, size: 32),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.school, size: 32),
                        ),
                ),
                const SizedBox(width: 12),

                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(
                              course.category.displayName,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 14),
                            label: Text(
                              _locationService.formatDistance(distance),
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bouton inscription
                Column(
                  children: [
                    if (course.price != null)
                      Text(
                        '${course.price!.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showEnrollmentDialog(course),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GhibliTheme.forestGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Inscrire',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.getCrossAxisCount(context),
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _nearbyCourses.length,
      itemBuilder: (context, index) {
        final course = _nearbyCourses[index];
        final distance = _userLocation != null
            ? _locationService.calculateDistance(
                _userLocation!.latitude,
                _userLocation!.longitude,
                course.location.latitude,
                course.location.longitude,
              )
            : 0.0;

        return _buildCourseCard(course, distance);
      },
    );
  }

  void _showCourseDetails(CourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourseDetailsSheet(
        course: course,
        distance: _userLocation != null
            ? _locationService.calculateDistance(
                _userLocation!.latitude,
                _userLocation!.longitude,
                course.location.latitude,
                course.location.longitude,
              )
            : null,
        onEnroll: () {
          Navigator.pop(context);
          _showEnrollmentDialog(course);
        },
      ),
    );
  }

  /// TAB 3: ENFANTS - Gestion des enfants
  Widget _buildChildrenTab(ChildEnrollmentProvider childProvider) {
    final children = childProvider.children;

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final padding = ResponsiveLayout.getResponsivePadding(context);

        return Column(
          children: [
            // Header avec bouton ajout
            Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mes enfants',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddChildDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GhibliTheme.forestGreen,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des enfants
            Expanded(
              child: children.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.child_care_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun enfant enregistré',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showAddChildDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un enfant'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: padding,
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        final child = children[index];
                        return _buildChildCard(child);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GhibliCard(
        onTap: () => _showEditChildDialog(child),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo
              Hero(
                tag: 'child_${child.id}',
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: child.photoUrl != null
                      ? NetworkImage(child.photoUrl!)
                      : null,
                  child: child.photoUrl == null
                      ? Text(
                          child.firstName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${child.firstName} ${child.lastName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          child.gender == ChildGender.male
                              ? Icons.boy
                              : child.gender == ChildGender.female
                                  ? Icons.girl
                                  : Icons.person,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${child.age} ans',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (child.schoolGrade != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.school,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            child.schoolGrade!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Né(e) le ${DateFormat('dd/MM/yyyy').format(child.dateOfBirth)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: GhibliTheme.skyBlue),
                    onPressed: () => _showEditChildDialog(child),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteChild(child),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TAB 4: PLANNING - Timeline hebdomadaire
  Widget _buildPlanningTab(ChildEnrollmentProvider childProvider) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final schedulesByDate =
        childProvider.groupSchedulesByDate(weekStart, weekEnd);

    // Note: Vous devrez créer des maps pour coursesById et childrenById
    final coursesById = <String, CourseModel>{};
    final childrenById = <String, ChildModel>{};

    for (var child in childProvider.children) {
      childrenById[child.id] = child;
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Planning de la semaine',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _initializeDashboard(),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
            ],
          ),
        ),

        // Timeline
        Expanded(
          child: childProvider.schedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune session planifiée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : WeeklyTimeline(
                  schedulesByDate: schedulesByDate,
                  coursesById: coursesById,
                  childrenById: childrenById,
                  onSessionTap: (session) {
                    // Afficher détails de la session
                  },
                ),
        ),
      ],
    );
  }
}

// =============================================================================
// DIALOGUES
// =============================================================================

/// Dialogue d'inscription à un cours
class EnrollmentDialog extends StatefulWidget {
  final CourseModel course;
  final List<ChildModel> children;

  const EnrollmentDialog({
    super.key,
    required this.course,
    required this.children,
  });

  @override
  State<EnrollmentDialog> createState() => _EnrollmentDialogState();
}

class _EnrollmentDialogState extends State<EnrollmentDialog> {
  String? _selectedChildId;
  bool _isLoading = false;

  Future<void> _handleEnrollment() async {
    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un enfant'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer l'inscription
      final enrollment = EnrollmentModel(
        id: '',
        courseId: widget.course.id,
        childId: _selectedChildId!,
        parentId: currentUser.uid,
        status: EnrollmentStatus.pending,
        enrolledAt: DateTime.now(),
        paymentStatus: PaymentStatus.pending,
        totalAmount: widget.course.price,
        paidAmount: 0,
      );

      // TODO: Sauvegarder via ChildEnrollmentProvider
      // await childProvider.createEnrollment(enrollment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie'),
            backgroundColor: GhibliTheme.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Inscription - ${widget.course.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionnez l\'enfant à inscrire:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...widget.children.map((child) {
            return RadioListTile<String>(
              title: Text('${child.firstName} ${child.lastName}'),
              subtitle: Text('${child.age} ans'),
              value: child.id,
              groupValue: _selectedChildId,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedChildId = value);
                    },
            );
          }).toList(),
          const SizedBox(height: 16),
          if (widget.course.price != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GhibliTheme.warmYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Prix:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.course.price!.toStringAsFixed(0)} DA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleEnrollment,
          style: ElevatedButton.styleFrom(
            backgroundColor: GhibliTheme.forestGreen,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Confirmer',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

/// Dialogue d'ajout/modification d'enfant
class ChildEnrollmentDialog extends StatefulWidget {
  final ChildModel? existingChild;

  const ChildEnrollmentDialog({super.key, this.existingChild});

  @override
  State<ChildEnrollmentDialog> createState() => _ChildEnrollmentDialogState();
}

class _ChildEnrollmentDialogState extends State<ChildEnrollmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final ImageStorageService _imageService = ImageStorageService();

  DateTime? _birthDate;
  ChildGender? _gender;
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingChild != null) {
      _firstNameCtrl.text = widget.existingChild!.firstName;
      _lastNameCtrl.text = widget.existingChild!.lastName;
      _gradeCtrl.text = widget.existingChild!.schoolGrade ?? '';
      _birthDate = widget.existingChild!.dateOfBirth;
      _gender = widget.existingChild!.gender;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Appareil photo'),
              onTap: () async {
                Navigator.pop(context);
                await _selectImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () async {
                Navigator.pop(context);
                await _selectImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() ||
        _birthDate == null ||
        _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final childProvider = context.read<ChildEnrollmentProvider>();

      // Upload photo si nouvelle
      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await _imageService.uploadChildPhoto(
          imageFile: _pickedImage!,
          childId: widget.existingChild?.id ?? DateTime.now().toString(),
        );
      }

      final isEdit = widget.existingChild != null;

      bool success;
      if (isEdit) {
        // Mise à jour
        success = await childProvider.updateChild(
          childId: widget.existingChild!.id,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          dateOfBirth: _birthDate!,
          gender: _gender!,
          schoolGrade:
              _gradeCtrl.text.trim().isEmpty ? null : _gradeCtrl.text.trim(),
        );
      } else {
        // Création
        success = await childProvider.addChild(
          parentId: currentUser.uid,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          dateOfBirth: _birthDate!,
          gender: _gender!,
          photo: _pickedImage,
          schoolGrade:
              _gradeCtrl.text.trim().isEmpty ? null : _gradeCtrl.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isEdit ? 'Enfant modifié' : 'Enfant ajouté')
                  : 'Erreur lors de l\'opération',
            ),
            backgroundColor: success ? GhibliTheme.forestGreen : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingChild != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifier l\'enfant' : 'Ajouter un enfant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (widget.existingChild?.photoUrl != null
                          ? NetworkImage(widget.existingChild!.photoUrl!)
                          : null),
                  child: _pickedImage == null &&
                          widget.existingChild?.photoUrl == null
                      ? const Icon(Icons.add_a_photo, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Prénom
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Nom
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Niveau scolaire
              TextFormField(
                controller: _gradeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Niveau scolaire (facultatif)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Date de naissance
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ??
                        DateTime.now().subtract(const Duration(days: 365 * 5)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _birthDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Sélectionner'
                        : DateFormat('dd/MM/yyyy').format(_birthDate!),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Genre
              DropdownButtonFormField<ChildGender>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                ),
                items: ChildGender.values
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g == ChildGender.male
                              ? 'Garçon'
                              : g == ChildGender.female
                                  ? 'Fille'
                                  : 'Autre'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? 'Requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: GhibliTheme.forestGreen,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEdit ? 'Enregistrer' : 'Ajouter',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

/// Bottom Sheet pour les détails d'un cours
class CourseDetailsSheet extends StatelessWidget {
  final CourseModel course;
  final double? distance;
  final VoidCallback onEnroll;

  const CourseDetailsSheet({
    super.key,
    required this.course,
    this.distance,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = LocationService();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Images
                    if (course.images.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: course.images.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                course.images[index].supabaseUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.school, size: 64),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Catégorie et saison
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(course.category.displayName),
                          backgroundColor:
                              GhibliTheme.warmYellow.withOpacity(0.3),
                        ),
                        Chip(
                          label: Text(course.season.displayName),
                          backgroundColor: GhibliTheme.skyBlue.withOpacity(0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      course.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations pratiques
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Localisation',
                      value: course.location.address,
                    ),
                    if (distance != null)
                      _buildInfoRow(
                        icon: Icons.directions,
                        label: 'Distance',
                        value: locationService.formatDistance(distance!),
                      ),
                    _buildInfoRow(
                      icon: Icons.people,
                      label: 'Places',
                      value: '${course.currentStudents}/${course.maxStudents}',
                    ),
                    if (course.price != null)
                      _buildInfoRow(
                        icon: Icons.payment,
                        label: 'Prix',
                        value: '${course.price!.toStringAsFixed(0)} DA',
                      ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Période',
                      value:
                          '${DateFormat('dd/MM/yyyy').format(course.seasonStartDate)} - ${DateFormat('dd/MM/yyyy').format(course.seasonEndDate)}',
                    ),

                    const SizedBox(height: 24),

                    // Bouton d'inscription
                    ElevatedButton(
                      onPressed: course.isAvailableNow() ? onEnroll : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GhibliTheme.forestGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        course.isAvailableNow()
                            ? 'Inscrire mon enfant'
                            : 'Complet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: GhibliTheme.skyBlue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
