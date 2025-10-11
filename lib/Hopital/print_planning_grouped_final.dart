import 'dart:io';

import 'package:flutter/material.dart' show BuildContext, DateUtils;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import 'Planning_pdf.dart';
import 'StaffProvider.dart';

/// Génère et sauvegarde le planning mensuel complet en PDF
/// Retourne le chemin du fichier sauvegardé
Future<String?> generateAndSaveMonthPlanningPDF(
  BuildContext context, {
  required int year,
  required int month,
}) async {
  final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  await staffProvider.fetchStaffs();
  final staffs = staffProvider.staffs ?? [];

  if (staffs.isEmpty) return null;

  final daysInMonth = DateUtils.getDaysInMonth(year, month);
  final monthName = DateFormat.MMMM('fr_FR').format(DateTime(year, month));
  final pdf = pw.Document();

  final fontData = await rootBundle.load('assets/fonts/Oswald-Regular.ttf');
  final oswald = pw.Font.ttf(fontData);
  final logoData = await rootBundle.load('assets/images/logo_hopital.png');
  final logo = pw.MemoryImage(logoData.buffer.asUint8List());

  final baseStyle = pw.TextStyle(font: oswald, fontSize: 9);
  final bold = pw.TextStyle(
    font: oswald,
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );

  // Regrouper par groupe (tel que dans ton code)
  final Map<String, List<dynamic>> grouped = {};
  for (var s in staffs) {
    final g = (s.groupe ?? 'Sans Groupe').toString();
    grouped.putIfAbsent(g, () => []).add(s);
  }

  // ✅ NOUVEAU : Fonction pour obtenir la priorité de l'équipe
  int getEquipePriority(String? equipe) {
    if (equipe == null) return 5;
    switch (equipe.toUpperCase()) {
      case 'A':
        return 1;
      case 'B':
        return 2;
      case 'C':
        return 3;
      case 'D':
        return 4;
      default:
        return 5;
    }
  }

  // Pour chaque groupe, on crée une page par sous-groupe (médecins / autres pour 08H-16H)
  grouped.forEach((groupe, membres) {
    List<List<dynamic>> subGroups = [];

    // ✅ Groupe 08H-12H (Agents d'hygiène)
    if (groupe.toUpperCase().contains('08H') &&
        groupe.toUpperCase().contains('12H') &&
        !groupe.toUpperCase().contains('16H')) {
      // ✅ Trier par nom pour ce groupe
      membres.sort((a, b) =>
          (a.nom ?? '').toString().compareTo((b.nom ?? '').toString()));
      subGroups.add(membres);
      print("✅ Groupe 08H-12H détecté: $groupe avec ${membres.length} membres");
    }
    // ✅ Groupe 08H-16H (Médecins/Administratifs)
    else if (groupe.toUpperCase().contains('08H') &&
        groupe.toUpperCase().contains('16H')) {
      final medecins = membres.where((s) {
        final grade = (s.grade ?? '').toString().toUpperCase();
        return grade.contains('MÉDECIN') ||
            grade.contains('MEDECIN') ||
            grade.contains('RHUMATOLOGUE');
      }).toList();

      final autres = membres.where((s) {
        final grade = (s.grade ?? '').toString().toUpperCase();
        return !(grade.contains('MÉDECIN') ||
            grade.contains('MEDECIN') ||
            grade.contains('RHUMATOLOGUE'));
      }).toList();

      // ✅ Trier chaque sous-groupe par équipe puis par nom
      medecins.sort((a, b) {
        int priorityA = getEquipePriority(a.equipe);
        int priorityB = getEquipePriority(b.equipe);
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return (a.nom ?? '').toString().compareTo((b.nom ?? '').toString());
      });

      autres.sort((a, b) {
        int priorityA = getEquipePriority(a.equipe);
        int priorityB = getEquipePriority(b.equipe);
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return (a.nom ?? '').toString().compareTo((b.nom ?? '').toString());
      });

      if (medecins.isNotEmpty) subGroups.add(medecins);
      if (autres.isNotEmpty) subGroups.add(autres);
    }
    // ✅ Tous les autres groupes (08H-08H, Garde 12H, etc.)
    else {
      // ✅ Trier par équipe puis par nom
      membres.sort((a, b) {
        int priorityA = getEquipePriority(a.equipe);
        int priorityB = getEquipePriority(b.equipe);
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return (a.nom ?? '').toString().compareTo((b.nom ?? '').toString());
      });
      subGroups.add(membres);
      print(
          "✅ Autre groupe détecté: $groupe avec ${membres.length} membres (trié par équipe)");
    }

    // Génération des pages
    for (var list in subGroups) {
      // ⭐ Titre corrigé
      final bool isMedecinsGroup = list.isNotEmpty &&
          ((list.first.grade ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('MÉDECIN') ||
              (list.first.grade ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('MEDECIN') ||
              (list.first.grade ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('RHUMATOLOGUE'));

      // ⭐ Détecter si c'est un groupe d'agents d'hygiène
      final bool isAgentsHygiene = list.isNotEmpty &&
          ((list.first.grade ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('HYGIÈNE') ||
              (list.first.grade ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('HYGIENE'));

      String title;
      if (isAgentsHygiene) {
        title = "Agents d'Hygiène (08h–12h)";
      } else if (isMedecinsGroup) {
        title = '08h–16h — (Personnel Médical)';
      } else if (groupe.toUpperCase().contains('08H') &&
          groupe.toUpperCase().contains('16H')) {
        title = '08h–16h — (Autres personnels)';
      } else {
        title = groupe;
      }

      final prefix = getMonthPrefix(monthName);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          header: (ctx) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                  width: 45,
                  height: 45,
                  margin: const pw.EdgeInsets.only(right: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RÉPUBLIQUE ALGÉRIENNE DÉMOCRATIQUE ET POPULAIRE',
                        style: bold),
                    pw.Text(
                        'MINISTÈRE DE LA SANTÉ, DE LA POPULATION ET DE LA RÉFORME HOSPITALIÈRE',
                        style: baseStyle),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        'Établissement Hospitalier d\'Aïn El Türck - Dr. Medjber Tami',
                        style: baseStyle),
                    pw.SizedBox(height: 24),
                  ]),
            ],
          ),
          build: (ctx) => [
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text('Unité : Service de Rhumatologie',
                    style: baseStyle.copyWith(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'TABLEAU D\'ACTIVITÉ DU MOIS ${prefix.toUpperCase()}${monthName.toUpperCase()} $year',
                style: bold.copyWith(fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
                child: pw.Text(title, style: bold.copyWith(fontSize: 12))),
            pw.SizedBox(height: 8),
            pw.Center(
              child: _buildGroupTable(list, daysInMonth, oswald, year, month),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                    'G : Garde 12h       Ré : Récupération       C : Congé       CM : Congé Maladie       N : Normal',
                    style: baseStyle),
                pw.Text(
                    'Fait à Aïn el Türck le : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: baseStyle),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
                'N.B : Toutes modifications de programme ne doivent se faire qu\'après accord de la direction',
                style: baseStyle),
            pw.Spacer(),
          ],
          footer: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text('Le Médecin Chef', style: baseStyle),
                  pw.Text('Le Surveillant Médical', style: baseStyle),
                  pw.Text('DAPM', style: baseStyle),
                  pw.Text('Le Directeur Général', style: baseStyle),
                ],
              ),
              pw.SizedBox(height: 90),
            ],
          ),
        ),
      );
    }
  });

  // Sauvegarde
  try {
    final pdfBytes = await pdf.save();
    final fileName = 'Planning_${monthName}_$year.pdf';
    if (Platform.isAndroid) {
      return await _saveToAndroid(pdfBytes, fileName);
    } else {
      return await _saveToDesktop(pdfBytes, fileName);
    }
  } catch (e) {
    print('❌ Erreur sauvegarde PDF : $e');
    return null;
  }
}

