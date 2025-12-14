import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:kenzy/Kids/claude/auth_provider_v2.dart';
import 'package:provider/provider.dart';

import '../models/course_model_complete.dart';
import '../models/user_model.dart';
import '../providers/course_provider_complete.dart';
import '../services/location_service_osm.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/location_picker_dialog_widget.dart';
import '../widgets/location_picker_windows.dart';

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
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();

    print(
        '╔═══════════════════════════════════════════════════════════════════');
    print('🔵 [CreateCourse] initState - DÉBUT');
    print('🔵 [PLATFORM] OS: ${Platform.operatingSystem}');
    print('🔵 [PLATFORM] Version: ${Platform.operatingSystemVersion}');
    print('🔵 [PLATFORM] isWindows: ${!kIsWeb && Platform.isWindows}');
    print('🔵 [PLATFORM] kIsWeb: $kIsWeb');
    print(
        '╚═══════════════════════════════════════════════════════════════════');

    try {
      if (widget.courseToEdit != null) {
        print('🔵 [CreateCourse] Mode ÉDITION');
        _loadCourseData();
      } else {
        print('🔵 [CreateCourse] Mode CRÉATION');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('🔵 [CreateCourse] PostFrameCallback appelé');
          _loadCurrentLocation();
        });
      }
    } catch (e, stackTrace) {
      print('❌ [CreateCourse] CRASH initState: $e');
      print('❌ [CreateCourse] StackTrace: $stackTrace');
      rethrow;
    }
  }

  void _loadCourseData() {
    print('🔵 [CreateCourse] _loadCourseData - DÉBUT');
    try {
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
      print('✅ [CreateCourse] Données chargées');
    } catch (e, stackTrace) {
      print('❌ [CreateCourse] CRASH _loadCourseData: $e');
      print('❌ [CreateCourse] StackTrace: $stackTrace');
    }
  }

  Future<void> _loadCurrentLocation() async {
    print('🔵 [CreateCourse] _loadCurrentLocation - DÉBUT');
    if (!mounted) {
      print('⚠️ [CreateCourse] Widget pas mounted');
      return;
    }

    setState(() => _isLoadingLocation = true);
    print('🔵 [CreateCourse] Loading location state: true');

    try {
      print('🔵 [CreateCourse] Création LocationService...');
      final locationService = LocationService();
      print('✅ [CreateCourse] LocationService créé');

      print('🔵 [CreateCourse] Appel getCurrentCourseLocation...');
      final location = await locationService.getCurrentCourseLocation();
      print(
          '🔵 [CreateCourse] getCurrentCourseLocation retour: ${location != null ? "NON NULL" : "NULL"}');

      if (location != null && mounted) {
        print('✅ [CreateCourse] Location reçue:');
        print('   - lat: ${location.latitude}');
        print('   - lon: ${location.longitude}');
        print('   - address: ${location.address}');

        setState(() {
          _selectedLocation = location;
          _isLoadingLocation = false;
        });
        print('✅ [CreateCourse] Location assignée');
      } else {
        print('⚠️ [CreateCourse] Location NULL ou widget pas mounted');
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
      }
    } catch (e, stackTrace) {
      print('❌ [CreateCourse] CRASH _loadCurrentLocation: $e');
      print('❌ [CreateCourse] StackTrace: $stackTrace');

      if (mounted) {
        setState(() => _isLoadingLocation = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur localisation: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    print('🔵 [CreateCourse] _loadCurrentLocation - FIN');
  }

  @override
  void dispose() {
    print('🔵 [CreateCourse] dispose');
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    print('🔵 [CreateCourse] _pickImages - DÉBUT');
    try {
      print('🔵 [CreateCourse] Appel FilePicker.platform.pickFiles...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
      );
      print(
          '🔵 [CreateCourse] FilePicker retour: ${result != null ? "${result.files.length} fichiers" : "NULL"}');

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(result.files.map((file) => File(file.path!)));
        });
        print('✅ [CreateCourse] ${result.files.length} images ajoutées');
      }
    } catch (e, stackTrace) {
      print('❌ [CreateCourse] CRASH _pickImages: $e');
      print('❌ [CreateCourse] StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur sélection images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    print('🔵 [CreateCourse] _removeImage index: $index');
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectLocation() async {
    print('🔵 [CreateCourse] _selectLocation - DÉBUT');
    final bool useWindowsVersion = !kIsWeb && Platform.isWindows;
    print('🔵 [CreateCourse] useWindowsVersion: $useWindowsVersion');

    try {
      print('🔵 [CreateCourse] Affichage dialog localisation...');
      final result = await showDialog<CourseLocation>(
        context: context,
        builder: (context) => useWindowsVersion
            ? LocationPickerDialogWindows(initialLocation: _selectedLocation)
            : LocationPickerDialog(
                initialLocation: _selectedLocation != null
                    ? AppLocation(
                        latitude: _selectedLocation!.latitude,
                        longitude: _selectedLocation!.longitude,
                        address: _selectedLocation!.address,
                        city: _selectedLocation!.city,
                        country: _selectedLocation!.country,
                      )
                    : null,
              ),
      );
      print(
          '🔵 [CreateCourse] Dialog fermé, résultat: ${result != null ? "NON NULL" : "NULL"}');

      if (result != null && mounted) {
        setState(() => _selectedLocation = result);
        print('✅ [CreateCourse] Nouvelle location: ${result.address}');
      }
    } catch (e, stackTrace) {
      print('❌ [CreateCourse] CRASH _selectLocation: $e');
      print('❌ [CreateCourse] StackTrace: $stackTrace');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    print('🔵 [CreateCourse] _selectDate - ${isStartDate ? "START" : "END"}');
    try {
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
        print('✅ [CreateCourse] Date sélectionnée: $picked');
      }
    } catch (e, stackTrace) {
      print('❌ [CreateCourse] CRASH _selectDate: $e');
      print('❌ [CreateCourse] StackTrace: $stackTrace');
    }
  }

  // ✅ VERSION REFACTORISÉE : Gestion robuste sans Consumer
  Future<void> _saveCourse() async {
    print(
        '╔═══════════════════════════════════════════════════════════════════');
    print('🔵 [SAVE] Début _saveCourse');
    print(
        '╚═══════════════════════════════════════════════════════════════════');

    // ÉTAPE 1 : Validation
    print('🔵 [SAVE] ÉTAPE 1/8 : Validation formulaire...');
    if (!_formKey.currentState!.validate()) {
      print('❌ [SAVE] Validation échouée');
      return;
    }
    print('✅ [SAVE] Validation OK');

    // ÉTAPE 2 : Location
    print('🔵 [SAVE] ÉTAPE 2/8 : Vérification location...');
    if (_selectedLocation == null) {
      print('❌ [SAVE] Location NULL');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez sélectionner une localisation')),
        );
      }
      return;
    }
    print('✅ [SAVE] Location OK: ${_selectedLocation!.address}');

    // ÉTAPE 3 : Providers
    print('🔵 [SAVE] ÉTAPE 3/8 : Récupération providers...');

    if (!mounted) {
      print('❌ [SAVE] Widget PAS mounted avant récupération providers');
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProviderV2>(context, listen: false);

    print('✅ [SAVE] CourseProvider récupéré');
    print('✅ [SAVE] AuthProvider récupéré');

    if (authProvider.currentUser == null) {
      print('❌ [SAVE] currentUser NULL');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Utilisateur non connecté')),
        );
      }
      return;
    }
    print('✅ [SAVE] currentUser: ${authProvider.currentUser!.id}');

    if (authProvider.userData == null) {
      print('❌ [SAVE] userData NULL');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur: Données utilisateur manquantes')),
        );
      }
      return;
    }
    print('✅ [SAVE] userData disponible');

    // ÉTAPE 4 : Préparation
    print('🔵 [SAVE] ÉTAPE 4/8 : Préparation données...');
    final hasImages = _selectedImages.isNotEmpty;
    print('🔵 [SAVE] Nombre d\'images: ${_selectedImages.length}');
    print('🔵 [SAVE] hasImages: $hasImages');
    print(
        '🔵 [SAVE] Mode: ${widget.courseToEdit == null ? "CRÉATION" : "ÉDITION"}');

    // ✅ NOUVEAU : Afficher le dialog AVANT l'opération avec gestion robuste du context
    print('🔵 [SAVE] ÉTAPE 5/8 : Affichage dialog...');

    if (!mounted) {
      print('❌ [SAVE] Widget PAS mounted avant dialog');
      return;
    }

    // Capturer le context de navigation AVANT showDialog
    final navigatorContext = Navigator.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          print('🔵 [SAVE] Builder dialog appelé');
          return _SaveProgressDialog(
            hasImages: hasImages,
            isEdit: widget.courseToEdit != null,
            progressNotifier: courseProvider.uploadProgressNotifier,
          );
        },
      );
      print('✅ [SAVE] Dialog affiché');
    } catch (e, stackTrace) {
      print('❌ [SAVE] CRASH showDialog: $e');
      print('❌ [SAVE] StackTrace: $stackTrace');
      return;
    }

    // ÉTAPE 6 : Attente courte pour laisser le dialog s'afficher
    print('🔵 [SAVE] ÉTAPE 6/8 : Attente 150ms...');
    await Future.delayed(const Duration(milliseconds: 150));
    print('✅ [SAVE] Attente terminée');

    // ÉTAPE 7 : Opération cloud avec gestion d'erreur complète
    print('🔵 [SAVE] ÉTAPE 7/8 : Opération cloud...');

    bool success = false;
    String? errorMessage;

    try {
      if (widget.courseToEdit == null) {
        print('🔵 [SAVE] Appel courseProvider.createCourse...');
        print('🔵 [SAVE] Paramètres:');
        print('   - title: ${_titleController.text.trim()}');
        print(
            '   - description: ${_descriptionController.text.trim().substring(0, 50)}...');
        print('   - category: $_selectedCategory');
        print('   - price: ${_priceController.text}');
        print('   - season: $_selectedSeason');
        print('   - location: ${_selectedLocation!.address}');
        print('   - imageFiles: ${_selectedImages.length}');
        print('   - maxStudents: ${_maxStudentsController.text}');

        // Dans _saveCourse()
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
          currentUserId: authProvider.currentUser!.id,
          // ✅ UUID direct
          currentUserRole: authProvider.userData!['role'],
          // ✅ Rôle depuis userData
          maxStudents: int.tryParse(_maxStudentsController.text) ?? 30,
        );
        print('✅ [SAVE] createCourse terminé: $success');
      } else {
        print('🔵 [SAVE] Appel courseProvider.updateCourse...');
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
        );
        print('✅ [SAVE] updateCourse terminé: $success');
      }

      errorMessage = courseProvider.error;
    } catch (e, stackTrace) {
      print('❌ [SAVE] CRASH opération cloud: $e');
      print('❌ [SAVE] StackTrace: $stackTrace');
      success = false;
      errorMessage = e.toString();
    }

    print('🔵 [SAVE] Résultat opération: $success');

    // ÉTAPE 8 : Fermeture et feedback
    print('🔵 [SAVE] ÉTAPE 8/8 : Fermeture et feedback...');

    // ✅ NOUVEAU : Fermer le dialog avec le navigatorContext capturé
    print('🔵 [SAVE] Fermeture dialog...');
    try {
      navigatorContext.pop();
      print('✅ [SAVE] Dialog fermé');
    } catch (e) {
      print('⚠️ [SAVE] Erreur fermeture dialog: $e');
    }

    // Vérifier mounted après fermeture dialog
    if (!mounted) {
      print('❌ [SAVE] Widget PAS mounted après opération');
      return;
    }
    print('✅ [SAVE] Widget mounted');

    if (success) {
      print('🔵 [SAVE] Succès : Affichage SnackBar...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.courseToEdit == null
              ? 'Cours créé avec succès'
              : 'Cours mis à jour avec succès'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      print('✅ [SAVE] SnackBar affiché');

      print('🔵 [SAVE] Attente 300ms avant navigation...');
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        print('🔵 [SAVE] Navigation pop...');
        Navigator.pop(context);
        print('✅ [SAVE] Navigation terminée');
      }
    } else {
      print('🔵 [SAVE] Échec : Affichage erreur...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      print('✅ [SAVE] SnackBar erreur affiché');
    }

    print(
        '╔═══════════════════════════════════════════════════════════════════');
    print('✅ [SAVE] Fin _saveCourse');
    print(
        '╚═══════════════════════════════════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseToEdit == null
            ? 'Créer un cours'
            : 'Modifier le cours'),
      ),
      body: _buildForm(),
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
            labelText: 'Titre du cours *',
            hintText: 'Ex: Cours de Mathématiques',
            helperText: 'Minimum 3 caractères',
            prefixIcon: Icon(Icons.title),
          ),
          maxLength: 100,
          // ✅ Limite maximale
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le titre est requis';
            }

            final trimmed = value.trim();

            // ✅ Contrainte Supabase : >= 3 caractères
            if (trimmed.length < 3) {
              return 'Le titre doit contenir au moins 3 caractères';
            }

            // ✅ Limite raisonnable
            if (trimmed.length > 100) {
              return 'Le titre ne peut pas dépasser 100 caractères';
            }

            return null; // Valide
          },
          onChanged: (value) {
            setState(() {}); // Pour mettre à jour l'aperçu
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
            if (value.trim().length < 10) {
              return 'La description doit contenir au moins 10 caractères';
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
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'DZD',
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
            leading: _isLoadingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.location_on),
            title: const Text('Localisation'),
            subtitle: _selectedLocation != null
                ? Text(_selectedLocation!.address)
                : _isLoadingLocation
                    ? const Text('Recherche de votre position...')
                    : const Text('Aucune localisation sélectionnée'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isLoadingLocation ? null : _selectLocation,
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

// ✅ NOUVEAU DIALOG : Sans Consumer, utilise ValueListenableBuilder
class _SaveProgressDialog extends StatelessWidget {
  final bool hasImages;
  final bool isEdit;
  final ValueNotifier<double> progressNotifier;

  const _SaveProgressDialog({
    required this.hasImages,
    required this.isEdit,
    required this.progressNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                isEdit ? 'Mise à jour du cours...' : 'Création du cours...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              if (hasImages) ...[
                const SizedBox(height: 16),
                Text(
                  'Upload des images en cours...',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // ✅ UTILISATION DE ValueListenableBuilder au lieu de Consumer
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (context, progress, child) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (progress > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Sauvegarde en cours...',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Veuillez patienter...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
