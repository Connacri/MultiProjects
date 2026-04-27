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
import 'pdf_options_dialog.dart';

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

  final baseStyle = pw.TextStyle(font: oswald, fontSize: 10);
  final bold = pw.TextStyle(
    font: oswald,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );

  // ⭐ NOUVELLE FONCTION : Tri personnalisé exactement comme TableauStaffPage
  void sortStaffList(List membres) {
    membres.sort((a, b) {
      // 1. Si les deux ont un ordre personnalisé, l'utiliser en priorité
      if (a.ordre != null && b.ordre != null) {
        return a.ordre!.compareTo(b.ordre!);
      }

      // 2. Si seulement l'un a un ordre, le mettre en premier
      if (a.ordre != null) return -1;
      if (b.ordre != null) return 1;

      // 3. Sinon, trier par nom (comme TableauStaff)
      return (a.nom ?? '').toString().compareTo((b.nom ?? '').toString());
    });
  }

  // Regrouper par groupe (tel que dans ton code)
  final Map<String, List<dynamic>> grouped = {};
  for (var s in staffs) {
    final g = (s.groupe ?? 'Sans Groupe').toString();
    grouped.putIfAbsent(g, () => []).add(s);
  }

  // Pour chaque groupe, on crée une page par sous-groupe (médecins / autres pour 08H-16H)
  grouped.forEach((groupe, membres) {
    List<List<dynamic>> subGroups = [];

    // ✅ Groupe 08H-12H (Agents d'hygiène)
    if (groupe.toUpperCase().contains('08H') &&
        groupe.toUpperCase().contains('12H') &&
        !groupe.toUpperCase().contains('16H')) {
      // ⭐ UTILISER LE TRI PERSONNALISÉ
      sortStaffList(membres);
      subGroups.add(membres);
      print(
          "✅ Groupe 08H-12H détecté: $groupe avec ${membres.length} membres (ordre personnalisé)");
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

      // ⭐ UTILISER LE TRI PERSONNALISÉ pour chaque sous-groupe
      sortStaffList(medecins);
      sortStaffList(autres);

      if (medecins.isNotEmpty) subGroups.add(medecins);
      if (autres.isNotEmpty) subGroups.add(autres);

      print(
          "✅ Groupe 08H-16H: ${medecins.length} médecins, ${autres.length} autres (ordre personnalisé)");
    }
    // ✅ Tous les autres groupes (08H-08H, Garde 12H, etc.)
    else {
      // ⭐ UTILISER LE TRI PERSONNALISÉ
      sortStaffList(membres);
      subGroups.add(membres);
      print(
          "✅ Autre groupe détecté: $groupe avec ${membres.length} membres (ordre personnalisé)");
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
        title = "Agents d'Hygiène — 12h";
      } else if (isMedecinsGroup) {
        title = '08h–16h — Personnel Médical';
      } else if (groupe.toUpperCase().contains('08H') &&
          groupe.toUpperCase().contains('16H')) {
        title = '08h–16h';
      } else {
        title = '24h'; //groupe;
      }

      final prefix = getMonthPrefix(monthName);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          header: (ctx) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // pw.Container(
              //     width: 45,
              //     height: 45,
              //     margin: const pw.EdgeInsets.only(right: 8),
              //     child: pw.Image(logo, fit: pw.BoxFit.contain)),
              pw.Center(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
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
              ),
            ],
          ),
          build: (ctx) => [
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text('Unité : Service de Rhumatologie',
                    style: baseStyle.copyWith(fontSize: 12)),
              ],
            ),
           // pw.SizedBox(height: 6),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'TABLEAU D\'ACTIVITÉ DU MOIS ${prefix.toUpperCase()}${monthName.toUpperCase()} $year | $title',
                style: bold.copyWith(fontSize: 14),
              ),
            ),
            // pw.SizedBox(height: 4),
            // pw.Center(
            //     child: pw.Text(title, style: bold.copyWith(fontSize: 12))),
            pw.SizedBox(height: 4),
            pw.Center(
              child: _buildGroupTable(list, daysInMonth, oswald, year, month),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                    'G : Garde       RE : Récupération       C : Congé       CM : Congé Maladie       N : Normal',
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
             // pw.Text('N.B : Toutes modifications de programme ne doivent se faire qu\'après accord de la direction', style: baseStyle),
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
    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}h${now.minute.toString().padLeft(2, '0')}m${now.second.toString().padLeft(2, '0')}s${now.millisecond.toString().padLeft(3, '0')}';

    final fileName = 'Planning_${monthName}_${year}_$formattedTime.pdf';
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

