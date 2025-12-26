import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider_dart.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/location_picker_dialog_widget.dart';
import '../widgets/location_picker_windows.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ImageStorageService _imageService = ImageStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isEditMode = false;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  UserRole? _selectedRole;
  AppLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _selectedRole = user?.role;
    _selectedLocation = user?.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- GESTION DES IMAGES ---

// --- GESTION DES IMAGES (VERSION CORRIGÉE) ---

  Future<void> _pickProfileImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      await _uploadImage(File(image.path), isProfile: true);
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      await _uploadImage(File(image.path), isProfile: false);
    }
  }

  Future<void> _uploadImage(File image, {required bool isProfile}) async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final user = authProvider.user!;

      print(
          '📤 [ProfileScreen] Début upload ${isProfile ? "profile" : "cover"}');
      print('📤 [ProfileScreen] User UID: ${user.uid}');

      // 1. Upload vers Supabase Storage
      final imageUrl = await _imageService.uploadUserProfileImage(
        imageFile: image,
        userId: user.uid,
        isProfileImage: isProfile,
      );

      if (imageUrl == null) {
        throw Exception('Upload a échoué: URL null retournée');
      }

      print('✅ [ProfileScreen] Upload réussi: $imageUrl');

      // 2. Mise à jour de l'objet UserProfileImages
      final currentImages = user.profileImages;

      final updatedImages = isProfile
          ? currentImages.copyWith(
              profileImageSupabase: imageUrl,
              profileImageFirebase: imageUrl, // Synchro
              lastUpdated: DateTime.now(),
            )
          : currentImages.copyWith(
              coverImageSupabase: imageUrl,
              coverImageFirebase: imageUrl, // Synchro
              lastUpdated: DateTime.now(),
            );

      print('📝 [ProfileScreen] Images mises à jour:');
      print('   - Profile Supabase: ${updatedImages.profileImageSupabase}');
      print('   - Cover Supabase: ${updatedImages.coverImageSupabase}');

      // 3. Sauvegarde en base de données
      print('📝 [ProfileScreen] Appel updateUserProfile...');
      await _authService.updateUserProfile(
        uid: user.uid,
        profileImages: updatedImages,
      );
      print('✅ [ProfileScreen] updateUserProfile réussi');

      // 4. Rafraîchir le provider pour voir l'image immédiatement
      print('🔄 [ProfileScreen] Rafraîchissement du provider...');
      await authProvider.refreshUser();
      print('✅ [ProfileScreen] Provider rafraîchi');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProfile
                  ? 'Photo de profil mise à jour avec succès'
                  : 'Image de couverture mise à jour avec succès',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      print('❌ [ProfileScreen] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [ProfileScreen] Erreur inattendue: $e');
      print('❌ [ProfileScreen] Type: ${e.runtimeType}');
      print('❌ [ProfileScreen] StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- GESTION DU PROFIL ---

  Future<void> _selectLocation() async {
    final result = await showDialog<AppLocation>(
      context: context,
      builder: (context) => Platform.isWindows
          ? const LocationPickerDialogWindows()
          : const LocationPickerDialog(),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateUserProfile(
        uid: authProvider.user!.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
        location: _selectedLocation,
      );

      // Rafraichir les données locales
      await authProvider.refreshUser();

      if (mounted) {
        setState(() => _isEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur sauvegarde: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    // ... code existant inchangé ...
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _handleDeactivateAccount() async {
    // ... code existant inchangé ...
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver le compte'),
        content: const Text(
          'Votre compte sera désactivé pendant 60 jours. Vous pourrez le réactiver en vous reconnectant pendant cette période.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().deactivateAccount();
    }
  }

  // --- UI CONSTRUCTION ---

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si le provider charge (ex: refreshUser), on montre le loading
        final isGlobalLoading = _isLoading || authProvider.isLoading;

        return LoadingOverlay(
          isLoading: isGlobalLoading,
          child: Scaffold(
            body: ResponsiveBuilder(
              builder: (context, deviceType) {
                if (deviceType == DeviceType.desktop) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildProfileContent(user, isDesktop: true),
                      ),
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.3),
                          border: Border(
                            left: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                        ),
                        child: _buildSettingsPanel(),
                      ),
                    ],
                  );
                }
                return _buildProfileContent(user, isDesktop: false);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(UserModel user, {required bool isDesktop}) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(user),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -50),
            child: _buildProfileInfo(user),
          ),
        ),
        SliverPadding(
          padding: ResponsiveLayout.getResponsivePadding(context),
          sliver: SliverToBoxAdapter(
            child: _buildDetailsSection(user),
          ),
        ),
        if (!isDesktop)
          SliverPadding(
            padding: ResponsiveLayout.getResponsivePadding(context),
            sliver: SliverToBoxAdapter(
              child: _buildSettingsPanel(),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }

  Widget _buildAppBar(UserModel user) {
    final coverImage = user.profileImages.coverImage;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      actions: [
        if (!_isEditMode)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier le profil',
            onPressed: () => setState(() => _isEditMode = true),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Annuler',
            onPressed: () {
              // Reset controllers to original values
              setState(() {
                _isEditMode = false;
                _nameController.text = user.name;
                _bioController.text = user.bio ?? '';
                _phoneController.text = user.phoneNumber ?? '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Enregistrer',
            onPressed: _saveProfile,
          ),
        ],
        PopupMenuButton<Locale>(
          icon: const Icon(Icons.language),
          tooltip: 'Changer de langue',
          onSelected: (locale) =>
              context.read<LocaleProvider>().setLocale(locale),
          itemBuilder: (context) => const [
            PopupMenuItem(value: Locale('fr'), child: Text('Français')),
            PopupMenuItem(value: Locale('en'), child: Text('English')),
            PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de couverture
            if (coverImage != null && coverImage.isNotEmpty)
              CachedNetworkImage(
                imageUrl: coverImage,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image,
                      size: 50, color: Colors.grey),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.white24),
                ),
              ),

            // Overlay sombre pour lisibilité icône
            if (_isEditMode) Container(color: Colors.black26),

            // Bouton modification couverture
            if (_isEditMode)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'edit_cover_btn',
                  onPressed: _pickCoverImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Changer couverture'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user) {
    final profileImage = user.profileImages.profileImage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage:
                      (profileImage != null && profileImage.isNotEmpty)
                          ? CachedNetworkImageProvider(profileImage)
                          : null,
                  child: (profileImage == null || profileImage.isEmpty)
                      ? Icon(_getRoleIcon(user.role),
                          size: 50,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
              ),
              if (_isEditMode)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20),
                    color: Colors.white,
                    onPressed: _pickProfileImage,
                    tooltip: 'Changer photo de profil',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditMode)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
          else
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(height: 12),
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: UserRole.values
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Row(
                            children: [
                              Icon(_getRoleIcon(role), size: 20),
                              const SizedBox(width: 8),
                              Text(role.displayName),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
              ),
            )
          else
            Chip(
              avatar: Icon(_getRoleIcon(user.role), size: 18),
              label: Text(user.role.displayName),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Bio
        if (_isEditMode)
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Biographie',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info_outline),
            ),
            maxLines: 4,
          )
        else if (user.bio != null && user.bio!.isNotEmpty)
          Card(
            elevation: 0,
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'À propos',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(user.bio!),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Section Téléphone
        if (_isEditMode)
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          )
        else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
          Card(
            child: ListTile(
              leading: Icon(Icons.phone,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Téléphone'),
              subtitle: Text(user.phoneNumber!),
            ),
          ),

        const SizedBox(height: 16),

        // Section Localisation
        if (_isEditMode)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              tileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.2),
              leading: const Icon(Icons.location_on),
              title: const Text('Localisation'),
              subtitle: _selectedLocation != null
                  ? Text(_selectedLocation!.address)
                  : const Text('Aucune localisation définie',
                      style: TextStyle(fontStyle: FontStyle.italic)),
              trailing: const Icon(Icons.edit_location_alt),
              onTap: _selectLocation,
            ),
          )
        else if (user.location != null && user.location!.hasLocation)
          Card(
            child: ListTile(
              leading: Icon(Icons.location_on,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Localisation'),
              subtitle: Text(user.location!.address),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Paramètres du compte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
                onTap: _handleSignOut,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Désactiver le compte'),
                subtitle: const Text('Suspension temporaire (60 jours)'),
                titleTextStyle: TextStyle(
                  color: Colors.red,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                  fontWeight: FontWeight.w500,
                ),
                onTap: _handleDeactivateAccount,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return Icons.family_restroom;
      case UserRole.school:
        return Icons.school;
      case UserRole.coach:
        return Icons.sports_soccer;
      case UserRole.autres:
        return Icons.person;
    }
  }
}

