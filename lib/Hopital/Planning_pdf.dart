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

/// Génère les pages 2 et 3 du planning (listes du personnel)
Future<String?> generatePersonnelListsPDF(
  BuildContext context, {
  required int year,
  required int month,
}) async {
  final staffProvider = Provider.of<StaffProvider>(context, listen: false);
  await staffProvider.fetchStaffs();
  final staffs = staffProvider.staffs ?? [];

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

  // Filtrer les médecins
  final medecins = staffs.where((s) {
    final grade = (s.grade ?? '').toString().toUpperCase();
    return grade.contains('MÉDECIN') ||
        grade.contains('MEDECIN') ||
        grade.contains('RHUMATOLOGUE');
  }).toList();

  // ========== PAGE 2 : PLANNING HEBDOMADAIRE DES MÉDECINS ==========
  if (medecins.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logo, bold, baseStyle),
            pw.SizedBox(height: 25),
            pw.Center(
              child: pw.Text(
                'Planning des Médecins « Mois D\'${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year »',
                style: bold.copyWith(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text('DE 8H À 16H', style: bold.copyWith(fontSize: 11)),
            ),
            pw.SizedBox(height: 20),
            _buildWeeklyScheduleTable(medecins, oswald),
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
          _buildHeader(logo, bold, baseStyle),
          pw.SizedBox(height: 20),

          // SECTION 1 : Personnel Médical
          pw.Text(
            'La liste du personnel médical du mois d\'${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year',
            style: bold.copyWith(fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text('DE 8H À 16H', style: bold.copyWith(fontSize: 10)),
          ),
          pw.SizedBox(height: 10),
          _buildMedicalStaffTable(medecins, oswald),

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
          _buildHeader(logo, bold, baseStyle),
          pw.SizedBox(height: 20),

          // SECTION 2 : Personnel Paramédical
          pw.Text(
            'Planning du Personnel Paramédical du Mois D\' ${monthName.substring(0, 1).toUpperCase()}${monthName.substring(1)} $year',
            style: bold.copyWith(fontSize: 11),
          ),
          pw.SizedBox(height: 10),
          _buildParamedicalStaffTable(staffs, oswald),

          pw.Spacer(),
          _buildFooter(baseStyle),
        ],
      ),
    ),
  );

  // Sauvegarde
  try {
    final pdfBytes = await pdf.save();
    final fileName = 'Liste_Personnel_${monthName}_$year.pdf';
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
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 45,
        height: 45,
        margin: const pw.EdgeInsets.only(right: 8),
        child: pw.Image(logo, fit: pw.BoxFit.contain),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
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
          pw.Text('Unité : Service de Rhumatologie', style: baseStyle),
        ],
      ),
    ],
  );
}

pw.Widget _buildFooter(pw.TextStyle baseStyle) {
  return pw.Column(
    children: [
      pw.Text(
        'fait à Aïn el Türck le : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        style: baseStyle,
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
    ],
  );
}

// ========== TABLEAU HEBDOMADAIRE DES MÉDECINS ==========

pw.Widget _buildWeeklyScheduleTable(List medecins, pw.Font oswald) {
  final headers = [
    'Nom et Prénom',
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi'
  ];

  // Mapping des activités hebdomadaires réelles
  final Map<String, Map<String, String>> activitesHebdo = {
    'Medjadi Mohsine': {
      'Dimanche': 'Service Biothérapie',
      'Lundi': 'DMO',
      'Mardi': 'Visite Générale',
      'Mercredi': 'Consultation\nE.P.S.P Ben Smir',
      'Jeudi': 'Journée Pédagogique',
    },
    'Ouadah Souad': {
      'Dimanche': 'Journée Pédagogique',
      'Lundi': 'Consultation\nE.P.S.P Mers El Kebir',
      'Mardi': 'Visite Générale',
      'Mercredi': 'DMO',
      'Jeudi': 'Service Biothérapie',
    },
    'Bouziane Kheira': {
      'Dimanche': 'Consultation\nE.P.S.P Ben Smir',
      'Lundi': 'Journée Pédagogique',
      'Mardi': 'Visite Générale',
      'Mercredi': 'Service',
      'Jeudi': 'DMO',
    },
    'Tlemsani Naziha': {
      'Dimanche': 'Service',
      'Lundi': 'Service',
      'Mardi': 'Consultation\nE.P.S.P Ben Smir',
      'Mercredi': 'Service',
      'Jeudi': 'Service',
    },
    'Boumazouzi.Hind': {
      'Dimanche': 'Service',
      'Lundi': 'Service',
      'Mardi': 'Visite Générale',
      'Mercredi': 'Service',
      'Jeudi': 'Consultation\nE.P.S.P Ben Smir',
    },
  };

  final rows = <pw.TableRow>[];

  // En-tête
  rows.add(
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: headers
          .map((h) => pw.Container(
                padding: const pw.EdgeInsets.all(6),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                      font: oswald,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ))
          .toList(),
    ),
  );

  // Lignes de données
  for (var medecin in medecins) {
    final nom = (medecin.nom ?? '').toString();
    final activites = activitesHebdo[nom] ?? {};

    rows.add(
      pw.TableRow(
        children: [
          _buildCell(nom, oswald, 9, alignment: pw.Alignment.centerLeft),
          _buildCell(activites['Dimanche'] ?? '', oswald, 8),
          _buildCell(activites['Lundi'] ?? '', oswald, 8),
          _buildCell(activites['Mardi'] ?? '', oswald, 8),
          _buildCell(activites['Mercredi'] ?? '', oswald, 8),
          _buildCell(activites['Jeudi'] ?? '', oswald, 8),
        ],
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey800),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.5),
      1: pw.FlexColumnWidth(1.8),
      2: pw.FlexColumnWidth(1.8),
      3: pw.FlexColumnWidth(1.8),
      4: pw.FlexColumnWidth(1.8),
      5: pw.FlexColumnWidth(1.8),
    },
    children: rows,
  );
}

