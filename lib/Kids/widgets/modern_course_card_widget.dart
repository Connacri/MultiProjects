import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/course_model_complete.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool showActions;
  final String? distance;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.showActions = false,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Protection contre données invalides
    if (course.id.isEmpty || course.title.isEmpty) {
      print('⚠️ [CourseCard] Cours invalide détecté');
      return const SizedBox.shrink();
    }

    final isDesktop = MediaQuery.of(context).size.width > 1200;

    return Card(
      elevation: isDesktop ? 4 : 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ CRITIQUE : Évite size: MISSING
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // ✅ SÉCURISÉ : Vérification stricte avec null-safety
    final imageUrl = course.images.isNotEmpty &&
            course.images.first.supabaseUrl != null &&
            course.images.first.supabaseUrl!.isNotEmpty
        ? course.images.first.supabaseUrl!
        : null;

    return SizedBox(
      height: 180, // ✅ Hauteur fixe au lieu de contraintes dynamiques
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print('⚠️ [CourseCard] Erreur chargement image: $error');
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 40),
                    );
                  },
                )
              : Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.school, size: 48),
                ),

          // Badge statut (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: course.isAvailableNow() ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                course.isAvailableNow()
                    ? 'Disponible'
                    : course.season.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Badge distance (top-left)
          if (distance != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      distance!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ CRITIQUE
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Modifier',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                if (onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.blue, size: 20),
                    onPressed: onShare,
                    tooltip: 'Partager',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Chip catégorie
          Chip(
            label: Text(
              course.category.displayName,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            course.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.3,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // ✅ SÉCURISÉ : Localisation avec null-safety
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.location.city ?? course.location.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ SÉCURISÉ : Prix et étudiants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Prix
              if (course.price != null && course.price! > 0)
                Text(
                  '${course.price!.toStringAsFixed(2)} ${course.currency}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                )
              else
                Text(
                  'Gratuit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),

              // Étudiants
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${course.currentStudents}/${course.maxStudents}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Extension Helper pour CourseImage (SÉCURISÉE)
// ============================================================================

extension CourseImageHelper on CourseImage {
  /// Retourne l'URL de l'image disponible (Supabase uniquement)
  String? get imageUrl {
    if (supabaseUrl != null && supabaseUrl!.isNotEmpty) return supabaseUrl;
    return null;
  }

  /// Vérifie si l'image a au moins une URL valide
  bool get hasValidUrl {
    return (supabaseUrl != null && supabaseUrl!.isNotEmpty);
  }
}
