import 'package:flutter/material.dart';

enum PdfPageType {
  // ✅ 4 types distincts
  activiteTableauMedical,
  activiteTableauAdministratif,
  activiteTableauParamedical,
  activiteTableauHygiene,
  // Pages de personnel
  medecinPlanning,
  medecinListe,
  paramedicalPlanning,
}

class PdfPageOption {
  final PdfPageType type;
  final String title;
  bool includeModificatif; // ⭐ Changé en non-final pour pouvoir modifier
  String? customText; // ⭐ Changé en non-final
  String? selectedImagePath; // ⭐ CHANGÉ de File à String
  String? customNotes; // ⭐ AJOUT

  PdfPageOption({
    required this.type,
    required this.title,
    this.includeModificatif = false,
    this.customText,
    this.selectedImagePath, // ⭐ CHANGÉ
    this.customNotes, // ⭐ AJOUT
  });
}

class PdfOptionsDialog extends StatefulWidget {
  final String monthName;
  final int year;
  final List<String>?
      availableImagePaths; // ⭐ CHANGÉ de List<File> à List<String>

  const PdfOptionsDialog({
    Key? key,
    required this.monthName,
    required this.year,
    this.availableImagePaths, // ⭐ CHANGÉ
  }) : super(key: key);

  @override
  State<PdfOptionsDialog> createState() => _PdfOptionsDialogState();
}

class _PdfOptionsDialogState extends State<PdfOptionsDialog> {
  final Map<PdfPageType, PdfPageOption> _options = {};

  @override
  void initState() {
    super.initState();
    _initializeOptions();
  }

  void _initializeOptions() {
    _options[PdfPageType.activiteTableauMedical] = PdfPageOption(
      type: PdfPageType.activiteTableauMedical,
      title: "TABLEAU D'ACTIVITÉ - Personnel Médical",
    );

    _options[PdfPageType.activiteTableauAdministratif] = PdfPageOption(
      type: PdfPageType.activiteTableauAdministratif,
      title: "TABLEAU D'ACTIVITÉ - Personnel Administratif",
    );

    _options[PdfPageType.activiteTableauParamedical] = PdfPageOption(
      type: PdfPageType.activiteTableauParamedical,
      title: "TABLEAU D'ACTIVITÉ - Personnel Paramédical",
    );

    _options[PdfPageType.activiteTableauHygiene] = PdfPageOption(
      type: PdfPageType.activiteTableauHygiene,
      title: "TABLEAU D'ACTIVITÉ - Agents d'Hygiène",
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
                    opt.selectedImagePath != null || // ⭐ CHANGÉ de customImage
                    opt.customNotes != null) // ⭐ AJOUTÉ
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

                // ⭐ AJOUT : Champ de notes NB
                SizedBox(height: 12),
                Divider(),
                Text(
                  "Note NB (affichée en bas du tableau) :",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: option.customNotes),
                  decoration: InputDecoration(
                    hintText: "Ex: NB : Planning modifié le 15/01/2025",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_add, size: 20),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: option.customNotes != null
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                option.customNotes = null;
                              });
                            },
                          )
                        : null,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setState(() {
                      option.customNotes =
                          value.trim().isEmpty ? null : value.trim();
                    });
                  },
                ),

                // ⭐ MODIFIÉ : Sélection d'image avec chemins d'assets
                if (widget.availableImagePaths != null &&
                    widget.availableImagePaths!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Divider(),
                  Text(
                    "Image personnalisée (tampon/signature) :",
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

  // ⭐ MODIFIÉ : Sélecteur d'images avec chemins d'assets
  Widget _buildImageSelector(PdfPageOption option) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.availableImagePaths!.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Option "Aucune image"
            return GestureDetector(
              onTap: () {
                setState(() {
                  option.selectedImagePath = null;
                });
              },
              child: Container(
                width: 100,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: option.selectedImagePath == null
                        ? Colors.blue
                        : Colors.grey[300]!,
                    width: option.selectedImagePath == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: option.selectedImagePath == null
                      ? Colors.blue.shade50
                      : Colors.grey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block,
                      color: option.selectedImagePath == null
                          ? Colors.blue
                          : Colors.grey[400],
                      size: 32,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Aucune",
                      style: TextStyle(
                        fontSize: 11,
                        color: option.selectedImagePath == null
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final imagePath = widget.availableImagePaths![index - 1];
          final isSelected = option.selectedImagePath == imagePath;

          return GestureDetector(
            onTap: () {
              setState(() {
                option.selectedImagePath = imagePath;
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
                child: Image.asset(
                  imagePath, // ⭐ CHANGÉ : Image.asset au lieu de Image.file
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Erreur',
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
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
      case PdfPageType.activiteTableauMedical:
        return "Tableau d'activité Médical";
      case PdfPageType.activiteTableauAdministratif:
        return "Tableau d'activité Administratif";
      case PdfPageType.activiteTableauParamedical:
        return "Tableau d'activité Paramédical";
      case PdfPageType.activiteTableauHygiene:
        return "Tableau d'activité Hygiène";
      case PdfPageType.medecinPlanning:
        return "Planning médecins";
      case PdfPageType.medecinListe:
        return "Liste personnel médical";
      case PdfPageType.paramedicalPlanning:
        return "Planning paramédical";
    }
  }
}

// ⭐ MODIFIÉ : Fonction helper avec chemins d'assets
Future<List<PdfPageOption>?> showPdfOptionsDialog(
  BuildContext context, {
  required String monthName,
  required int year,
  List<String>? availableImagePaths, // ⭐ CHANGÉ
}) async {
  return await showDialog<List<PdfPageOption>>(
    context: context,
    builder: (context) => PdfOptionsDialog(
      monthName: monthName,
      year: year,
      availableImagePaths: availableImagePaths, // ⭐ CHANGÉ
    ),
  );
}
