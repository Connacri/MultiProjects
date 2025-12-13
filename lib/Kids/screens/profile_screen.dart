import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart'; // ← AJOUT IMPORTANT
import '../providers/auth_provider_dart.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/image_storage_service.dart';
import '../services/location_service_osm.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/location_picker_dialog_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ImageStorageService _imageService = ImageStorageService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isEditMode = false;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  UserRole? _selectedRole;
  AppLocation?
      _selectedLocation; // ← UserLocation n'existe pas, utiliser AppLocation

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

  Future<void> _pickProfileImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null && mounted) {
      await _uploadProfileImage(File(image.path), isProfile: true);
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (image != null && mounted) {
      await _uploadProfileImage(File(image.path), isProfile: false);
    }
  }

  Future<void> _uploadProfileImage(File image,
      {required bool isProfile}) async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user == null) return;

      final imageUrl = await _imageService.uploadUserProfileImage(
        imageFile: image,
        userId: authProvider.user!.uid,
        isProfileImage: isProfile,
      );

      if (imageUrl != null) {
        final currentImages = authProvider.user!.profileImages;
        final updatedImages = isProfile
            ? currentImages.copyWith(
                profileImageFirebase: imageUrl,
                lastUpdated: DateTime.now(),
              )
            : currentImages.copyWith(
                coverImageFirebase: imageUrl,
                lastUpdated: DateTime.now(),
              );

        await _authService.updateUserProfile(
          uid: authProvider.user!.uid,
          profileImages: updatedImages,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isProfile
                    ? 'Photo de profil mise à jour'
                    : 'Image de couverture mise à jour',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<AppLocation>(
      // ← Changé de UserLocation à AppLocation
      context: context,
      builder: (context) => const LocationPickerDialog(),
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

      if (mounted) {
        setState(() => _isEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
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

        return LoadingOverlay(
          isLoading: _isLoading,
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
                              color: Theme.of(context).dividerColor,
                            ),
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
      ],
    );
  }

  Widget _buildAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      actions: [
        if (!_isEditMode)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _isEditMode = true),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _isEditMode = false),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
        PopupMenuButton<Locale>(
          icon: const Icon(Icons.language),
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
            if (user.profileImages.coverImage != null)
              CachedNetworkImage(
                imageUrl: user.profileImages.coverImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade300),
                errorWidget: (context, url, error) =>
                    Container(color: Colors.grey.shade300),
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
              ),
            if (_isEditMode)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'cover',
                  onPressed: _pickCoverImage,
                  child: const Icon(Icons.camera_alt),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserModel user) {
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
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: user.profileImages.profileImage != null
                      ? CachedNetworkImageProvider(
                          user.profileImages.profileImage!,
                        )
                      : null,
                  child: user.profileImages.profileImage == null
                      ? Icon(
                          _getRoleIcon(user.role),
                          size: 50,
                        )
                      : null,
                ),
              ),
              if (_isEditMode)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    color: Colors.white,
                    onPressed: _pickProfileImage,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditMode)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
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
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: UserRole.values
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(_getRoleIcon(role)),
                            const SizedBox(width: 8),
                            Text(role.displayName),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value),
            )
          else
            Chip(
              avatar: Icon(_getRoleIcon(user.role)),
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
        if (_isEditMode)
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Biographie',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          )
        else if (user.bio != null && user.bio!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'À propos',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user.bio!),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_isEditMode)
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          )
        else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
          Card(
            child: ListTile(
              leading: Icon(
                Icons.phone,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Téléphone'),
              subtitle: Text(user.phoneNumber!),
            ),
          ),
        const SizedBox(height: 16),
        if (_isEditMode)
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Localisation'),
              subtitle: _selectedLocation != null
                  ? Text(_selectedLocation!.address)
                  : const Text('Non définie'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectLocation,
            ),
          )
        else if (user.location != null && user.location!.hasLocation)
          Card(
            child: ListTile(
              leading: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Localisation'),
              subtitle: Text(user.location!.address),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        Card(
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
                titleTextStyle: TextStyle(
                  color: Colors.red,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
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
        return Icons.person;
      case UserRole.school:
        return Icons.school;
      case UserRole.coach:
        return Icons.sports;
      case UserRole.autres:
        return Icons.account_box_rounded;
    }
  }
}
