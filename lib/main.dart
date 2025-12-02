import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as su;
import 'package:timeago/timeago.dart' as timeago;

import 'Hopital/p2p/connection_manager.dart';
import 'Hopital/p2p/delta_generator_real.dart';
import 'Hopital/p2p/messenger/NodesManager.dart';
import 'Hopital/p2p/messenger/messaging_integration.dart';
import 'Hopital/p2p/messenger/messaging_manager.dart';
import 'Hopital/p2p/p2p_integration.dart';
import 'Hopital/p2p/p2p_manager.dart';
import 'firebase_options.dart';
import 'objectBox/MyApp.dart';
import 'objectBox/classeObjectBox.dart';

// ============================================================================
// LOGGING HELPER
// ============================================================================
void logDebug(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] 🔍 DEBUG: $message');
}

void logInfo(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ℹ️  INFO: $message');
}

void logSuccess(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ✅ SUCCESS: $message');
}

void logWarning(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ⚠️  WARNING: $message');
}

void logError(String message, [Object? error, StackTrace? stackTrace]) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ❌ ERROR: $message');
  if (error != null) {
    print('[$timestamp]    └─ Error: $error');
  }
  if (stackTrace != null) {
    print('[$timestamp]    └─ StackTrace:\n$stackTrace');
  }
}

void logStep(String step) {
  print('\n════════════════════════════════════════════════════════════════');
  print('   $step');
  print('════════════════════════════════════════════════════════════════\n');
}

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
late ObjectBox objectBox;
late P2PManager p2pManager;
late P2PIntegration p2pIntegration;
late ConnectionManager connectionManager;
late MessagingManager messagingManager;
late MessagingP2PIntegration messagingP2P;

bool isFirebaseInitialized = false;
bool isFirebaseSupported = false;

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      };
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logInfo('Tentative d\'initialisation Firebase pour message background');
  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp();
      logSuccess('Firebase initialisé pour message background');
      logInfo("Message reçu en arrière-plan: ${message.messageId}");
    } catch (e, stackTrace) {
      logError('Erreur Firebase background handler', e, stackTrace);
    }
  }
}

