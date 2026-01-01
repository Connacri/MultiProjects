import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../discovery/discovery_screen.dart';
import 'profile_provider.dart';

/// 🎨 Écran de complétion de profil - Design moderne Material 3
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _occupationController = TextEditingController();
  final _cityController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  String? _lookingFor;
  List<String> _interests = [];

  File? _avatarFile;
  bool _isUploading = false;
  String? _uploadedAvatarUrl;
  double _uploadProgress = 0.0;

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
    final colorScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, provider),
              Expanded(
                child: _buildForm(context, provider),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGalleryBottomSheet(provider),
        child: const Icon(Icons.photo_library_outlined),
      ),
    );
  }

  /// Header avec progression dynamique
  Widget _buildHeader(BuildContext context, ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Complétez votre profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quelques informations pour commencer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: provider.completionPercentage / 100,
            backgroundColor: Colors.grey[300],
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  /// Formulaire principal
  Widget _buildForm(BuildContext context, ProfileProvider provider) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          _buildAvatarSection(context),
          const SizedBox(height: 32),

          // Nom complet
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Nom complet *',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 16),

          // Date de naissance
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              _dateOfBirth == null
                  ? 'Date de naissance *'
                  : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
          ),
          const SizedBox(height: 16),

          // Genre
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Genre *',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Homme')),
              DropdownMenuItem(value: 'female', child: Text('Femme')),
              DropdownMenuItem(value: 'other', child: Text('Autre')),
            ],
            onChanged: (v) => _gender = v,
            validator: (v) => v == null ? 'Requis' : null,
          ),
          const SizedBox(height: 16),

          // Recherche
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Recherche *',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Hommes')),
              DropdownMenuItem(value: 'female', child: Text('Femmes')),
              DropdownMenuItem(value: 'both', child: Text('Les deux')),
            ],
            onChanged: (v) => _lookingFor = v,
            validator: (v) => v == null ? 'Requis' : null,
          ),
          const SizedBox(height: 16),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio *',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) =>
                v == null || v.length < 20 ? 'Minimum 20 caractères' : null,
          ),
          const SizedBox(height: 16),

          // Profession
          TextFormField(
            controller: _occupationController,
            decoration: InputDecoration(
              labelText: 'Profession',
              prefixIcon: const Icon(Icons.work_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ville
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'Ville *',
              prefixIcon: const Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 32),

          // Centres d'intérêt (Chip input simple)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests
                .map((interest) => Chip(
                      label: Text(interest),
                      onDeleted: () =>
                          setState(() => _interests.remove(interest)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final interest = await showDialog<String>(
                context: context,
                builder: (context) {
                  final ctrl = TextEditingController();
                  return AlertDialog(
                    title: const Text('Ajouter un intérêt'),
                    content: TextField(controller: ctrl),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler')),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, ctrl.text.trim()),
                        child: const Text('Ajouter'),
                      ),
                    ],
                  );
                },
              );
              if (interest != null &&
                  interest.isNotEmpty &&
                  !_interests.contains(interest)) {
                setState(() => _interests.add(interest));
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un intérêt'),
          ),
          const SizedBox(height: 32),

          // Bouton sauvegarde
          if (_isUploading) LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : () => _handleSave(provider),
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder et continuer'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Section avatar
  Widget _buildAvatarSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = !kIsWeb;

    return Center(
      child: GestureDetector(
        onTap: () => _showImagePickerOptions(context, isMobile),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.surfaceVariant,
              backgroundImage:
                  _avatarFile != null ? FileImage(_avatarFile!) : null,
              child: _avatarFile == null
                  ? Icon(Icons.person,
                      size: 60, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.camera_alt, size: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Options picker image
  void _showImagePickerOptions(BuildContext context, bool isMobile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: colorScheme.primary),
                ),
                title: const Text('Galerie'),
                subtitle: const Text('Choisir une photo existante'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (isMobile) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.camera_alt, color: colorScheme.secondary),
                  ),
                  title: const Text('Appareil photo'),
                  subtitle: const Text('Prendre une nouvelle photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
              if (_avatarFile != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _avatarFile = null;
                      _uploadedAvatarUrl = null;
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Sélectionner une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _avatarFile = File(pickedFile.path);
      });

      _showSnackBar('Photo sélectionnée', isError: false);
    } catch (e) {
      print('Erreur pick image: $e');
      _showSnackBar('Erreur lors de la sélection', isError: true);
    }
  }

  /// Uploader l'avatar vers Supabase Storage
  Future<String?> _uploadAvatar(ProfileProvider provider) async {
    if (_avatarFile == null) return null;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final url = await provider.uploadPhoto(_avatarFile!);
      setState(() {
        _uploadProgress = 1.0;
        _uploadedAvatarUrl = url;
      });
      return url;
    } catch (e) {
      print('❌ Erreur upload avatar: $e');
      _showSnackBar('Erreur lors de l\'upload', isError: true);
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Sauvegarde
// Dans ProfileCompletionScreen._handleSave() → version corrigée et robuste

  Future<void> _handleSave(ProfileProvider provider) async {
    // 1. Validation formulaire
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez corriger les erreurs', isError: true);
      return;
    }

    // 2. Validation champs obligatoires
    if (_dateOfBirth == null) {
      _showSnackBar('Date de naissance requise', isError: true);
      return;
    }
    if (_gender == null) {
      _showSnackBar('Genre requis', isError: true);
      return;
    }
    if (_lookingFor == null) {
      _showSnackBar('Recherche requise', isError: true);
      return;
    }
    if (_interests.length < 3) {
      _showSnackBar('Au moins 3 centres d\'intérêt', isError: true);
      return;
    }
    if (provider.photos.length < 2) {
      _showSnackBar('Ajoutez au moins 2 photos dans la galerie', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 3. Upload avatar principal si modifié
      String? finalPhotoUrl = provider.photoUrl;
      if (_avatarFile != null) {
        finalPhotoUrl = await provider
            .uploadPhoto(_avatarFile!); // méthode existante pour avatar
        if (finalPhotoUrl == null) throw Exception('Upload avatar échoué');
      }

      // 4. Mise à jour profil avec tous les champs
      await provider.updateProfile(
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        occupation: _occupationController.text.trim().isNotEmpty
            ? _occupationController.text.trim()
            : null,
        city: _cityController.text.trim(),
        photoUrl: finalPhotoUrl,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        lookingFor: _lookingFor,
        interests: _interests,
      );

      // 5. Vérification finale du statut complété
      // Le provider a déjà recalculé completion_percentage + profile_completed
      if (provider.profileCompleted && provider.completionPercentage >= 90) {
        _showSnackBar('Profil complété avec succès ! 🎉', isError: false);

        // Navigation forcée + nettoyage stack
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
            (route) => false, // supprime tout le stack précédent
          );
        }
      } else {
        // Cas improbable (bug calcul) → force refresh + message
        await provider.refresh();
        _showSnackBar(
          'Profil mis à jour mais pas encore complet (${provider.completionPercentage}%)',
          isError: false,
        );
      }
    } catch (e) {
      print('❌ Erreur sauvegarde complète: $e');
      _showSnackBar('Erreur lors de la sauvegarde : $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

// Dans ProfileCompletionScreen ou ProfileEditScreen
// Ajoute cette méthode privée

  void _showGalleryBottomSheet(ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Ajouter des photos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jusqu\'à 6 photos pour montrer qui vous êtes',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Grille actuelle des photos
                Consumer<ProfileProvider>(
                  builder: (context, prov, _) {
                    final currentPhotos = prov.photos;
                    final remainingSlots = 6 - currentPhotos.length;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount:
                          currentPhotos.length + (remainingSlots > 0 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < currentPhotos.length) {
                          final url = currentPhotos[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: Colors.black12),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text(
                                            'Supprimer cette photo ?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Annuler')),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await prov.removePhotoFromGallery(url);
                                      if (mounted)
                                        Navigator.pop(
                                            context); // referme le sheet pour refresh
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        // Bouton d'ajout
                        return DottedBorder(
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(12),
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          dashPattern: const [6, 4],
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Material(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3),
                              child: InkWell(
                                onTap: remainingSlots > 0
                                    ? () => _pickAndAddGalleryPhoto(provider)
                                    : null,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 32,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajouter',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (remainingSlots > 1)
                                      Text(
                                        '$remainingSlots places',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndAddGalleryPhoto(ProfileProvider provider) async {
    Navigator.pop(context); // ferme le sheet avant picker

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      await provider.addPhotoToGallery(File(picked.path));
      _showSnackBar('Photo ajoutée à votre galerie', isError: false);
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
