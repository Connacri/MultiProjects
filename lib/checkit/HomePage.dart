import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/checkit/admobHelper.dart';
import 'package:kenzy/checkit/providerF.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;

import '../objectBox/Utils/My_widgets.dart';
import 'AuthProvider.dart';
import 'Models.dart';

class HomePage3 extends StatefulWidget {
  @override
  _HomePage3State createState() => _HomePage3State();
}

class _HomePage3State extends State<HomePage3> {
  final AuthService _authService = AuthService();
  User? _user;
  final numeroController = TextEditingController();
  final motifController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showDetail = true;
  bool _showSignalBtn = true;
  String? numeroRecherche;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  BannerAd? _bannerAd;

  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignalementProviderSupabase>(context, listen: false)
          .chargerSignalements();
    });
    // if (Platform.isAndroid)
    //   BannerAd(
    //     adUnitId: AdHelper.bannerAdUnitId,
    //     request: AdRequest(),
    //     size: AdSize.banner,
    //     listener: BannerAdListener(onAdLoaded: (ad) {
    //       setState(() {
    //         _bannerAd = ad as BannerAd;
    //       });
    //     }, onAdFailedToLoad: (ad, err) {
    //       print('Failure to load _adBanner ${err.message}');
    //       ad.dispose();
    //     }),
    //   )..load();
    // if (Platform.isAndroid)
    //   InterstitialAd.load(
    //       adUnitId: AdHelper.getInterstatitialAdUnitId,
    //       request: AdRequest(),
    //       adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
    //         ad.fullScreenContentCallback = FullScreenContentCallback(
    //             onAdDismissedFullScreenContent: (ad) {});
    //         setState(() {
    //           _interstitialAd = ad;
    //         });
    //       }, onAdFailedToLoad: (err) {
    //         print('Failure to load Interstatitial ad ${err.message}');
    //       }));
    // if (Platform.isAndroid) _interstitialAd?.show();
    _loadBannerAd();
    _loadInterstitialAd();
    _initializeFCM();
  }

  Future<void> _loadBannerAd() async {
    if (!Platform.isAndroid) return;

    await BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Erreur bannière: ${err.message}');
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    ).load();
  }

  Future<void> _loadInterstitialAd() async {
    if (!Platform.isAndroid) return;

    await InterstitialAd.load(
      adUnitId: AdHelper.getInterstatitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _interstitialAd?.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Erreur interstitiel: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Affichez l'annonce dès que l'application se charge
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();

    super.dispose();
  }

  void _initializeFCM() async {
    await _messaging.requestPermission();
    await _messaging.subscribeToTopic('checkit_alerts');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu : ${message.notification?.title}');
      // Gère le message reçu
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Message en arrière-plan : ${message.messageId}');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text('Erreur')),
        content: FittedBox(
            child: Text(
          message,
          textAlign: TextAlign.center,
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String selectedMotif = 'Fraude ou tentative de fraude';

  final List<String> motifs = [
    'Fraude ou tentative de fraude',
    'Comportement abusif ou agressif',
    'Retours excessifs ou abusifs',
    'Non-paiement ou paiements en retard',
    'Violation des conditions d\'utilisation',
    'Vol à l\'étalage',
    'Fausse réclamation ou plainte',
    'Utilisation inappropriée des promotions',
    'Comportement suspect',
    'Non-respect des règles de sécurité',
    'Refus de réception de la commande',
    'Comportement suspect',
    'Retard dans le paiement',
    'Utilisation de moyens de paiement frauduleux',
    'Mauvaise foi lors de la réclamation',
    'Non-respect des conditions de livraison',
    'Abus de retour ou d\'échange',
    'Demande de remboursement injustifiée',
    'Utilisation de documents falsifiés',
    'Non-remise de la marchandise à la bonne personne',
    'Tentative de fraude sur les produits',
    'Modifications fréquentes des informations de commande',
    'Comportement menaçant',
    'Ignorance des consignes de sécurité',
  ];

  void _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SignalementProviderSupabase>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true, // important !
      appBar: AppBar(
        leading: _user != null
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: InkWell(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (ctx) => googleBtn())),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(_user!.photoURL ?? ''),
                    radius: 15, // Important : plus petit pour AppBar
                  ),
                ),
              )
            : IconButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (ctx) => googleBtn())),
                icon: Icon(
                  Icons.account_circle,
                  size: 35,
                ),
              ),
        title: Text(
          _user != null
              ? '${_user!.displayName ?? "Utilisateur"} Check-it'
              : 'Unknow User Check-it',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (_user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
          SizedBox(
            width: 14,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: //const EdgeInsets.all(8.0),
              EdgeInsets.only(
            left: 8,
            right: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            top: 0,
          ),
          child: IntrinsicHeight(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Text(
                      'شكيت'.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ArbFONTS'),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Lottie.asset('assets/lotties/1 (128).json'),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  AnimatedTextField(
                    // fieldKey: _numeroFieldKey,
                    controller: numeroController,
                    labelText: 'Numéro',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    resetOnClear: true,
                    isNumberPhone: true,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  _showSignalBtn
                      ? SizedBox.shrink()
                      : _showDetail
                          ? Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'Motif',
                                        alignLabelWithHint: true,
                                        hintText: 'Entrez un texte long ici...',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        contentPadding: EdgeInsets.all(15),
                                      ),
                                      value: selectedMotif,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedMotif = newValue!;
                                        });
                                      },
                                      items: motifs
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez sélectionner un motif';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDetail = !_showDetail;
                                    });
                                  },
                                  icon: Icon(
                                    _showDetail ? FontAwesomeIcons.plus : null,
                                    size: 17,
                                  ),
                                ),
                                //child: Text(_showDetail ? "Ajouter Motif" : 'Reduire')),
                              ],
                            )
                          : SizedBox.shrink(),
                  _showSignalBtn
                      ? SizedBox.shrink()
                      : _showDetail
                          ? SizedBox.shrink()
                          : Row(
                              children: [
                                Expanded(
                                  child: AnimatedLongTextField(
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
                                  // AnimatedTextField(
                                  //   controller: motifController,
                                  //   labelText: 'Motif',
                                  //   validator: (value) {
                                  //     // if (value == null || value.isEmpty) {
                                  //     //   return 'Veuillez entrer un motif';
                                  //     // }
                                  //     // return null;
                                  //   },
                                  //   isNumberPhone: false,
                                  // ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDetail = !_showDetail;
                                    });
                                  },
                                  icon: Icon(
                                    FontAwesomeIcons.minus,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: _showSignalBtn
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceAround,
                    children: [
                      _showSignalBtn
                          ? SizedBox.shrink()
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                              onPressed: () async {
                                if (_user != null) {
                                  if (_formKey.currentState!.validate()) {
                                    final numero = provider
                                        .normalizeAndValidateAlgerianPhone(
                                            numeroController.text.trim());

                                    if (numero == null) {
                                      _showErrorDialog(
                                          "Le numéro de téléphone est invalide.");
                                      return;
                                    }

                                    // Vérification si le numéro a déjà été signalé par l'utilisateur
                                    final alreadyReported =
                                        await provider.checkIfAlreadyReported(
                                            numero, _user!.uid);

                                    if (alreadyReported) {
                                      _showErrorDialog(
                                          "Vous avez déjà signalé\n0$numero.");
                                      return;
                                    }

                                    final signalement = Signalement(
                                      numero: numero,
                                      signalePar: _user!.uid,
                                      motif: motifController.text.trim(),
                                      gravite: 1,
                                      description: selectedMotif,
                                      date: DateTime.now(),
                                      user: _user!.uid,
                                    );

                                    await provider
                                        .ajouterSignalement(signalement);

                                    // Réinitialiser les champs
                                    numeroController.clear();
                                    motifController.clear();

                                    setState(() {
                                      selectedMotif = motifs.first;
                                      numeroRecherche = numero;
                                      _showSignalBtn = !_showSignalBtn;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Le numéro 0$numero a bien été signalé'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } else {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (ctx) => googleBtn()));
                                }
                              },
                              label: Text("Signaler"),
                              icon: Icon(
                                Icons.add,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                      SizedBox(width: 10),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            //////////////////////////////////////////////////////////////
                            if (_isInterstitialAdReady) {
                              _interstitialAd?.show();
                            } else {
                              print("L'annonce interstitielle n'est pas prête");
                            }
                            //////////////////////////////////////////////////////////////
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
                            setState(() {
                              _showSignalBtn = false;
                            });
                          },
                          label: Text("Rechercher"),
                          icon: Icon(
                            Icons.search,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_bannerAd != null)
                    Container(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class googleBtn extends StatefulWidget {
  @override
  _googleBtnState createState() => _googleBtnState();
}

class _googleBtnState extends State<googleBtn> {
  final AuthService _authService = AuthService();
  User? _user;
  bool isLoading = false;
  List<Map<String, dynamic>> _reportedNumbers = [];
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 10; // Nombre de résultats par page

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _loadReportedNumbers();
    }
  }

  Future<void> _loadReportedNumbers() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

    try {
      final data = await su.Supabase.instance.client
          .from('signalements')
          .select('numero')
          .eq('signalePar', _user!.uid)
          .range(currentPage * pageSize, (currentPage + 1) * pageSize - 1)
          .order('date', ascending: false);

      setState(() {
        _reportedNumbers.addAll(List<Map<String, dynamic>>.from(data));
        hasMore = data.length == pageSize;
        if (hasMore) currentPage++;
      });
    } catch (e) {
      if (e is su.PostgrestException) {
        print('Erreur de pagination: ${e.details}');
      }
      hasMore = false;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteReportedNumber(String numero) async {
    try {
      await su.Supabase.instance.client
          .from('signalements')
          .delete()
          .eq('numero', numero)
          .eq('signalePar', _user!.uid);

      setState(() {
        _reportedNumbers.removeWhere((item) => item['numero'] == numero);
      });
    } catch (e) {
      print('Erreur suppression: ${e.toString()}');
    }
  }

  Future<void> _deleteAllReportedNumbers() async {
    try {
      await su.Supabase.instance.client
          .from('signalements')
          .delete()
          .eq('signalePar', _user!.uid);

      setState(() => _reportedNumbers.clear());
    } catch (e) {
      print('Erreur suppression totale: ${e.toString()}');
    }
  }

  void _handleSignIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();
      setState(() {
        _user = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur d\'authentification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion : $e')),
      );
    }
  }

  void _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-it Profil'),
        actions: [
          if (_user != null)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : _user == null
                ? _buildLoginUI()
                : _buildProfileUI(),
      ),
    );
  }

  Widget _buildLoginUI() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: Lottie.asset('assets/lotties/google.json'),
            ),
            SizedBox(height: 40),
            FittedBox(
              child: Text(
                'Utilisant Ton Compte Google pour ce connecter\net te permettre de signaler des les numéros'
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Oswald'),
              ),
            ),
            SizedBox(height: 10),
            FittedBox(
              child: Text(
                'استخدام حسابك الخاص قوقل لتسجيل الدخول\nحتى تتمكن من الإبلاغ عن الأرقام'
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'ArbFONTS'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4.0,
                  minimumSize: const Size.fromHeight(50)),
              icon: Icon(
                FontAwesomeIcons.google,
                color: Colors.red,
              ),
              label: const Text(
                'Google',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              onPressed: _handleSignIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(_user!.photoURL ?? ''),
          radius: 40,
        ),
        SizedBox(height: 20),
        Text('Connecté en tant que ${_user!.displayName}'),
        SizedBox(height: 20),
        Text('${_user!.email}'),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              onPressed: _handleSignOut,
              label: Text(
                'SignOut',
                overflow: TextOverflow.ellipsis,
              ),
              icon: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(
                  Icons.logout,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary, // Force la couleur
                ),
              )),
        ),
        SizedBox(
          height: 20,
        ),
        _buildReportedNumbersList(),
      ],
    );
  }

  Widget _buildReportedNumbersList() {
    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 500) {
            _loadReportedNumbers();
          }
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _reportedNumbers.length == 0
                  ? SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                        onPressed: () => _deleteAllReportedNumbers(),
                        child: Text(
                          'Delete All',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ),
              Expanded(
                child: ListView.builder(
                  itemCount: _reportedNumbers.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _reportedNumbers.length) {
                      return Center(
                        child: hasMore
                            ? const CircularProgressIndicator()
                            : const Text('Fin des résultats'),
                      );
                    }

                    final reportedNumber = _reportedNumbers[index];
                    print(reportedNumber['date'].toString());
                    return ListTile(
                      title: Text('0${reportedNumber['numero']}'),
                      subtitle: Text(
                        reportedNumber['date'] != null
                            ? _formatDate(reportedNumber['date']!)
                            : 'Date inconnue',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 25,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _deleteReportedNumber(reportedNumber['numero']),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode helper séparée
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Format invalide';
    }
  }
}