Future<void> main() async {
  logStep('🚀 DÉMARRAGE DE L\'APPLICATION');

  try {
    // ============================================================================
    // ÉTAPE 1: INITIALISATION DE BASE
    // ============================================================================
    logStep('ÉTAPE 1: Initialisation Flutter Bindings');
    logDebug('Appel WidgetsFlutterBinding.ensureInitialized()');
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    logSuccess('Flutter Bindings initialisé');

    // ============================================================================
    // ÉTAPE 2: DÉTECTION DE LA PLATEFORME
    // ============================================================================
    logStep('ÉTAPE 2: Détection de la plateforme');
    if (kIsWeb) {
      logInfo('Plateforme détectée: WEB');
    } else {
      logInfo('Plateforme détectée: ${Platform.operatingSystem}');
      logInfo('Version: ${Platform.operatingSystemVersion}');
    }

    // ============================================================================
    // ÉTAPE 3: INITIALISATION FIREBASE
    // ============================================================================
    logStep('ÉTAPE 3: Initialisation Firebase');
    await _initializeFirebaseConditionally();

    // ============================================================================
    // ÉTAPE 4: INITIALISATION SUPABASE
    // ============================================================================
    logStep('ÉTAPE 4: Initialisation Supabase');
    await initializeSupabase();

    // ============================================================================
    // ÉTAPE 5: INITIALISATION MOBILE ADS
    // ============================================================================
    logStep('ÉTAPE 5: Initialisation Mobile Ads');
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        logDebug('Tentative d\'initialisation Mobile Ads');
        await MobileAds.instance.initialize();
        logSuccess('Mobile Ads initialisé');
      } catch (e, stackTrace) {
        logError('Erreur Mobile Ads', e, stackTrace);
      }
    } else {
      logWarning('Mobile Ads non supporté sur cette plateforme');
    }

    // ============================================================================
    // ÉTAPE 6: INITIALISATION DATE/TIME
    // ============================================================================
    logStep('ÉTAPE 6: Initialisation Date/Time');
    try {
      logDebug('Initialisation des formats de date français');
      await initializeDateFormatting('fr_FR', null);
      timeago.setLocaleMessages('fr', timeago.FrMessages());
      timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());
      logSuccess('Date/Time configuré');
    } catch (e, stackTrace) {
      logError('Erreur Date/Time', e, stackTrace);
    }

    // ============================================================================
    // ÉTAPE 7: INITIALISATION OBJECTBOX
    // ============================================================================
    logStep('ÉTAPE 7: Initialisation ObjectBox');
    try {
      logDebug('Création de l\'instance ObjectBox');
      objectBox = ObjectBox();
      logDebug('Appel objectBox.init()');
      await objectBox.init();
      logSuccess('ObjectBox initialisé');
    } catch (e, stackTrace) {
      logError('ERREUR CRITIQUE: ObjectBox', e, stackTrace);
      rethrow;
    }

    // ============================================================================
    // ÉTAPE 8: INITIALISATION P2P
    // ============================================================================
    logStep('ÉTAPE 8: Initialisation P2P');
    await _initializeP2P();

    // ============================================================================
    // ÉTAPE 9: PERMISSIONS RÉSEAU
    // ============================================================================
    logStep('ÉTAPE 9: Configuration des permissions réseau');
    await _setupNetworkPermissions();

    // ============================================================================
    // ÉTAPE 10: INITIALISATION MESSAGING P2P
    // ============================================================================
    logStep('ÉTAPE 10: Initialisation Messaging P2P');
    await _initializeMessaging();

    // ============================================================================
    // ÉTAPE 11: LANCEMENT DE L'APPLICATION
    // ============================================================================
    logStep('ÉTAPE 11: Lancement de l\'interface utilisateur');
    logDebug('Appel runApp()');
    runApp(MyApp());
    logSuccess('Application lancée avec succès');
  } catch (e, stackTrace) {
    logError('ERREUR FATALE DANS MAIN()', e, stackTrace);

    // Afficher une UI d'erreur
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Erreur Critique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'L\'application n\'a pas pu démarrer:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    print('════════════════════════════════════════');
                    print('LOGS COMPLETS:');
                    print('════════════════════════════════════════');
                    print('Erreur: $e');
                    print('StackTrace: $stackTrace');
                  },
                  child: const Text('Afficher les détails'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

/// Initialise Firebase uniquement sur les plateformes supportées
Future<void> _initializeFirebaseConditionally() async {
  try {
    logDebug('Début de l\'initialisation Firebase');

    // Vérifier la plateforme
    logDebug('Vérification du support Firebase pour cette plateforme');
    if (kIsWeb) {
      logInfo('Plateforme: Web - Firebase supporté');
      isFirebaseSupported = true;
    } else if (Platform.isAndroid) {
      logInfo('Plateforme: Android - Firebase supporté');
      isFirebaseSupported = true;
    } else if (Platform.isIOS) {
      logInfo('Plateforme: iOS - Firebase supporté');
      isFirebaseSupported = true;
    } else if (Platform.isMacOS) {
      logInfo('Plateforme: macOS - Firebase supporté');
      isFirebaseSupported = true;
    } else if (Platform.isWindows) {
      logWarning('Plateforme: Windows - Firebase partiellement supporté');
      logWarning('Tentative d\'initialisation avec gestion d\'erreur');
      isFirebaseSupported = true;
    } else if (Platform.isLinux) {
      logWarning('Plateforme: Linux - Firebase NON supporté');
      isFirebaseSupported = false;
      logInfo('Mode sans Firebase activé');
      return;
    } else {
      logWarning('Plateforme inconnue - Firebase NON supporté');
      isFirebaseSupported = false;
      return;
    }

    if (!isFirebaseSupported) {
      logInfo('Firebase désactivé pour cette plateforme');
      return;
    }

    // Tentative d'initialisation Firebase
    logDebug('Appel Firebase.initializeApp()');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    isFirebaseInitialized = true;
    logSuccess('Firebase initialisé avec succès');

    // Configuration Firestore
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        logDebug('Configuration de la persistence Firestore');
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
        logSuccess('Firestore persistence activée');
      } catch (e, stackTrace) {
        logError('Erreur configuration Firestore', e, stackTrace);
      }
    }

    // Configuration Firebase Messaging
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        logDebug('Configuration Firebase Messaging');
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
        logSuccess('Firebase Messaging configuré');
      } catch (e, stackTrace) {
        logError('Erreur Firebase Messaging', e, stackTrace);
      }
    }
  } catch (e, stackTrace) {
    isFirebaseInitialized = false;
    logError('ERREUR lors de l\'initialisation Firebase', e, stackTrace);

    if (!kIsWeb && Platform.isWindows) {
      logWarning('Windows détecté - L\'application continuera sans Firebase');
      logInfo('Supabase sera utilisé comme backend principal');
    } else {
      logWarning('L\'application continuera sans Firebase');
    }
  }
}

