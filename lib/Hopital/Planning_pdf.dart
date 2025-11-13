import 'dart:io';

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'StaffProvider.dart';
import 'pdf_options_dialog.dart';

/// Génère les pages 2 et 3 du planning (listes du personnel)
Future<String?> generatePersonnelListsPDF(
  BuildContext context, {
  required int year,
  required int month,
}) async {
  final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  await staffProvider.fetchStaffs();
  final staffs = staffProvider.staffs ?? [];

  // 🆕 RÉCUPÉRER LE PROVIDER TypeActivite
  final typeActiviteProvider =
      Provider.of<TypeActiviteProvider>(context, listen: false);
  await typeActiviteProvider.fetchTypesActivites();

  if (staffs.isEmpty) return null;

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

  final prefix = getMonthPrefix(monthName);
  // Filtrer les médecins
  final medecins = staffs.where((s) {
    final grade = (s.grade ?? '').toString().toUpperCase();
    return grade.contains('MÉDECIN') ||
        grade.contains('MEDECIN') ||
        grade.contains('RHUMATOLOGUE');
  }).toList();

  pw.Widget _buildScheduleCell(
    String text,
    pw.Font oswald,
    double fontSize, {
    pw.Alignment alignment = pw.Alignment.center,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      alignment: alignment,
      constraints: const pw.BoxConstraints(minHeight: 35),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: oswald,
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignment == pw.Alignment.centerLeft
            ? pw.TextAlign.left
            : pw.TextAlign.center,
        maxLines: 3,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
// ========== TABLEAU HEBDOMADAIRE DES MÉDECINS - VERSION AMÉLIORÉE ==========

  pw.Widget _buildWeeklyScheduleTableImproved(List medecins, pw.Font oswald) {
    final headers = [
      'Nom et Prénom',
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi'
    ];

    final rows = <pw.TableRow>[];

    // En-tête avec style amélioré
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey800,
        ),
        children: headers.map((h) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            alignment: pw.Alignment.center,
            child: pw.Text(
              h,
              style: pw.TextStyle(
                font: oswald,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );

    // Lignes de données avec alternance de couleurs
    // Lignes de données
    for (int i = 0; i < medecins.length; i++) {
      final medecin = medecins[i];
      final nom = (medecin.nom ?? '').toString();

      // Variables pour stocker les LIBELLÉS
      String dimanche = '';
      String lundi = '';
      String mardi = '';
      String mercredi = '';
      String jeudi = '';

      try {
        if (medecin.planningsHebdo != null &&
            medecin.planningsHebdo.isNotEmpty) {
          final planning = medecin.planningsHebdo.first;

          // 🆕 CONVERSION CODE → LIBELLÉ AVEC LE PROVIDER
          // Au lieu de récupérer directement le code, on le convertit
          final codeDimanche = planning.dimanche ?? '';
          final codeLundi = planning.lundi ?? '';
          final codeMardi = planning.mardi ?? '';
          final codeMercredi = planning.mercredi ?? '';
          final codeJeudi = planning.jeudi ?? '';

          // Conversion en utilisant le Provider
          dimanche = _getActivityLabel(codeDimanche, typeActiviteProvider);
          lundi = _getActivityLabel(codeLundi, typeActiviteProvider);
          mardi = _getActivityLabel(codeMardi, typeActiviteProvider);
          mercredi = _getActivityLabel(codeMercredi, typeActiviteProvider);
          jeudi = _getActivityLabel(codeJeudi, typeActiviteProvider);
        }
      } catch (e) {
        print('⚠️ Erreur lecture planning hebdo pour $nom: $e');
      }

      final isEven = i % 2 == 0;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            _buildScheduleCell(
              nom,
              oswald,
              9.5,
              alignment: pw.Alignment.centerLeft,
              bold: true,
            ),
            // ⭐ MAINTENANT ON AFFICHE LES LIBELLÉS
            _buildScheduleCell(dimanche, oswald, 8.5),
            _buildScheduleCell(lundi, oswald, 8.5),
            _buildScheduleCell(mardi, oswald, 8.5),
            _buildScheduleCell(mercredi, oswald, 8.5),
            _buildScheduleCell(jeudi, oswald, 8.5),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        width: 0.8,
        color: PdfColors.grey700,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(1.8),
        5: pw.FlexColumnWidth(1.8),
      },
      children: rows,
    );
  }

  if (medecins.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logo, bold, baseStyle),
            pw.SizedBox(height: 50),
            pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Planning des Médecins « Mois ${prefix}${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year »',
                style: bold.copyWith(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text('DE 8H À 16H', style: bold.copyWith(fontSize: 11)),
            ),
            pw.Spacer(),
            _buildWeeklyScheduleTableImproved(medecins, oswald),
            pw.Spacer(),
            _buildFooter(baseStyle),
          ],
        ),
      ),
    );
  }

  // ========== PAGE 3 : LISTE PERSONNEL MÉDICAL ==========
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(logo, bold, baseStyle), pw.SizedBox(height: 50),
          pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
          pw.SizedBox(height: 20),

          // SECTION 1 : Personnel Médical
          pw.Center(
            child: pw.Text(
              'La liste du personnel médical du mois ${prefix}${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year',
              style: bold.copyWith(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text('DE 8H À 16H', style: bold.copyWith(fontSize: 10)),
          ),
          pw.Spacer(),
          _buildMedicalStaffTable(medecins, oswald, month, year),

          pw.Spacer(),
          _buildFooter(baseStyle),
        ],
      ),
    ),
  );

  // ========== PAGE 4 : PERSONNEL PARAMÉDICAL ==========

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(logo, bold, baseStyle), pw.SizedBox(height: 50),
          pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
          pw.SizedBox(height: 20),

          // SECTION 2 : Personnel Paramédical
          pw.Center(
              child: pw.Text(
            'Planning du Personnel Paramédical du Mois ${prefix}${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year',
            style: bold.copyWith(fontSize: 11),
          )),
          pw.Spacer(),
          _buildParamedicalStaffTable(staffs, oswald, month, year),

          pw.Spacer(),
          _buildFooter(baseStyle),
        ],
      ),
    ),
  );

  // Sauvegarde
  try {
    final pdfBytes = await pdf.save();
    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}h${now.minute.toString().padLeft(2, '0')}m${now.second.toString().padLeft(2, '0')}s${now.millisecond.toString().padLeft(3, '0')}';

    final fileName = 'Liste_Personnel_${monthName}_${year}_$formattedTime.pdf';

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

