import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kenzy/checkit/provider.dart';
import 'package:kenzy/checkit/providerF.dart';
import 'package:lottie/lottie.dart';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Lottie.asset('assets/lotties/1 (29).json'),
                ),
                SizedBox(
                  height: 20,
                ),
                AnimatedTextField(
                  // fieldKey: _numeroFieldKey,
                  controller: numeroController,
                  labelText: 'Numéro',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  validator: (value) {
                    // if (value == null || value.isEmpty) {
                    //   return 'Veuillez entrer un numéro';
                    // }
                    // if (!provider.isValidAlgerianPhoneNumber(value!)) {
                    //   return 'Entrer un Numéro de téléphone invalide';
                    // }
                    // return null;
                  },
                  resetOnClear: true,
                  isNumberPhone: true,
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
                  isNumberPhone: false,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('le Numéro 0$numero a bien été signalé'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      child: Text("Ajouter"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          numeroRecherche = null;
                        });
                        final numero =
                            provider.normalizeAndValidateAlgerianPhone(
                                numeroController.text.trim());

                        if (numero == null) {
                          _showErrorDialog(
                              "Le numéro de téléphone est invalide.");
                          return;
                        }

                        setState(() {
                          numeroRecherche = numero;
                        });
                        _showSignalementDialog(
                            context, numeroRecherche!, provider);
                      },
                      child: Text("Rechercher"),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // if (numeroRecherche != null) ...[
                //   Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       SizedBox(
                //         width: 100,
                //         height: 100,
                //         child: ClipRRect(
                //           borderRadius: BorderRadius.circular(10),
                //           child: provider.getLogoOperateur(
                //                           provider.detecterOperateur(
                //                               numeroRecherche!)) ==
                //                       null ||
                //                   provider
                //                       .getLogoOperateur(provider
                //                           .detecterOperateur(numeroRecherche!))
                //                       .isEmpty
                //               ? Container(
                //                   color: Colors.grey[300],
                //                   child: Icon(Icons.image_not_supported,
                //                       color: Colors.grey[600]),
                //                 )
                //               : Image(
                //                   image: provider
                //                           .getLogoOperateur(
                //                               provider.detecterOperateur(
                //                                   numeroRecherche!))
                //                           .startsWith('http')
                //                       ? CachedNetworkImageProvider(
                //                           provider.getLogoOperateur(
                //                               provider.detecterOperateur(
                //                                   numeroRecherche!)),
                //                           errorListener: (error) =>
                //                               debugPrint("Image error"),
                //                         )
                //                       : FileImage(File(
                //                               provider.getLogoOperateur(
                //                                   provider.detecterOperateur(
                //                                       numeroRecherche!))))
                //                           as ImageProvider,
                //                   fit: BoxFit.contain,
                //                 ),
                //         ),
                //       ),
                //       SizedBox(height: 10),
                //       SelectableText(
                //         provider.nombreSignalements(numeroRecherche!) == 0
                //             ? "Ce numéro de téléphone\n0$numeroRecherche\nn'a jamais été signalé"
                //             : "Ce numéro de téléphone 0$numeroRecherche a été signalé ${provider.nombreSignalements(numeroRecherche!)} fois",
                //         textAlign: TextAlign.center,
                //         style: TextStyle(
                //             fontWeight: FontWeight.bold, fontSize: 30),
                //       ),
                //       DangerBarWithAnimation(
                //           degree:
                //               provider.nombreSignalements(numeroRecherche!)),
                //     ],
                //   ),
                //   SizedBox(height: 8),
                //   // Expanded(
                //   //   child: ListView(
                //   //     children:
                //   //         provider.getSignalements(numeroRecherche!).map((s) {
                //   //       String operateur =
                //   //           provider.detecterOperateur(s.numero.toString());
                //   //       String logoOperateur =
                //   //           provider.getLogoOperateur(operateur);
                //   //
                //   //       return ListTile(
                //   //         title:
                //   //             Text("${s.signalePar} - Gravité: ${s.gravite}"),
                //   //         subtitle: Column(
                //   //           mainAxisSize: MainAxisSize.min,
                //   //           crossAxisAlignment: CrossAxisAlignment.start,
                //   //           children: [
                //   //             Flexible(
                //   //               child:
                //   //                   DangerBarWithAnimation(degree: s.gravite),
                //   //             ),
                //   //             Text(s.description ?? 'Aucune description'),
                //   //           ],
                //   //         ),
                //   //         trailing: Text(
                //   //           '${s.date.day}/${s.date.month}/${s.date.year}',
                //   //           style: TextStyle(fontSize: 12),
                //   //         ),
                //   //       );
                //   //     }).toList(),
                //   //   ),
                //   // ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignalementDialog(BuildContext context, String numeroRecherche,
      SignalementProviderSupabase provider) {
    final nbSignalements = provider.nombreSignalements(numeroRecherche);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo opérateur
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: provider.getLogoOperateur(provider
                                    .detecterOperateur(numeroRecherche)) ==
                                null ||
                            provider
                                .getLogoOperateur(
                                    provider.detecterOperateur(numeroRecherche))
                                .isEmpty
                        ? Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey[600]),
                          )
                        : Image(
                            image: provider
                                    .getLogoOperateur(provider
                                        .detecterOperateur(numeroRecherche))
                                    .startsWith('http')
                                ? CachedNetworkImageProvider(
                                    provider.getLogoOperateur(provider
                                        .detecterOperateur(numeroRecherche)),
                                    errorListener: (error) =>
                                        debugPrint("Image error"),
                                  )
                                : FileImage(File(provider.getLogoOperateur(
                                    provider.detecterOperateur(
                                        numeroRecherche)))) as ImageProvider,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                SizedBox(height: 10),

                // Texte signalement
                SelectableText(
                  nbSignalements == 0
                      ? "Ce numéro de téléphone\n0$numeroRecherche\nn'a jamais été signalé"
                      : "Ce numéro de téléphone 0$numeroRecherche a été signalé $nbSignalements fois",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                SizedBox(height: 10),

                // Barre de danger animée
                DangerBarWithAnimation(degree: nbSignalements),

                SizedBox(height: 10),

                // // Détails des signalements (optionnel)
                // if (nbSignalements > 0)
                //   ...provider.getSignalements(numeroRecherche).map((s) {
                //     String operateur =
                //         provider.detecterOperateur(s.numero.toString());
                //     return ListTile(
                //       title: Text("${s.signalePar} :${s.gravite}"),
                //       subtitle: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(s.description ?? 'Aucune description'),
                //           Text(
                //             '${s.date.day}/${s.date.month}/${s.date.year}',
                //             style: TextStyle(fontSize: 12),
                //           ),
                //         ],
                //       ),
                //       trailing: Text("${s.gravite}"),
                //     );
                //   }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Fermer"),
            ),
          ],
        );
      },
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

  // Retourne la couleur associée au degré de gravité
  Color getColorForSignalements(int signalements) {
    if (signalements == 0) {
      return Colors.green;
    } else if (signalements == 1) {
      return Colors.lightGreen;
    } else if (signalements == 2) {
      return Colors.yellow;
    } else if (signalements == 3 || signalements == 4) {
      return Colors.orange;
    } else if (signalements >= 5) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  // Retourne le texte associé au degré de gravité

  String getTextForSignalements(int signalements) {
    if (signalements == 0) {
      return 'Ce numéro n\'a jamais été signalé.';
    } else if (signalements == 1) {
      return 'Ce numéro présente un risque modéré.';
    } else if (signalements == 2) {
      return 'Ce numéro présente un risque moyen.';
    } else if (signalements == 3 || signalements == 4) {
      return 'Ce numéro présente un risque élevé.';
    } else if (signalements >= 5) {
      return 'Ce numéro présente un risque très élevé.';
    } else {
      return 'État de signalement inconnu.';
    }
  }

  // Retourne le chemin du fichier Lottie associé au degré de gravité
  String getLottieFilePathForDegree(int degree) {
    switch (degree) {
      case 1:
        return 'assets/lotties/1 (119).json';
      case 2:
        return 'assets/lotties/1 (120).json';
      case 3:
        return 'assets/lotties/1 (118).json';
      case 4:
        return 'assets/lotties/1 (122).json';
      case 5:
        return 'assets/lotties/1 (123).json';
      default:
        return 'assets/lotties/1 (12).json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Lottie.asset(getLottieFilePathForDegree(widget.degree)),
        ),
        SelectableText(
          getTextForSignalements(widget.degree),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: getColorForSignalements(widget.degree),
          ),
        ),
      ],
    );
  }
}