/// Génère et sauvegarde le planning mensuel complet en PDF avec options
/// ✅ VERSION CORRIGÉE - Génère le planning avec 4 types d'activité distincts
Future<String?> generateAndSaveMonthPlanningPDFWithOptions(
  BuildContext context, {
  required int year,
  required int month,
  required List<PdfPageOption> options,
}) async {
  // ✅ Vérifier si au moins un type d'activité est sélectionné
  final hasAnyActivite = options.any((opt) =>
      opt.type == PdfPageType.activiteTableauMedical ||
      opt.type == PdfPageType.activiteTableauAdministratif ||
      opt.type == PdfPageType.activiteTableauParamedical ||
      opt.type == PdfPageType.activiteTableauHygiene);

  if (!hasAnyActivite && options.isNotEmpty) {
    return null;
  }

  // ✅ Récupérer les 4 options distinctes
  final medicalOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.activiteTableauMedical,
    orElse: () =>
        PdfPageOption(type: PdfPageType.activiteTableauMedical, title: ''),
  );

  final administratifOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.activiteTableauAdministratif,
    orElse: () => PdfPageOption(
        type: PdfPageType.activiteTableauAdministratif, title: ''),
  );

  final paramedicalOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.activiteTableauParamedical,
    orElse: () =>
        PdfPageOption(type: PdfPageType.activiteTableauParamedical, title: ''),
  );

  final hygieneOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.activiteTableauHygiene,
    orElse: () =>
        PdfPageOption(type: PdfPageType.activiteTableauHygiene, title: ''),
  );

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

  final baseStyle = pw.TextStyle(font: oswald, fontSize: 10);
  final bold = pw.TextStyle(
    font: oswald,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );

  void sortStaffList(List membres) {
    membres.sort((a, b) {
      if (a.ordre != null && b.ordre != null) {
        return a.ordre!.compareTo(b.ordre!);
      }
      if (a.ordre != null) return -1;
      if (b.ordre != null) return 1;

      return (a.nom ?? '').toString().compareTo((b.nom ?? '').toString());
    });
  }

  // Regrouper par groupe
  final Map<String, List<dynamic>> grouped = {};
  for (var s in staffs) {
    final g = (s.groupe ?? 'Sans Groupe').toString();
    grouped.putIfAbsent(g, () => []).add(s);
  }

  final prefix = getMonthPrefix(monthName);

  // ✅ GÉNÉRATION DES PAGES SELON LES OPTIONS
  grouped.forEach((groupe, membres) {
    List<List<dynamic>> subGroups = [];
    PdfPageOption? currentOption;
    String pageTitle = '';

    // ✅ Déterminer le type et l'option correspondante
    if (groupe.toUpperCase().contains('08H-12H')) {
      // Agents d'hygiène
      if (!options.any((o) => o.type == PdfPageType.activiteTableauHygiene))
        return;
      currentOption = hygieneOption;
      sortStaffList(membres);
      subGroups.add(membres);
      pageTitle = "Agents d'Hygiène - 12h";
    } else if (groupe.toUpperCase().contains('08H-16H')) {
      // 08H-16H : séparer médecins / administratifs
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

      sortStaffList(medecins);
      sortStaffList(autres);

      // Médecins
      if (medecins.isNotEmpty &&
          options.any((o) => o.type == PdfPageType.activiteTableauMedical)) {
        subGroups.add(medecins);
        currentOption = medicalOption;
        pageTitle = '08h–16h – Personnel Médical';
        _addActivityPage(
            pdf,
            medecins,
            daysInMonth,
            oswald,
            year,
            month,
            pageTitle,
            currentOption,
            logo,
            bold,
            baseStyle,
            prefix,
            monthName);
      }

      // Administratifs
      if (autres.isNotEmpty &&
          options
              .any((o) => o.type == PdfPageType.activiteTableauAdministratif)) {
        currentOption = administratifOption;
        pageTitle = '08h–16h';
        _addActivityPage(
            pdf,
            autres,
            daysInMonth,
            oswald,
            year,
            month,
            pageTitle,
            currentOption,
            logo,
            bold,
            baseStyle,
            prefix,
            monthName);
      }
      return;
    } else {
      // Personnel paramédical (08H-08H)
      if (!options.any((o) => o.type == PdfPageType.activiteTableauParamedical))
        return;
      currentOption = paramedicalOption;
      sortStaffList(membres);
      subGroups.add(membres);
      pageTitle = '24h';
    }

    // Générer les pages pour les groupes simples
    for (var list in subGroups) {
      _addActivityPage(
          pdf,
          list,
          daysInMonth,
          oswald,
          year,
          month,
          pageTitle,
          currentOption,
          logo,
          bold,
          baseStyle,
          prefix,
          monthName);
    }
  });

  // Sauvegarde
  try {
    final pdfBytes = await pdf.save();
    final now = DateTime.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}h'
        '${now.minute.toString().padLeft(2, '0')}m'
        '${now.second.toString().padLeft(2, '0')}s'
        '${now.millisecond.toString().padLeft(3, '0')}';

    final fileName = 'Planning_${monthName}_${year}_$formattedTime.pdf';

    if (Platform.isAndroid) {
      return await _saveToAndroid(pdfBytes, fileName);
    } else {
      return await _saveToDesktop(pdfBytes, fileName);
    }
  } catch (e) {
    print('✖ Erreur sauvegarde PDF : $e');
    return null;
  }
}