/// Génère les pages 2 et 3 du planning (listes du personnel)
Future<String?> generatePersonnelListsPDFWithOptions(
  BuildContext context, {
  required int year,
  required int month,
  required List<PdfPageOption> options,
}) async {
  // Si aucune option de personnel n'est sélectionnée, ne rien générer
  final hasPersonnelPages = options.any(
    (opt) =>
        opt.type == PdfPageType.medecinPlanning ||
        opt.type == PdfPageType.medecinListe ||
        opt.type == PdfPageType.paramedicalPlanning,
  );

  if (!hasPersonnelPages && options.isNotEmpty) {
    return null;
  }
  final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  await staffProvider.fetchStaffs();
  final staffs = staffProvider.staffs ?? [];

  // 🆕 RÉCUPÉRER LE PROVIDER TypeActivite
  final typeActiviteProvider =
      Provider.of<TypeActiviteProvider>(context, listen: false);
  await typeActiviteProvider.fetchTypesActivites();

  if (staffs.isEmpty) return null;

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

  final prefix = getMonthPrefix(monthName);

  // Filtrer les médecins
  final medecins = staffs.where((s) {
    final grade = (s.grade ?? '').toString().toUpperCase();
    return grade.contains('MÉDECIN') ||
        grade.contains('MEDECIN') ||
        grade.contains('RHUMATOLOGUE');
  }).toList();

  // Fonctions helper existantes
  pw.Widget _buildScheduleCell(String text, pw.Font oswald, double fontSize,
      {pw.Alignment alignment = pw.Alignment.center, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      alignment: alignment,
      constraints: const pw.BoxConstraints(minHeight: 35),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: oswald,
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignment == pw.Alignment.centerLeft
            ? pw.TextAlign.left
            : pw.TextAlign.center,
        maxLines: 3,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  // Récupérer les options pour chaque type de page
  final medecinPlanningOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.medecinPlanning,
    orElse: () => PdfPageOption(
      type: PdfPageType.medecinPlanning,
      title: '',
    ),
  );

  final medecinListeOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.medecinListe,
    orElse: () => PdfPageOption(
      type: PdfPageType.medecinListe,
      title: '',
    ),
  );

  final paramedicalOption = options.firstWhere(
    (opt) => opt.type == PdfPageType.paramedicalPlanning,
    orElse: () => PdfPageOption(
      type: PdfPageType.paramedicalPlanning,
      title: '',
    ),
  );
// ========== TABLEAU HEBDOMADAIRE DES MÉDECINS - VERSION AMÉLIORÉE ==========

  pw.Widget _buildWeeklyScheduleTableImproved(List medecins, pw.Font oswald) {
    final headers = [
      'Nom et Prénom',
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi'
    ];

    final rows = <pw.TableRow>[];

    // En-tête avec style amélioré
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey800,
        ),
        children: headers.map((h) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            alignment: pw.Alignment.center,
            child: pw.Text(
              h,
              style: pw.TextStyle(
                font: oswald,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );

    // Lignes de données avec alternance de couleurs
    // Lignes de données
    for (int i = 0; i < medecins.length; i++) {
      final medecin = medecins[i];
      final nom = (medecin.nom ?? '').toString();

      // Variables pour stocker les LIBELLÉS
      String dimanche = '';
      String lundi = '';
      String mardi = '';
      String mercredi = '';
      String jeudi = '';

      try {
        if (medecin.planningsHebdo != null &&
            medecin.planningsHebdo.isNotEmpty) {
          final planning = medecin.planningsHebdo.first;

          // 🆕 CONVERSION CODE → LIBELLÉ AVEC LE PROVIDER
          // Au lieu de récupérer directement le code, on le convertit
          final codeDimanche = planning.dimanche ?? '';
          final codeLundi = planning.lundi ?? '';
          final codeMardi = planning.mardi ?? '';
          final codeMercredi = planning.mercredi ?? '';
          final codeJeudi = planning.jeudi ?? '';

          // Conversion en utilisant le Provider
          dimanche = _getActivityLabel(codeDimanche, typeActiviteProvider);
          lundi = _getActivityLabel(codeLundi, typeActiviteProvider);
          mardi = _getActivityLabel(codeMardi, typeActiviteProvider);
          mercredi = _getActivityLabel(codeMercredi, typeActiviteProvider);
          jeudi = _getActivityLabel(codeJeudi, typeActiviteProvider);
        }
      } catch (e) {
        print('⚠️ Erreur lecture planning hebdo pour $nom: $e');
      }

      final isEven = i % 2 == 0;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            _buildScheduleCell(
              nom,
              oswald,
              9.5,
              alignment: pw.Alignment.centerLeft,
              bold: true,
            ),
            // ⭐ MAINTENANT ON AFFICHE LES LIBELLÉS
            _buildScheduleCell(dimanche, oswald, 8.5),
            _buildScheduleCell(lundi, oswald, 8.5),
            _buildScheduleCell(mardi, oswald, 8.5),
            _buildScheduleCell(mercredi, oswald, 8.5),
            _buildScheduleCell(jeudi, oswald, 8.5),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        width: 0.8,
        color: PdfColors.grey700,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(1.8),
        5: pw.FlexColumnWidth(1.8),
      },
      children: rows,
    );
  }

  // PAGE 2 : Planning hebdomadaire des médecins (si sélectionné)
  if (medecins.isNotEmpty &&
      (options.isEmpty ||
          options.any((opt) => opt.type == PdfPageType.medecinPlanning))) {
    // Construire le titre avec les options
    String mainTitle =
        'Planning des Médecins « Mois ${prefix}${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year »';

    if (medecinPlanningOption.includeModificatif) {
      mainTitle += ' (Modificatif)';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logo, bold, baseStyle),
            pw.SizedBox(height: 50),
            pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                mainTitle,
                style: bold.copyWith(fontSize: 12),
              ),
            ),

            // Ajouter le texte personnalisé si présent
            if (medecinPlanningOption.customText != null) ...[
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  medecinPlanningOption.customText!,
                  style: baseStyle.copyWith(
                    fontSize: 10,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text('DE 8H À 16H', style: bold.copyWith(fontSize: 11)),
            ),
            pw.Spacer(),
            _buildWeeklyScheduleTableImproved(medecins, oswald),
            pw.Spacer(),
            _buildFooter(baseStyle),
          ],
        ),
      ),
    );
  }

  // PAGE 3 : Liste personnel médical (si sélectionné)
  if (options.isEmpty ||
      options.any((opt) => opt.type == PdfPageType.medecinListe)) {
    String mainTitle =
        'La liste du personnel médical du mois ${prefix}${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year';

    if (medecinListeOption.includeModificatif) {
      mainTitle += ' (Modificatif)';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logo, bold, baseStyle),
            pw.SizedBox(height: 50),
            pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                mainTitle,
                style: bold.copyWith(fontSize: 11),
              ),
            ),
            if (medecinListeOption.customText != null) ...[
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  medecinListeOption.customText!,
                  style: baseStyle.copyWith(
                    fontSize: 9,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
            ],
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text('DE 8H À 16H', style: bold.copyWith(fontSize: 10)),
            ),
            pw.Spacer(),
            _buildMedicalStaffTable(medecins, oswald, month, year),
            pw.Spacer(),
            _buildFooter(baseStyle),
          ],
        ),
      ),
    );
  }

  // PAGE 4 : Personnel paramédical (si sélectionné)
  if (options.isEmpty ||
      options.any((opt) => opt.type == PdfPageType.paramedicalPlanning)) {
    String mainTitle =
        'Planning du Personnel Paramédical du Mois ${prefix}${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year';

    if (paramedicalOption.includeModificatif) {
      mainTitle += ' (Modificatif)';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logo, bold, baseStyle),
            pw.SizedBox(height: 50),
            pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                mainTitle,
                style: bold.copyWith(fontSize: 11),
              ),
            ),
            if (paramedicalOption.customText != null) ...[
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  paramedicalOption.customText!,
                  style: baseStyle.copyWith(
                    fontSize: 9,
                    color: PdfColors.blue700,
                  ),
                ),
              ),
            ],
            pw.Spacer(),
            _buildParamedicalStaffTable(staffs, oswald, month, year),
            pw.Spacer(),
            _buildFooter(baseStyle),
          ],
        ),
      ),
    );
  }

  // Sauvegarde
  try {
    final pdfBytes = await pdf.save();
    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}h${now.minute.toString().padLeft(2, '0')}m${now.second.toString().padLeft(2, '0')}s${now.millisecond.toString().padLeft(3, '0')}';

    final fileName = 'Liste_Personnel_${monthName}_${year}_$formattedTime.pdf';

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

