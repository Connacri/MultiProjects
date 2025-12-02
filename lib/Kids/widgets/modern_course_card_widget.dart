import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/course_model_complete.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final String? distance;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: isDesktop ? 4 : 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
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
    // CORRECTION: Utiliser firebaseUrl ou supabaseUrl au lieu de profileImage
    final imageUrl = course.images.isNotEmpty
        ? (course.images.first.firebaseUrl.isNotEmpty
            ? course.images.first.firebaseUrl
            : course.images.first.supabaseUrl)
        : null;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),
                )
              : Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.school, size: 64),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: course.isAvailableNow() ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              course.isAvailableNow()
                  ? 'Disponible'
                  : course.season.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (distance != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    distance!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showActions) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(course.category.displayName),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            course.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.location.city ?? course.location.address,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (course.price != null)
                Text(
                  '${course.price!.toStringAsFixed(2)} ${course.currency}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                )
              else
                Text(
                  'Gratuit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${course.currentStudents}/${course.maxStudents}',
                    style: Theme.of(context).textTheme.bodyMedium,
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
// FICHIER: course_image_extension.dart (NOUVEAU)
// Extension helper pour CourseImage
// ============================================================================

extension CourseImageHelper on CourseImage {
  /// Retourne l'URL de l'image disponible (Firebase en priorité, puis Supabase)
  String? get imageUrl {
    if (firebaseUrl.isNotEmpty) return firebaseUrl;
    if (supabaseUrl != null && supabaseUrl!.isNotEmpty) return supabaseUrl;
    return null;
  }

  /// Vérifie si l'image a au moins une URL valide
  bool get hasValidUrl {
    return (firebaseUrl.isNotEmpty) ||
        (supabaseUrl != null && supabaseUrl!.isNotEmpty);
  }
}

// ============================================================================
// FICHIER: responsive_layout_helper.dart (AJOUT MANQUANT)
// Helper pour le responsive design
// ============================================================================
