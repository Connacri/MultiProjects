import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../../Entity.dart';
import 'claude_crud.dart';
import 'provider_hotel.dart';

class SeasonalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SeasonalAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (_, provider, __) {
        final selected = provider.selectedSeasonalPricing;

        if (selected == null) {
          return const Text(
            "Aucune saison active",
            style: TextStyle(color: Colors.white),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            /// ---- 1ère Card : période + progression ----
            _SeasonalDateCard(
              startDate: selected.startDate,
              endDate: selected.endDate,
            ),
            const SizedBox(width: 8),

            /// ---- 2ème Card : détails saison ----
            _SeasonalDetailsCard(season: selected),
          ],
        );
      },
    );
  }
}

/// Card affichant les dates + progression
class _SeasonalDateCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _SeasonalDateCard({
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatter = DateFormat("EEE d MMM", "fr_FR");

    final total = endDate.difference(startDate).inDays;
    final passed = now.difference(startDate).inDays;
    final progress = (passed / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_circle, color: Colors.green, size: 18),
              const SizedBox(width: 4),
              Text(
                formatter.format(startDate),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Icon(Icons.event, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                formatter.format(endDate),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 140,
            height: 5,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.greenAccent, Colors.green],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card affichant les détails saison
class _SeasonalDetailsCard extends StatelessWidget {
  final SeasonalPricing season;

  const _SeasonalDetailsCard({required this.season});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // 👈 important pour ne pas forcer la largeur
        children: [
          CircleAvatar(
            backgroundColor: Colors.black54,
            radius: 18,
            child: Text(
              "x${season.multiplier}",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 👈 évite de forcer la hauteur
            children: [
              Text(
                season.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (season.description != null)
                Text(
                  season.description!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

SeasonStyle getSeasonStyle(SeasonalPricing season) {
  final name = season.name.toLowerCase();
  if (name.contains('été') || name.contains('summer')) {
    return SeasonStyle(
      icon: Icons.wb_sunny,
      color: Colors.amber,
      label: 'Été',
    );
  } else if (name.contains('hiver') || name.contains('winter')) {
    return SeasonStyle(
      icon: Icons.ac_unit,
      color: Colors.lightBlue,
      label: 'Hiver',
    );
  } else if (name.contains('printemps') || name.contains('spring')) {
    return SeasonStyle(
      icon: Icons.local_florist,
      color: Colors.lightGreen,
      label: 'Printemps',
    );
  } else if (name.contains('automne') || name.contains('autumn')) {
    return SeasonStyle(
      icon: Icons.spa,
      color: Colors.orange,
      label: 'Automne',
    );
  } else {
    return SeasonStyle(
      icon: Icons.calendar_today,
      color: Colors.grey,
      label: 'Saison',
    );
  }
}

class SeasonStyle {
  final IconData icon;
  final Color color;
  final String label;

  SeasonStyle({required this.icon, required this.color, required this.label});
}

class PricingInfo {
  final String text;
  final Color color;
  final IconData icon;

  PricingInfo(this.text, this.color, this.icon);
}

class ReservationExtraItem {
  final ExtraService extraService;
  int quantity;
  double unitPrice;
  double totalPrice;
  DateTime? scheduledDate;
  String? notes;

  ReservationExtraItem({
    required this.extraService,
    this.quantity = 1,
    required this.unitPrice,
    this.totalPrice = 0.0,
    this.scheduledDate,
    this.notes,
  });
}

class PriceCard extends StatelessWidget {
  final double basePrice;
  final double seasonalMultiplier;
  final SeasonalPricing? season;

  const PriceCard({
    super.key,
    required this.basePrice,
    required this.seasonalMultiplier,
    this.season,
  });

  @override
  Widget build(BuildContext context) {
    double seasonalPrice = basePrice * seasonalMultiplier;
    double variation = ((seasonalMultiplier * 100) - 100);

    bool isHigher = seasonalPrice > basePrice;

    return Container(
      margin: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 0 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isHigher
            ? LinearGradient(
                colors: [Colors.black87, Colors.green.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [Colors.black87, Colors.red.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prix de saison
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    child: Text('x${season!.multiplier}'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${seasonalPrice.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width < 600 ? 25 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Variation + flèche
            MediaQuery.of(context).size.width < 600
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isHigher
                                ? FontAwesomeIcons.arrowUp
                                : FontAwesomeIcons.arrowDown,
                            color: isHigher
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: MediaQuery.of(context).size.width < 600
                                ? 14
                                : 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${variation.toStringAsFixed(2)}%",
                            style: TextStyle(
                              fontSize: 16,
                              color: isHigher
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        isHigher
                            ? FontAwesomeIcons.arrowUp
                            : FontAwesomeIcons.arrowDown,
                        color: isHigher ? Colors.greenAccent : Colors.redAccent,
                        size: MediaQuery.of(context).size.width < 600 ? 14 : 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${variation.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isHigher ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
            FittedBox(
              child: Text(
                season!.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 0 : 20),

            // Prix de base
            Text(
              "Prix de base:\n${basePrice.toStringAsFixed(2)} DA/nuitée",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriceCard22 extends StatelessWidget {
  final double basePrice;
  final double seasonalMultiplier;
  final SeasonalPricing? season;

  const PriceCard22({
    super.key,
    required this.basePrice,
    required this.seasonalMultiplier,
    this.season,
  });

  @override
  Widget build(BuildContext context) {
    double seasonalPrice = basePrice * seasonalMultiplier;
    double variation = ((seasonalMultiplier * 100) - 100);

    bool isHigher = seasonalPrice >= basePrice;

    return Banner(
      location: BannerLocation.bottomEnd,
      color: Colors.yellow,
      textStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontFamily: 'OSWALD'),
      message: 'Nuitée',
      child: Container(
        margin:
            EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 0 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isHigher
              ? LinearGradient(
                  colors: [Colors.black87, Colors.green.shade300],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [Colors.black87, Colors.red.shade300],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prix de saison
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${seasonalPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width < 600 ? 20 : 25,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Variation + flèche
                  MediaQuery.of(context).size.width < 600
                      ? Row(
                          children: [
                            Icon(
                              isHigher
                                  ? FontAwesomeIcons.arrowUp
                                  : FontAwesomeIcons.arrowDown,
                              color: isHigher
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: MediaQuery.of(context).size.width < 600
                                  ? 14
                                  : 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${variation.toStringAsFixed(2)}%",
                              style: TextStyle(
                                fontSize: 16,
                                color: isHigher
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(
                              isHigher
                                  ? FontAwesomeIcons.arrowUp
                                  : FontAwesomeIcons.arrowDown,
                              color: isHigher
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: MediaQuery.of(context).size.width < 600
                                  ? 14
                                  : 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${variation.toStringAsFixed(2)}%",
                              style: TextStyle(
                                fontSize: 16,
                                color: isHigher
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                  Text(
                    'x${season!.multiplier}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isHigher ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  season!.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(
                  height: MediaQuery.of(context).size.width < 600 ? 0 : 20),

              // Prix de base
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Prix de Base: ${basePrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
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

/// --- Widget principal : ReservationCard ---
class ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const ReservationCard({super.key, required this.reservation});

  String get _nights =>
      reservation.to.difference(reservation.from).inDays.toString();

  String get _guestsCount => reservation.guests.length.toString();

  @override
  Widget build(BuildContext context) {
    final NumberFormat money =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return AspectRatio(
      aspectRatio: MediaQuery.of(context).size.width < 600 ? 1.8 : 2.2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Carte principale
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment(-1.0, -0.6),
                end: Alignment(1.0, 0.6),
                colors: [
                  Color(0xFF04BF9F),
                  Color(0xFFD69E09),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            child: MediaQuery.of(context).size.width < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Board Basis',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Text(
                        reservation.boardBasis.target!.name,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      // ⬇️ CORRECTION ICI : Spacer → Overflow ! On le remplace :
                      //const Expanded(child: SizedBox()),
                      // ✅ Safe, ne déborde jamais
                      const Spacer(),
                      Row(
                        children: [
                          _InfoColumn2(
                            label: 'Person(s)',
                            value: _guestsCount,
                          ),
                          // SizedBox(
                          //   width: 10,
                          // ),
                          // _InfoColumn2(
                          //   label: 'Nuitées',
                          //   value: '$_nights',
                          // ),
                        ],
                      ),

                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoColumn(
                              label: 'Prix / pers.',
                              value:
                                  '${money.format(reservation.boardBasis.target!.pricePerPerson)}',
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          _InfoColumn(
                            label: 'Total board',
                            value: money.format(reservation.boardBasisPrice),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Bloc texte gauche
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Board Basis',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            Text(
                              reservation.boardBasis.target!.name,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            // ⬇️ CORRECTION ICI : Spacer → Overflow ! On le remplace :
                            //const Expanded(child: SizedBox()),
                            // ✅ Safe, ne déborde jamais
                            const Spacer(),
                            Row(
                              children: [
                                _InfoColumn2(
                                  label: 'Person(s)',
                                  value: _guestsCount,
                                ),
                                // SizedBox(
                                //   width: 16,
                                // ),
                                // _InfoColumn2(
                                //   label: 'Nuitées',
                                //   value: '$_nights',
                                // ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _InfoColumn(
                                  label: 'Prix / pers.',
                                  value:
                                      '${money.format(reservation.boardBasis.target!.pricePerPerson)}',
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                _InfoColumn(
                                  label: 'Total board',
                                  value:
                                      money.format(reservation.boardBasisPrice),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Décor graphique droit (lignes courbes)
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CustomPaint(
                            size: const Size(120, 140), // ✅ taille fixe
                            painter: _WavePainter(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bouton "pastille" qui dépasse à droite
          MediaQuery.of(context).size.width < 600
              ? Positioned(
                  right: 15,
                  top: 10,
                  child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => BoardBasisDetailScreen(
                                  boardBasis: reservation.boardBasis.target!,
                                )));
                      },
                      icon: Icon(
                        Icons.info,
                        size: 25,
                      )),
                )
              : Positioned(
                  right: 15,
                  bottom: 15,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => BoardBasisDetailScreen(
                                  boardBasis: reservation.boardBasis.target!,
                                )));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          'Détails',
                          style: TextStyle(
                            color: Color(0xFFB3FF6A),
                            fontWeight: FontWeight.w700,
                            fontSize: MediaQuery.of(context).size.width < 600
                                ? 10
                                : 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/// Petit widget réutilisable pour afficher label + valeur
class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        // const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width < 600 ? 15 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoColumn2 extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn2({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Painter pour les lignes de décor (courbes) sur la droite
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2) // ✅ plus visible
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.2 + i * 0.3);
      final path = Path();
      path.moveTo(0, y);
      path.quadraticBezierTo(
        size.width * 0.4,
        y + size.height * 0.1,
        size.width,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BentoCard extends StatelessWidget {
  final SeasonalPricing season;

  const BentoCard({super.key, required this.season});

  /// Mapping saison → image existante dans assets/seasons/
  static final Map<String, String> seasonalImages = {
    "hiver": "assets/seasons/hiver.jpg",
    "printemps": "assets/seasons/printemps.jpg",
    "été": "assets/seasons/ete.jpg", // attention au é accentué
    "automne": "assets/seasons/automne.jpg",
    "vacances scolaires hiver": "assets/seasons/vacances_scolaires_hiver.jpg",
    "fêtes de fin d'année": "assets/seasons/fetes_de_fin_dannee.jpg",
    "ramadan - tarifs préférentiels":
        "assets/seasons/ramadan_tarifs_preferentiels.jpg",
    "festival culturel été": "assets/seasons/festival_culturel_ete.jpg",
    "conférence internationale": "assets/seasons/conference_internationale.jpg",
    "promotion séjour long": "assets/seasons/promotion_sejour_long.jpeg",
  };

  String _formatDate(DateTime date) {
    return DateFormat("EEEE d MMM", "fr_FR").format(date);
  }

  IconData _getSeasonIcon(String name) {
    if (name.toLowerCase().contains("hiver")) return Icons.ac_unit;
    if (name.toLowerCase().contains("printemps")) return Icons.local_florist;
    if (name.toLowerCase().contains("ete")) return Icons.wb_sunny;
    if (name.toLowerCase().contains("automne")) return Icons.park;
    if (name.toLowerCase().contains("ramadan"))
      return FontAwesomeIcons.starAndCrescent;
    if (name.toLowerCase().contains("fête")) return Icons.celebration;
    if (name.toLowerCase().contains("festival")) return Icons.music_note;
    if (name.toLowerCase().contains("conférence")) return Icons.business;
    return Icons.event;
  }

  String _normalizeSeasonName(String name) {
    // Conversion en minuscule
    String normalized = name.toLowerCase();

    // Remplacement des accents par leurs équivalents simples
    normalized = normalized
        .replaceAll(RegExp(r"[àâä]"), "a")
        .replaceAll(RegExp(r"[éèêë]"), "e")
        .replaceAll(RegExp(r"[îï]"), "i")
        .replaceAll(RegExp(r"[ôö]"), "o")
        .replaceAll(RegExp(r"[ùûü]"), "u")
        .replaceAll(RegExp(r"[ç]"), "c");

    // Remplacement des espaces et caractères spéciaux par "_"
    normalized = normalized
        .replaceAll(RegExp(r"[^\w]+"), "_") // tout ce qui n'est pas [a-z0-9_]
        .replaceAll(RegExp(r"_+"), "_") // supprime les doubles __
        .replaceAll(RegExp(r"^_|_$"), ""); // supprime "_" au début/fin

    return normalized;
  }

  String getSeasonImage(String name) {
    final normalized = _normalizeSeasonName(name);

    // Liste des fichiers existants dans assets/seasons
    const availableImages = [
      "automne.jpg",
      "conference_internationale.jpg",
      "festival_culturel_ete.jpg",
      "fetes_de_fin_dannee.jpg",
      "hiver.jpg",
      "printemps.jpg",
      "promotion_sejour_long.jpeg",
      "ramadan_tarifs_preferentiels.jpg",
      "vacances_scolaires_hiver.jpg",
      "ete.jpg", // correspond à été.jpg après normalisation
    ];

    // Chercher le fichier correspondant
    final match = availableImages.firstWhere(
      (file) => file.startsWith(normalized),
      orElse: () => "default.jpg", // fallback si pas trouvé
    );

    return "assets/seasons/$match";
  }

  @override
  Widget build(BuildContext context) {
    // final imagePath = seasonalImages[season.name.toLowerCase()] ??
    //     "assets/seasons/default.jpg";
    final imagePath = getSeasonImage(season.name);

    return Center(
      child: Container(
        width: 320,
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _getSeasonIcon(season.name),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      season.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TimelineWidget(
                        startDate: season.startDate, endDate: season.endDate),
                    const SizedBox(height: 8),
                    Text(
                      season.description ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "${season.multiplier}x",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const TimelineWidget({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return DateFormat("d MMMM y", "fr_FR").format(date);
  }

  String _formatDateName(DateTime date) {
    return DateFormat("EEEE", "fr_FR").format(date);
  }

  String _formatDateDateShort(DateTime date) {
    return DateFormat("d/MM", "fr_FR").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Point de départ
          _buildTimelinePoint(
            dateName: _formatDateName(startDate),
            iconColor: Colors.white70,
            circleColor: Colors.black54,
            circleBorderColor: Colors.white70,
            checkIcon: Icons.check,
            date: _formatDate(startDate),
            dateShort: _formatDateDateShort(startDate),
          ),

          // Ligne avec flèche
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: 50,
                child: CustomPaint(
                  painter: TimelineArrowPainter(
                    color: Colors.green,
                    strokeWidth: 6,
                    arrowHeadSize: 15,
                  ),
                ),
              ),
            ),
          ),

          // Point d'arrivée
          _buildTimelinePoint(
            dateName: _formatDateName(endDate),
            iconColor: Colors.green,
            circleColor: Colors.black54,
            circleBorderColor: Colors.green,
            checkIcon: Icons.refresh,
            date: _formatDate(endDate),
            dateShort: _formatDateDateShort(endDate),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePoint({
    required String dateName,
    required Color iconColor,
    required Color circleColor,
    required Color circleBorderColor,
    required IconData checkIcon,
    required String date,
    required String dateShort,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(color: circleBorderColor, width: 2),
              ),
              // child: Icon(checkIcon, size: 12, color: Colors.white),
            ),
            Text(
              dateShort,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // const SizedBox(height: 8),
        // Text(
        //   date,
        //   style: const TextStyle(
        //     color: Colors.white70,
        //     fontSize: 13,
        //   ),
        // ),
        Text(
          dateName.capitalize,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class TimelineArrowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double arrowHeadSize;

  TimelineArrowPainter({
    required this.color,
    this.strokeWidth = 5.0,
    this.arrowHeadSize = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dessine la ligne horizontale au centre
    final centerY = size.height / 2;
    final lineStart = Offset(0, centerY);
    final lineEnd = Offset(size.width, centerY);
    canvas.drawLine(lineStart, lineEnd, paint);

    // Dessine la tête de flèche
    final path = Path();
    path.moveTo(size.width - arrowHeadSize, centerY - arrowHeadSize / 2);
    path.lineTo(size.width, centerY);
    path.lineTo(size.width - arrowHeadSize, centerY + arrowHeadSize / 2);
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant TimelineArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.arrowHeadSize != arrowHeadSize;
  }
}

class ReservationExtrasList extends StatefulWidget {
  final List<ReservationExtra> extras;
  final Reservation reservation;

  const ReservationExtrasList(
      {super.key, required this.extras, required this.reservation});

  @override
  State<ReservationExtrasList> createState() => _ReservationExtrasListState();
}

class _ReservationExtrasListState extends State<ReservationExtrasList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final extras = widget.extras;

    // calcul du total
    final total = extras.fold<double>(
      0,
      (sum, e) => sum + e.extraService.target!.price,
    );

    final itemCount =
        _expanded ? extras.length : (extras.length > 3 ? 3 : extras.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final extra = extras[index];
            return Tooltip(
              message: extra.extraService.target!.name,
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExtraServiceDetailPage(reservationExtra: extra),
                  ),
                ),
                leading: CircleAvatar(
                  child: Text('${extra.quantity}'),
                ),
                title: Text(
                  extra.extraService.target!.name,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'PU: ${extra.unitPrice}${_getPricingText(extra.extraService.target!.pricingUnit)} = ',
                ),
                trailing: Text(
                  '${extra.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                dense: true,
              ),
            );
          },
        ),
        if (extras.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(_expanded ? "Voir moins" : "Voir plus"),
            ),
          ),

        // affichage du total
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Total : ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                widget.reservation.extrasTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPricingText(String pricingUnit) {
    switch (pricingUnit.toLowerCase()) {
      case 'per_person':
        return '/Personne';
      case 'per_item':
        return '/Article';
      case 'per_night':
        return '/Nuit';
      case 'per_stay':
        return '/Séjour';
      default:
        return '';
    }
  }
}
