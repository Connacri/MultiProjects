import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../claude/auth_provider_v2.dart';
import '../models/user_model.dart';
import '../providers/locale_provider.dart';
import '../services/hybrid_image_picker.dart';
import '../services/image_storage_service.dart';
import '../services/responsive_layout_helper.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/location_picker_dialog_widget.dart';
import '../widgets/location_picker_windows.dart';

/// 🎯 ProfileScreen Modern UI/UX - Inspiré design premium
/// ✅ FIX: Cache-busting + rebuild instantané + picking non-bloquant Windows
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderV2>(
      builder: (context, authProvider, _) {
        if (authProvider.currentUser == null || authProvider.userData == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userModel = UserModel.fromSupabase(authProvider.userData!);

        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: ResponsiveBuilder(
              builder: (context, deviceType) {
                if (deviceType == DeviceType.desktop) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _ProfileContent(user: userModel),
                      ),
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: const _SettingsPanel(),
                      ),
                    ],
                  );
                }
                return _ProfileContent(user: userModel);
              },
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// CONTENU PROFIL MODERNE
// ============================================================================

class _ProfileContent extends StatelessWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _ModernProfileHeader(user: user),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ProfileAvatarCard(user: user),
              const SizedBox(height: 24),
              _ProfileInfoCards(user: user),
              const SizedBox(height: 24),
              _ProfileDetailsCards(user: user),
              const SizedBox(height: 24),
              _QuickActionsCard(user: user),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HEADER MODERNE AVEC COVER IMAGE
// ============================================================================

