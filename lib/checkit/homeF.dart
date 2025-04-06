import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kenzy/checkit/provider.dart';
import 'package:kenzy/checkit/providerF.dart';
import 'package:provider/provider.dart';

class SignalementHomePageSupabase extends StatefulWidget {
  @override
  State<SignalementHomePageSupabase> createState() =>
      _SignalementHomePageSupabaseState();
}

class _SignalementHomePageSupabaseState
    extends State<SignalementHomePageSupabase> {
  final numeroController = TextEditingController();
  final utilisateurController = TextEditingController();
  final descriptionController = TextEditingController();
  final motifController = TextEditingController();
  final graviteController = TextEditingController();

  String? numeroRecherche;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProviderSupabase>(context, listen: false)
          .chargerSignalements();
    });
  }

  String _normaliserNumero(String numero) {
    numero = numero.replaceAll(RegExp(r'\s+'), '');
    if (numero.startsWith('+213')) {
      return '0${numero.substring(4)}';
    } else if (numero.startsWith('213')) {
      return '0${numero.substring(3)}';
    }
    return numero;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SignalementProviderSupabase>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Numéros signalés')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: numeroController,
              decoration: InputDecoration(labelText: 'Numéro'),
              keyboardType: TextInputType.phone,
            ),
            // TextField(
            //   controller: utilisateurController,
            //   decoration: InputDecoration(labelText: 'Nom du signaleur'),
            // ),
            TextField(
              controller: motifController,
              decoration: InputDecoration(labelText: 'Motif'),
            ),
            // TextField(
            //   controller: graviteController,
            //   keyboardType: TextInputType.number,
            //   decoration: InputDecoration(labelText: 'Gravité (1-5)'),
            // ),
            // TextField(
            //   controller: descriptionController,
            //   decoration:
            //       InputDecoration(labelText: 'Description (optionnelle)'),
            // ),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final numero =
                        _normaliserNumero(numeroController.text.trim());

                    if (numero.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Veuillez remplir tous les champs obligatoires"),
                      ));
                      return;
                    }

                    final operateur = provider.detecterOperateur(numero);
                    final logo = provider.getLogoOperateur(operateur);

                    final signalement = Signalement(
                      numero: int.tryParse(numero) ?? 0,
                      signalePar: utilisateurController.text.trim(),
                      motif: motifController.text.trim(),
                      gravite: int.tryParse(graviteController.text.trim()) ?? 1,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      date: DateTime.now(),
                    );

                    await provider.ajouterSignalement(signalement);

                    numeroController.clear();
                    utilisateurController.clear();
                    motifController.clear();
                    graviteController.clear();
                    descriptionController.clear();

                    setState(() {
                      numeroRecherche = numero;
                    });
                  },
                  child: Text("Ajouter"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      numeroRecherche =
                          _normaliserNumero(numeroController.text.trim());
                    });
                  },
                  child: Text("Rechercher"),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (numeroRecherche != null) ...[
              // Obtenir le logo de l'opérateur

              Row(
                children: [
                  SizedBox(
                    width: 100, // Taille fixe pour un carré
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      // Coins arrondis
                      child: provider.getLogoOperateur(provider
                                      .detecterOperateur(numeroRecherche!)) ==
                                  null ||
                              provider
                                  .getLogoOperateur(provider
                                      .detecterOperateur(numeroRecherche!))
                                  .isEmpty
                          ? Container(
                              color: Colors.grey[300],
                              // Couleur de fond si pas d'image
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey[600]),
                            )
                          : Image(
                              image: provider
                                      .getLogoOperateur(provider
                                          .detecterOperateur(numeroRecherche!))
                                      .startsWith('http')
                                  ? CachedNetworkImageProvider(
                                      provider.getLogoOperateur(provider
                                          .detecterOperateur(numeroRecherche!)),
                                      errorListener: (error) =>
                                          debugPrint("Image error"),
                                    )
                                  : FileImage(File(provider.getLogoOperateur(
                                      provider.detecterOperateur(
                                          numeroRecherche!)))) as ImageProvider,
                              fit: BoxFit
                                  .cover, // Remplir tout l'espace disponible
                            ),
                    ),
                  ),
                  Text(
                    "Signalements pour $numeroRecherche : ${provider.nombreSignalements(numeroRecherche!)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: provider.getSignalements(numeroRecherche!).map((s) {
                    // Détecter l'opérateur basé sur le numéro
                    String operateur =
                        provider.detecterOperateur(s.numero.toString());

                    // Obtenir le logo de l'opérateur
                    String logoOperateur = provider.getLogoOperateur(operateur);

                    return ListTile(
                      //leading: CircleAvatar(child: Image.asset(logoOperateur)),
                      title: Text("${s.signalePar} - Gravité: ${s.gravite}"),
                      subtitle: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            // Changed from Expanded
                            child: DangerBarWithAnimation(degree: s.gravite),
                          ),
                          Text('Opérateur : $operateur'),
                          Text(s.description ?? 'Aucune description'),
                        ],
                      ),
                      trailing: Text(
                        '${s.date.day}/${s.date.month}/${s.date.year}',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DangerBarWithAnimation extends StatefulWidget {
  final int degree; // Le degré de gravité entre 1 et 5

  DangerBarWithAnimation({required this.degree});

  @override
  _DangerBarWithAnimationState createState() => _DangerBarWithAnimationState();
}

class _DangerBarWithAnimationState extends State<DangerBarWithAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // On crée une animation qui déplace la flèche en fonction du degré
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    // L'animation qui déplace la flèche
    _animation =
        Tween<double>(begin: 0.0, end: widget.degree.toDouble()).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Lancer l'animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Retourne la couleur et le texte associé au degré de gravité
  Color getColorForDegree(int degree) {
    switch (degree) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.yellow;
      case 5:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String getTextForDegree(int degree) {
    switch (degree) {
      case 1:
        return 'Faible Gravité';
      case 2:
        return 'Modéré';
      case 3:
        return 'Moyenne';
      case 4:
        return 'Elevée';
      case 5:
        return 'Très Elevée';
      default:
        return 'Inconnu';
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          getTextForDegree(widget.degree),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: getColorForDegree(widget.degree),
          ),
        ),
      ],
    );
  }
}