/// Configure les permissions réseau nécessaires
Future<void> _setupNetworkPermissions() async {
  if (kIsWeb) {
    logInfo('Web - Pas de permissions réseau nécessaires');
    return;
  }

  try {
    logDebug('Début de la configuration des permissions réseau');

    if (Platform.isAndroid) {
      logDebug(
          'Android - Demande des permissions location et nearbyWifiDevices');
      final statuses = await [
        Permission.location,
        Permission.nearbyWifiDevices,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        logWarning('Certaines permissions Android ont été refusées');
        statuses.forEach((permission, status) {
          logDebug('  $permission: $status');
        });
      } else {
        logSuccess('Toutes les permissions Android accordées');
      }
    } else if (Platform.isIOS) {
      logDebug('iOS - Demande de la permission nearbyWifiDevices');
      final status = await Permission.nearbyWifiDevices.request();

      if (status.isDenied) {
        logWarning('Permission réseau local refusée sur iOS');
      } else if (status.isPermanentlyDenied) {
        logWarning('Permission réseau définitivement refusée');
        logInfo('Suggestion: Ouvrir les paramètres de l\'app');
      } else {
        logSuccess('Permission iOS accordée');
      }
    } else {
      logInfo('${Platform.operatingSystem} - Pas de permissions spécifiques');
    }

    // Vérifier la connectivité
    logDebug('Vérification de la connectivité réseau');
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      logWarning('Aucune connexion réseau disponible');
    } else {
      logSuccess('Connectivité réseau OK: $connectivity');
    }
  } catch (e, stackTrace) {
    logError('Erreur configuration permissions réseau', e, stackTrace);
  }
}

/// Initialise le système P2P complet
Future<void> _initializeP2P() async {
  try {
    logDebug('Création de l\'instance P2PIntegration');
    p2pIntegration = P2PIntegration();

    logDebug('Appel initializeP2PSystem()');
    await p2pIntegration.initializeP2PSystem();

    logDebug('Configuration du callback de broadcast');
    final deltaGenerator = DeltaGenerator();
    deltaGenerator
        .setBroadcastCallback((delta) => p2pIntegration.broadcastDelta(delta));

    logDebug('Initialisation P2PManager et ConnectionManager');
    p2pManager = P2PManager();
    connectionManager = p2pIntegration.connectionManager;

    logSuccess('P2P System initialisé');
  } catch (e, stackTrace) {
    logError('ERREUR lors de l\'initialisation P2P', e, stackTrace);
    rethrow;
  }
}

/// Initialise le système de messagerie P2P
Future<void> _initializeMessaging() async {
  try {
    logDebug('Création de MessagingManager');
    messagingManager = MessagingManager();

    logDebug('Initialisation MessagingManager avec ObjectBox et nodeId');
    await messagingManager.initialize(objectBox, p2pManager.nodeId);
    logSuccess('MessagingManager initialisé');

    logDebug('Création et initialisation NodesManager');
    final nodesManager = NodesManager();
    await nodesManager.initialize(p2pManager, connectionManager);
    logSuccess('NodesManager initialisé');

    logDebug('Création de MessagingP2PIntegration');
    messagingP2P = MessagingP2PIntegration();

    logDebug('Initialisation MessagingP2PIntegration');
    await messagingP2P.initialize(
        messagingManager, p2pIntegration, connectionManager, objectBox);

    logDebug('Démarrage de MessagingP2PIntegration');
    messagingP2P.start();
    logSuccess('MessagingP2PIntegration démarré');

    logDebug('Création et initialisation MessagingSyncObserver');
    final messagingSyncObserver = MessagingSyncObserver();
    await messagingSyncObserver.initialize(objectBox, messagingP2P);
    messagingSyncObserver.start();
    logSuccess('MessagingSyncObserver démarré');

    logSuccess('Système de messagerie P2P complètement initialisé');
  } catch (e, stackTrace) {
    logError('ERREUR lors de l\'initialisation Messaging', e, stackTrace);
    rethrow;
  }
}

