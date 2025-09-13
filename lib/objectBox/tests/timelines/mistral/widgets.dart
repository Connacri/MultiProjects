import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

class PriceCard extends StatelessWidget {
  final double basePrice;
  final double seasonalMultiplier;

  const PriceCard({
    super.key,
    required this.basePrice,
    required this.seasonalMultiplier,
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
            Center(
              child: Text(
                "${seasonalPrice.toStringAsFixed(2)} DA",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 25 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                      const Text(
                        "Prix saison",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
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
                      const Text(
                        "Prix saison",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      )
                    ],
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