Future<String?> _saveToAndroid(List<int> pdfBytes, String fileName) async {
  try {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        print('❌ Permission de stockage refusée');
        return null;
      }
    }

    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Documents');

      if (!await directory.exists()) {
        directory = Directory('/storage/emulated/0/Download');
      }

      final appFolder = Directory('${directory.path}/Plannings');
      if (!await appFolder.exists()) {
        await appFolder.create(recursive: true);
      }
      directory = appFolder;
    }

    if (directory != null) {
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    }
  } catch (e) {
    print('❌ Erreur Android : $e');
  }

  return null;
}

Future<String?> _saveToDesktop(List<int> pdfBytes, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();

    final planningsFolder = Directory('${directory.path}/Plannings');
    if (!await planningsFolder.exists()) {
      await planningsFolder.create(recursive: true);
    }

    final file = File('${planningsFolder.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  } catch (e) {
    print('❌ Erreur Desktop : $e');
  }

  return null;
}

pw.Widget _buildGroupTable(
  List membres,
  int daysInMonth,
  pw.Font oswald,
  int year,
  int month,
) {
  final headers = <String>['N°', 'Nom et Prénom', 'Grade'] +
      List.generate(daysInMonth, (i) => '${i + 1}');

  final data = <List<String>>[];
  int index = 1;
  for (var s in membres) {
    final nom = (s.nom ?? '').toString();
    final grade = (s.grade ?? '').toString();
    final activites = (s.activites ?? []).toList();

    final row = <String>[
      index.toString(),
      nom,
      grade,
      ...List.generate(daysInMonth, (d) {
        final act = activites.firstWhere(
          (a) => (a.jour ?? -1) == d + 1,
          orElse: () => ActiviteJour.empty(),
        );
        final statut = (act?.statut ?? '')?.toString() ?? '';
        return statut;
      }),
    ];
    data.add(row);
    index++;
  }

  final columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(13),
    1: const pw.FlexColumnWidth(2),
    2: const pw.FlexColumnWidth(1.7),
  };
  for (int i = 0; i < daysInMonth; i++) {
    columnWidths[3 + i] = const pw.FixedColumnWidth(18);
  }

  final headerCells = <pw.Widget>[];
  for (int ci = 0; ci < headers.length; ci++) {
    bool isWeekend = false;
    if (ci >= 3) {
      final day = ci - 2;
      final date = DateTime(year, month, day);
      isWeekend =
          date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
    }
    final bg = isWeekend ? PdfColors.black : PdfColors.grey300;
    final txtColor = isWeekend ? PdfColors.white : PdfColors.black;

    headerCells.add(
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: pw.BoxDecoration(color: bg),
        alignment: pw.Alignment.center,
        child: pw.Text(
          headers[ci],
          style: pw.TextStyle(
              font: oswald,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: txtColor),
        ),
      ),
    );
  }

  final rows = <pw.TableRow>[];
  rows.add(pw.TableRow(children: headerCells));

  for (int r = 0; r < data.length; r++) {
    final row = data[r];
    final cells = <pw.Widget>[];
    for (int ci = 0; ci < row.length; ci++) {
      bool isWeekend = false;
      if (ci >= 3) {
        final day = ci - 2;
        final date = DateTime(year, month, day);
        isWeekend = date.weekday == DateTime.friday ||
            date.weekday == DateTime.saturday;
      }

      final bg = isWeekend ? PdfColors.grey900 : PdfColors.white;
      final txtColor = isWeekend ? PdfColors.white : PdfColors.grey900;

      cells.add(
        pw.Container(
          height: 18,
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
          decoration: pw.BoxDecoration(color: bg),
          alignment: pw.Alignment.center,
          child: pw.Text(
            row[ci],
            style: pw.TextStyle(font: oswald, fontSize: 8, color: txtColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );
    }

    rows.add(pw.TableRow(children: cells));
  }

  return pw.Container(
    child: pw.Table(
      border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey600),
      columnWidths: columnWidths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    ),
  );
}