/// ✅ Fonction helper pour ajouter une page d'activité
void _addActivityPage(
  pw.Document pdf,
  List<dynamic> staffList,
  int daysInMonth,
  pw.Font oswald,
  int year,
  int month,
  String subtitle,
  PdfPageOption? option,
  pw.MemoryImage logo,
  pw.TextStyle bold,
  pw.TextStyle baseStyle,
  String prefix,
  String monthName,
) {
  // Construction du titre avec Modificatif
  String mainTitle =
      'TABLEAU D\'ACTIVITÉ DU MOIS ${prefix.toUpperCase()}${monthName.toUpperCase()} $year';
  if (option?.includeModificatif ?? false) {
    mainTitle += ' (Modificatif) ';
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      header: (ctx) => _buildPageHeader(logo, bold, baseStyle),
      build: (ctx) => [
        pw.Spacer(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text('Unité : Service de Rhumatologie',
                style: baseStyle.copyWith(fontSize: 12)),
          ],
        ),
        pw.SizedBox(height: 6),

        // ✅ Titre avec texte personnalisé sur la même ligne
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(mainTitle + ' ' + subtitle,
                  style: bold.copyWith(fontSize: 14),
                  textAlign: pw.TextAlign.center),
              // pw.SizedBox(height: 4),
              // pw.Center(
              //     child: pw.Text(subtitle, style: bold.copyWith(fontSize: 12))),
              if (option?.customText != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  option!.customText!,
                  style: baseStyle.copyWith(
                    fontSize: 10,
                    color: PdfColors.blue700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 8),
        pw.Center(
            child:
                _buildGroupTable(staffList, daysInMonth, oswald, year, month)),
        pw.SizedBox(height: 8),
        _buildPageFooterContent(baseStyle),
        pw.Spacer(),
      ],
      footer: (ctx) => _buildPageFooter(baseStyle),
    ),
  );
}

/// Helpers pour header/footer (à créer si pas déjà présents)
pw.Widget _buildPageHeader(
    pw.MemoryImage logo, pw.TextStyle bold, pw.TextStyle baseStyle) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
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
          ],
        ),
      ),
    ],
  );
}

pw.Widget _buildPageFooterContent(pw.TextStyle baseStyle) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
          'G : Garde       RE : Récupération       C : Congé       CM : Congé Maladie       N : Normal',
          style: baseStyle),
      pw.Text(
          'Fait à Aïn el Türck le : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          style: baseStyle),
    ],
  );
}

pw.Widget _buildPageFooter(pw.TextStyle baseStyle) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('N.B : Toutes modifications de programme ne doivent se faire qu\'après accord de la direction', style: baseStyle),
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
  );
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
  // ⭐ Détecter si c'est le personnel paramédical (avec équipes A,B,C,D)
  final hasEquipes = membres.any((s) =>
      s.equipe != null &&
      ['A', 'B', 'C', 'D'].contains(s.equipe.toString().toUpperCase()));

