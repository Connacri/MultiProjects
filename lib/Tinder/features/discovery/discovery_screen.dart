// lib/Tinder/features/discovery/discovery_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';

import '../../core/domain/enums/swipe_action.dart';
import '../../core/swipe_action_enum.dart';
import '../profile/profile.dart';
import '../profile/profile_card.dart';
import 'discovery_provider.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Initialiser une seule fois
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DiscoveryProvider, (bool, List<Profile>, String?)>(
      selector: (_, provider) => (
        provider.loading,
        provider.profiles,
        provider.error,
      ),
      builder: (context, data, __) {
        final (loading, profiles, error) = data;

        // ✅ Écran d'erreur avec retry
        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<DiscoveryProvider>().refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Loading state
        if (loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Recherche de profils à proximité...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // ✅ État vide
        if (profiles.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Plus de profils autour de vous',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Revenez plus tard ou augmentez votre rayon de recherche',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<DiscoveryProvider>().refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Swiper avec profils
        return Stack(
          children: [
            // Cards swipables
            CardSwiper(
              cardsCount: profiles.length,
              allowedSwipeDirection: const AllowedSwipeDirection.all(),
              onSwipe: (previousIndex, currentIndex, direction) async {
                if (previousIndex == null) return false;

                final profile = profiles[previousIndex];
                final action = SwipeAction.fromDirection(direction);

                // ✅ Appel asynchrone sans bloquer l'UI
                context.read<DiscoveryProvider>().onSwipe(profile, action);

                return true;
              },
              cardBuilder: (context, index) {
                if (index >= profiles.length) return const SizedBox.shrink();
                return ProfileCard(profile: profiles[index]);
              },
              padding: const EdgeInsets.all(16),
            ),

            // ✅ Indicateur de profils restants
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${profiles.length} profils',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ✅ Boutons d'action manuels
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: _buildActionButtons(context),
            ),
          ],
        );
      },
    );
  }

  /// ✅ NOUVEAU: Boutons d'action manuels
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pass
        _ActionButton(
          icon: Icons.close,
          color: Colors.red,
          onTap: () => _handleManualSwipe(context, SwipeAction.pass),
        ),

        // Superlike
        _ActionButton(
          icon: Icons.star,
          color: Colors.blue,
          size: 60,
          onTap: () => _handleManualSwipe(context, SwipeAction.superlike),
        ),

        // Like
        _ActionButton(
          icon: Icons.favorite,
          color: Colors.green,
          onTap: () => _handleManualSwipe(context, SwipeAction.like),
        ),
      ],
    );
  }

  void _handleManualSwipe(BuildContext context, SwipeAction action) {
    final provider = context.read<DiscoveryProvider>();

    if (provider.profiles.isEmpty) return;

    final profile = provider.profiles.first;
    provider.onSwipe(profile, action);
  }
}

/// ✅ Widget bouton d'action réutilisable
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
