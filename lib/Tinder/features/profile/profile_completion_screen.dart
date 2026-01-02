import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenzy/Tinder/bottom_nav.dart';
import 'package:provider/provider.dart';

import 'profile_provider.dart';

/// 🎨 Écran de complétion de profil - Design attractif comme Tinder
class ProfileCompletion extends StatefulWidget {
  const ProfileCompletion({super.key});

  @override
  State<ProfileCompletion> createState() => _ProfileCompletionState();
}

class _ProfileCompletionState extends State<ProfileCompletion> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers pour tous les champs de la table profiles
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _occupationController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _heightController = TextEditingController();
  final _educationController = TextEditingController();
  final _relationshipStatusController = TextEditingController();
  final _instagramController = TextEditingController();
  final _spotifyController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _lookingFor;
  List<String> _interests = [];

  File? _avatarFile;
  File? _coverFile;
  bool _isUploading = false;
  String? _uploadedAvatarUrl;
  String? _uploadedCoverUrl;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Pré-remplir tous les champs après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);

      // Infos de base
      _fullNameController.text = provider.fullName;
      _bioController.text = provider.bio;
      _occupationController.text = provider.occupation ?? '';
      _cityController.text = provider.city ?? '';
      _countryController.text = provider.country ?? '';
      _heightController.text = provider.heightCm?.toString() ?? '';
      _educationController.text = provider.education ?? '';
      _relationshipStatusController.text = provider.relationshipStatus ?? '';
      _instagramController.text = provider.instagramHandle ?? '';
      _spotifyController.text = provider.spotifyAnthem ?? '';

      // Date de naissance
      if (provider.profileData?['date_of_birth'] != null) {
        try {
          _dateOfBirth = DateTime.parse(provider.profileData!['date_of_birth']);
        } catch (e) {
          _dateOfBirth = null;
        }
      }

      // Dropdowns
      _gender = provider.gender;
      _lookingFor = provider.lookingFor;

      // Intérêts
      _interests = List<String>.from(provider.interests);

      // Localisation
      if (provider.latitude != null) {
        _latitudeController.text = provider.latitude.toString();
      }
      if (provider.longitude != null) {
        _longitudeController.text = provider.longitude.toString();
      }

      // Forcer rebuild pour afficher les valeurs
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _heightController.dispose();
    _educationController.dispose();
    _relationshipStatusController.dispose();
    _instagramController.dispose();
    _spotifyController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
              Colors.pinkAccent.withOpacity(0.8),
              Colors.orangeAccent.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildSectionTitle('Infos de base'),
                      _buildTextField(_fullNameController, 'Nom complet',
                          Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildDatePickerField(),
                      const SizedBox(height: 16),
                      _buildDropdownField('Genre', ['male', 'female', 'other'],
                          (v) => _gender = v),
                      const SizedBox(height: 16),
                      _buildDropdownField('Recherche',
                          ['male', 'female', 'both'], (v) => _lookingFor = v),
                      const SizedBox(height: 24),
                      _buildSectionTitle('À propos de vous'),
                      _buildTextField(_bioController, 'Bio', Icons.edit_note,
                          maxLines: 3),
                      const SizedBox(height: 16),
                      _buildInterestsInput(),
                      const SizedBox(height: 16),
                      _buildTextField(_occupationController, 'Profession',
                          Icons.work_outline),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _heightController, 'Taille (cm)', Icons.height,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _educationController, 'Éducation', Icons.school),
                      const SizedBox(height: 16),
                      _buildTextField(_relationshipStatusController,
                          'Statut relationnel', Icons.favorite_border),
                      _buildSectionTitle('Localisation'),
                      _buildTextField(
                          _cityController, 'Ville', Icons.location_city),
                      const SizedBox(height: 16),
                      _buildTextField(_countryController, 'Pays', Icons.flag),
                      const SizedBox(height: 16),
                      _buildTextField(_latitudeController,
                          'Latitude (optionnel)', Icons.my_location,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 16),
                      _buildTextField(_longitudeController,
                          'Longitude (optionnel)', Icons.my_location,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true)),
                      _buildSectionTitle('Photos'),
                      _buildAvatarUploader(),
                      const SizedBox(height: 16),
                      _buildCoverUploader(),
                      const SizedBox(height: 16),
                      _buildGalleryBottomSheetButton(provider),
                      _buildSectionTitle('Social'),
                      _buildTextField(_instagramController, 'Instagram handle',
                          Icons.camera_alt),
                      const SizedBox(height: 16),
                      _buildTextField(_spotifyController, 'Spotify anthem',
                          Icons.music_note),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Complétez votre profil',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          TextButton(
            onPressed: _handleSkip,
            child: const Text('Passer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildDropdownField(
      String label, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: Colors.black.withOpacity(0.8),
      style: const TextStyle(color: Colors.white),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _dateOfBirth = picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          _dateOfBirth == null
              ? 'Sélectionnez'
              : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInterestsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Intérêts',
          style: TextStyle(color: Colors.white70),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interests
              .map((interest) => Chip(
                    label: Text(interest),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () =>
                        setState(() => _interests.remove(interest)),
                  ))
              .toList(),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          onPressed: () async {
            final interest = await showDialog<String>(
              context: context,
              builder: (context) {
                final ctrl = TextEditingController();
                return AlertDialog(
                  title: const Text('Ajouter intérêt'),
                  content: TextField(controller: ctrl),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                      child: const Text('Ajouter'),
                    ),
                  ],
                );
              },
            );
            if (interest != null && interest.isNotEmpty) {
              setState(() => _interests.add(interest));
            }
          },
        ),
      ],
    );
  }

  Widget _buildAvatarUploader() {
    return Center(
      child: GestureDetector(
        onTap: () => _pickImageForAvatar(),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage:
                  _avatarFile != null ? FileImage(_avatarFile!) : null,
              child: _avatarFile == null
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                  : null,
            ),
            const Positioned(
              bottom: 0,
              right: 0,
              child: Icon(Icons.edit, color: Colors.pinkAccent, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverUploader() {
    return GestureDetector(
      onTap: () => _pickImageForCover(),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          image: _coverFile != null
              ? DecorationImage(
                  image: FileImage(_coverFile!), fit: BoxFit.cover)
              : null,
        ),
        child: _coverFile == null
            ? const Center(
                child: Icon(Icons.add_photo_alternate,
                    size: 60, color: Colors.white))
            : null,
      ),
    );
  }

  Widget _buildGalleryBottomSheetButton(ProfileProvider provider) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.photo_library),
      label: const Text('Galerie photos'),
      onPressed: () => _showGalleryBottomSheet(provider),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  void _showGalleryBottomSheet(ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Galerie photos (max 6)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: provider.photos.length +
                    (provider.photos.length < 6 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < provider.photos.length) {
                    return GestureDetector(
                      onTap: () => provider
                          .removePhotoFromGallery(provider.photos[index]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: provider.photos[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _pickImageForGallery(provider),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, size: 40),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageForAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _pickImageForCover() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _coverFile = File(picked.path));
  }

  Future<void> _pickImageForGallery(ProfileProvider provider) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      await provider.addPhotoToGallery(File(picked.path));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildSaveButton(ProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FilledButton(
        onPressed: () => _handleSave(provider),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('Sauvegarder et continuer',
            style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Future<void> _handleSave(ProfileProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String? photoUrl;
      if (_avatarFile != null) {
        photoUrl = await provider.uploadPhoto(_avatarFile!);
      }

      String? coverUrl;
      if (_coverFile != null) {
        coverUrl = await provider.uploadPhoto(_coverFile!, isCover: true);
      }

      await provider.updateProfile(
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        occupation: _occupationController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        lookingFor: _lookingFor,
        heightCm: int.tryParse(_heightController.text.trim()),
        education: _educationController.text.trim(),
        relationshipStatus: _relationshipStatusController.text.trim(),
        instagramHandle: _instagramController.text.trim(),
        spotifyAnthem: _spotifyController.text.trim(),
        latitude: double.tryParse(_latitudeController.text.trim()),
        longitude: double.tryParse(_longitudeController.text.trim()),
        interests: _interests,
        photoUrl: photoUrl,
        coverUrl: coverUrl,
      );

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNav()));
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _handleSkip() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const BottomNav()));
  }
}