Future<void> initializeSupabase() async {
  try {
    logDebug('=== DIAGNOSTIC SUPABASE ===');

    const supabaseUrl = 'https://zjbnzghyhdhlivpokstz.supabase.co';
    const supabaseKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqYm56Z2h5aGRobGl2cG9rc3R6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2ODA1MjcsImV4cCI6MjA1NDI1NjUyN30.99PBeSXyoFJQMFopizHfLDlqLrMunSBLlBfTGcLIpv8';

    // Diagnostic 1: Vérifier les caractères
    logDebug('URL length: ${supabaseUrl.length}');
    logDebug('Key length: ${supabaseKey.length}');
    logDebug('URL bytes: ${supabaseUrl.codeUnits.take(10).toList()}');
    logDebug('Key bytes: ${supabaseKey.codeUnits.take(10).toList()}');

    // Diagnostic 2: Vérifier le format de la clé JWT
    final keyParts = supabaseKey.split('.');
    logDebug('JWT parts: ${keyParts.length} (devrait être 3)');

    if (keyParts.length != 3) {
      logError(
          'Clé JWT invalide - devrait avoir 3 parties séparées par des points');
      return;
    }

    // Diagnostic 3: Vérifier l'URL
    try {
      final uri = Uri.parse(supabaseUrl);
      logDebug('URL scheme: ${uri.scheme}');
      logDebug('URL host: ${uri.host}');
    } catch (e) {
      logError('URL invalide', e, null);
      return;
    }

    // Tentative d'initialisation
    logDebug('Tentative d\'initialisation...');

    await su.Supabase.initialize(
      url: supabaseUrl.trim(),
      anonKey: supabaseKey.trim(),
      authOptions: const su.FlutterAuthClientOptions(
        authFlowType: su.AuthFlowType.pkce,
      ),
      realtimeClientOptions: const su.RealtimeClientOptions(
        logLevel: su.RealtimeLogLevel.info,
      ),
      storageOptions: const su.StorageClientOptions(
        retryAttempts: 10,
      ),
      debug: true,
    );

    logSuccess('✅ Supabase initialisé avec succès');
  } catch (e, stackTrace) {
    logError('❌ ERREUR Supabase', e, stackTrace);

    if (e is FormatException) {
      logError('Format Exception Message', e.message, null);
      logError('Format Exception Source', e.source, null);
      logError('Format Exception Offset', e.offset, null);
    }
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
final globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  MyApp({super.key});

  static const String _title = 'DZ Wallet';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLicenseValidated = false;
  bool _isLicenseDemoValidated = false;

  @override
  void initState() {
    super.initState();
    logDebug('MyApp.initState() appelé');
    _checkLicenseStatus();
  }

  Future<void> _checkLicenseStatus() async {
    try {
      logDebug('Vérification du statut de licence');
      SharedPreferences prefs = await SharedPreferences.getInstance();

      bool? isLicenseValidated = prefs.getBool('isLicenseValidated');
      bool? isLicenseDemoValidated = prefs.getBool('isLicenseDemoValidated');

      logDebug('isLicenseValidated: $isLicenseValidated');
      logDebug('isLicenseDemoValidated: $isLicenseDemoValidated');

      if (isLicenseValidated != null && isLicenseValidated) {
        setState(() {
          _isLicenseValidated = true;
        });
        logInfo('Licence validée');
      } else if (isLicenseDemoValidated != null && isLicenseDemoValidated) {
        setState(() {
          _isLicenseDemoValidated = true;
        });
        logInfo('Licence démo validée');
      } else {
        logInfo('Aucune licence trouvée');
      }
    } catch (e, stackTrace) {
      logError('Erreur lors de la vérification de licence', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    logDebug('MyApp.build() appelé');

    return MaterialApp(
      scaffoldMessengerKey: globalScaffoldMessengerKey,
      scrollBehavior: CustomScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'OSWALD',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.black87,
          labelStyle: TextStyle(color: Colors.white),
          shape: StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ),
      locale: const Locale('fr', 'CA'),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ramzi',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: Colors.black87),
          shape: StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ),
      home: MyMain(),
    );
  }
}