// ----------------------------------------------------------------------------
// DIALOG D'EDITION (OPTIONNEL SI TU UTILISES LE MODE EDIT IN-PLACE)
// ----------------------------------------------------------------------------
class UserProfileEditDialog extends StatefulWidget {
  final UserModel user;

  const UserProfileEditDialog({super.key, required this.user});

  @override
  State<UserProfileEditDialog> createState() => _UserProfileEditDialogState();
}

class _UserProfileEditDialogState extends State<UserProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;

  File? _profileImage;
  File? _coverImage;
  AppLocation? _location;

  final LocationService _locationService = LocationService();
  final ImageStorageService _imageService = ImageStorageService();
  final AuthService _authService = AuthService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
    _location = widget.user.location;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(image.path);
        } else {
          _coverImage = File(image.path);
        }
      });
    }
  }

  Future<void> _updateLocation() async {
    // Utiliser le widget de sélection approprié
    final result = await showDialog<AppLocation>(
      context: context,
      builder: (context) => Platform.isWindows
          ? LocationPickerDialogWindows(initialLocation: _location)
          : LocationPickerDialog(initialLocation: _location),
    );

    if (result != null) {
      setState(() => _location = result);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload des images si changées
      final urls = await _imageService.uploadUserProfileImages(
        profileImage: _profileImage,
        coverImage: _coverImage,
        userId: widget.user.uid,
      );

      // 2. Construction des nouvelles données images
      UserProfileImages newImages = widget.user.profileImages;

      // Si une nouvelle photo de profil est uploadée
      if (urls['profile'] != null) {
        newImages = newImages.copyWith(
          profileImageFirebase: urls['profile'],
          profileImageSupabase: urls['profile'], // Synchro
          lastUpdated: DateTime.now(),
        );
      }

      // Si une nouvelle cover est uploadée
      if (urls['cover'] != null) {
        newImages = newImages.copyWith(
          coverImageFirebase: urls['cover'],
          coverImageSupabase: urls['cover'], // Synchro
          lastUpdated: DateTime.now(),
        );
      }

      // 3. Update User
      await _authService.updateUserProfile(
        uid: widget.user.uid,
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        location: _location,
        profileImages: newImages,
      );

      // 4. Rafraîchir Provider
      if (mounted) {
        await context.read<AuthProvider>().refreshUser();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil mis à jour'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Éditer le profil'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar Edit
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (widget.user.profileImages.profileImage != null
                                ? NetworkImage(
                                        widget.user.profileImages.profileImage!)
                                    as ImageProvider
                                : null),
                        child: (_profileImage == null &&
                                widget.user.profileImages.profileImage == null)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue,
                          child:
                              Icon(Icons.edit, size: 12, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Cover Edit
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: _coverImage != null
                          ? DecorationImage(
                              image: FileImage(_coverImage!), fit: BoxFit.cover)
                          : (widget.user.profileImages.coverImage != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                      widget.user.profileImages.coverImage!),
                                  fit: BoxFit.cover)
                              : null),
                    ),
                    child: const Center(child: Icon(Icons.panorama)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom', border: OutlineInputBorder()),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bioCtrl,
              decoration: const InputDecoration(
                  labelText: 'Bio', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                  labelText: 'Téléphone', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _updateLocation,
              icon: const Icon(Icons.location_on),
              label: Text(_location != null
                  ? 'Modifier localisation'
                  : 'Ajouter localisation'),
            ),
            if (_location != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(_location!.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
