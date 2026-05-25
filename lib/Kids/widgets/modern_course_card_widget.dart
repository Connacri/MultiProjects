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
    final cs = Theme.of(context).colorScheme;

    if (course.id.isEmpty || course.title.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context, cs),
            _buildContent(context, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme cs) {
    final imageUrl = course.images.isNotEmpty &&
            course.images.first.supabaseUrl != null &&
            course.images.first.supabaseUrl!.isNotEmpty
        ? course.images.first.supabaseUrl!
        : null;

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: cs.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported,
                        size: 40, color: cs.onSurfaceVariant),
                  ),
                )
              : Container(
                  color: cs.surfaceContainerHighest,
                  child:
                      Icon(Icons.school, size: 48, color: cs.onSurfaceVariant),
                ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    course.isAvailableNow() ? cs.primary : cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                course.isAvailableNow()
                    ? 'Disponible'
                    : course.season.displayName,
                style: TextStyle(
                  color: course.isAvailableNow()
                      ? cs.onPrimary
                      : cs.onTertiaryContainer,
                  fontSize: 11,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.inverseSurface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        size: 12, color: cs.onInverseSurface),
                    const SizedBox(width: 3),
                    Text(
                      distance!,
                      style: TextStyle(
                        color: cs.onInverseSurface,
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

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: cs.onSurface,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: cs.onSurfaceVariant),
                  onPressed: onEdit,
                  tooltip: 'Modifier',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: cs.error, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (onShare != null)
                  IconButton(
                    icon: Icon(Icons.share, color: cs.primary, size: 20),
                    onPressed: onShare,
                    tooltip: 'Partager',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              course.category.displayName,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: cs.primaryContainer,
            labelStyle: TextStyle(color: cs.onPrimaryContainer),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(height: 8),
          Text(
            course.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.3,
                  color: cs.onSurfaceVariant,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.location.city ?? course.location.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (course.price != null && course.price! > 0)
                Text(
                  '${course.price!.toStringAsFixed(2)} DZD',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                )
              else
                Text(
                  'Gratuit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${course.currentStudents}/${course.maxStudents}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
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

extension CourseImageHelper on CourseImage {
  String? get imageUrl {
    if (supabaseUrl != null && supabaseUrl!.isNotEmpty) return supabaseUrl;
    return null;
  }

  bool get hasValidUrl {
    return (supabaseUrl != null && supabaseUrl!.isNotEmpty);
  }
}