// ========== TABLEAU PERSONNEL MÉDICAL ==========

pw.Widget _buildMedicalStaffTable(List medecins, pw.Font oswald) {
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
          _buildCell('8h 16h', oswald, 9),
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

// Fonction pour récupérer les observations d'un staff avec OBS et TimeOff
String _getObservationWithTimeOff(dynamic staff) {
  final List<String> observations = [];

  // Récupérer OBS si existe
  final obs = staff.obs ?? '';
  if (obs.isNotEmpty) {
    observations.add(obs);
  }

  // Récupérer TimeOff si existe (c'est une relation ToMany<TimeOff>)
  try {
    // Accéder directement à la collection timeOff
    final timeOffList = staff.timeOff;

    if (timeOffList != null && timeOffList.isNotEmpty) {
      // Pour chaque congé, récupérer le motif avec les dates
      for (var timeOff in timeOffList) {
        final motif = timeOff.motif ?? '';
        if (motif.isNotEmpty) {
          // Formater : Motif (date début - date fin)
          final debut = DateFormat('dd/MM').format(timeOff.debut);
          final fin = DateFormat('dd/MM').format(timeOff.fin);
          observations.add('$motif ($debut-$fin)');
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

pw.Widget _buildParamedicalStaffTable(List staffs, pw.Font oswald) {
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

  const double rowHeight = 16.0;
  const double headerHeight = 22.0;

  // Fonction helper pour calculer la hauteur d'une ligne selon le nombre d'observations
  double getRowHeight(dynamic staff) {
    final obsText = _getObservationWithTimeOff(staff);
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
    return total.roundToDouble();
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
    return total.roundToDouble();
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
              _buildMergedCell('08h-08h', oswald, 9, 80,
                  getTotalHeightFor08h08h(groupesEquipe, ordreGroupes),
                  bold: true, fullBorder: true, isHoraireBoundary: true),
              _buildMergedCell('08h-12h', oswald, 9, 80,
                  getTotalHeightForGroup(groupe08h12h),
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
                          child: _buildMergedCell(_getObservationWithTimeOff(m),
                              oswald, 7, null, dynamicHeight,
                              isHoraireBoundary: index == 0),
                        ),
                      ],
                    );
                  }),
                  // Trait de séparation après 08h-16h
                  pw.Container(
                    height: 0.5,
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
                                  _getObservationWithTimeOff(m),
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
                    height: 0.5,
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
                          child: _buildMergedCell(_getObservationWithTimeOff(m),
                              oswald, 7, null, dynamicHeight,
                              isHoraireBoundary: index == 0),
                        ),
                      ],
                    );
                  }),
                  // Trait de séparation après 08h-12h (optionnel si c'est le dernier groupe)
                  pw.Container(
                    height: 0.5,
                    width: double.infinity,
                    color: PdfColors.grey800,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      // Ligne de fermeture finale en bas du tableau (supprimée car déjà gérée)
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
      isGroupHeader ? PdfColors.black : (header ? PdfColors.grey300 : null);

  final textColor = isGroupHeader ? PdfColors.white : PdfColors.black;

  // Trait du haut : visible pour header, fullBorder, groupHeader, et première ligne (isHoraireBoundary)
  final borderColorTop =
      (header || fullBorder || isGroupHeader || isHoraireBoundary)
          ? PdfColors.grey800
          : PdfColors.white;

  // Trait du bas : visible uniquement pour header, fullBorder, et groupHeader
  // MAIS PAS pour isHoraireBoundary (première ligne de section)
  final borderColorBottom = (header || fullBorder || isGroupHeader)
      ? PdfColors.grey800
      : PdfColors.white;

  // Alignement vertical : en haut pour les cellules de contenu, centré pour header/horaire
  final verticalAlignment = (header || fullBorder)
      ? pw.Alignment.center
      : (alignLeft ? pw.Alignment.topLeft : pw.Alignment.topCenter);

  return pw.Container(
    width: width,
    height: height.roundToDouble(),
    // Arrondir pour éviter les décalages
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(width: 0.5, color: PdfColors.grey800),
        right: pw.BorderSide(width: 0.5, color: PdfColors.grey800),
        top: pw.BorderSide(width: 0.5, color: borderColorTop),
        bottom: pw.BorderSide(width: 0.5, color: borderColorBottom),
      ),
      color: backgroundColor,
    ),
    padding: const pw.EdgeInsets.all(3),
    // Padding uniforme pour éviter les décalages
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
      maxLines: header ? null : 10, // Augmenté pour permettre plus de lignes
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
