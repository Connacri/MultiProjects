import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../objectBox/Entity.dart';
import 'Providers.dart';

class PlanningMoisPageSynfusion extends StatefulWidget {
  const PlanningMoisPageSynfusion({super.key});

  @override
  State<PlanningMoisPageSynfusion> createState() =>
      _PlanningMoisPageSynfusionState();
}

class _PlanningMoisPageSynfusionState extends State<PlanningMoisPageSynfusion> {
  int _annee = DateTime.now().year;
  int _mois = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final personnels = context.watch<PersonnelProvider>().personnels;
    final affectations =
        context.watch<AffectationJourProvider>().getForMonth(_annee, _mois);

    final dataSource =
        _PlanningDataSource(personnels, affectations, _annee, _mois, context);

    final joursDansMois = DateUtils.getDaysInMonth(_annee, _mois);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Planning mensuel"),
        actions: [
          // Sélecteur Année
          DropdownButton<int>(
            value: _annee,
            items: List.generate(5, (i) {
              final year = DateTime.now().year - 2 + i;
              return DropdownMenuItem(value: year, child: Text("$year"));
            }),
            onChanged: (val) {
              if (val != null && mounted) {
                setState(() => _annee = val);
              }
            },
          ),
          const SizedBox(width: 10),
          // Sélecteur Mois
          DropdownButton<int>(
            value: _mois,
            items: List.generate(12, (i) {
              final m = i + 1;
              return DropdownMenuItem(
                  value: m, child: Text("${m.toString().padLeft(2, '0')}"));
            }),
            onChanged: (val) {
              if (val != null && mounted) {
                setState(() => _mois = val);
              }
            },
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SfDataGrid(
        source: dataSource,
        frozenColumnsCount: 2, // garde Nom + Fonction fixes
        columnWidthMode: ColumnWidthMode.fitByCellValue,
        columns: [
          GridColumn(
              width: 140,
              columnName: 'nom',
              label: const Center(child: Text("Nom"))),
          GridColumn(
              width: 120,
              columnName: 'fonction',
              label: const Center(child: Text("Fonction"))),
          ...List.generate(joursDansMois, (i) {
            final jour = DateTime(_annee, _mois, i + 1);
            final dayLabel = [
              "DIM",
              "LUN",
              "MAR",
              "MER",
              "JEU",
              "VEN",
              "SAM"
            ][jour.weekday % 7];
            return GridColumn(
              width: 45,
              columnName: '${i + 1}',
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${i + 1}", style: const TextStyle(fontSize: 11)),
                  Text(dayLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (jour.weekday == 5
                              ? Colors.brown
                              : jour.weekday == 6
                                  ? Colors.orange
                                  : Colors.black))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PlanningDataSource extends DataGridSource {
  final List<Personnel> personnels;
  final List<AffectationJour> affectations;
  final int annee;
  final int mois;
  final BuildContext context;
  List<DataGridRow> _rows = [];

  _PlanningDataSource(
      this.personnels, this.affectations, this.annee, this.mois, this.context) {
    buildRows();
  }

  void buildRows() {
    _rows = [];

    // ⚡ Regroupement par service comme proxy de "groupes"
    final Map<String, List<Personnel>> groupes = {};
    for (var p in personnels) {
      groupes.putIfAbsent(p.service, () => []).add(p);
    }

    groupes.forEach((service, membres) {
      // ligne titre du groupe
      _rows.add(DataGridRow(cells: [
        DataGridCell<dynamic>(columnName: 'nom', value: "📌 $service"),
        DataGridCell<dynamic>(columnName: 'fonction', value: ""),
        ...List.generate(DateUtils.getDaysInMonth(annee, mois),
            (i) => DataGridCell<dynamic>(columnName: '${i + 1}', value: null)),
      ]));

      // lignes membres
      for (var emp in membres) {
        final cells = [
          DataGridCell<dynamic>(
              columnName: 'nom', value: "${emp.nom} ${emp.prenom}"),
          DataGridCell<dynamic>(columnName: 'fonction', value: emp.fonction),
        ];

        for (var d = 1; d <= DateUtils.getDaysInMonth(annee, mois); d++) {
          final aff = affectations.firstWhere(
            (a) => a.personnel.target?.id == emp.id && a.date.day == d,
            orElse: () => AffectationJour.empty()
              ..date = DateTime(annee, mois, d)
              ..statut = StatutActivite.normal.index
              ..personnel.target = emp,
          );
          cells.add(DataGridCell<dynamic>(columnName: '$d', value: aff));
        }
        _rows.add(DataGridRow(cells: cells));
      }
    });
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    // Ligne groupe
    if (row.getCells()[0].value.toString().startsWith("📌")) {
      return DataGridRowAdapter(cells: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blueGrey[200],
          alignment: Alignment.centerLeft,
          child: Text(row.getCells()[0].value.toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        ...List.generate(row.getCells().length - 1,
            (_) => Container(color: Colors.blueGrey[200])),
      ]);
    }

    // Ligne normale
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((c) {
        final day = int.tryParse(c.columnName) ?? 0;
        final date = (day > 0) ? DateTime(annee, mois, day) : null;
        final isFriday = date?.weekday == 5;
        final isSaturday = date?.weekday == 6;

        Color? bg;
        if (isFriday) bg = Colors.brown[100];
        if (isSaturday) bg = Colors.orange[100];

        if (c.value is! AffectationJour) {
          return Container(
            padding: const EdgeInsets.all(6),
            alignment: Alignment.centerLeft,
            child: Text(c.value?.toString() ?? ""),
          );
        }

        final aff = c.value as AffectationJour;

        return Container(
          color: bg,
          alignment: Alignment.center,
          child: DropdownButton<int>(
            value: aff.statut,
            underline: const SizedBox.shrink(),
            icon: SizedBox.shrink(),
            isDense: true,
            items: StatutActivite.values.map((s) {
              return DropdownMenuItem(
                value: s.index,
                child: Text(s.name.substring(0, 3).toUpperCase(),
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && context.mounted) {
                aff.statut = val;
                context.read<AffectationJourProvider>().updateAffectation(aff);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
