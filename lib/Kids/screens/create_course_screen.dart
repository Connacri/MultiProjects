import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../providers/auth_provider_dart.dart';
import '../providers/course_provider_complete.dart';
import '../services/location_service_osm.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/location_picker_dialog_widget.dart';

class CreateCourseScreen extends StatefulWidget {
  final CourseModel? courseToEdit;

  const CreateCourseScreen({super.key, this.courseToEdit});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController();

  CourseCategory _selectedCategory = CourseCategory.other;
  CourseSeason _selectedSeason = CourseSeason.yearRound;
  DateTime _seasonStartDate = DateTime.now();
  DateTime _seasonEndDate = DateTime.now().add(const Duration(days: 365));
  CourseLocation? _selectedLocation;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.courseToEdit != null) {
      _loadCourseData();
    } else {
      _loadCurrentLocation();
    }
  }

  void _loadCourseData() {
    final course = widget.courseToEdit!;
    _titleController.text = course.title;
    _descriptionController.text = course.description;
    _priceController.text = course.price?.toString() ?? '';
    _maxStudentsController.text = course.maxStudents.toString();
    _selectedCategory = course.category;
    _selectedSeason = course.season;
    _seasonStartDate = course.seasonStartDate;
    _seasonEndDate = course.seasonEndDate;
    _selectedLocation = course.location;
  }

  Future<void> _loadCurrentLocation() async {
    final locationService = LocationService();
    final location = await locationService.getCurrentCourseLocation();
    if (location != null && mounted) {
      setState(() => _selectedLocation = location);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<CourseLocation>(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _seasonStartDate : _seasonEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _seasonStartDate = picked;
        } else {
          _seasonEndDate = picked;
        }
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une localisation')),
      );
      return;
    }

    if (widget.courseToEdit == null && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final courseProvider = context.read<CourseProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    bool success;

    if (widget.courseToEdit == null) {
      success = await courseProvider.createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        season: _selectedSeason,
        seasonStartDate: _seasonStartDate,
        seasonEndDate: _seasonEndDate,
        location: _selectedLocation!,
        imageFiles: _selectedImages,
        currentUser: authProvider.user!,
        maxStudents: int.tryParse(_maxStudentsController.text) ?? 30,
        onImageUploadProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
          });
        },
      );
    } else {
      success = await courseProvider.updateCourse(
        courseId: widget.courseToEdit!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        season: _selectedSeason,
        seasonStartDate: _seasonStartDate,
        seasonEndDate: _seasonEndDate,
        location: _selectedLocation,
        newImageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        maxStudents: int.tryParse(_maxStudentsController.text) ?? 30,
        onImageUploadProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
          });
        },
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.courseToEdit == null
                ? 'Cours créé avec succès'
                : 'Cours mis à jour avec succès'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(courseProvider.error ?? 'Une erreur est survenue'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseToEdit == null
            ? 'Créer un cours'
            : 'Modifier le cours'),
      ),
      body: _isLoading ? _buildLoadingIndicator() : _buildForm(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Upload des images...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(value: _uploadProgress),
          ),
          const SizedBox(height: 8),
          Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ResponsiveBuilder(
        builder: (context, deviceType) {
          if (deviceType == DeviceType.desktop) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormFields(),
                ),
                Expanded(
                  child: _buildPreviewPanel(),
                ),
              ],
            );
          }
          return _buildFormFields();
        },
      ),
    );
  }

  Widget _buildFormFields() {
    return ListView(
      padding: ResponsiveLayout.getResponsivePadding(context),
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titre du cours',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le titre est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<CourseCategory>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            prefixIcon: Icon(Icons.category),
          ),
          items: CourseCategory.values
              .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix (optionnel)',
                  prefixIcon: Icon(Icons.euro),
                  suffixText: 'EUR',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Places maximum',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requis';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<CourseSeason>(
          value: _selectedSeason,
          decoration: const InputDecoration(
            labelText: 'Saison',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          items: CourseSeason.values
              .map((season) => DropdownMenuItem(
                    value: season,
                    child: Text(season.displayName),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedSeason = value);
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Date de début'),
                subtitle: Text(
                  '${_seasonStartDate.day}/${_seasonStartDate.month}/${_seasonStartDate.year}',
                ),
                leading: const Icon(Icons.event),
                onTap: () => _selectDate(context, true),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ListTile(
                title: const Text('Date de fin'),
                subtitle: Text(
                  '${_seasonEndDate.day}/${_seasonEndDate.month}/${_seasonEndDate.year}',
                ),
                leading: const Icon(Icons.event),
                onTap: () => _selectDate(context, false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Localisation'),
            subtitle: _selectedLocation != null
                ? Text(_selectedLocation!.address)
                : const Text('Aucune localisation sélectionnée'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _selectLocation,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Images du cours',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16),
                          color: Colors.white,
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Ajouter des images'),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _saveCourse,
          icon: const Icon(Icons.save),
          label: Text(
              widget.courseToEdit == null ? 'Créer le cours' : 'Mettre à jour'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            _titleController.text.isEmpty
                ? 'Titre du cours'
                : _titleController.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Chip(label: Text(_selectedCategory.displayName)),
          const SizedBox(height: 16),
          Text(
            _descriptionController.text.isEmpty
                ? 'Description du cours...'
                : _descriptionController.text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