// ========== WIDGETS COMMUNS ==========

pw.Widget _buildHeader(
    pw.MemoryImage logo, pw.TextStyle bold, pw.TextStyle baseStyle) {
  return pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        // pw.Container(
        //   width: 45,
        //   height: 45,
        //   margin: const pw.EdgeInsets.only(right: 8),
        //   child: pw.Image(logo, fit: pw.BoxFit.contain),
        // ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('RÉPUBLIQUE ALGÉRIENNE DÉMOCRATIQUE ET POPULAIRE',
                style: bold),
            pw.Text(
              'MINISTÈRE DE LA SANTÉ, DE LA POPULATION ET DE LA RÉFORME HOSPITALIÈRE',
              style: baseStyle,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Établissement Hospitalier d\'Aïn El Türck - Dr. Medjber Tami',
              style: baseStyle,
            ),
          ],
        ),
      ],
    ),
  ]);
}

pw.Widget _buildFooter(pw.TextStyle baseStyle) {
  return pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'fait à Aïn el Türck le : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          style: baseStyle,
        ),
      ),
      pw.SizedBox(height: 15),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Text('Le Médecin chef', style: baseStyle),
          pw.Text('Le Surveillant Médical', style: baseStyle),
          pw.Text('DAPM', style: baseStyle),
          pw.Text('Le Directeur Général', style: baseStyle),
        ],
      ),
      pw.SizedBox(height: 80),
    ],
  );
}

