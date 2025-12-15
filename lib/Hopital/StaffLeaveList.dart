import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../objectBox/Entity.dart';

class StaffLeaveList extends StatelessWidget {
  final List<Staff> staffs;
  final int selectedMonth;
  final int selectedYear;

  const StaffLeaveList({
    Key? key,
    required this.staffs,
    required this.selectedMonth,
    required this.selectedYear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Liste du personnel avec congés et observations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: staffs.length,
              itemBuilder: (context, index) {
                final staff = staffs[index];
                final timeOffs = staff.timeOff.toList();
                final obs = staff.obs ?? "Aucune observation";

                // Filtrer les congés pour le mois/année sélectionnés
                final filteredTimeOffs = timeOffs.where((timeOff) {
                  final startOfMonth = DateTime(selectedYear, selectedMonth, 1);
                  final endOfMonth =
                      DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59);
                  final isInMonth = (timeOff.debut.isBefore(endOfMonth) ||
                          timeOff.debut.isAtSameMomentAs(endOfMonth)) &&
                      (timeOff.fin.isAfter(startOfMonth) ||
                          timeOff.fin.isAtSameMomentAs(startOfMonth));
                  return isInMonth;
                }).toList();

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom et fonction du staff
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              "${staff.nom} (${staff.grade ?? 'Non spécifié'})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Observations
                        Row(
                          children: [
                            const Icon(Icons.comment,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Obs: $obs",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Liste des congés
                        if (filteredTimeOffs.isNotEmpty) ...[
                          const Text(
                            "Congés:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...filteredTimeOffs.map((timeOff) {
                            final duree =
                                timeOff.fin.difference(timeOff.debut).inDays +
                                    1;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 16.0, top: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${timeOff.motif ?? 'Congé'} (${DateFormat('dd/MM/yyyy').format(timeOff.debut)} => ${DateFormat('dd/MM/yyyy').format(timeOff.fin)}) - $duree jour${duree > 1 ? 's' : ''}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0, top: 4.0),
                            child: Text(
                              "Aucun congé pour ce mois.",
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
