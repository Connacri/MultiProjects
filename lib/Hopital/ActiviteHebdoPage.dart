import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import 'Providers.dart';

class ActiviteHebdoPage extends StatelessWidget {
  const ActiviteHebdoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final personnels = context.watch<PersonnelProvider>().personnels;
    final activites = context.watch<ActiviteHebdoProvider>().activites;

    final jours = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi"];

    return Scaffold(
      appBar: AppBar(title: const Text("Planning Hebdo Médecins")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
          columns: [
            const DataColumn(label: Text("Nom")),
            const DataColumn(label: Text("Fonction")),
            ...jours.map((j) => DataColumn(label: Text(j))),
          ],
          rows: personnels.map((emp) {
            return DataRow(
              cells: [
                DataCell(Text("${emp.nom} ${emp.prenom}")),
                DataCell(Text(emp.fonction)),
                ...jours.map((j) {
                  final act = activites.firstWhere(
                    (a) => a.personnel.target?.id == emp.id && a.jour == j,
                    orElse: () => ActiviteHebdo(
                      jour: j,
                      activite: "Service",
                    )..personnel.target = emp,
                  );

                  return DataCell(
                    TextFormField(
                      initialValue: act.activite,
                      onFieldSubmitted: (val) {
                        act.activite = val;
                        context
                            .read<ActiviteHebdoProvider>()
                            .updateActivite(act);
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
