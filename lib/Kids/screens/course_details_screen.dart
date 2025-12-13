import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../providers/course_provider_complete.dart';
import '../services/responsive_layout_helper.dart';
import 'create_course_screen.dart';

/// Écran de détails d'un cours avec toutes les informations
class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  int _currentImageIndex = 0;
  late CourseModel _course;

  // ✅ Contrôleurs pour le carousel
  late PageController _pageController;
  Timer? _autoScrollTimer;

  // ✅ Configuration auto-scroll
  static const Duration _autoScrollDuration = Duration(seconds: 4);
  static const Duration _animationDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _pageController = PageController(initialPage: 0);

    // ✅ Démarrer l'auto-scroll si plusieurs images
    if (_course.images.length > 1) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ Auto-scroll timer
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (!mounted) return;

      final nextPage = (_currentImageIndex + 1) % _course.images.length;

      _pageController.animateToPage(
        nextPage,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _pauseAutoScroll() {
    _stopAutoScroll();
    // Redémarrer après 10 secondes d'inactivité
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _course.images.length > 1) {
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: ResponsiveBuilder(
              builder: (context, deviceType) {
                if (deviceType == DeviceType.desktop) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  /// AppBar avec images en carousel
  Widget _buildAppBar() {
    final hasImages = _course.images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background:
            hasImages ? _buildImageCarousel() : _buildPlaceholderImage(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCourse,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ Carousel d'images avec auto-scroll
  Widget _buildImageCarousel() {
    return GestureDetector(
      onTap: _pauseAutoScroll, // Pause quand l'utilisateur interagit
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carousel principal
          PageView.builder(
            controller: _pageController,
            itemCount: _course.images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              final image = _course.images[index];
              return CachedNetworkImage(
                imageUrl: image.supabaseUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) {
                  return _buildPlaceholderImage();
                },
              );
            },
          ),

          // ✅ Boutons de navigation (gauche/droite)
          if (_course.images.length > 1) ...[
            // Bouton gauche
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    _pauseAutoScroll();
                    final prevPage =
                        (_currentImageIndex - 1 + _course.images.length) %
                            _course.images.length;
                    _pageController.animateToPage(
                      prevPage,
                      duration: _animationDuration,
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                ),
              ),
            ),

            // Bouton droite
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    _pauseAutoScroll();
                    final nextPage =
                        (_currentImageIndex + 1) % _course.images.length;
                    _pageController.animateToPage(
                      nextPage,
                      duration: _animationDuration,
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],

          // Indicateur de page (points)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _course.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),

          // Gradient overlay en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Image placeholder si pas d'images
  Widget _buildPlaceholderImage() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.school,
          size: 80,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Layout mobile
  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoCards(),
          const SizedBox(height: 24),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildStatsSection(),
          const SizedBox(height: 80), // Espace pour le bottom bar
        ],
      ),
    );
  }

  /// Layout desktop
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildLocationSection(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _buildInfoCards(),
                const SizedBox(height: 24),
                _buildStatsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Header avec titre, badges ET galerie horizontale d'images
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text(
          _course.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(
                Icons.category,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(_course.category.displayName),
            ),
            Chip(
              avatar: Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              label: Text(_course.season.displayName),
            ),
            if (_course.price != null)
              Chip(
                avatar: Icon(
                  Icons.euro,
                  size: 16,
                  color: Colors.green,
                ),
                label: Text(
                    '${_course.price!.toStringAsFixed(2)} ${_course.currency}'),
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
            Chip(
              label: Text(
                _course.isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: _course.isActive ? Colors.green : Colors.grey,
                ),
              ),
              backgroundColor: _course.isActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
          ],
        ),

        // ✅ NOUVELLE GALERIE HORIZONTALE D'IMAGES
        if (_course.images.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildHorizontalImageGallery(),
        ],
      ],
    );
  }

  /// ✅ Galerie horizontale des images (thumbnails cliquables)
  Widget _buildHorizontalImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Galerie (${_course.images.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Liste horizontale des thumbnails
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _course.images.length,
            itemBuilder: (context, index) {
              final image = _course.images[index];
              final isSelected = index == _currentImageIndex;

              return GestureDetector(
                onTap: () {
                  // ✅ Cliquer sur thumbnail → scroll vers cette image
                  _pauseAutoScroll();
                  _pageController.animateToPage(
                    index,
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: image.supabaseUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 32),
                          ),
                        ),

                        // Badge numéro
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Overlay si sélectionné
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Info cards avec prix et durée
  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.euro,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prix',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course.price != null
                        ? '${_course.price!.toStringAsFixed(2)} ${_course.currency}'
                        : 'Gratuit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _course.price != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.green,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Durée',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDurationText(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Description du cours
  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _course.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Période',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateRange(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
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

  /// Section localisation
  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Localisation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_course.location.address),
            if (_course.location.city != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_course.location.city}${_course.location.country != null ? ', ${_course.location.country}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.map),
              label: const Text('Voir sur la carte'),
            ),
          ],
        ),
      ),
    );
  }

  /// Section statistiques
  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Capacité maximale', '${_course.maxStudents} élèves'),
            _buildStatRow('Places occupées', '${_course.currentStudents}'),
            _buildStatRow('Places disponibles', '${_course.availableSpots}'),
            _buildStatRow(
              'Taux de remplissage',
              '${(_course.currentStudents / _course.maxStudents * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Actions en bas de l'écran
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editCourse,
                icon: const Icon(Icons.edit),
                label: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _course.isActive ? _deactivateCourse : _activateCourse,
                icon: Icon(
                    _course.isActive ? Icons.visibility_off : Icons.visibility),
                label: Text(_course.isActive ? 'Désactiver' : 'Activer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helpers
  String _formatDateRange() {
    final start = _course.seasonStartDate;
    final end = _course.seasonEndDate;
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  String _getDurationText() {
    final duration = _course.seasonEndDate.difference(_course.seasonStartDate);
    final days = duration.inDays;
    if (days < 30) {
      return '$days jours';
    } else if (days < 365) {
      final months = (days / 30).round();
      return '$months mois';
    } else {
      final years = (days / 365).round();
      return '$years an${years > 1 ? 's' : ''}';
    }
  }

  /// Actions
  void _shareCourse() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage du cours: ${_course.title}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editCourse();
        break;
      case 'delete':
        _deleteCourse();
        break;
    }
  }

  Future<void> _editCourse() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateCourseScreen(courseToEdit: _course),
      ),
    );

    if (result == true && mounted) {
      // Recharger le cours
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.loadCourseById(_course.id);

      if (courseProvider.selectedCourse != null) {
        setState(() {
          _course = courseProvider.selectedCourse!;
        });
      }
    }
  }

  Future<void> _deleteCourse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${_course.title}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final courseProvider = context.read<CourseProvider>();
      final success = await courseProvider.deleteCourse(_course.id);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(); // Retour au dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cours supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                courseProvider.error ?? 'Erreur lors de la suppression',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _activateCourse() async {
    final courseProvider = context.read<CourseProvider>();
    final success = await courseProvider.updateCourse(
      courseId: _course.id,
      isActive: true,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _course = _course.copyWith(isActive: true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours activé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deactivateCourse() async {
    final courseProvider = context.read<CourseProvider>();
    final success = await courseProvider.updateCourse(
      courseId: _course.id,
      isActive: false,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _course = _course.copyWith(isActive: false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours désactivé'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _openInMaps() {
    // TODO: Implémenter l'ouverture dans Google Maps/Apple Maps
    final lat = _course.location.latitude;
    final lng = _course.location.longitude;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouvrir: $lat, $lng dans Maps'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
