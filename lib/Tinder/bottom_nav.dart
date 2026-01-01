// lib/Tinder/bottom_nav.dart

import 'package:flutter/material.dart';

import 'features/discovery/discovery_screen.dart';
import 'features/matches/matches_screen.dart';
import 'features/profile/profile_page.dart';
import 'location.dart';
import 'star.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      const DiscoveryScreen(),
      const Location(),
      const Star(),
      const MatchesScreen(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      bottomNavigationBar: NavigationBar(
        destinations: [
          _buildNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          _buildNavDestination(
            icon: Icons.location_on_outlined,
            selectedIcon: Icons.location_on_sharp,
            label: 'Location',
          ),
          const NavigationDestination(
            icon: _StarIcon(),
            label: '',
          ),
          _buildNavDestination(
            icon: Icons.chat_outlined,
            selectedIcon: Icons.chat_rounded,
            label: 'Chat',
          ),
          _buildNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profil',
          ),
        ],
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color: Colors.grey.shade800,
      ),
      label: label,
      selectedIcon: Icon(
        selectedIcon,
        color: Colors.white,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('목이길어슬픈기린님의 새로운 스팟'),
      leading: Image.asset(
        'assets/location.png',
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.location_on),
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1000.0),
            color: Colors.black,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rate_rounded,
                color: Color(0xffff2782),
                size: 20,
              ),
              SizedBox(width: 4),
              Text(
                '323,233',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: const Badge(
            child: Icon(Icons.notifications_outlined),
          ),
        ),
      ],
    );
  }
}

class _StarIcon extends StatelessWidget {
  const _StarIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/star.png',
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.star_rounded,
          color: Colors.amber,
        );
      },
    );
  }
}
