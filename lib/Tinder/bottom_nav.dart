import 'package:flutter/material.dart';

import 'chat.dart';
import 'features/discovery/domain/entities/profile.dart';
import 'features/discovery/presentation/discovery_screen.dart';
import 'features/matches/matches_screen.dart';
import 'home.dart';
import 'location.dart';
import 'star.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  _screens = [
  const DiscoveryScreen(),
  const LocationScreen(),
  const Placeholder(), // Star
  const MatchesScreen(),   // ← remplace Chat par Matches realtime
  const ProfileScreen(),
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      bottomNavigationBar: NavigationBar(
        destinations: [
          navDest(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          navDest(
            icon: Icons.location_on_outlined,
            selectedIcon: Icons.location_on_sharp,
            label: 'Location',
          ),
          navDest(
            icon: Icons.star_rounded,
            selectedIcon: Icons.star_rounded,
            label: '',
          ),
          navDest(
            icon: Icons.chat_outlined,
            selectedIcon: Icons.chat_rounded,
            label: 'Chat',
          ),
          navDest(
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
      body: _screens[_currentIndex],
    );
  }

  navDest(
      {required IconData selectedIcon,
      required IconData icon,
      required String label}) {
    return label == ''
        ? Image.asset('assets/star.png')
        : NavigationDestination(
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

  AppBar _appBar() {
    return AppBar(
      title: const Text('목이길어슬픈기린님의 새로운 스팟'),
      leading: Image.asset('assets/location.png'),
      actions: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1000.0),
            color: Colors.black,
          ),
          child: const Padding(
            padding: EdgeInsets.all(5.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rate_rounded,
                  color: Color(0xffff2782),
                ),
                Text('323,233'),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Badge(
            child: Icon(
              Icons.notifications_outlined,
            ),
          ),
        )
      ],
    );
  }
}
