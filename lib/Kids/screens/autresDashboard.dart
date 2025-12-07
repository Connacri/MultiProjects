import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';

import '../claude/auth_provider_v2.dart';
import '../models/user_model.dart';

class AutreDashboard extends StatefulWidget {
  const AutreDashboard({super.key});

  @override
  State<AutreDashboard> createState() => _AutreDashboardState();
}

class _AutreDashboardState extends State<AutreDashboard> {
  bool _isLoading = true;
  UserModel? _user;
  String? _error;

  // Controllers pour édition inline
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _editingFields = {};

  // États des sections expandables
  bool _infoExpanded = true;
  bool _locationExpanded = false;
  bool _imagesExpanded = false;
  bool _metadataExpanded = false;
  bool _technicalExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProviderV2>();
      final userData = authProvider.userData;

      if (userData == null) {
        setState(() {
          _error = 'Aucune donnée utilisateur disponible';
          _isLoading = false;
        });
        return;
      }

      // Construire le UserModel depuis les données brutes
      _user = UserModel.fromSupabase(userData);

      // Initialiser les controllers
      _initializeControllers();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    if (_user == null) return;

    _controllers['name'] = TextEditingController(text: _user!.name);
    _controllers['email'] = TextEditingController(text: _user!.email);
    _controllers['bio'] = TextEditingController(text: _user!.bio ?? '');
    _controllers['phoneNumber'] =
        TextEditingController(text: _user!.phoneNumber ?? '');
    _controllers['address'] =
        TextEditingController(text: _user!.location?.address ?? '');
    _controllers['city'] =
        TextEditingController(text: _user!.location?.city ?? '');
    _controllers['country'] =
        TextEditingController(text: _user!.location?.country ?? '');
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mon Profil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Actualiser',
              ),
            ],
          ),
          body: _buildBody(isDesktop),
        );
      },
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des données...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text('Aucun utilisateur trouvé'),
      );
    }

    // Vérifier si l'utilisateur est désactivé
    if (!_user!.isActive) {
      return _buildDeactivatedWarning();
    }

    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }

  // ============================================================================
  // LAYOUT MOBILE
  // ============================================================================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCoverAndAvatar(),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildQuickInfo(),
                const SizedBox(height: 16),
                _buildPersonalInfoSection(),
                const SizedBox(height: 12),
                _buildLocationSection(),
                const SizedBox(height: 12),
                _buildImagesSection(),
                const SizedBox(height: 12),
                _buildMetadataSection(),
                const SizedBox(height: 12),
                _buildTechnicalInfoSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LAYOUT DESKTOP
  // ============================================================================

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCoverAndAvatar(),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildQuickInfo(),
                      const SizedBox(height: 16),
                      _buildPersonalInfoSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Colonne droite
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildLocationSection(),
                      const SizedBox(height: 16),
                      _buildImagesSection(),
                      const SizedBox(height: 16),
                      _buildMetadataSection(),
                      const SizedBox(height: 16),
                      _buildTechnicalInfoSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // COVER & AVATAR
  // ============================================================================

  Widget _buildCoverAndAvatar() {
    final coverUrl = _user!.profileImages.coverImage;
    final profileUrl = _user!.profileImages.profileImage;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
              gradient: coverUrl == null
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    )
                  : null,
              image: coverUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(coverUrl),
                      fit: BoxFit.scaleDown,
                    )
                  : DecorationImage(
                      image: AssetImage('assets/photos/a (5).png'),
                      fit: BoxFit.cover,
                    )),
          child: coverUrl == null
              ? Center(
                  child: Icon(
                    Icons.landscape,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),

        // Avatar
        Positioned(
          bottom: -40,
          left: 24,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 4,
              ),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  profileUrl != null ? NetworkImage(profileUrl) : null,
              child: profileUrl == null
                  ? Text(
                      _user!.name.isNotEmpty
                          ? _user!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // QUICK INFO (sous avatar)
  // ============================================================================

  Widget _buildQuickInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user!.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(),
              ],
            ),
            if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ReadMoreText(
                _user!.bio!,
                trimMode: TrimMode.Length,
                trimLength: 85,
                trimLines: 2,
                // colorClickableText: Colors.blue,
                trimCollapsedText: '  more',
                trimExpandedText: '  less',
                moreStyle: Theme.of(context).textTheme.bodyMedium,
              ),

              // Text(
              //   _user!.bio!,
              //   style: Theme
              //       .of(context)
              //       .textTheme
              //       .bodyMedium,
              // ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    final role = _user!.role;
    IconData icon;
    Color color;

    switch (role) {
      case UserRole.parent:
        icon = Icons.family_restroom;
        color = Colors.blue;
        break;
      case UserRole.coach:
        icon = Icons.sports;
        color = Colors.green;
        break;
      case UserRole.school:
        icon = Icons.school;
        color = Colors.orange;
        break;
      case UserRole.autres:
        icon = Icons.account_box;
        color = Colors.blue;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        role.displayName,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  // ============================================================================
  // SECTIONS EXPANDABLES
  // ============================================================================

  Widget _buildPersonalInfoSection() {
    return Consumer<AuthProviderV2>(
        // ✅ Rebuild UNIQUEMENT si userData change
        builder: (context, authProvider, child) {
      return _buildExpandableCard(
        title: 'Informations personnelles',
        icon: Icons.person,
        isExpanded: _infoExpanded,
        onTap: () => setState(() => _infoExpanded = !_infoExpanded),
        children: [
          _buildEditableField(
            label: 'Nom complet',
            value: _user!.name,
            fieldKey: 'name',
            icon: Icons.badge,
          ),
          _buildEditableField(
            label: 'Email',
            value: _user!.email,
            fieldKey: 'email',
            icon: Icons.email,
            readOnly: true, // L'email ne peut pas être modifié
          ),
          _buildEditableField(
            label: 'Téléphone',
            value: _user!.phoneNumber ?? 'Non renseigné',
            fieldKey: 'phoneNumber',
            icon: Icons.phone,
          ),
          _buildEditableField(
            label: 'Bio',
            value: _user!.bio ?? 'Aucune bio',
            fieldKey: 'bio',
            icon: Icons.description,
            maxLines: 3,
          ),
        ],
      );
    });
  }

  Widget _buildLocationSection() {
    final hasLocation = _user!.location?.hasLocation ?? false;

    return _buildExpandableCard(
      title: 'Localisation',
      icon: Icons.location_on,
      isExpanded: _locationExpanded,
      onTap: () => setState(() => _locationExpanded = !_locationExpanded),
      children: [
        if (hasLocation) ...[
          _buildEditableField(
            label: 'Adresse',
            value: _user!.location!.address,
            fieldKey: 'address',
            icon: Icons.home,
          ),
          _buildEditableField(
            label: 'Ville',
            value: _user!.location!.city ?? 'Non spécifiée',
            fieldKey: 'city',
            icon: Icons.location_city,
          ),
          _buildEditableField(
            label: 'Pays',
            value: _user!.location!.country ?? 'Non spécifié',
            fieldKey: 'country',
            icon: Icons.flag,
          ),
          _buildReadOnlyField(
            label: 'Coordonnées GPS',
            value:
                '${_user!.location!.latitude.toStringAsFixed(6)}, ${_user!.location!.longitude.toStringAsFixed(6)}',
            icon: Icons.my_location,
          ),
        ] else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucune localisation configurée'),
          ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return _buildExpandableCard(
      title: 'Images de profil',
      icon: Icons.image,
      isExpanded: _imagesExpanded,
      onTap: () => setState(() => _imagesExpanded = !_imagesExpanded),
      children: [
        _buildImageInfo(
          label: 'Photo de profil (Firebase)',
          url: _user!.profileImages.profileImageFirebase,
        ),
        _buildImageInfo(
          label: 'Photo de profil (Supabase)',
          url: _user!.profileImages.profileImageSupabase,
        ),
        _buildImageInfo(
          label: 'Image de couverture (Firebase)',
          url: _user!.profileImages.coverImageFirebase,
        ),
        _buildImageInfo(
          label: 'Image de couverture (Supabase)',
          url: _user!.profileImages.coverImageSupabase,
        ),
        if (_user!.profileImages.lastUpdated != null)
          _buildReadOnlyField(
            label: 'Dernière mise à jour',
            value: _formatDateTime(_user!.profileImages.lastUpdated!),
            icon: Icons.update,
          ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    final metadata = _user!.metadata;

    return _buildExpandableCard(
      title: 'Métadonnées',
      icon: Icons.data_object,
      isExpanded: _metadataExpanded,
      onTap: () => setState(() => _metadataExpanded = !_metadataExpanded),
      children: [
        if (metadata == null || metadata.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucune métadonnée'),
          )
        else
          ...metadata.entries.map((entry) {
            return _buildReadOnlyField(
              label: entry.key,
              value: entry.value.toString(),
              icon: Icons.label,
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTechnicalInfoSection() {
    return _buildExpandableCard(
      title: 'Informations techniques',
      icon: Icons.settings,
      isExpanded: _technicalExpanded,
      onTap: () => setState(() => _technicalExpanded = !_technicalExpanded),
      children: [
        _buildReadOnlyField(
          label: 'UID',
          value: _user!.uid,
          icon: Icons.fingerprint,
        ),
        _buildReadOnlyField(
          label: 'Rôle',
          value: _user!.role.name,
          icon: Icons.badge,
        ),
        _buildReadOnlyField(
          label: 'Compte actif',
          value: _user!.isActive ? 'Oui' : 'Non',
          icon: _user!.isActive ? Icons.check_circle : Icons.cancel,
        ),
        _buildReadOnlyField(
          label: 'Créé le',
          value: _formatDateTime(_user!.createdAt),
          icon: Icons.calendar_today,
        ),
        _buildReadOnlyField(
          label: 'Mis à jour le',
          value: _formatDateTime(_user!.updatedAt),
          icon: Icons.update,
        ),
        if (_user!.deactivatedAt != null)
          _buildReadOnlyField(
            label: 'Désactivé le',
            value: _formatDateTime(_user!.deactivatedAt!),
            icon: Icons.block,
          ),
        if (_user!.scheduledDeletionDate != null) ...[
          _buildReadOnlyField(
            label: 'Suppression programmée',
            value: _formatDateTime(_user!.scheduledDeletionDate!),
            icon: Icons.delete_forever,
          ),
          _buildReadOnlyField(
            label: 'Jours restants',
            value: '${_user!.getDaysUntilDeletion()} jours',
            icon: Icons.timer,
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // WIDGETS HELPER
  // ============================================================================

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: onTap,
          ),
          if (isExpanded) ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required String fieldKey,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    final isEditing = _editingFields[fieldKey] ?? false;
    final controller = _controllers[fieldKey];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing && !readOnly)
                  TextField(
                    controller: controller,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _saveField(fieldKey),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _cancelEdit(fieldKey, value),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (!readOnly && !isEditing)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                setState(() => _editingFields[fieldKey] = true);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageInfo({required String label, String? url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                if (url != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else
                  const Text(
                    'Aucune image',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // COMPTE DÉSACTIVÉ
  // ============================================================================

  Widget _buildDeactivatedWarning() {
    final daysUntilDeletion = _user!.getDaysUntilDeletion();
    final canReactivate = _user!.canReactivate();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          color: Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 24),
                Text(
                  'Compte Désactivé',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Votre compte a été désactivé le ${_formatDateTime(_user!.deactivatedAt!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                if (daysUntilDeletion != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Suppression dans $daysUntilDeletion jours',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date de suppression: ${_formatDateTime(_user!.scheduledDeletionDate!)}',
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ],
                    ),
                  ),
                ],
                if (canReactivate) ...[
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _reactivateAccount,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réactiver mon compte'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _saveField(String fieldKey) async {
    final controller = _controllers[fieldKey];
    if (controller == null) return;

    final newValue = controller.text.trim();

    try {
      final authProvider = context.read<AuthProviderV2>();

      Map<String, dynamic> updateData = {};

      switch (fieldKey) {
        case 'name':
          updateData['name'] = newValue;
          break;
        case 'bio':
          updateData['bio'] = newValue.isEmpty ? null : newValue;
          break;
        case 'phoneNumber':
          updateData['phone_number'] = newValue.isEmpty ? null : newValue;
          break;
        // ... autres cas
      }

      // ✅ UTILISER LA VERSION SILENCIEUSE (à créer dans AuthProviderV2)
      final result = await authProvider.updateUserProfileSilent(updateData);

      if (result.success) {
        // ✅ Mettre à jour UNIQUEMENT l'état local
        if (mounted) {
          setState(() {
            _editingFields[fieldKey] = false;

            // ✅ Mise à jour optimisée du modèle
            _user = _user!.copyWith(
              name: fieldKey == 'name' ? newValue : _user!.name,
              bio: fieldKey == 'bio'
                  ? (newValue.isEmpty ? null : newValue)
                  : _user!.bio,
              phoneNumber: fieldKey == 'phoneNumber'
                  ? (newValue.isEmpty ? null : newValue)
                  : _user!.phoneNumber,
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modification enregistrée'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1), // ✅ Réduire la durée
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }

  void _cancelEdit(String fieldKey, String originalValue) {
    setState(() {
      _editingFields[fieldKey] = false;
      _controllers[fieldKey]?.text = originalValue;
    });
  }

  Future<void> _reactivateAccount() async {
    // TODO: Implémenter la logique de réactivation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de réactivation à implémenter'),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(dateTime);
  }
}