class _ModernProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ModernProfileHeader({required this.user});

  /// ✅ FIX WINDOWS: Utilise HybridImagePickerService (non-bloquant)
  Future<void> _pickCoverImage(BuildContext context) async {
    try {
      print('📸 [ProfileScreen] Sélection cover via HybridPicker...');

      // ✅ Utilise le service hybride qui ne bloque pas sur Windows
      final imageFile = await HybridImagePickerService.pickCoverImage();

      if (imageFile != null && context.mounted) {
        await _uploadImage(context, imageFile, isProfile: false);
      }
    } catch (e) {
      print('❌ [ProfileScreen] Erreur sélection cover: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(
    BuildContext context,
    File imageFile, {
    required bool isProfile,
  }) async {
    final authProvider = context.read<AuthProviderV2>();
    final imageService = ImageStorageService();

    try {
      print(
          '📤 [ProfileScreen] Début upload ${isProfile ? "profile" : "cover"}');

      final imageUrl = await imageService.uploadUserProfileImage(
        imageFile: imageFile,
        userId: authProvider.currentUser!.id,
        isProfileImage: isProfile,
      );

      if (imageUrl == null) throw Exception('Upload échoué');

      print('✅ [ProfileScreen] URL reçue: $imageUrl');

      // ✅ FIX: Éviction du cache AVANT la mise à jour
      final currentImagesMap =
          authProvider.userData?['profile_images'] as Map<String, dynamic>? ??
              {};
      final currentImages = UserProfileImages.fromMap(currentImagesMap);

      final oldUrl =
          isProfile ? currentImages.profileImage : currentImages.coverImage;

      if (oldUrl != null && oldUrl.isNotEmpty) {
        print('🧹 [ProfileScreen] Éviction cache pour: $oldUrl');
        await CachedNetworkImage.evictFromCache(oldUrl);
      }

      // ✅ FIX: Cache-busting avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageUrlWithCacheBust = '$imageUrl?t=$timestamp';

      print('🔄 [ProfileScreen] URL avec cache-bust: $imageUrlWithCacheBust');

      final updatedImages = isProfile
          ? currentImages.copyWith(
              profileImageSupabase: imageUrlWithCacheBust,
              profileImageFirebase: imageUrlWithCacheBust,
              lastUpdated: DateTime.now(),
            )
          : currentImages.copyWith(
              coverImageSupabase: imageUrlWithCacheBust,
              coverImageFirebase: imageUrlWithCacheBust,
              lastUpdated: DateTime.now(),
            );

      final result = await authProvider.updateUserProfileSilent({
        'profile_images': updatedImages.toMapSupabase(),
      });

      print(
          '✅ [ProfileScreen] updateUserProfileSilent result: ${result.success}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? (isProfile
                      ? '✅ Photo de profil mise à jour'
                      : '✅ Couverture mise à jour')
                  : '❌ Erreur: ${result.message}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [ProfileScreen] Erreur upload: $e');
      print('❌ [ProfileScreen] StackTrace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverImage = user.profileImages.coverImage;

    // ✅ FIX ULTIME: Utiliser l'URL elle-même comme clé (contient le timestamp)
    final coverKey = coverImage ?? 'cover_${user.uid}_empty';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      actions: [
        PopupMenuButton<Locale>(
          icon: Icon(Icons.language,
              color: Theme.of(context).colorScheme.primary),
          tooltip: 'Changer de langue',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (locale) =>
              context.read<LocaleProvider>().setLocale(locale),
          itemBuilder: (context) => const [
            PopupMenuItem(value: Locale('fr'), child: Text('🇫🇷 Français')),
            PopupMenuItem(value: Locale('en'), child: Text('🇬🇧 English')),
            PopupMenuItem(value: Locale('ar'), child: Text('🇸🇦 العربية')),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverImage != null && coverImage.isNotEmpty)
              CachedNetworkImage(
                key: ValueKey(coverKey),
                imageUrl: coverImage,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                memCacheHeight: 600,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.error_outline,
                        size: 48, color: Colors.white70),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE8D4F2),
                      Color(0xFFD4E4F2),
                      Color(0xFFF2E4D4),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'edit_cover',
                onPressed: () => _pickCoverImage(context),
                backgroundColor: Colors.white,
                elevation: 4,
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CARD AVATAR MODERNE
// ============================================================================

class _ProfileAvatarCard extends StatelessWidget {
  final UserModel user;

  const _ProfileAvatarCard({required this.user});

  /// ✅ FIX WINDOWS: Utilise HybridImagePickerService (non-bloquant)
  Future<void> _pickProfileImage(BuildContext context) async {
    try {
      print('📸 [ProfileScreen] Sélection profile via HybridPicker...');

      // ✅ Utilise le service hybride qui ne bloque pas sur Windows
      final imageFile = await HybridImagePickerService.pickProfileImage();

      if (imageFile != null && context.mounted) {
        await _uploadImage(context, imageFile);
      }
    } catch (e) {
      print('❌ [ProfileScreen] Erreur sélection profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(BuildContext context, File imageFile) async {
    final authProvider = context.read<AuthProviderV2>();
    final imageService = ImageStorageService();

    try {
      print('📤 [ProfileScreen] Début upload profile');

      final imageUrl = await imageService.uploadUserProfileImage(
        imageFile: imageFile,
        userId: authProvider.currentUser!.id,
        isProfileImage: true,
      );

      if (imageUrl == null) throw Exception('Upload échoué');

      print('✅ [ProfileScreen] URL profile reçue: $imageUrl');

      final currentImagesMap =
          authProvider.userData?['profile_images'] as Map<String, dynamic>? ??
              {};
      final currentImages = UserProfileImages.fromMap(currentImagesMap);

      final oldUrl = currentImages.profileImage;

      if (oldUrl != null && oldUrl.isNotEmpty) {
        print('🧹 [ProfileScreen] Éviction cache profile pour: $oldUrl');
        await CachedNetworkImage.evictFromCache(oldUrl);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageUrlWithCacheBust = '$imageUrl?t=$timestamp';

      print(
          '🔄 [ProfileScreen] URL profile avec cache-bust: $imageUrlWithCacheBust');

      final updatedImages = currentImages.copyWith(
        profileImageSupabase: imageUrlWithCacheBust,
        profileImageFirebase: imageUrlWithCacheBust,
        lastUpdated: DateTime.now(),
      );

      final result = await authProvider.updateUserProfileSilent({
        'profile_images': updatedImages.toMapSupabase(),
      });

      print(
          '✅ [ProfileScreen] updateUserProfileSilent profile result: ${result.success}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '✅ Photo de profil mise à jour'
                  : '❌ Erreur: ${result.message}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ [ProfileScreen] Erreur upload profile: $e');
      print('❌ [ProfileScreen] StackTrace: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = user.profileImages.profileImage;

    // ✅ FIX ULTIME: Utiliser l'URL elle-même comme clé (contient le timestamp)
    final avatarKey = profileImage ?? 'avatar_${user.uid}_empty';

    return Transform.translate(
      offset: const Offset(0, -50),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        key: ValueKey(avatarKey),
                        backgroundImage:
                            (profileImage != null && profileImage.isNotEmpty)
                                ? CachedNetworkImageProvider(profileImage)
                                : null,
                        child: (profileImage == null || profileImage.isEmpty)
                            ? Icon(
                                _getRoleIcon(user.role),
                                size: 60,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 20),
                      color: Colors.white,
                      onPressed: () => _pickProfileImage(context),
                      tooltip: 'Changer photo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.5),
                      Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRoleIcon(user.role),
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.role.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return Icons.family_restroom_rounded;
      case UserRole.school:
        return Icons.school_rounded;
      case UserRole.coach:
        return Icons.sports_soccer_rounded;
      case UserRole.autres:
        return Icons.person_rounded;
    }
  }
}

// ============================================================================
// CARDS INFORMATIONS (reste identique)
// ============================================================================

class _ProfileInfoCards extends StatelessWidget {
  final UserModel user;

  const _ProfileInfoCards({required this.user});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _InfoCard(
          icon: Icons.phone_rounded,
          title: 'Téléphone',
          value: user.phoneNumber ?? 'Non renseigné',
          gradient: const [Color(0xFFE8D4F2), Color(0xFFD4E4F2)],
        ),
        _InfoCard(
          icon: Icons.location_on_rounded,
          title: 'Localisation',
          value: user.location?.address.split(',').first ?? 'Non définie',
          gradient: const [Color(0xFFD4E4F2), Color(0xFFF2E4D4)],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<Color> gradient;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const Spacer(),
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailsCards extends StatelessWidget {
  final UserModel user;

  const _ProfileDetailsCards({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.bio == null || user.bio!.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                    ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('À propos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 16),
            Text(user.bio!,
                style: TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final UserModel user;

  const _QuickActionsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions rapides',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 16),
            _ActionButton(
                icon: Icons.edit_rounded,
                label: 'Modifier le profil',
                gradient: const [Color(0xFFE8D4F2), Color(0xFFD4E4F2)],
                onTap: () => _showEditDialog(context, user)),
            const SizedBox(height: 12),
            _ActionButton(
                icon: Icons.logout_rounded,
                label: 'Déconnexion',
                gradient: const [Color(0xFFFDE4E4), Color(0xFFFDEDE4)],
                onTap: () => _handleSignOut(context)),
            const SizedBox(height: 12),
            _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Désactiver le compte',
                gradient: const [Color(0xFFFFE5E5), Color(0xFFFFEEEE)],
                textColor: Colors.red.shade700,
                onTap: () => _handleDeactivateAccount(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ModernDialog(
            title: 'Déconnexion',
            message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
            confirmText: 'Déconnexion',
            confirmColor: Colors.orange));
    if (confirmed == true && context.mounted)
      await context.read<AuthProviderV2>().logout();
  }

  Future<void> _handleDeactivateAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ModernDialog(
            title: 'Désactiver le compte',
            message: 'Votre compte sera désactivé pendant 60 jours.',
            confirmText: 'Désactiver',
            confirmColor: Colors.red));
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Fonctionnalité à implémenter'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  void _showEditDialog(BuildContext context, UserModel user) => showDialog(
      context: context,
      builder: (context) => _ModernProfileEditDialog(user: user));
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Color? textColor;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.gradient,
      required this.onTap,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, color: textColor ?? Colors.grey.shade800),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.grey.shade800))),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: textColor ?? Colors.grey.shade400)
          ]),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Paramètres',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            ListTile(
                leading: const Icon(Icons.notifications_rounded),
                title: const Text('Notifications'),
                trailing: Switch(value: true, onChanged: (v) {})),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('Mode sombre'),
                trailing: Switch(value: false, onChanged: (v) {}))
          ]),
        ),
      ],
    );
  }
}

