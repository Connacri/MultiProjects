// features/discovery/presentation/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';

import 'provider/discovery_provider.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryProvider>(
      builder: (context, provider, _) {
        provider.init(); // appel une fois

        if (provider.loading)
          return const Center(child: CircularProgressIndicator());

        if (provider.profiles.isEmpty) {
          return const Center(child: Text('Plus de profils autour de vous'));
        }

        return CardSwiper(
          controller: CardSwiperController(),
          cardsCount: provider.profiles.length,
          allowedSwipeDirection: const AllowedSwipeDirection.all(),
          onSwipe: (prev, curr, direction) async {
            final profile = provider.profiles[prev!];
            final action = switch (direction) {
              CardSwiperDirection.left => 'pass',
              CardSwiperDirection.right => 'like',
              CardSwiperDirection.top => 'superlike',
              _ => 'pass',
            };
            await provider.onSwipe(profile, action);
            return true;
          },
          cardBuilder: (context, index) =>
              ProfileCard(profile: provider.profiles[index]),
        );
      },
    );
  }
}
