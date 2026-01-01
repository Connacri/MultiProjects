// lib/Tinder/features/profile/profile_edit_screen.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'profile_provider.dart';

/// ✅ Écran d'édition de profil avec upload cover + photo
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  late TextEditingController _cityController;

  File? _newAvatar;
  File? _newCover;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    _fullNameController = TextEditingController(text: provider.fullName);
    _bioController = TextEditingController(text: provider.bio);
    _occupationController = TextEditingController(text: provider.occupation ?? '');
    _cityController = TextEditingController(text: provider.city ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Modifier le profil'),
            actions: [
              if (!_uploading)
                TextButton(
                  onPressed: () => _saveProfile(provider),
                  child: const Text(
                    'Sauvegarder',
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ✅ Cover + Avatar (éditable)
                _buildPhotosHeader(provider),
                const SizedBox(height: 16),

                // ✅ Formulaire
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                          hintText: 'Parlez de vous...',
                        ),
                        validator: (value) =>
                            value == null || value.length < 20
                                ? 'Minimum 20 caractères'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _occupationController,
                        decoration: const InputDecoration(
                          labelText: 'Profession',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Ville',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ✅ Galerie photos
                      const Text(
                        'Galerie photos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPhotoGallery(provider),
                      const SizedBox(height: 24),

                      // ✅ Bouton suppression compte
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteAccountDialog(context, provider),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text(
                          'Supprimer mon compte',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Header avec cover + avatar éditables
  Widget _buildPhotosHeader(ProfileProvider provider) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Cover image
          GestureDetector(
            onTap: () => _pickImage(isCover: true),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                image: _newCover != null
                    ? DecorationImage(
                        image: FileImage(_newCover!),
                        fit: BoxFit.cover,
                      )
                    : provider.coverUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(provider.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _newCover == null && provider.coverUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter une photo de couverture',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    )
                  : const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
            ),
          ),

          // Avatar
          Positioned(
            bottom: 0,
            left: 16,
            child: GestureDetector(
              onTap: () => _pickImage(isAvatar: true),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _newAvatar != null
                      ? FileImage(_newAvatar!)
                      : provider.photoUrl != null
                          ? CachedNetworkImageProvider(provider.photoUrl!) as ImageProvider
                          : null,
                  child: _newAvatar == null && provider.photoUrl == null
                      ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
            ),
          ),

          // Badge édition avatar
          if (_newAvatar != null || provider.photoUrl != null)
            Positioned(
              bottom: 0,
              left: 100,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ Galerie photos
  Widget _buildPhotoGallery(ProfileProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: provider.photos.length + 1,
      itemBuilder: (context, index) {
        // Bouton d'ajout
        if (index == provider.photos.length) {
          if (provider.photos.length >= 6) {
            return const SizedBox();
          }
          return GestureDetector(
            onTap: () => _pickImage(isGallery: true),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 32, color: Colors.grey),
              ),
            ),
          );
        }

        // Photo existante
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: provider.photos[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade300),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removePhoto(provider, provider.photos[index]),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Actions
  Future<void> _pickImage({
    bool isAvatar = false,
    bool isCover = false,
    bool isGallery = false,
  }) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      if (isAvatar) {
        _newAvatar = File(pickedFile.path);
      } else if (isCover) {
        _newCover = File(pickedFile.path);
      }
    });

    // Upload immédiatement pour la galerie
    if (isGallery) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      setState(() => _uploading = true);
      await provider.addPhotoToGallery(File(pickedFile.path));
      setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto(ProfileProvider provider, String photoUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _uploading = true);
      await provider.removePhotoFromGallery(photoUrl);
      setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile(ProfileProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _uploading = true);

    // Upload photos si modifiées
    if (_newAvatar != null) {
      await provider.uploadPhoto(_newAvatar!);
    }

    if (_newCover != null) {
      await provider.uploadPhoto(_newCover!, isCover: true);
    }

    // Update profile
    await provider.updateProfile(
      fullName: _fullNameController.text.trim(),
      bio: _bioController.text.trim(),
      occupation: _occupationController.text.trim(),
      city: _cityController.text.trim(),
    );

    setState(() => _uploading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour !')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showDeleteAccountDialog(
      BuildContext context, ProfileProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer votre compte ?'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implémenter suppression compte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression à implémenter')),
      );
    }
  }
}
