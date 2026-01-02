import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Tinder/bottom_nav.dart';
import 'auth_provider_v2.dart';

/// 🎯 Écran de complétion du profil - Style onboarding moderne
class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 3;

  // Contrôleurs pour les champs
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Champs spécifiques selon le rôle
  final _organizationNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _organizationNameController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              _buildHeader(context),
              _buildProgressIndicator(colorScheme),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    _buildPersonalInfoStep(),
                    _buildContactInfoStep(),
                    _buildRoleSpecificStep(),
                  ],
                ),
              ),
              _buildNavigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête avec titre et bouton skip
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complétez votre profil',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Étape ${_currentStep + 1} sur $_totalSteps',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleSkip,
            child: const Text('Passer'),
          ),
        ],
      ),
    );
  }

  /// Barre de progression visuelle
  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Étape 1 : Informations personnelles
  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepTitle('Informations personnelles'),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _firstNameController,
              label: 'Prénom',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              label: 'Nom',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Étape 2 : Coordonnées
  Widget _buildContactInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Coordonnées'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _addressController,
            label: 'Adresse',
            icon: Icons.home_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre adresse';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _cityController,
                  label: 'Ville',
                  icon: Icons.location_city_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ville requise';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Code postal',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                  icon: Icons.local_post_office,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Étape 3 : Informations spécifiques au rôle
  Widget _buildRoleSpecificStep() {
    final authProvider = context.watch<AuthProviderV2>();
    final role = authProvider.userData?['role'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(_getRoleSpecificTitle(role)),
          const SizedBox(height: 24),
          if (role == 'coach' || role == 'school') ...[
            _buildTextField(
              controller: _organizationNameController,
              label:
                  role == 'coach' ? 'Nom du club/organisation' : 'Nom du club',
              icon: Icons.business_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          if (role == 'coach') ...[
            _buildTextField(
              controller: _licenseNumberController,
              label: 'Numéro de licence (optionnel)',
              icon: Icons.badge_outlined,
            ),
          ],
          const SizedBox(height: 24),
          _buildInfoCard(
            _getRoleInfoText(role),
            Icons.info_outline,
          ),
        ],
      ),
    );
  }

  /// Titre d'étape avec icône
  Widget _buildStepTitle(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStepIcon(_currentStep),
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  /// Champ de texte stylisé
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      validator: validator,
    );
  }

  /// Carte d'information
  Widget _buildInfoCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Boutons de navigation
  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _handlePrevious,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _handleNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Consumer<AuthProviderV2>(
                builder: (context, authProvider, _) {
                  if (authProvider.isLoading) {
                    return const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    );
                  }

                  return Text(
                    _currentStep == _totalSteps - 1 ? 'Terminer' : 'Suivant',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  void _handlePrevious() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNext() {
    bool isValid = true;

    if (_currentStep == 0) {
      isValid = _formKey.currentState!.validate();
    }

    if (_currentStep == 1) {
      isValid = _addressController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _postalCodeController.text.isNotEmpty;
    }

    // Pour coach / school
    if (_currentStep == 2) {
      final role =
          context.read<AuthProviderV2>().currentUser?.userMetadata?['role'];

      if (role == 'coach' || role == 'school') {
        if (_organizationNameController.text.isEmpty) {
          _showSnackBar("Veuillez remplir le champ organisation",
              isError: true);
          return;
        }
      }
    }

    if (!isValid) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSaveProfile();
    }
  }

  Future<void> _handleSaveProfile() async {
    final authProvider = context.read<AuthProviderV2>();
    final user = authProvider.currentUser;

    if (user == null) {
      _showSnackBar("Utilisateur non authentifié", isError: true);
      return;
    }

    final role = user.userMetadata?['role'] as String? ?? 'parent';

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();

    final profileData = {
      'name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'profile_completed': true, // ← important pour ne plus revenir ici
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (role == 'coach' || role == 'school') {
      profileData['organization_name'] =
          _organizationNameController.text.trim();
    }
    if (role == 'coach') {
      profileData['license_number'] = _licenseNumberController.text.trim();
    }

    final result = await authProvider.updateUserProfile(profileData);

    if (!mounted) return;

    if (result.success) {
      _showSnackBar('Profil complété avec succès !', isError: false);

      // Redirection immédiate vers le dashboard principal
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BottomNav()),
        (route) => false,
      );
    } else {
      _showSnackBar(result.message ?? 'Erreur lors de la sauvegarde',
          isError: true);
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

// Correction ciblée : _handleSkip doit quitter l'écran de complétion
// et rediriger vers le dashboard principal

  void _handleSkip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passer cette étape ?'),
        content: const Text(
          'Vous pourrez compléter votre profil plus tard depuis les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Annuler le dialog
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Ferme le dialog

              // Optionnel : marquer explicitement que l'utilisateur a skip
              // pour ne plus le montrer au prochain login
              final authProvider = context.read<AuthProviderV2>();
              await authProvider.updateUserProfile({
                'profile_completed': false,
                // ou un champ dédié 'onboarding_skipped': true
                'updated_at': DateTime.now().toIso8601String(),
              });

              // Quitte définitivement l'écran de complétion
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BottomNav()),
                  // ← ton dashboard principal
                  (route) => false, // supprime tout le stack précédent
                );
              }

              _showSnackBar(
                  'Profil complétable plus tard depuis les paramètres',
                  isError: false);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.location_on_outlined;
      case 2:
        return Icons.workspace_premium_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _getRoleSpecificTitle(String? role) {
    switch (role) {
      case 'parent':
        return 'Informations parent';
      case 'coach':
        return 'Informations coach';
      case 'school':
        return 'Informations club';
      default:
        return 'Informations supplémentaires';
    }
  }

  String _getRoleInfoText(String? role) {
    switch (role) {
      case 'parent':
        return 'En tant que parent, vous pourrez inscrire vos enfants aux cours et suivre leur progression.';
      case 'coach':
        return 'En tant que coach, vous pourrez gérer vos cours et suivre vos élèves.';
      case 'school':
        return 'En tant que club, vous pourrez gérer vos coachs, cours et inscriptions.';
      default:
        return 'Complétez votre profil pour accéder à toutes les fonctionnalités.';
    }
  }
}
