import 'dart:ui';

import 'package:flutter/material.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // fond sombre en dégradé comme sur la maquette
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1216), Color(0xFF0A0E12)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: GridView.count(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.65,
                children: const [
                  CardBtn(
                    title: 'Collarless Faux\nSuede Jacket',
                    nombrePersonne: null,
                    imageUrl:
                        'https://images.unsplash.com/photo-1544006659-f0b21884ce1d?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x6636E3FF), Color(0x6613D6B4)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.centerLeft,
                  ),
                  CardBtn(
                    title: 'Mens Washed\nOversized Hoodie',
                    nombrePersonne: 256,
                    imageUrl:
                        'https://images.unsplash.com/photo-1516280030429-27679b3dc9cf?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x66B4FFDE), Color(0x66FFE38F)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.centerRight,
                  ),
                  CardBtn(
                    title: 'Mens Washed\nOversized Hoodie',
                    nombrePersonne: 128,
                    imageUrl:
                        'https://images.unsplash.com/photo-1542060748-10c28b62716b?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x66B7C6FF), Color(0x339AA6B2)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.topCenter,
                    grayscaleImage: true,
                  ),
                  CardBtn(
                    title: 'Mens Washed\nOversized Hoodie',
                    nombrePersonne: null,
                    imageUrl:
                        'https://images.unsplash.com/photo-1520975922373-a83ca6c0557a?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x66FF9D3C), Color(0x33F3D2C1)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.center,
                    warmGlow: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardBtn extends StatelessWidget {
  final String title;
  final int? nombrePersonne;
  final String imageUrl;
  final List<Color> overlayColors;
  final String buttonLabel;
  final Alignment imageAlignment;
  final bool grayscaleImage;
  final bool warmGlow;
  final VoidCallback? onPressed;

  const CardBtn({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.overlayColors,
    required this.buttonLabel,
    this.nombrePersonne = 0,
    this.imageAlignment = Alignment.center,
    this.grayscaleImage = false,
    this.warmGlow = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [
              // ombre douce sous la carte (look “flottant”)
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image background
                ColorFiltered(
                  colorFilter: grayscaleImage
                      ? const ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : const ColorFilter.mode(
                          Colors.transparent, BlendMode.dst),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imageUrl),
                        fit: BoxFit.cover,
                        alignment: imageAlignment,
                      ),
                    ),
                  ),
                ),

                // Glow / vignette chaude sur la 4ème carte
                if (warmGlow)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [Color(0xFFFFB066), Colors.transparent],
                        stops: [0.0, 0.9],
                      ),
                    ),
                  ),

                // Dégradé coloré semi-flou façon “neumorph / glass”
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: overlayColors,
                    ),
                  ),
                ),

                // Légère couche assombrissante pour garantir le contraste du texte
                Container(color: const Color(0x14000000)),

                // Effet verre dépoli pour la partie basse (texte + bouton)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black38, blurRadius: 6),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // if (nombrePersonne != null)
                                  //   Container(
                                  //     padding: const EdgeInsets.symmetric(
                                  //         horizontal: 10, vertical: 6),
                                  //     decoration: BoxDecoration(
                                  //       color: Colors.white.withOpacity(0.18),
                                  //       borderRadius: BorderRadius.circular(14),
                                  //       border: Border.all(
                                  //         color: Colors.white.withOpacity(0.26),
                                  //       ),
                                  //     ),
                                  //     child: Text(
                                  //       '${nombrePersonne!} Pers',
                                  //       style: const TextStyle(
                                  //         color: Colors.white,
                                  //         fontWeight: FontWeight.w700,
                                  //       ),
                                  //     ),
                                  //   )
                                  // else
                                  //   const SizedBox(height: 28),
                                  // const Spacer(),
                                  _GlassButton(
                                    label: buttonLabel,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Prix en haut gauche (gros texte) si demandé par le mock
                if (nombrePersonne != null)
                  Positioned(
                    top: 18,
                    left: 18,
                    child: Text(
                      '${nombrePersonne!} Pers',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 12)
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;

  const _GlassButton({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.22),
              border: Border.all(color: Colors.white.withOpacity(0.30)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
