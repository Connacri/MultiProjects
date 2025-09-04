import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Entity.dart';
import 'provider_hotel.dart';

class SeasonalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SeasonalAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Consumer<HotelProvider>(
        builder: (_, provider, __) {
          final selected = provider.selectedSeasonalPricing;

          if (selected == null) {
            return const Text(
              "Aucune saison active",
              style: TextStyle(color: Colors.white),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
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
