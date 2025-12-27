import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/Kids/claude/auth_provider_v2.dart';
import 'package:provider/provider.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/user_model.dart';
import '../providers/child_enrollment_provider.dart';
import '../providers/course_provider_complete.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart';
import 'profile_screen.dart';

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

// =============================================================================
// ✅ PARENT DASHBOARD AVEC AUTHPROVIDERV2
// =============================================================================
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();

  AppLocation? _userLocation;
  List<CourseModel> _nearbyCourses = [];
  String? _errorMessage;

  late TabController _tabController;
  CourseCategory? _selectedCategory;
  double _selectedRadius = 50.0;
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

  /// ✅ Initialisation avec AuthProviderV2
  Future<void> _initializeDashboard() async {
    try {
      final authProvider = context.read<AuthProviderV2>();

      if (authProvider.currentUser == null || authProvider.userData == null) {
        setState(() => _errorMessage = 'Utilisateur non connecté');
        return;
      }

      final userModel = UserModel.fromSupabase(authProvider.userData!);

      final childProvider = context.read<ChildEnrollmentProvider>();
      await childProvider.loadChildren(authProvider.currentUser!.id);

      await _loadUserLocation(userModel);
      await _loadNearbyCourses();
      await childProvider
          .loadAllSchedulesForParent(authProvider.currentUser!.id);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: $e');
    }
  }

  Future<void> _loadUserLocation(UserModel user) async {
    if (user.location != null && user.location!.hasLocation) {
      setState(() => _userLocation = user.location);
    } else {
      final loc = await _locationService.getCurrentUserLocation();
      setState(() => _userLocation = loc ??
          AppLocation(
            latitude: LocationService.defaultLatitude,
            longitude: LocationService.defaultLongitude,
            address: LocationService.defaultAddress,
          ));
    }
  }

  /// ✅ Sauvegarde localisation avec updateUserProfileSilent
  Future<void> _saveUserLocation(AppLocation location) async {
    try {
      final result =
          await context.read<AuthProviderV2>().updateUserProfileSilent({
        'location': location.toMap(),
      });

      if (result.success) {
        setState(() => _userLocation = location);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Localisation sauvegardée'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadNearbyCourses() async {
    if (_userLocation == null) return;

    final courseProvider = context.read<CourseProvider>();
    await courseProvider.loadCoursesNearby(
      latitude: _userLocation!.latitude,
      longitude: _userLocation!.longitude,
      radiusKm: _selectedRadius,
    );

    setState(() {
      _nearbyCourses = courseProvider.courses
          .where((c) =>
              _selectedCategory == null || c.category == _selectedCategory)
          .where((c) => !_showAvailableOnly || c.isAvailableNow())
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Consumer AuthProviderV2
    return Consumer<AuthProviderV2>(
      builder: (context, authProvider, _) {
        if (authProvider.currentUser == null || authProvider.userData == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final currentUser = UserModel.fromSupabase(authProvider.userData!);

        if (_errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  Text(_errorMessage!),
                  ElevatedButton(
                    onPressed: _initializeDashboard,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('Bonjour, ${currentUser.name}'),
                    background: _buildCoverImage(currentUser),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: () => _loadUserLocation(currentUser),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'profile') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        } else if (value == 'logout') {
                          authProvider.logout();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'profile', child: Text('Mon profil')),
                        const PopupMenuItem(
                            value: 'logout', child: Text('Déconnexion')),
                      ],
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.home), text: 'Accueil'),
                      Tab(icon: Icon(Icons.school), text: 'Cours'),
                      Tab(icon: Icon(Icons.child_care), text: 'Enfants'),
                      Tab(icon: Icon(Icons.calendar_today), text: 'Planning'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _HomeTab(
                      userLocation: _userLocation, courses: _nearbyCourses),
                  _CoursesTab(
                      courses: _nearbyCourses, onEnroll: _showEnrollmentDialog),
                  _ChildrenTab(),
                  _PlanningTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverImage(UserModel user) {
    return user.profileImages.coverImage != null
        ? Image.network(user.profileImages.coverImage!, fit: BoxFit.cover)
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GhibliTheme.skyBlue,
                  GhibliTheme.lavenderPurple.withOpacity(0.7)
                ],
              ),
            ),
          );
  }

  void _showEnrollmentDialog(CourseModel course) {
    final children = context.read<ChildEnrollmentProvider>().children;
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord un enfant')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => EnrollmentDialog(course: course, children: children),
    );
  }
}

// =============================================================================
// TABS SIMPLIFIÉS
// =============================================================================
class _HomeTab extends StatelessWidget {
  final AppLocation? userLocation;
  final List<CourseModel> courses;

  const _HomeTab({required this.userLocation, required this.courses});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${provider.children.length} enfants',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            if (userLocation != null)
              Text('Localisation: ${userLocation!.address}'),
            const SizedBox(height: 16),
            Text('${courses.length} cours à proximité'),
          ],
        );
      },
    );
  }
}

class _CoursesTab extends StatelessWidget {
  final List<CourseModel> courses;
  final Function(CourseModel) onEnroll;

  const _CoursesTab({required this.courses, required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(courses[i].title),
        trailing: ElevatedButton(
          onPressed: () => onEnroll(courses[i]),
          child: const Text('Inscrire'),
        ),
      ),
    );
  }
}

class _ChildrenTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChildEnrollmentProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          itemCount: provider.children.length,
          itemBuilder: (context, i) {
            final child = provider.children[i];
            return ListTile(
              title: Text('${child.firstName} ${child.lastName}'),
              subtitle: Text('${child.age} ans'),
            );
          },
        );
      },
    );
  }
}

class _PlanningTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Planning à venir'));
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
      final authProvider = context.read<AuthProviderV2>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer l'inscription
      final enrollment = EnrollmentModel(
        id: '',
        courseId: widget.course.id,
        childId: _selectedChildId!,
        parentId: currentUser.id,
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
      final authProvider = context.read<AuthProviderV2>();
      final currentUser = authProvider.currentUser;

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
          parentId: currentUser.id,
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
