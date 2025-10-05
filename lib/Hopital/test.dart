import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../checkit/HomePage.dart';
import '../objectBox/MyApp.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectBox/pages/invoice/FacturationPageUI.dart';
import '../objectBox/tests/timelines/mistral/claude.dart';
import 'TableauStaff.dart';

// 1. Définir le modèle de données pour vos cartes
class PageCardData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Color> gradientColors;
  final Widget destination; // La page de destination

  PageCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.gradientColors,
    required this.destination,
  });
}

// Le widget de l'interface de sélection
class CardSelectionScreen1 extends StatelessWidget {
  // Passez votre objectBox si nécessaire

  const CardSelectionScreen1({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final objectBox = Provider.of<ObjectBox?>(context);
    if (objectBox == null) {
      return Center(child: CircularProgressIndicator());
    }
    // Données pour vos 5 pages
    final List<PageCardData> cardData = [
      PageCardData(
        title: 'Staff Hopital',
        subtitle: 'Gestion du personnel',
        imageUrl: 'assets/photos/nav (1).jpg',
        gradientColors: [
          Colors.blue.shade800.withOpacity(0.8),
          Colors.cyan.shade800.withOpacity(0.8)
        ],
        destination: TableauStaffPage(),
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
        title: ' Hotel Management',
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection de Module'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children:
                  cardData.map((data) => _buildCard(context, data)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PageCardData data) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => data.destination,
          ),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 300,
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                data.gradientColors[0].withOpacity(0.9),
                data.gradientColors[1].withOpacity(0.0),
              ],
              stops: const [0.0, 0.5],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Image de fond
              Positioned.fill(
                child: Image.asset(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: data.gradientColors[0].withOpacity(0.3),
                      child: const Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.white30,
                      ),
                    );
                  },
                ),
              ),

              // Overlay gradient pour améliorer la lisibilité
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

              // Contenu texte
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                            blurRadius: 4,
                          ),
                        ],
                      ),
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
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bouton d'accès
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
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Accéder',
                            style: TextStyle(
                              color: data.gradientColors[0],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: data.gradientColors[0],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Icône en haut à droite
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