// ========== TABLEAU PERSONNEL MÉDICAL ==========

pw.Widget _buildMedicalStaffTable(
    List medecins, pw.Font oswald, int month, int year) {
  final rows = <pw.TableRow>[];

  // En-tête
  rows.add(
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _buildCell('Nom et Prénom', oswald, 9, bold: true),
        _buildCell('Fonction', oswald, 9, bold: true),
        _buildCell('O.B.S', oswald, 9, bold: true),
      ],
    ),
  );

  // Lignes de données
  for (var medecin in medecins) {
    rows.add(
      pw.TableRow(
        children: [
          _buildCell((medecin.nom ?? '').toString(), oswald, 9,
              alignment: pw.Alignment.centerLeft),
          _buildCell((medecin.grade ?? '').toString(), oswald, 8.5,
              alignment: pw.Alignment.centerLeft),
          _buildCell(
            _getObservationWithTimeOff(medecin, month, year).length == 0
                ? '08h-16h'
                : _getObservationWithTimeOff(medecin, month, year),
            oswald,
            9,
          )
        ],
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey800),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(4.5),
      2: pw.FlexColumnWidth(2),
    },
    children: rows,
  );
}

// Fonction pour récupérer les observations d'un staff avec OBS et TimeOff filtrés par mois/année
String _getObservationWithTimeOff(dynamic staff, int month, int year) {
  final List<String> observations = [];

  // Récupérer OBS si existe
  final obs = staff.obs ?? '';
  if (obs.isNotEmpty) {
    observations.add(obs);
  }

  // Récupérer TimeOff si existe et filtrer par mois/année
  try {
    final timeOffList = staff.timeOff;

    if (timeOffList != null && timeOffList.isNotEmpty) {
      // Créer les dates de début et fin du mois sélectionné
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      for (var timeOff in timeOffList) {
        final debut = timeOff.debut;
        final fin = timeOff.fin;

        // Vérifier si le congé chevauche le mois sélectionné
        // Un congé est inclus si:
        // - Il commence dans le mois OU
        // - Il se termine dans le mois OU
        // - Il englobe complètement le mois
        final isInMonth = (debut.isBefore(endOfMonth) ||
                debut.isAtSameMomentAs(endOfMonth)) &&
            (fin.isAfter(startOfMonth) || fin.isAtSameMomentAs(startOfMonth));

        if (isInMonth) {
          final motif = timeOff.motif ?? '';
          if (motif.isNotEmpty) {
            // Formater : Motif (date début - date fin)
            final debutStr = DateFormat('dd/MM').format(debut);
            final finStr = DateFormat('dd/MM').format(fin);
            observations.add('$motif ($debutStr-$finStr)');
          }
        }
      }
    }
  } catch (e) {
    print('⚠️ Erreur lecture TimeOff: $e');
  }

  // Si pas de données, retourner vide
  if (observations.isEmpty) {
    return '';
  }

  // Joindre avec un saut de ligne pour afficher chaque congé sur une ligne séparée
  return observations.join('\n');
}