// // ✅ Headers avec nombre de jours dynamique
//   final headers = hasEquipes
//       ? <String>['N°', 'Nom et Prénom', 'Grade', 'Équipe'] +
//           List.generate(
//             daysInMonth,
//             (i) {
//               final jour = i + 1;
//               final date = DateTime(year, month, jour);
//               final nomJour = DateFormat('EEE', 'fr_FR')
//                   .format(date)
//                   .substring(0, 3)
//                   .toUpperCase();
//               return '$jour\n$nomJour';
//             },
//           )
//       : <String>['N°', 'Nom et Prénom', 'Grade'] +
//           List.generate(daysInMonth, (i) {
//             final jour = i + 1;
//             final date = DateTime(year, month, jour);
//             final nomJour = DateFormat('EEE', 'fr_FR')
//                 .format(date)
//                 .substring(0, 3)
//                 .toUpperCase();
//             return '$jour\n$nomJour';
//           });
// ✅ Headers avec nombre de jours dynamique (retourne Map)
  final headers = hasEquipes
      ? <Map<String, dynamic>>[
          {'jour': 'Nom et Prénom', 'nomJour': ''},
          {'jour': 'Grade', 'nomJour': ''},
          {'jour': 'Équipe', 'nomJour': ''},
          ...List.generate(daysInMonth, (i) {
            final jour = i + 1;
            final date = DateTime(year, month, jour);
            final nomJour = DateFormat('EEE', 'fr_FR')
                .format(date)
                .substring(0, 3)
                .toUpperCase();
            return {'jour': '$jour', 'nomJour': nomJour};
          }),
        ]
      : <Map<String, dynamic>>[
          {'jour': 'Nom et Prénom', 'nomJour': ''},
          {'jour': 'Grade', 'nomJour': ''},
          ...List.generate(daysInMonth, (i) {
            final jour = i + 1;
            final date = DateTime(year, month, jour);
            final nomJour = DateFormat('EEE', 'fr_FR')
                .format(date)
                .substring(0, 3)
                .toUpperCase();
            return {'jour': '$jour', 'nomJour': nomJour};
          }),
        ];

  final data = <List<String>>[];

  // ⭐ IMPORTANT : Les membres sont déjà triés par sortStaffList()
  // On respecte donc l'ordre personnalisé
  for (var s in membres) {
    final nom = (s.nom ?? '').toString();
    final grade = (s.grade ?? '').toString();
    final equipe = (s.equipe ?? '-').toString();
    final activites = (s.activites ?? []).toList();

    final row = hasEquipes
        ? <String>[
            nom,
            grade,
            equipe, // ⭐ Colonne équipe ajoutée
            ...List.generate(daysInMonth, (d) {
              final act = activites.firstWhere(
                (a) => (a.jour ?? -1) == d + 1,
                orElse: () => ActiviteJour.empty(),
              );
              final statut = (act?.statut ?? '')?.toString() ?? '';
              return statut;
            }),
          ]
        : <String>[
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
  }

  // ⭐ Largeurs de colonnes ajustées selon la présence d'équipe
  final columnWidths = <int, pw.TableColumnWidth>{
    0: const pw.FlexColumnWidth(1.22), // Nom -10%
    1: const pw.FlexColumnWidth(1.1), // Grade -20%
  };

  if (hasEquipes) {
    columnWidths[2] = const pw.FixedColumnWidth(25); // Colonne Équipe
    for (int i = 0; i < daysInMonth; i++) {
      columnWidths[3 + i] = const pw.FixedColumnWidth(18);
    }
  } else {
    for (int i = 0; i < daysInMonth; i++) {
      columnWidths[2 + i] = const pw.FixedColumnWidth(18);
    }
  }

  final headerCells = <pw.Widget>[];
  for (int ci = 0; ci < headers.length; ci++) {
    bool isWeekend = false;

    // ⭐ Ajuster l'offset selon la présence de la colonne Équipe
    final dayColumnStart = hasEquipes ? 3 : 2;

    if (ci >= dayColumnStart) {
      final day = ci - dayColumnStart + 1;
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
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Center(
              child: pw.Text(
                headers[ci]['jour'].toString(),
                style: pw.TextStyle(
                  font: oswald,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: txtColor,
                ),
              ),
            ),
            if ((headers[ci]['nomJour'] ?? '').isNotEmpty)
              pw.Center(
                child: pw.Text(
                  headers[ci]['nomJour'].toString(),
                  style: pw.TextStyle(
                    font: oswald,
                    fontSize: 8,
                    color: txtColor,
                  ),
                ),
              ),
          ],
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

      // ⭐ Ajuster l'offset selon la présence de la colonne Équipe
      final dayColumnStart = hasEquipes ? 3 : 2;

      if (ci >= dayColumnStart) {
        final day = ci - dayColumnStart + 1;
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
            style: pw.TextStyle(font: oswald, fontSize: 9, color: txtColor),
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
