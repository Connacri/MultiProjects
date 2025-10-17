import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez cette ligne
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;
import 'package:timeago/timeago.dart' as timeago;

import 'Hopital/decentralized/p2p_integration.dart';
import 'firebase_options.dart';
import 'objectBox/MyApp.dart';
import 'objectBox/classeObjectBox.dart';

///gere les gestu
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      };
}

// Future<void> signInAnonymously() async {
//   try {
//     UserCredential userCredential =
//         await FirebaseAuth.instance.signInAnonymously();
//     User? user = userCredential.user;
//     if (user != null) {
//       print('Utilisateur anonyme connecté avec l\'ID : ${user.uid}');
//     }
//   } on FirebaseAuthException catch (e) {
//     print('Erreur lors de la connexion anonyme : ${e.code}');
//   }
// }
// const apiKey = "AIzaSyCUqIwqieBQxsqzXnWKISJSw52XLbJxWKk";
// const projectId = "walletdz-d12e0";
//late ObjectBox objectbox;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  MobileAds.instance.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeSupabase();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  initializeDateFormatting(
      'fr_FR', null); // Initialisez la localisation française
  if (Platform.isAndroid || Platform.isIOS) {
    MobileAds.instance.initialize();
  } else {
    print("Google Mobile Ads n'est pas supporté sur cette plateforme");
  }

  // SplashMaster.initialize();
  // Future.delayed(const Duration(seconds: 2)).then(
  //   (value) {
  //     SplashMaster.resume();
  //   },
  // );
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());

  await ObjectBox().init();
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  runApp(MyApp()
      //P2PAdminDashboard(),
      );
  // ⚡ Initialiser P2P EN ARRIÈRE-PLAN (non-bloquant)
  _initializeP2PAsync();
}

/// ⚡ Initialisation P2P asynchrone (ne bloque pas l'UI)
Future<void> _initializeP2PAsync() async {
  try {
    print('🔄 Initialisation P2P en arrière-plan...');

    // Timeout pour éviter les blocages
    await P2PIntegration.initializeP2PSystem().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ Timeout P2P - Mode dégradé');
      },
    );

    // Démarrer la découverte
    P2PIntegration.startDiscovery();

    print('✅ P2P initialisé avec succès');
  } catch (e) {
    print('⚠️ Erreur P2P (mode dégradé): $e');
    // L'app continue de fonctionner sans P2P
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Message reçu en arrière-plan: ${message.messageId}");
}

Future<void> initializeSupabase() async {
  const supabaseUrl = 'https://zjbnzghyhdhlivpokstz.supabase.co';
  const supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqYm56Z2h5aGRobGl2cG9rc3R6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2ODA1MjcsImV4cCI6MjA1NDI1NjUyN30.99PBeSXyoFJQMFopizHfLDlqLrMunSBLlBfTGcLIpv8';

  try {
    // await su.Supabase.initialize(
    //   url: supabaseUrl,
    //   anonKey: supabaseKey,
    //   //debug: true,
    // );
    await su.Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: const su.FlutterAuthClientOptions(
        authFlowType: su.AuthFlowType.pkce,
      ),
      realtimeClientOptions: const su.RealtimeClientOptions(
        logLevel: su.RealtimeLogLevel.info,
      ),
      storageOptions: const su.StorageClientOptions(
        retryAttempts: 10,
      ),
    );
    if (su.Supabase.instance == null) {
      print('Supabase initialization failed.');
      return;
    }

    print('Supabase initialized successfully.');
  } catch (error) {
    //  print('Error initializing Supabase: $error');
  }
}

// Future<void> clearFirestoreCache() async {
//   try {
//     await FirebaseFirestore.instance.clearPersistence();
//     print("Firestore cache cleared successfully.");
//   } catch (e) {
//     print("Failed to clear Firestore cache: $e");
//   }
// }