// ========== TABLEAU PERSONNEL PARAMÉDICAL ==========

pw.Widget _buildParamedicalStaffTable(
    List staffs, pw.Font oswald, int month, int year) {
  final paramedical = staffs.where((s) {
    final grade = (s.grade ?? '').toString().toUpperCase();
    return !(grade.contains('MÉDECIN') ||
        grade.contains('MEDECIN') ||
        grade.contains('RHUMATOLOGUE'));
  }).toList();

  // Regrouper par horaire
  final groupe08h16h = paramedical.where((s) {
    final groupe = (s.groupe ?? '').toString().toUpperCase();
    return groupe.contains('08H') && groupe.contains('16H');
  }).toList();

  final groupe08h08h = paramedical.where((s) {
    final groupe = (s.groupe ?? '').toString().toUpperCase();
    return groupe.contains('GARDE') && groupe.contains('12H');
  }).toList();

  final groupe08h12h = paramedical.where((s) {
    final groupe = (s.groupe ?? '').toString().toUpperCase();
    return groupe.contains('08H') &&
        groupe.contains('12H') &&
        !groupe.contains('16H');
  }).toList();

  // Regrouper 08h-08h par équipe
  final groupesEquipe = <String, List<dynamic>>{};
  for (var membre in groupe08h08h) {
    final equipe = (membre.equipe ?? 'Autre').toString().toUpperCase();
    groupesEquipe.putIfAbsent(equipe, () => []).add(membre);
  }

  // Calculer les tailles pour les fusions
  int totalLignes08h08h = 0;
  final ordreGroupes = ['A', 'B', 'C', 'D'];
  for (var equipe in ordreGroupes) {
    if (groupesEquipe.containsKey(equipe)) {
      totalLignes08h08h += 1 + groupesEquipe[equipe]!.length;
    }
  }

  const double rowHeight = 14.0;
  const double headerHeight = 19.0;

  // Fonction helper pour calculer la hauteur d'une ligne selon le nombre d'observations
  double getRowHeight(dynamic staff) {
    final obsText = _getObservationWithTimeOff(staff, month, year);
    if (obsText.isEmpty) return rowHeight;

    // Compter le nombre de lignes (nombre de \n + 1)
    final lineCount = '\n'.allMatches(obsText).length + 1;
    // Arrondir pour éviter les décalages de pixels
    return (rowHeight * lineCount.clamp(1, 4)).roundToDouble();
  }

  // Calculer la hauteur totale de chaque section d'horaire
  double getTotalHeightForGroup(List<dynamic> members) {
    double total = 0;
    for (var member in members) {
      total += getRowHeight(member);
    }
    return total;
  }

  double getTotalHeightFor08h08h(
      Map<String, List<dynamic>> groupes, List<String> ordreGroupes) {
    double total = 0;
    for (var equipe in ordreGroupes) {
      if (groupes.containsKey(equipe)) {
        total += rowHeight; // Ligne titre groupe
        for (var member in groupes[equipe]!) {
          total += getRowHeight(member);
        }
      }
    }
    return total;
  }

  // Construction du tableau avec Row/Column
  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Colonne Horaire
          pw.Column(
            children: [
              _buildMergedCell('Horaire', oswald, 9, 80, headerHeight,
                  bold: true, header: true, fullBorder: true),
              _buildMergedCell('08h-16h', oswald, 9, 80,
                  getTotalHeightForGroup(groupe08h16h),
                  bold: true, fullBorder: true, isHoraireBoundary: true),
              _buildMergedCell('24h', oswald, 9, 80,
                  getTotalHeightFor08h08h(groupesEquipe, ordreGroupes),
                  bold: true, fullBorder: true, isHoraireBoundary: true),
              _buildMergedCell(
                  '12h', oswald, 9, 80, getTotalHeightForGroup(groupe08h12h),
                  bold: true, fullBorder: true, isHoraireBoundary: true),
            ],
          ),
          // Colonnes Nom, Fonction et OBS
          pw.Expanded(
            child: pw.Column(
              children: [
                // En-tête
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: _buildMergedCell(
                          'Nom et Prénom', oswald, 9, null, headerHeight,
                          bold: true, header: true, fullBorder: true),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: _buildMergedCell(
                          'Fonction', oswald, 9, null, headerHeight,
                          bold: true, header: true, fullBorder: true),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: _buildMergedCell(
                          'OBS', oswald, 9, null, headerHeight,
                          bold: true, header: true, fullBorder: true),
                    ),
                  ],
                ),
                // 08h-16h
                if (groupe08h16h.isNotEmpty) ...[
                  ...groupe08h16h.asMap().entries.map((entry) {
                    final index = entry.key;
                    final m = entry.value;
                    final dynamicHeight = getRowHeight(m);
                    return pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: _buildMergedCell((m.nom ?? '').toString(),
                              oswald, 8, null, dynamicHeight,
                              alignLeft: true, isHoraireBoundary: index == 0),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: _buildMergedCell((m.grade ?? '').toString(),
                              oswald, 7.5, null, dynamicHeight,
                              alignLeft: true, isHoraireBoundary: index == 0),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: _buildMergedCell(
                              _getObservationWithTimeOff(m, month, year),
                              oswald,
                              7,
                              null,
                              dynamicHeight,
                              isHoraireBoundary: index == 0),
                        ),
                      ],
                    );
                  }),
                  // Trait de séparation après 08h-16h
                  pw.Container(
                    height: 0,
                    width: double.infinity,
                    color: PdfColors.grey800,
                  ),
                ],
                // 08h-08h avec groupes
                if (groupesEquipe.isNotEmpty) ...[
                  ...ordreGroupes.expand((equipe) {
                    if (!groupesEquipe.containsKey(equipe))
                      return <pw.Widget>[];
                    final membres = groupesEquipe[equipe]!;
                    final isFirstGroup = equipe ==
                        ordreGroupes.firstWhere(
                          (e) => groupesEquipe.containsKey(e),
                          orElse: () => '',
                        );

                    return [
                      // Ligne titre groupe (avec bordure si premier groupe)
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: _buildMergedCell(
                                'Groupe $equipe', oswald, 8.5, null, rowHeight,
                                bold: true,
                                isGroupHeader: true,
                                isHoraireBoundary: isFirstGroup),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: _buildMergedCell(
                                '', oswald, 8, null, rowHeight,
                                isHoraireBoundary: isFirstGroup),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: _buildMergedCell(
                                '', oswald, 7.5, null, rowHeight,
                                isHoraireBoundary: isFirstGroup),
                          ),
                        ],
                      ),
                      // Membres
                      ...membres.map((m) {
                        final dynamicHeight = getRowHeight(m);
                        return pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 3,
                              child: _buildMergedCell((m.nom ?? '').toString(),
                                  oswald, 8, null, dynamicHeight,
                                  alignLeft: true),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: _buildMergedCell(
                                  (m.grade ?? '').toString(),
                                  oswald,
                                  7.5,
                                  null,
                                  dynamicHeight,
                                  alignLeft: true),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: _buildMergedCell(
                                  _getObservationWithTimeOff(m, month, year),
                                  oswald,
                                  7,
                                  null,
                                  dynamicHeight),
                            ),
                          ],
                        );
                      }),
                    ];
                  }),
                  // Trait de séparation après 08h-08h
                  pw.Container(
                    height: 0,
                    width: double.infinity,
                    color: PdfColors.grey800,
                  ),
                ],
                // 08h-12h
                if (groupe08h12h.isNotEmpty) ...[
                  ...groupe08h12h.asMap().entries.map((entry) {
                    final index = entry.key;
                    final m = entry.value;
                    final dynamicHeight = getRowHeight(m);
                    return pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: _buildMergedCell((m.nom ?? '').toString(),
                              oswald, 8, null, dynamicHeight,
                              alignLeft: true, isHoraireBoundary: index == 0),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: _buildMergedCell((m.grade ?? '').toString(),
                              oswald, 7.5, null, dynamicHeight,
                              alignLeft: true, isHoraireBoundary: index == 0),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: _buildMergedCell(
                              _getObservationWithTimeOff(m, month, year),
                              oswald,
                              7,
                              null,
                              dynamicHeight,
                              isHoraireBoundary: index == 0),
                        ),
                      ],
                    );
                  }),
                  // Trait de séparation après 08h-12h
                  pw.Container(
                    height: 1,
                    width: double.infinity,
                    color: PdfColors.black,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

// Helper pour créer une cellule fusionnée
pw.Widget _buildMergedCell(
  String text,
  pw.Font oswald,
  double fontSize,
  double? width,
  double height, {
  bool bold = false,
  bool header = false,
  bool alignLeft = false,
  bool isGroupHeader = false,
  bool fullBorder = false,
  bool isHoraireBoundary = false,
}) {
  final backgroundColor =
      isGroupHeader ? PdfColors.black : (header ? PdfColors.white : null);

  final textColor = isGroupHeader ? PdfColors.white : PdfColors.black;

  // Trait du haut : visible pour header, fullBorder, groupHeader, et première ligne (isHoraireBoundary)
  final borderColorTop =
      (header || fullBorder || isGroupHeader || isHoraireBoundary)
          ? PdfColors.black
          : PdfColors.white;

  // Trait du bas : visible uniquement pour header, fullBorder, et groupHeader
  final borderColorBottom = (header || fullBorder || isGroupHeader)
      ? PdfColors.black
      : PdfColors.white;

  // Alignement vertical : en haut pour les cellules de contenu, centré pour header/horaire
  final verticalAlignment = (header || fullBorder)
      ? pw.Alignment.center
      : (alignLeft ? pw.Alignment.topLeft : pw.Alignment.topCenter);

  return pw.Container(
    width: width,
    height: height.roundToDouble(),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(width: 1, color: PdfColors.grey800),
        right: pw.BorderSide(width: 1, color: PdfColors.grey800),
        top: pw.BorderSide(width: 1, color: borderColorTop),
        bottom: pw.BorderSide(width: 1, color: borderColorBottom),
      ),
      color: backgroundColor,
    ),
    padding: const pw.EdgeInsets.symmetric(horizontal: 3),
    alignment: verticalAlignment,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: oswald,
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor,
      ),
      textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
      maxLines: header ? null : 10,
      overflow: pw.TextOverflow.clip,
    ),
  );
}

// Helper standard pour cellules normales
pw.Widget _buildCell(
  String text,
  pw.Font oswald,
  double fontSize, {
  pw.Alignment alignment = pw.Alignment.center,
  bool bold = false,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    alignment: alignment,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: oswald,
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textAlign: alignment == pw.Alignment.centerLeft
          ? pw.TextAlign.left
          : pw.TextAlign.center,
    ),
  );
}

// ========== FONCTIONS DE SAUVEGARDE ==========

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

/// Retourne le préfixe approprié selon la première lettre du mois
String getMonthPrefix(String monthName) {
  final vowels = ['a', 'e', 'i', 'o', 'u', 'h'];
  final firstLetter = monthName[0].toLowerCase();
  if (vowels.contains(firstLetter)) {
    return "d'"; // apostrophe typographique
  } else {
    return "de ";
  }
}

String _getActivityLabel(
    String? code, TypeActiviteProvider typeActiviteProvider) {
  if (code == null || code.isEmpty) return '';

  // Utiliser la méthode du Provider pour trouver le type
  final type = typeActiviteProvider.getTypeByCode(code);

  // Retourner le libellé ou le code si non trouvé
  return type?.libelle ?? code;
}
