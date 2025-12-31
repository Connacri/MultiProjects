// home.dart (concise)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../daily_rewards.dart';
import 'chat.dart';
import 'location.dart';
import 'profile.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _index = 0;
  final _screens = [
    const Home(),
    const Location(),
    const DailyRewards(), // New daily engagement screen
    const Chat(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목이길어슬픈기린님의 새로운 스팟'),
        leading: Image.asset('assets/location.png'),
        actions: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1000), color: Colors.black),
            padding: const EdgeInsets.all(5),
            child: const Row(children: [
              Icon(Icons.star_rate_rounded, color: Color(0xffff2782)),
              Text('323,233')
            ]),
          ),
          const Badge(
              child: Icon(Icons.notifications_outlined),
              padding: EdgeInsets.symmetric(horizontal: 10)),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          _dest(Icons.home_outlined, Icons.home, 'Home'),
          _dest(Icons.location_on_outlined, Icons.location_on, 'Location'),
          Image.asset('assets/star.png'),
          _dest(Icons.chat_outlined, Icons.chat_rounded, 'Chat'),
          _dest(Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  NavigationDestination _dest(IconData icon, IconData selIcon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.grey.shade800),
      selectedIcon: Icon(selIcon, color: Colors.white),
      label: label,
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  final List<String> imgs = const ['100', '101', '102'];

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('추천 드릴 친구들을 준비 중이에요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('매일 새로운 친구들을 소개시켜드려요'),
          ],
        ),
      ),
      CardSwiper(
        cardsCount: imgs.length,
        isLoop: false,
        cardBuilder: (_, i, __, ___) => _card(imgs[i]),
      ),
    ]);
  }

  Widget _card(String img) {
    const double wh = 460;
    return Container(
      width: kIsWeb ? wh : double.infinity,
      height: kIsWeb ? wh : double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Stack(children: [
        Image.asset('assets/$img.png',
            fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [
                  Colors.transparent,
                  Color.fromARGB(182, 0, 0, 0)
                ]))),
        const Positioned(bottom: 130, left: 15, child: _Badge()),
        const Positioned(bottom: 50, left: 15, child: _Info()),
        const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Icon(Icons.keyboard_arrow_down_rounded)),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(1000)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, color: Colors.grey),
          Text('29,930')
        ]),
      );
}

class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) => Row(children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('잭과분홍콩나물 25',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('서울·2km 거리에 있음'),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color.fromARGB(177, 0, 0, 0),
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(1000)),
          child: Image.asset('assets/heart.png'),
        ),
      ]);
}

// Other screens unchanged (Location, Star, Chat, Profile)
