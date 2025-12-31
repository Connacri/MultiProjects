import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';

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
    context.read<DiscoveryProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DiscoveryProvider, (bool, List<Profile>, String?)>(
      selector: (_, p) => (p.loading, p.profiles, p.error),
      builder: (_, data, __) {
        final (loading, profiles, error) = data;

        if (error != null) {
          return Center(
              child: Text(error, style: const TextStyle(color: Colors.red)));
        }
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (profiles.isEmpty) {
          return const Center(child: Text('Plus de profils autour de vous'));
        }

        return CardSwiper(
          cardsCount: profiles.length,
          allowedSwipeDirection: const AllowedSwipeDirection.all(),
          onSwipe: (previousIndex, currentIndex, direction) async {
            final profile = profiles[previousIndex!];
            final action = switch (direction) {
              CardSwiperDirection.left => 'pass',
              CardSwiperDirection.right => 'like',
              CardSwiperDirection.top => 'superlike',
              _ => 'pass',
            };
            await context.read<DiscoveryProvider>().onSwipe(profile, action);
            return true;
          },
          cardBuilder: (_, index) => ProfileCard(profile: profiles[index]),
          padding: const EdgeInsets.all(16),
        );
      },
    );
  }
}
