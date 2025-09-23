import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import 'Providers.dart';

class PlanningMoisPage extends StatelessWidget {
  final int annee;
  final int mois;

  const PlanningMoisPage({super.key, required this.annee, required this.mois});

  @override
  Widget build(BuildContext context) {
    final personnels = context.watch<PersonnelProvider>().personnels;
    final affectations =
        context.watch<AffectationJourProvider>().getForMonth(annee, mois);

    int daysInMonth = DateUtils.getDaysInMonth(annee, mois);

    return Scaffold(
      appBar: AppBar(title: Text("Planning $mois/$annee")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columns: [
            const DataColumn(label: Text("Nom")),
            const DataColumn(label: Text("Fonction")),
            ...List.generate(daysInMonth, (i) {
              return DataColumn(label: Text("${i + 1}"));
            }),
          ],
          rows: personnels.map((emp) {
            return DataRow(
              cells: [
                DataCell(Text("${emp.nom} ${emp.prenom}")),
                DataCell(Text(emp.fonction)),
                ...List.generate(daysInMonth, (day) {
                  // trouver l’affectation du jour
                  final aff = affectations.firstWhere(
                    (a) =>
                        a.personnel.target?.id == emp.id &&
                        a.date.day == day + 1,
                    orElse: () => AffectationJour.empty()
                      ..date = DateTime(annee, mois, day + 1)
                      ..statut = StatutActivite.normal.index
                      ..personnel.target = emp,
                  );

                  return DataCell(
                    DropdownButton<int>(
                      value: aff.statut,
                      items: StatutActivite.values.map((s) {
                        return DropdownMenuItem(
                          value: s.index,
                          child: Text(s.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          aff.statut = val;
                          context
                              .read<AffectationJourProvider>()
                              .updateAffectation(aff);
                        }
                      },
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