// Future<void> initializeApp() async {
//   // Vérifie si la plateforme est Android, iOS ou Web, sinon on sort de la fonction
//   if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
//     print('Plateforme non supportée');
//     return;
//   }
//
//   try {
// //Initialisation de Firebase
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     print('Firebase initialisé avec succès');
//
//     // Configuration de Supabase
//     const String supabaseUrl = 'https://wirxpjoeahuvjoocdnbk.supabase.co';
//     const String supabaseKey =
//         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indpcnhwam9lYWh1dmpvb2NkbmJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTYxNjI0MzAsImV4cCI6MjAzMTczODQzMH0.MQpp7i2TdH3Q5aPEbMq5qvUwbuYpIX8RccW_GH64r1U';
//
//     // Initialisation de Supabase
//     // await Supabase.initialize(
//     //   url: supabaseUrl,
//     //   anonKey: supabaseKey,
//     // );
//     // print('Supabase initialisé avec succès');
//   } catch (e, stacktrace) {
//     // print('❌ ERREUR lors de l\'initialisation: $e');
//     // print('Stack trace: $stacktrace');
//   }
// }

// Future<Database> initsembastDatabase() async {
//   final appDocumentDir = await getApplicationDocumentsDirectory();
//   final dbPath = p.join(appDocumentDir.path, 'my_sembast_database.db');
//   final database = await databaseFactoryIo.openDatabase(dbPath);
//   return database;
// }
//FlutterNativeSplash.remove();

// Future initialization(BuildContext? context) async {
//   Future.delayed(Duration(seconds: 5));
// }

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  MyApp({
    super.key,
    /*required this.objectBox*/
  });

//  final ObjectBox objectBox;
//   static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
//   static FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

  static const String _title = 'DZ Wallet';

  @override
  State<MyApp> createState() => _MyAppState();
}

final globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class _MyAppState extends State<MyApp> {
  bool _isLicenseValidated = false;
  bool _isLicenseDemoValidated = false;

  //final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // initializeDefault();

    _checkLicenseStatus();
  }

  Future<void> _checkLicenseStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Vérifier les deux états dans SharedPreferences
    bool? isLicenseValidated = prefs.getBool('isLicenseValidated');
    bool? isLicenseDemoValidated = prefs.getBool('isLicenseDemoValidated');

    // Mettre à jour l'état en fonction des valeurs récupérées
    if (isLicenseValidated != null && isLicenseValidated) {
      setState(() {
        _isLicenseValidated = true;
      });
    } else if (isLicenseDemoValidated != null && isLicenseDemoValidated) {
      setState(() {
        _isLicenseDemoValidated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: globalScaffoldMessengerKey,

      scrollBehavior: CustomScrollBehavior(),
      // Applique le nouveau ScrollBehavior
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'OSWALD',
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.black87, // fond foncé
          labelStyle: const TextStyle(color: Colors.white), // texte clair
          shape: StadiumBorder(), // arrondi moderne
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ),
      locale: const Locale('fr', 'CA'),

      //scaffoldMessengerKey: Utils.messengerKey,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ramzi',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white, // fond clair
          labelStyle: const TextStyle(color: Colors.black87), // texte foncé
          shape: StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ),
      home: //LicenseCheckScreen(),
          // Platform.isAndroid || Platform.isIOS
          //     ?.
          MyMain(),
      //     SplashMaster.lottie(
      //   source: AssetSource('assets/lotties/1 (104).json'),
      //   lottieConfig: LottieConfig(
      //     fit: BoxFit.contain,
      //     // conserve le ratio original
      //     overrideBoxFit: false,
      //     // empêche SplashMaster de forcer le BoxFit
      //     alignment: Alignment.center,
      //     //centre l’animation
      //     repeat: true,
      //     // si tu veux que ça boucle
      //     animate: true,
      //     // démarre automatiquement
      //     filterQuality: FilterQuality.high,
      //     // meilleure qualité d’affichage
      //     visibilityEnum: VisibilityEnum.none,
      //   ),
      //   nextScreen: MyMain(),
      // ),

      //     : _isLicenseValidated || _isLicenseDemoValidated
      //         ? MyMain()
      //         : hashPage()
    );
  }
}