class _ModernDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;

  const _ModernDialog(
      {required this.title,
      required this.message,
      required this.confirmText,
      required this.confirmColor});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Annuler'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: confirmColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(confirmText)))
            ]),
          ],
        ),
      ),
    );
  }
}

class _ModernProfileEditDialog extends StatefulWidget {
  final UserModel user;

  const _ModernProfileEditDialog({required this.user});

  @override
  State<_ModernProfileEditDialog> createState() =>
      _ModernProfileEditDialogState();
}

class _ModernProfileEditDialogState extends State<_ModernProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;
  late UserRole _selectedRole;
  AppLocation? _selectedLocation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
    _selectedRole = widget.user.role;
    _selectedLocation = widget.user.location;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    final result = await showDialog<AppLocation>(
        context: context,
        builder: (context) => Platform.isWindows
            ? LocationPickerDialogWindows(initialLocation: _selectedLocation)
            : LocationPickerDialog(initialLocation: _selectedLocation));
    if (result != null) setState(() => _selectedLocation = result);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProviderV2>();
      final updateData = {
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'role': _selectedRole.toJson(),
        'location': _selectedLocation?.toMap(),
        'updated_at': DateTime.now().toIso8601String()
      };
      final result = await authProvider.updateUserProfileSilent(updateData);
      if (mounted) {
        if (result.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))));
        } else
          throw Exception(result.message);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.2)
                        ]),
                        borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.edit_rounded,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(width: 16),
                Expanded(
                    child: Text('Éditer le profil',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold))),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context))
              ]),
              const SizedBox(height: 24),
              _ModernTextField(
                  controller: _nameCtrl,
                  label: 'Nom complet',
                  icon: Icons.person_rounded,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Nom requis' : null),
              const SizedBox(height: 16),
              _ModernTextField(
                  controller: _bioCtrl,
                  label: 'Biographie',
                  icon: Icons.info_outline_rounded,
                  maxLines: 3),
              const SizedBox(height: 16),
              _ModernTextField(
                  controller: _phoneCtrl,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                      labelText: 'Rôle',
                      prefixIcon: const Icon(Icons.work_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.grey.shade50),
                  items: UserRole.values
                      .map((role) => DropdownMenuItem(
                          value: role, child: Text(role.displayName)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRole = value);
                  }),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                  onPressed: _updateLocation,
                  icon: const Icon(Icons.location_on_rounded),
                  label: Text(_selectedLocation != null
                      ? 'Modifier localisation'
                      : 'Ajouter localisation'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)))),
              if (_selectedLocation != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_selectedLocation!.address,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700)))
                        ]))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Annuler'))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Enregistrer')))
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ModernTextField(
      {required this.controller,
      required this.label,
      required this.icon,
      this.maxLines = 1,
      this.keyboardType,
      this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.grey.shade50));
}
