import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Kids/main.dart';
import '../checkit/HomePage.dart';
import '../dependences/calendar_timeline/home.dart';
import '../objectBox/MyApp.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectBox/pages/invoice/FacturationPageUI.dart';
import '../objectBox/tests/timelines/Tinder-clone-main/Tinder-clone-main/lib/main.dart';
import '../objectBox/tests/timelines/mistral/claude.dart';
import 'TableauStaff.dart';

// 1. Modèle de données pour les cartes
class PageCardData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Color> gradientColors;
  final Widget destination;

  PageCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gradientColors,
    required this.destination,
  });
}

// Écran principal avec parallax corrigé
class CardSelectionScreen extends StatefulWidget {
  const CardSelectionScreen({super.key});

  @override
  State<CardSelectionScreen> createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objectBox = Provider.of<ObjectBox?>(context);
    if (objectBox == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<PageCardData> cardData = [
      PageCardData(
        title: 'Planning Staff\nRhumatologie',
        subtitle: 'Gestion du personnel',
        imageUrl: 'assets/photos/hopital/d (6).jpg',
        gradientColors: [
          Colors.blue.shade800.withOpacity(0.8),
          Colors.black.withOpacity(0.5)
        ],
        destination: const LoadingScreen(destination: 'staff'),
      ),
      PageCardData(
        title: 'POS',
        subtitle: 'Gestion des factures',
        imageUrl: 'assets/photos/nav (2).jpg',
        gradientColors: [
          Colors.purple.shade800.withOpacity(0.8),
          Colors.pink.shade800.withOpacity(0.8)
        ],
        destination: FacturationPageUI(),
      ),
      PageCardData(
        title: Platform.isAndroid || Platform.isIOS
            ? 'Mobile Home'
            : 'Hotel Management',
        subtitle: Platform.isAndroid || Platform.isIOS
            ? 'Interface mobile'
            : 'Gestion hôtelière',
        imageUrl: 'assets/photos/nav (3).jpg',
        gradientColors: [
          Colors.orange.shade800.withOpacity(0.8),
          Colors.red.shade800.withOpacity(0.8)
        ],
        destination: Platform.isAndroid || Platform.isIOS
            ? HomePage3()
            : Hotel_Management(),
      ),
      PageCardData(
        title: 'Hotel Management',
        subtitle: 'Interface adaptative',
        imageUrl: 'assets/photos/nav (4).jpg',
        gradientColors: [
          Colors.green.shade800.withOpacity(0.8),
          Colors.teal.shade800.withOpacity(0.8)
        ],
        destination: Hotel_Management(),
      ),
      PageCardData(
        title: 'Adaptive Home',
        subtitle: 'Interface adaptative',
        imageUrl: 'assets/photos/nav (5).jpg',
        gradientColors: [
          Colors.green.shade800.withOpacity(0.8),
          Colors.teal.shade800.withOpacity(0.8)
        ],
        destination: adaptiveHome(objectBox: objectBox),
      ),
      PageCardData(
        title: 'Tinder',
        subtitle: 'Social',
        imageUrl: 'assets/100.png',
        gradientColors: [
          Colors.blue.shade800.withOpacity(0.8),
          Colors.black.withOpacity(0.5)
        ],
        destination: MyApp_TinderClone(),
      ),
      PageCardData(
        title: 'Kids',
        subtitle: 'Childrens',
        imageUrl: 'assets/photos/a (1).png',
        gradientColors: [
          Colors.deepOrangeAccent.withOpacity(0.8),
          Colors.black.withOpacity(0.5)
        ],
        destination: EduPlatformApp(),
      ),
      PageCardData(
        title: 'Calendar Timeline',
        subtitle: 'Calendar',
        imageUrl: 'assets/photos/a (7).png',
        gradientColors: [
          Colors.indigo.withOpacity(0.8),
          Colors.black.withOpacity(0.5)
        ],
        destination: HomePageCalendar(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection de Module'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          controller: _scrollController, // ← Important !
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: cardData
                  .map((data) => _buildCard(context, data, _scrollOffset))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PageCardData data,
      ValueNotifier<double> scrollOffset) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final double cardHeight = isMobile ? 200 : 400;
    final double sensitivity =
        isMobile ? 3.5 : 5.0; // Ajuste l'intensité du parallax

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => data.destination),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 300,
          height: cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Parallax avec AnimatedBuilder (très performant)
              AnimatedBuilder(
                animation: scrollOffset,
                builder: (context, child) {
                  final double parallax = scrollOffset.value / sensitivity;
                  return Transform.translate(
                    offset: Offset(0, -parallax),
                    // Négatif pour un effet "derrière"
                    child: child,
                  );
                },
                child: OverflowBox(
                  maxHeight: cardHeight + 300,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: cardHeight + 300,
                    width: double.infinity,
                    child: Image.asset(
                      data.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: data.gradientColors[0].withOpacity(0.3),
                          child: const Icon(Icons.image,
                              size: 100, color: Colors.white30),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Overlay gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      data.gradientColors[0].withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Texte et bouton
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 4),
                          ]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          shadows: const [
                            Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 3),
                          ]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Accéder',
                              style: TextStyle(
                                  color: data.gradientColors[0],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward,
                              color: data.gradientColors[0], size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Icône dashboard
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.dashboard,
                      color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  final String destination;

  const LoadingScreen({super.key, required this.destination});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => TableauStaffPage()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Chargement du planning...",
                style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
