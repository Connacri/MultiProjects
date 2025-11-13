import 'dart:io';

import 'package:flutter/material.dart';

enum PdfPageType {
  activiteTableau,
  medecinPlanning,
  medecinListe,
  paramedicalPlanning,
}

class PdfPageOption {
  final PdfPageType type;
  final String title;
  bool includeModificatif;
  String? customText;
  File? customImage;

  PdfPageOption({
    required this.type,
    required this.title,
    this.includeModificatif = false,
    this.customText,
    this.customImage,
  });
}

class PdfOptionsDialog extends StatefulWidget {
  final String monthName;
  final int year;
  final List<File>? availableImages;

  const PdfOptionsDialog({
    Key? key,
    required this.monthName,
    required this.year,
    this.availableImages,
  }) : super(key: key);

  @override
  State<PdfOptionsDialog> createState() => _PdfOptionsDialogState();
}

class _PdfOptionsDialogState extends State<PdfOptionsDialog> {
  final Map<PdfPageType, PdfPageOption> _options = {};
  final TextEditingController _customTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeOptions();
  }

  void _initializeOptions() {
    _options[PdfPageType.activiteTableau] = PdfPageOption(
      type: PdfPageType.activiteTableau,
      title:
          "TABLEAU D'ACTIVITÉ DU MOIS ${widget.monthName.toUpperCase()} ${widget.year}",
    );

    _options[PdfPageType.medecinPlanning] = PdfPageOption(
      type: PdfPageType.medecinPlanning,
      title:
          "Planning des Médecins « Mois ${_getPrefix()}${widget.monthName} ${widget.year} »",
    );

    _options[PdfPageType.medecinListe] = PdfPageOption(
      type: PdfPageType.medecinListe,
      title:
          "La liste du personnel médical du mois ${_getPrefix()}${widget.monthName} ${widget.year}",
    );

    _options[PdfPageType.paramedicalPlanning] = PdfPageOption(
      type: PdfPageType.paramedicalPlanning,
      title:
          "Planning du Personnel Paramédical du Mois ${_getPrefix()}${widget.monthName} ${widget.year}",
    );
  }

  String _getPrefix() {
    final vowels = ['a', 'e', 'i', 'o', 'u', 'h'];
    final firstLetter = widget.monthName[0].toLowerCase();
    return vowels.contains(firstLetter) ? "d'" : "de ";
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text("Options de génération PDF")),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sélectionnez les tableaux à inclure :",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              ..._options.entries.map((entry) => _buildPageOption(entry.value)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text("Annuler"),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.picture_as_pdf, size: 18),
          label: Text("Générer PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final selectedOptions = _options.values
                .where((opt) =>
                    opt.includeModificatif ||
                    opt.customText != null ||
                    opt.customImage != null)
                .toList();

            // Si aucune option n'est sélectionnée, retourner toutes les pages par défaut
            if (selectedOptions.isEmpty) {
              Navigator.of(context).pop(_options.values.toList());
            } else {
              Navigator.of(context).pop(selectedOptions);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPageOption(PdfPageOption option) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          _getShortTitle(option.type),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          option.title,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option Modificatif
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text("Ajouter la mention (Modificatif)"),
                  value: option.includeModificatif,
                  onChanged: (value) {
                    setState(() {
                      option.includeModificatif = value ?? false;
                    });
                  },
                ),

                Divider(),

                // Texte personnalisé
                Text(
                  "Texte personnalisé :",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: option.customText),
                  decoration: InputDecoration(
                    hintText: "Ex: Version révisée, Mise à jour...",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: option.customText != null
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                option.customText = null;
                              });
                            },
                          )
                        : null,
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    setState(() {
                      option.customText =
                          value.trim().isEmpty ? null : value.trim();
                    });
                  },
                ),

                if (widget.availableImages != null &&
                    widget.availableImages!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Divider(),

                  // Sélection d'image
                  Text(
                    "Image personnalisée :",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  _buildImageSelector(option),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector(PdfPageOption option) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.availableImages!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Option "Aucune image"
            return GestureDetector(
              onTap: () {
                setState(() {
                  option.customImage = null;
                });
              },
              child: Container(
                width: 100,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: option.customImage == null
                        ? Colors.blue
                        : Colors.grey[300]!,
                    width: option.customImage == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: option.customImage == null
                      ? Colors.blue.shade50
                      : Colors.grey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block,
                      color: option.customImage == null
                          ? Colors.blue
                          : Colors.grey[400],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Aucune",
                      style: TextStyle(
                        fontSize: 11,
                        color: option.customImage == null
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final image = widget.availableImages![index - 1];
          final isSelected = option.customImage?.path == image.path;

          return GestureDetector(
            onTap: () {
              setState(() {
                option.customImage = image;
              });
            },
            child: Container(
              width: 100,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getShortTitle(PdfPageType type) {
    switch (type) {
      case PdfPageType.activiteTableau:
        return "Tableau d'activité";
      case PdfPageType.medecinPlanning:
        return "Planning médecins";
      case PdfPageType.medecinListe:
        return "Liste personnel médical";
      case PdfPageType.paramedicalPlanning:
        return "Planning paramédical";
    }
  }
}

// Fonction helper pour afficher le dialog
Future<List<PdfPageOption>?> showPdfOptionsDialog(
  BuildContext context, {
  required String monthName,
  required int year,
  List<File>? availableImages,
}) async {
  return await showDialog<List<PdfPageOption>>(
    context: context,
    builder: (context) => PdfOptionsDialog(
      monthName: monthName,
      year: year,
      availableImages: availableImages,
    ),
  );
}
