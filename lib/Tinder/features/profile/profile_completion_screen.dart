// lib/Tinder/features/profile/profile_completion_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../discovery/discovery_screen.dart';
import 'profile_provider.dart';

/// ✅ Écran de complétion de profil avec progress bar
class ProfileCompletionScreenTinder extends StatefulWidget {
  const ProfileCompletionScreenTinder({super.key});

  @override
  State<ProfileCompletionScreenTinder> createState() =>
      _ProfileCompletionScreenTinderState();
}

class _ProfileCompletionScreenTinderState
    extends State<ProfileCompletionScreenTinder> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _occupationController = TextEditingController();
  final _cityController = TextEditingController();

  // State
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedLookingFor;
  File? _avatarFile;
  File? _coverFile;
  List<File> _galleryFiles = [];
  List<String> _selectedInterests = [];

  final List<String> _availableInterests = [
    '🎬 Cinéma',
    '🎵 Musique',
    '⚽ Sport',
    '📚 Lecture',
    '✈️ Voyages',
    '🍳 Cuisine',
    '🎨 Art',
    '🎮 Gaming',
    '🏃 Fitness',
    '🎭 Théâtre',
    '📷 Photo',
    '🌿 Nature',
    '🍷 Gastronomie',
    '🎪 Festivals',
    '🧘 Yoga',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    _fullNameController.text = provider.fullName;
    _bioController.text = provider.bio;
    _occupationController.text = provider.occupation ?? '';
    _cityController.text = provider.city ?? '';
    _selectedGender = provider.gender;
    _selectedLookingFor = provider.lookingFor;
    _selectedInterests = provider.interests;
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
        final completion = provider.completionPercentage;
        final missingFields = provider.getMissingFields();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complétez votre profil'),
            centerTitle: true,
            actions: [
              if (completion >= 80)
                TextButton(
                  onPressed: () => _finishSetup(context, provider),
                  child: const Text(
                    'Terminer',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // ✅ Progress Bar
              _buildProgressHeader(completion, missingFields.length),

              // ✅ Form scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Photos', '30%'),
                        _buildPhotoSection(provider),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Informations de base', '40%'),
                        _buildBasicInfoSection(),
                        const SizedBox(height: 24),

                        _buildSectionTitle('À propos de vous', '20%'),
                        _buildBioSection(),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Centres d\'intérêt', '10%'),
                        _buildInterestsSection(),
                        const SizedBox(height: 32),

                        // ✅ Bouton de sauvegarde
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: provider.loading
                                ? null
                                : () => _saveProfile(provider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                            ),
                            child: provider.loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Sauvegarder',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Progress Header
  Widget _buildProgressHeader(int completion, int missingCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Complétion: $completion%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: completion >= 80 ? Colors.green : Colors.orange,
                ),
              ),
              Text(
                missingCount > 0
                    ? '$missingCount champs restants'
                    : '✅ Complet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              completion >= 80 ? Colors.green : Colors.pink,
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String weight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            weight,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Photo Section
  Widget _buildPhotoSection(ProfileProvider provider) {
    return Column(
      children: [
        // Avatar + Cover
        Row(
          children: [
            Expanded(
              child: _buildPhotoCard(
                label: 'Photo de profil',
                file: _avatarFile,
                existingUrl: provider.photoUrl,
                onTap: () => _pickImage(isAvatar: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPhotoCard(
                label: 'Photo de couverture',
                file: _coverFile,
                existingUrl: provider.coverUrl,
                onTap: () => _pickImage(isCover: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Galerie (2-6 photos)
        Text(
          'Photos supplémentaires (${provider.photos.length + _galleryFiles.length}/6)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: provider.photos.length + _galleryFiles.length + 1,
          itemBuilder: (context, index) {
            // Bouton d'ajout
            if (index == provider.photos.length + _galleryFiles.length) {
              return _buildAddPhotoButton();
            }

            // Photo existante
            if (index < provider.photos.length) {
              return _buildGalleryPhoto(
                url: provider.photos[index],
                onRemove: () =>
                    provider.removePhotoFromGallery(provider.photos[index]),
              );
            }

            // Photo nouvellement ajoutée
            final fileIndex = index - provider.photos.length;
            return _buildGalleryPhoto(
              file: _galleryFiles[fileIndex],
              onRemove: () {
                setState(() {
                  _galleryFiles.removeAt(fileIndex);
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoCard({
    required String label,
    File? file,
    String? existingUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          image: file != null
              ? DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                )
              : existingUrl != null
                  ? DecorationImage(
                      image: NetworkImage(existingUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: file == null && existingUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildAddPhotoButton() {
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

  Widget _buildGalleryPhoto(
      {File? file, String? url, required VoidCallback onRemove}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: file != null
                  ? FileImage(file)
                  : NetworkImage(url!) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
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
  }

  /// ✅ Basic Info Section
  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet *',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Champ obligatoire' : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date de naissance *',
              border: OutlineInputBorder(),
            ),
            child: Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Sélectionner',
              style: TextStyle(
                color: _selectedDate != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Genre *',
            border: OutlineInputBorder(),
          ),
          items: ['male', 'female', 'other']
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e == 'male'
                        ? 'Homme'
                        : e == 'female'
                            ? 'Femme'
                            : 'Autre'),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedLookingFor,
          decoration: const InputDecoration(
            labelText: 'Je recherche *',
            border: OutlineInputBorder(),
          ),
          items: ['male', 'female', 'both']
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e == 'male'
                        ? 'Hommes'
                        : e == 'female'
                            ? 'Femmes'
                            : 'Tous'),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedLookingFor = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _occupationController,
          decoration: const InputDecoration(
            labelText: 'Profession',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// ✅ Bio Section
  Widget _buildBioSection() {
    return TextFormField(
      controller: _bioController,
      maxLines: 5,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: 'Bio (min 20 caractères) *',
        border: OutlineInputBorder(),
        hintText: 'Parlez de vous...',
      ),
      validator: (value) =>
          value == null || value.length < 20 ? 'Minimum 20 caractères' : null,
    );
  }

  /// ✅ Interests Section
  Widget _buildInterestsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(interest);
              } else {
                _selectedInterests.remove(interest);
              }
            });
          },
          selectedColor: Colors.pink,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
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
        _avatarFile = File(pickedFile.path);
      } else if (isCover) {
        _coverFile = File(pickedFile.path);
      } else if (isGallery && _galleryFiles.length < 6) {
        _galleryFiles.add(File(pickedFile.path));
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveProfile(ProfileProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    // Upload photos
    String? avatarUrl;
    String? coverUrl;

    if (_avatarFile != null) {
      avatarUrl = await provider.uploadPhoto(_avatarFile!);
    }

    if (_coverFile != null) {
      coverUrl = await provider.uploadPhoto(_coverFile!, isCover: true);
    }

    // Upload gallery
    for (final file in _galleryFiles) {
      await provider.addPhotoToGallery(file);
    }

    // Update profile
    await provider.updateProfile(
      fullName: _fullNameController.text.trim(),
      bio: _bioController.text.trim(),
      occupation: _occupationController.text.trim(),
      city: _cityController.text.trim(),
      dateOfBirth: _selectedDate,
      gender: _selectedGender,
      lookingFor: _selectedLookingFor,
      interests: _selectedInterests,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil sauvegardé !')),
      );
    }
  }

  void _finishSetup(BuildContext context, ProfileProvider provider) {
    if (provider.completionPercentage < 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complétez au moins 80% de votre profil'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
    );
  }
}