void _showSignalementDialog(BuildContext context, String numeroRecherche,
    SignalementProviderSupabase provider) async {
  final nbSignalements = await provider.nombreSignalements(numeroRecherche);

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
                    ? "Utilisateur\n0$numeroRecherche\n"
                    : "Ce numéro de téléphone 0$numeroRecherche a été signalé",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              nbSignalements == 0
                  ? SizedBox.shrink()
                  : SizedBox(
                      height: 10,
                    ),
              nbSignalements == 0
                  ? SizedBox.shrink()
                  : CircleAvatar(
                      child: Text(
                        nbSignalements.toString(),
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                      maxRadius: 30,
                      minRadius: 30,
                      backgroundColor: getColorForSignalements(nbSignalements),
                    ),
              nbSignalements == 0
                  ? SizedBox.shrink()
                  : Text(
                      "Fois",
                    ),
              nbSignalements == 0 ? SizedBox.shrink() : SizedBox(height: 10),
              DangerBarWithAnimation(degree: nbSignalements),
              SizedBox(height: 10),
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
  String getLottieFilePathForDegree(int signalements) {
    if (signalements == 0) {
      return 'assets/lotties/1 (7).json';
    } else if (signalements == 1) {
      return 'assets/lotties/1 (27).json';
    } else if (signalements == 2) {
      return 'assets/lotties/1 (71).json';
    } else if (signalements == 3 || signalements == 4) {
      return 'assets/lotties/1 (124).json';
    } else if (signalements >= 5) {
      return 'assets/lotties/1 (123).json';
    } else {
      return 'assets/lotties/1 (129).json';
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
            fontSize: 18,
            color: getColorForSignalements(widget.degree),
          ),
        ),
      ],
    );
  }
}

// Retourne la couleur associée au degré de gravité
Color getColorForSignalements(int signalements) {
  if (signalements == 0) {
    return Colors.green;
  } else if (signalements == 1) {
    return Colors.lightGreen;
  } else if (signalements == 2) {
    return Colors.blue;
  } else if (signalements == 3 || signalements == 4) {
    return Colors.orange;
  } else if (signalements >= 5) {
    return Colors.red;
  } else {
    return Colors.grey;
  }
}
