import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kenzy/checkit/provider.dart';
import 'package:kenzy/checkit/providerF.dart';
import 'package:provider/provider.dart';

import '../objectBox/Utils/My_widgets.dart';

class SignalementHomePageSupabase extends StatefulWidget {
  @override
  State<SignalementHomePageSupabase> createState() =>
      _SignalementHomePageSupabaseState();
}

class _SignalementHomePageSupabaseState
    extends State<SignalementHomePageSupabase> {
  final numeroController = TextEditingController();
  final motifController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  //final _numeroFieldKey = GlobalKey<FormFieldState>();
  String? numeroRecherche;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProviderSupabase>(context, listen: false)
          .chargerSignalements();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SignalementProviderSupabase>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Numéros signalés')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedTextField(
                // fieldKey: _numeroFieldKey,
                controller: numeroController,
                labelText: 'Numéro',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  if (!provider.isValidAlgerianPhoneNumber(value)) {
                    return 'Numéro de téléphone invalide';
                  }
                  return null;
                },
                resetOnClear: true,
              ),
              AnimatedTextField(
                controller: motifController,
                labelText: 'Motif',
                validator: (value) {
                  // if (value == null || value.isEmpty) {
                  //   return 'Veuillez entrer un motif';
                  // }
                  // return null;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final numero =
                            provider.normalizeAndValidateAlgerianPhone(
                                numeroController.text.trim());

                        if (numero == null) {
                          _showErrorDialog(
                              "Le numéro de téléphone est invalide.");
                          return;
                        }

                        final signalement = Signalement(
                          numero: numero,
                          signalePar: 'Utilisateur',
                          motif: motifController.text.trim(),
                          gravite: 1,
                          description: '',
                          date: DateTime.now(),
                        );

                        await provider.ajouterSignalement(signalement);

                        // Réinitialiser les champs
                        numeroController.clear();
                        motifController.clear();
                        //  _numeroFieldKey.currentState?.reset();

                        // Réinitialiser l'icône en appelant resetIcon()
                        // (Vous pouvez soit appeler directement resetIcon() ici, soit gérer cela via un listener)
                        // Par exemple, si AnimatedTextField expose une méthode resetIcon :
                        // animatedTextFieldKey.currentState?.resetIcon();

                        setState(() {
                          numeroRecherche = numero;
                        });
                      }
                    },
                    child: Text("Ajouter"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final numero = provider.normalizeAndValidateAlgerianPhone(
                          numeroController.text.trim());

                      if (numero == null) {
                        _showErrorDialog(
                            "Le numéro de téléphone est invalide.");
                        return;
                      }

                      setState(() {
                        numeroRecherche = numero;
                      });
                    },
                    child: Text("Rechercher"),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (numeroRecherche != null) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: provider.getLogoOperateur(provider
                                        .detecterOperateur(numeroRecherche!)) ==
                                    null ||
                                provider
                                    .getLogoOperateur(provider
                                        .detecterOperateur(numeroRecherche!))
                                    .isEmpty
                            ? Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey[600]),
                              )
                            : Image(
                                image: provider
                                        .getLogoOperateur(
                                            provider.detecterOperateur(
                                                numeroRecherche!))
                                        .startsWith('http')
                                    ? CachedNetworkImageProvider(
                                        provider.getLogoOperateur(
                                            provider.detecterOperateur(
                                                numeroRecherche!)),
                                        errorListener: (error) =>
                                            debugPrint("Image error"),
                                      )
                                    : FileImage(File(provider.getLogoOperateur(
                                            provider.detecterOperateur(
                                                numeroRecherche!))))
                                        as ImageProvider,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    provider.nombreSignalements(numeroRecherche!) == 0
                        ? Text(
                            "Ce numéro de téléphone 0$numeroRecherche n'a jamais été signalé",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        : Text(
                            "Ce numéro de téléphone 0$numeroRecherche a été signalé ${provider.nombreSignalements(numeroRecherche!)} fois",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                    DangerBarWithAnimation(
                        degree: provider.nombreSignalements(numeroRecherche!)),
                  ],
                ),
                SizedBox(height: 8),
                // Expanded(
                //   child: ListView(
                //     children:
                //         provider.getSignalements(numeroRecherche!).map((s) {
                //       String operateur =
                //           provider.detecterOperateur(s.numero.toString());
                //       String logoOperateur =
                //           provider.getLogoOperateur(operateur);
                //
                //       return ListTile(
                //         title: Text("${s.signalePar} - Gravité: ${s.gravite}"),
                //         subtitle: Column(
                //           mainAxisSize: MainAxisSize.min,
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Flexible(
                //               child: DangerBarWithAnimation(degree: s.gravite),
                //             ),
                //             Text(s.description ?? 'Aucune description'),
                //           ],
                //         ),
                //         trailing: Text(
                //           '${s.date.day}/${s.date.month}/${s.date.year}',
                //           style: TextStyle(fontSize: 12),
                //         ),
                //       );
                //     }).toList(),
                //   ),
                // ),
              ],
            ],
          ),
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
        return Colors.yellow;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.black;
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
