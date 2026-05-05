import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importez cette ligne
import 'package:kenzy/Kids/claude/auth_wrapper_refactored.dart'
    show AuthWrapperRefactored;
import 'package:kenzy/Kids/screens/autresDashboard.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:timeago/timeago.dart' as timeago;

import '../Kids/providers/locale_provider.dart';
import 'Hopital/p2p/connection_manager.dart';
import 'Hopital/p2p/delta_generator_real.dart';
import 'Hopital/p2p/messenger/NodesManager.dart';
import 'Hopital/p2p/messenger/messaging_integration.dart';
import 'Hopital/p2p/messenger/messaging_manager.dart';
import 'Hopital/p2p/p2p_integration.dart';
import 'Hopital/p2p/p2p_manager.dart';
import 'Kids/models/user_model.dart';
import 'Kids/screens/coach_dashboard_screen.dart';
import 'Kids/screens/parent_dashboard_screen.dart';
import 'Kids/screens/school_dashboard_screen.dart';
import 'firebase_options.dart';
import 'package:kenzy/objectBox/MyApp.dart';
import 'package:kenzy/objectBox/classeObjectBox.dart';

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

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialisation Firebase
  logStep('🔹 Initialisation Firebase');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logStep('✅ Firebase initialisé');
  } catch (e, st) {
    logError('Erreur initialisation Firebase', e, st);
  }
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

  // ========================================================================
  // 1️⃣ INITIALISER OBJECTBOX EN PREMIER - C'EST CRITIQUE
  // ========================================================================
  print('[Main] 1️⃣ Initialisation ObjectBox...');
  objectBox = ObjectBox();
  await objectBox.init(); // ⚠️ ATTENDRE LA FINALISATION
  print('[Main] ✅ ObjectBox initialisé');
  // 2️⃣ Initialiser P2P
  await _initializeP2P();
  //////////////////////////////////////////////////////////////////////////////
  // 1. Vérifier les permissions réseau
  await _setupNetworkPermissions();

  // ========================================================================
  // INITIALISATION MESSAGING P2P
  // ========================================================================
  print('[Main] =========== Initialisation Messaging ===========');

  // ✅ Initialiser messagingP2P ici pour éviter LateInitializationError
  messagingP2P = MessagingP2PIntegration();

  try {
    // 1. Initialiser MessagingManager avec objectBox initialisé
    messagingManager = MessagingManager();
    await messagingManager.initialize(objectBox, p2pManager.nodeId);
    print('✅ MessagingManager initialisé');
    
    // 2. Initialiser NodesManager avec les vrais nœuds
    final nodesManager = NodesManager();
    await nodesManager.initialize(p2pManager, connectionManager);
    print('✅ NodesManager initialisé');
    
    // 3. Initialiser MessagingP2PIntegration
    await messagingP2P.initialize(
        messagingManager, p2pIntegration, connectionManager, objectBox);
    messagingP2P.start();
    print('✅ MessagingP2PIntegration initialisé et démarré');

    // 4. Initialiser sync observer pour messaging
    final messagingSyncObserver = MessagingSyncObserver();
    await messagingSyncObserver.initialize(objectBox, messagingP2P);
    messagingSyncObserver.start();
    print('✅ MessagingSyncObserver démarré');
  } catch (e) {
    print('[Main] ❌ Erreur initialisation Messaging: $e');
  }

  print('[Main] ======================================');

// Initialisation Supabase (IMPORTANT pour la persistance)
  // if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  logStep('🔹 Initialisation Supabase pour Desktop');

  // ========================================================================
  // Nettoyage DÉSACTIVÉ - Sessions persistées correctement
  // ========================================================================
  // IMPORTANT: Ce bloc ne doit être activé QUE si tu rencontres des erreurs
  // de corruption. En temps normal, il doit rester commenté pour que les
  // sessions persistent entre les redémarrages.

  // try {
  //   logStep('🧹 Nettoyage RADICAL des données Supabase...');
  //   final sp = await SharedPreferences.getInstance();
  //
  //   // ✅ CORRECTION : Le préfixe réel est "flutter.supabase_auth_"
  //   final supabaseKeys = sp
  //       .getKeys()
  //       .where((k) => k.startsWith('supabase_auth_session'))
  //       .toList();
  //
  //   if (supabaseKeys.isNotEmpty) {
  //     logWarning(
  //         '⚠️ ${supabaseKeys.length} clé(s) Supabase détectée(s) - SUPPRESSION TOTALE');
  //
  //     for (var key in supabaseKeys) {
  //       try {
  //         await sp.remove(key);
  //         logStep('  🗑️ Supprimé: $key');
  //       } catch (e) {
  //         logError('  ❌ Échec suppression: $key', e);
  //       }
  //     }
  //
  //     logSuccess(
  //         '✅ Nettoyage radical terminé - ${supabaseKeys.length} clé(s) supprimée(s)');
  //     logWarning('⚠️ Vous devrez vous reconnecter');
  //   } else {
  //     logStep('✅ Aucune donnée Supabase existante');
  //   }
  // } catch (e, st) {
  //   logError('Erreur lors du nettoyage radical', e, st);
  // }

  // ========================================================================
  // Initialisation Supabase
  // ========================================================================
  try {
    await Supabase.initialize(
      url: 'https://ftaqbokfeahvfndorzuf.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0YXFib2tmZWFodmZuZG9yenVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NDE5MDEsImV4cCI6MjA4MDMxNzkwMX0.I_pvSiN5S8Y31XS3NV2Gw5dVrCDNjXqmUUSloycXhcw',
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        // localStorage: SharedPrefsStorage(),
      ),
      debug: true,
    );
    logSuccess('✅ Supabase initialisé avec persistance');
  } catch (e, st) {
    logError('Erreur initialisation Supabase', e, st);
  }
  // }

  // Run App avec Provider
  runApp(
    // MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => AuthProvider()),
    //     ChangeNotifierProvider(create: (_) => ChildEnrollmentProvider()),
    //     ChangeNotifierProvider(create: (_) => LocaleProvider()),
    //     ChangeNotifierProvider(create: (_) => CourseProvider()),
    //     ChangeNotifierProvider(create: (_) => AuthProviderV2()),
    //     ChangeNotifierProvider(create: (_) => ThemeProvider()),
    //   ],
    //   child: KidsAcademyApp(), //MyApp(),
    // ),
    MyMain(),
  );
}

/// Configure les permissions réseau nécessaires
Future<void> _setupNetworkPermissions() async {
  try {
    print('[Main] Vérification des permissions réseau...');

    if (Platform.isAndroid) {
      // Android: demander les permissions à l'exécution
      final statuses = await [
        Permission.location, // Remplace accessNetworkState
        Permission.nearbyWifiDevices,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        print('[Main] ⚠️ Certaines permissions refusées sur Android');
      } else {
        print('[Main] ✅ Permissions Android accordées');
      }
    } else if (Platform.isIOS) {
      // iOS: demander l'accès réseau local
      final status = await Permission.nearbyWifiDevices.request();

      if (status.isDenied) {
        print('[Main] ⚠️ Permission réseau local refusée sur iOS');
      } else if (status.isPermanentlyDenied) {
        print('[Main] ⚠️ Permission réseau local définitivement refusée');
        await openAppSettings();
      } else {
        print('[Main] ✅ Permissions iOS accordées');
      }
    }

    // Vérifier la connectivité
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
      print('[Main] ⚠️ Aucune connexion réseau disponible');
    } else {
      print('[Main] ✅ Connectivité réseau OK: $connectivity');
    }
  } catch (e) {
    print('[Main] ❌ Erreur configuration permissions ou connectivité: $e');
  }
}

/// Initialise le système P2P complet
Future<void> _initializeP2P() async {
  try {
    print('[Main] =========== Initialisation P2P ===========');
    p2pIntegration = P2PIntegration();
    
    // ✅ Initialiser les références AVANT l'initialisation système pour éviter LateInitializationError
    p2pManager = p2pIntegration.p2pManager;
    connectionManager = p2pIntegration.connectionManager;

    await p2pIntegration.initializeP2PSystem();

    // ✅ CRITIQUE : Configurer le callback APRÈS l'initialisation
    print('[Main] 🔧 Configuration du callback de broadcast...');
    final deltaGenerator = DeltaGenerator();
    deltaGenerator
        .setBroadcastCallback((delta) => p2pIntegration.broadcastDelta(delta));
    print('[Main] ✅ Callback configuré');

    print('[Main] ✅ P2P System initialisé');
  } catch (e) {
    print('[Main] ❌ Erreur initialisation P2P: $e');
    // On s'assure que les variables sont quand même initialisées si p2pIntegration existe
    p2pManager = p2pIntegration.p2pManager;
    connectionManager = p2pIntegration.connectionManager;
  }
}

// ============================================================================
// LOGGING UTILS (à conserver dans ton main.dart)
// ============================================================================
void logStep(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] 🔹 STEP: $message');
}

void logError(String message, [Object? e, StackTrace? st]) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ❌ ERROR: $message');
  if (e != null) print('[$timestamp]     └─ $e');
  if (st != null) print('[$timestamp]     └─ StackTrace:\n$st');
}

void logWarning(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ⚠️ WARNING: $message');
}

void logSuccess(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ✅ SUCCESS: $message');
}

// ===========================================
// AuthProvider
// ===========================================

class MemoryStorage implements GotrueAsyncStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<String?> getItem({required String key}) async => _data[key];

  @override
  Future<void> removeItem({required String key}) async => _data.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async {
    _data[key] = value;
  }
}

class AuthProvider extends ChangeNotifier {
  bool loading = true;
  bool isSupabase = false;
  User? firebaseUser;
  Session? supabaseSession;

  StreamSubscription<AuthState>? _supabaseAuthSubscription;

  // Flag pour éviter les double-initialisations lors du hot reload
  bool _isInitialized = false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Protection contre double initialisation (hot reload)
    if (_isInitialized) {
      logWarning('⚠️ AuthProvider déjà initialisé, récupération session...');
      await _recoverSession();
      return;
    }

    if (kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS))) {
      // ============ PATH FIREBASE ============
      isSupabase = false;
      FirebaseAuth.instance.authStateChanges().listen((u) {
        firebaseUser = u;
        loading = false;
        notifyListeners();
      });
      _isInitialized = true;
    } else {
      // ============ PATH SUPABASE (DESKTOP) ============
      isSupabase = true;

      try {
        logStep('🔐 Vérification session Supabase...');

        // Petit délai pour laisser Supabase s'initialiser proprement
        await Future.delayed(const Duration(milliseconds: 300));

        // Récupération de la session actuelle
        final sess = Supabase.instance.client.auth.currentSession;

        if (sess != null) {
          logSuccess('✅ Session trouvée: ${sess.user.email}');
          supabaseSession = sess;
        } else {
          logStep('❌ Aucune session trouvée');
        }
      } catch (e, stackTrace) {
        logError('❌ Erreur init Supabase', e, stackTrace);

        // Gestion spécifique FormatException (session corrompue)
        if (e is FormatException) {
          logWarning('🔧 FormatException détectée - Nettoyage complet...');
          await _handleCorruptedSession();
        }
      } finally {
        loading = false;
        _isInitialized = true;
        notifyListeners();
      }

      // Écoute des changements d'authentification
      _supabaseAuthSubscription?.cancel(); // Cancel previous if any
      _supabaseAuthSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        logStep('🔔 Auth Event: ${data.event}');

        // Ne pas écraser une session valide avec null lors du hot reload
        if (data.session != null || data.event == AuthChangeEvent.signedOut) {
          supabaseSession = data.session;
          notifyListeners();
        }
      });
    }
  }

  /// Récupération de session lors du hot reload
  Future<void> _recoverSession() async {
    if (!isSupabase) return;

    try {
      loading = true;
      notifyListeners();

      logStep('🔄 Récupération session après hot reload...');

      await Future.delayed(const Duration(milliseconds: 200));

      final sess = Supabase.instance.client.auth.currentSession;

      if (sess != null) {
        logSuccess('✅ Session récupérée: ${sess.user.email}');
        supabaseSession = sess;
      } else {
        logWarning('⚠️ Aucune session à récupérer');
      }
    } catch (e, st) {
      logError('Erreur récupération session', e, st);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Gestion session corrompue
  Future<void> _handleCorruptedSession() async {
    try {
      // Nettoyage complet du storage
      final storage = SharedPrefsStorage();
      await storage.removePersistedSession();
      logSuccess('✅ Storage nettoyé après corruption');

      // Réinitialisation état
      supabaseSession = null;
    } catch (cleanupError, st) {
      logError('Erreur lors du nettoyage post-corruption', cleanupError, st);
    }
  }

  bool get isLoggedIn {
    if (!isSupabase) {
      return firebaseUser != null;
    } else {
      return supabaseSession != null;
    }
  }

  String? get userEmail {
    if (!isSupabase) {
      return firebaseUser?.email;
    } else {
      return supabaseSession?.user.email;
    }
  }

  Future<String?> login(String email, String password) async {
    loading = true;
    notifyListeners();
    logStep('🔐 Tentative de connexion: $email');

    // if (!isSupabase) {
    //   // ============ FIREBASE LOGIN ============
    //   try {
    //     await FirebaseAuth.instance
    //         .signInWithEmailAndPassword(email: email, password: password);
    //     logSuccess('✅ Connexion Firebase réussie');
    //     return null;
    //   } on FirebaseAuthException catch (e) {
    //     logError('FirebaseAuthException', e);
    //     return e.message;
    //   } catch (e) {
    //     logError('Erreur Firebase', e);
    //     return "Erreur inconnue";
    //   } finally {
    //     loading = false;
    //     notifyListeners();
    //   }
    // } else {
    //   // ============ SUPABASE LOGIN ============
    //   try {
    //     final res = await Supabase.instance.client.auth.signInWithPassword(
    //       email: email,
    //       password: password,
    //     );
    //
    //     if (res.session == null) {
    //       loading = false;
    //       notifyListeners();
    //       return 'Email ou mot de passe invalide';
    //     }
    //
    //     supabaseSession = res.session;
    //     logSuccess('✅ Connexion Supabase réussie: ${res.session!.user.email}');
    //
    //     loading = false;
    //     notifyListeners();
    //     return null;
    //   } catch (e, st) {
    //     logError('Erreur Supabase login', e, st);
    //     loading = false;
    //     notifyListeners();
    //     return "Erreur: $e";
    //   }
    // }
    // ============ SUPABASE LOGIN ============
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null) {
        loading = false;
        notifyListeners();
        return 'Email ou mot de passe invalide';
      }

      supabaseSession = res.session;
      logSuccess('✅ Connexion Supabase réussie: ${res.session!.user.email}');

      loading = false;
      notifyListeners();
      return null;
    } catch (e, st) {
      logError('Erreur Supabase login', e, st);
      loading = false;
      notifyListeners();
      return "Erreur: $e";
    }
  }

  Future<String?> signup(String email, String password) async {
    loading = true;
    notifyListeners();

    if (!isSupabase) {
      // ============ FIREBASE SIGNUP ============
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return null;
      } on FirebaseAuthException catch (e) {
        return e.message;
      } catch (e) {
        return "Erreur inconnue";
      } finally {
        loading = false;
        notifyListeners();
      }
    } else {
      // ============ SUPABASE SIGNUP ============
      try {
        final res = await Supabase.instance.client.auth
            .signUp(email: email, password: password);

        if (res.session == null && res.user == null) {
          loading = false;
          notifyListeners();
          return 'Erreur lors de l\'inscription';
        }

        supabaseSession = res.session;
        loading = false;
        notifyListeners();
        return null;
      } catch (e, st) {
        logError('Erreur signup', e, st);
        loading = false;
        notifyListeners();
        return "Erreur: $e";
      }
    }
  }

  Future<void> logout() async {
    loading = true;
    notifyListeners();

    if (!isSupabase) {
      await FirebaseAuth.instance.signOut();
      firebaseUser = null;
    } else {
      await Supabase.instance.client.auth.signOut();
      supabaseSession = null;
    }

    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }
}

// ===========================================
// MyApp
// ===========================================
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
          SplashScreen(),
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

// ===========================================
// SplashScreen
// ===========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Attendre que loading soit terminé
    int attempts = 0;
    while (auth.loading && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    logStep('🔍 État final:');
    logStep('   - isSupabase: ${auth.isSupabase}');
    logStep('   - isLoggedIn: ${auth.isLoggedIn}');
    logStep('   - email: ${auth.userEmail}');

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (auth.isLoggedIn) {
      logStep('✅ → HomeScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthWrapper()), //const HomeScreen()),
      );
    } else {
      logStep('❌ → LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement...'),
          ],
        ),
      ),
    );
  }
}

// ===========================================
// LoginScreen
// ===========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe"),
              ),
              const SizedBox(height: 24),
              if (auth.loading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    final result = await auth.login(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                    );
                    if (result != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    }
                  },
                  child: const Text("Connexion"),
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text("Créer un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================
// SignupScreen
// ===========================================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Confirmer le mot de passe"),
              ),
              const SizedBox(height: 24),
              if (auth.loading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (passCtrl.text != confirmPassCtrl.text) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Les mots de passe ne correspondent pas"),
                          ),
                        );
                      }
                      return;
                    }

                    final result = await auth.signup(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                    );

                    if (result != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    }
                  },
                  child: const Text("S'inscrire"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================
// HomeScreen
// ===========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFFf093fb),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header moderne
                _buildHeader(context, auth, isDark),

                // Contenu principal
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(auth, isDark),
                        const SizedBox(height: 24),
                        _buildStatsGrid(isDark),
                        const SizedBox(height: 24),
                        _buildQuickActions(context, isDark),
                        const SizedBox(height: 24),
                        _buildRecentActivity(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildIconButton(
                Icons.notifications_outlined,
                () {},
                isDark,
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                Icons.logout,
                () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                isDark,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark,
      {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red[300] : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 32,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.userEmail ?? 'Invité',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final stats = [
      {
        'icon': Icons.task_alt,
        'label': 'Tâches',
        'value': '24',
        'color': Colors.blue
      },
      {
        'icon': Icons.notifications_active,
        'label': 'Notifications',
        'value': '8',
        'color': Colors.orange
      },
      {
        'icon': Icons.trending_up,
        'label': 'Progression',
        'value': '76%',
        'color': Colors.green
      },
      {
        'icon': Icons.star,
        'label': 'Points',
        'value': '1.2K',
        'color': Colors.purple
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          icon: stat['icon'] as IconData,
          label: stat['label'] as String,
          value: stat['value'] as String,
          color: stat['color'] as Color,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionChip(
                Icons.add_circle_outline, 'Nouveau', Colors.blue, isDark),
            _buildActionChip(Icons.search, 'Rechercher', Colors.purple, isDark),
            _buildActionChip(
                Icons.filter_list, 'Filtrer', Colors.orange, isDark),
            _buildActionChip(Icons.settings, 'Paramètres', Colors.teal, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
      IconData icon, String label, Color color, bool isDark) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    final activities = [
      {
        'title': 'Tâche complétée',
        'subtitle': 'Il y a 2 heures',
        'icon': Icons.check_circle
      },
      {
        'title': 'Nouveau message',
        'subtitle': 'Il y a 5 heures',
        'icon': Icons.message
      },
      {
        'title': 'Mise à jour système',
        'subtitle': 'Hier',
        'icon': Icons.system_update
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité Récente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 16),
        ...activities.map((activity) => _buildActivityItem(
              title: activity['title'] as String,
              subtitle: activity['subtitle'] as String,
              icon: activity['icon'] as IconData,
              isDark: isDark,
            )),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bon matin';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

class SharedPrefsStorage implements LocalStorage {
  final String prefix;
  static const String _sessionKey = 'session';
  static const String _accessTokenKey = 'access-token';

  // Cache pour éviter les lectures répétées
  SharedPreferences? _prefs;

  SharedPrefsStorage(
      {this.prefix = "supabase_auth_session"}); // ✅ SANS flutter.

  Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> initialize() async {
    logStep('📦 SharedPrefs: INITIALIZE appelé');

    try {
      final sp = await _sharedPrefs;

      // Lister UNIQUEMENT les clés (pas de lecture)
      final allKeys = sp.getKeys().where((k) => k.startsWith(prefix)).toList();

      if (allKeys.isEmpty) {
        logStep('📦 SharedPrefs: Aucune donnée Supabase stockée');
        return;
      }

      logStep('📦 SharedPrefs: ${allKeys.length} clé(s) trouvée(s)');

      // Tentative de validation PROTÉGÉE
      try {
        final sessionString = sp.getString("$prefix$_sessionKey");

        if (sessionString != null && sessionString.isNotEmpty) {
          try {
            final decoded = json.decode(sessionString);

            if (decoded is Map<String, dynamic> &&
                decoded.containsKey('access_token') &&
                decoded.containsKey('user')) {
              logSuccess('📦 ✅ Session existante VALIDE');
              return;
            } else {
              logWarning('📦 Structure de session invalide');
              await _cleanupCorruptedSession(sp);
            }
          } on FormatException catch (e) {
            logWarning('📦 Session corrompue (FormatException)');
            logStep('  └─ ${e.message}');
            await _cleanupCorruptedSession(sp);
          }
        }
      } catch (e) {
        // Si lecture échoue, supprimer TOUTES les clés
        logWarning('📦 ❌ Impossible de lire la session - Nettoyage complet');
        logStep('  └─ $e');
        await _cleanupCorruptedSession(sp);
      }
    } catch (e, st) {
      logError('Erreur critique initialize()', e, st);
      // En cas d'erreur critique, forcer nettoyage complet
      try {
        final sp = await _sharedPrefs;
        await _cleanupCorruptedSession(sp);
      } catch (_) {
        logError('Impossible de nettoyer après erreur critique');
      }
    }
  }

  /// Nettoyage sécurisé des données corrompues
  Future<void> _cleanupCorruptedSession(SharedPreferences sp) async {
    try {
      logStep('🧹 Nettoyage session corrompue...');

      final keysToRemove =
          sp.getKeys().where((k) => k.startsWith(prefix)).toList();

      for (var key in keysToRemove) {
        await sp.remove(key);
        logStep('🧹 Clé supprimée: $key');
      }

      logSuccess('✅ Nettoyage terminé');
    } catch (e, st) {
      logError('Erreur lors du nettoyage', e, st);
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      final sp = await _sharedPrefs;

      // IMPORTANT: On récupère depuis la session complète, pas depuis access-token
      // Car Supabase s'attend à parser du JSON, pas un JWT brut
      final sessionString = sp.getString("$prefix$_sessionKey");

      if (sessionString != null && sessionString.isNotEmpty) {
        try {
          final session = json.decode(sessionString);
          if (session is Map<String, dynamic> &&
              session.containsKey('access_token')) {
            final token = session['access_token'];
            logStep(
                '📦 GET accessToken = ${token != null ? "TROUVÉ (depuis session)" : "NULL"}');
            return token;
          }
        } catch (e) {
          logWarning('📦 Erreur parsing session pour accessToken');
          return null;
        }
      }

      logStep('📦 GET accessToken = NULL');
      return null;
    } catch (e, st) {
      logError('Erreur accessToken()', e, st);
      return null;
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    final hasToken = token != null && token.isNotEmpty;
    logStep('📦 hasAccessToken = $hasToken');
    return hasToken;
  }

  @override
  Future<void> persistSession(String sessionString) async {
    try {
      logStep(
          '📦 SharedPrefs: PERSIST SESSION (${sessionString.length} chars)');

      // 1. Validation JSON AVANT toute écriture
      final Map<String, dynamic> sessionData;
      try {
        final decoded = json.decode(sessionString);
        if (decoded is! Map<String, dynamic>) {
          logError('Session data n\'est pas un Map valide');
          return;
        }
        sessionData = decoded;
      } catch (e, st) {
        logError('JSON invalide lors de persistSession', e, st);
        return;
      }

      // 2. Validation structure minimale
      if (!sessionData.containsKey('access_token')) {
        logError('Session manque access_token');
        return;
      }

      // 3. Écriture UNIQUEMENT de la session complète
      final sp = await _sharedPrefs;

      // Sauvegarder UNIQUEMENT la session complète
      // Supabase lira le JSON complet, pas juste l'access_token
      final saveResult =
          await sp.setString("$prefix$_sessionKey", sessionString);
      if (!saveResult) {
        logError('Échec sauvegarde session dans SharedPreferences');
        return;
      }

      logSuccess('📦 ✅ Session persistée avec succès');
    } catch (e, st) {
      logError('Erreur critique persistSession()', e, st);
      // En cas d'erreur, nettoyer pour éviter état corrompu
      await removePersistedSession();
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      logStep('📦 SharedPrefs: REMOVE PERSISTED SESSION');
      final sp = await _sharedPrefs;

      // Suppression des clés principales
      await sp.remove("$prefix$_sessionKey");
      await sp.remove("$prefix$_accessTokenKey");

      // Suppression de toutes les clés avec notre prefix
      final allKeys = sp.getKeys().where((k) => k.startsWith(prefix)).toList();
      for (var key in allKeys) {
        await sp.remove(key);
        logStep('📦 Clé supprimée: $key');
      }

      logSuccess('📦 ✅ Session supprimée complètement');
    } catch (e, st) {
      logError('Erreur removePersistedSession()', e, st);
    }
  }

  @override
  Future<void> removeItem(String key) async {
    try {
      logStep('📦 SharedPrefs: REMOVE "$prefix$key"');
      final sp = await _sharedPrefs;
      await sp.remove("$prefix$key");
    } catch (e, st) {
      logError('Erreur removeItem($key)', e, st);
    }
  }

  @override
  Future<String?> getItem(String key) async {
    try {
      final sp = await _sharedPrefs;
      final value = sp.getString("$prefix$key");

      // Validation spéciale pour la clé session
      if (key == _sessionKey && value != null && value.isNotEmpty) {
        try {
          final decoded = json.decode(value);
          if (decoded is! Map<String, dynamic>) {
            logWarning('📦 Session invalide pour "$key", retour null');
            await sp.remove("$prefix$key");
            return null;
          }
        } catch (e) {
          logWarning('📦 Session corrompue pour "$key", retour null');
          await sp.remove("$prefix$key");
          return null;
        }
      }

      logStep('📦 GET "$prefix$key" = ${value != null ? "TROUVÉ" : "NULL"}');
      return value;
    } catch (e, st) {
      logError('Erreur getItem($key)', e, st);
      return null;
    }
  }

  @override
  Future<void> setItem(String key, String value) async {
    try {
      logStep('📦 SharedPrefs: SET "$prefix$key"');
      final sp = await _sharedPrefs;
      await sp.setString("$prefix$key", value);
    } catch (e, st) {
      logError('Erreur setItem($key)', e, st);
    }
  }
}

void logInfo(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] ℹ️ INFO: $message');
}

void logDebug(String message) {
  final timestamp = DateTime.now().toString().substring(11, 19);
  print('[$timestamp] 🔍 DEBUG: $message');
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Afficher le loader pendant le chargement
        if (authProvider.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Vérifier si l'utilisateur est connecté
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

        // TODO: Récupérer les données utilisateur depuis Firestore/Supabase
        // Pour l'instant, afficher un dashboard par défaut
        // Tu devras implémenter la logique de récupération du UserModel
        return FutureBuilder<UserModel?>(
          future: _fetchUserData(authProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              // Si pas de données utilisateur, déconnecter
              WidgetsBinding.instance.addPostFrameCallback((_) {
                authProvider.logout();
              });
              return const Scaffold(
                body: Center(
                  child: Text('Erreur de chargement du profil'),
                ),
              );
            }

            final user = snapshot.data!;

            // Vérifier si le compte est actif
            if (!user.isActive) {
              return DeactivatedAccountScreen(
                onReactivate: () async {
                  // TODO: Implémenter la réactivation
                  // await authProvider.reactivateAccount();
                },
                onLogout: () async {
                  await authProvider.logout();
                },
              );
            }

            // Router vers le dashboard approprié selon le rôle
            switch (user.role) {
              case UserRole.parent:
                return const ParentDashboard_screen();
              case UserRole.school:
                return const SchoolDashboard();
              case UserRole.coach:
                return const CoachDashboard();
              case UserRole.autres:
                return const AutreDashboard();
            }
          },
        );
      },
    );
  }

  /// Récupère les données utilisateur depuis Firestore/Supabase
  Future<UserModel?> _fetchUserData(AuthProvider authProvider) async {
    try {
      final email = authProvider.userEmail;
      if (email == null) return null;

      // TODO: Implémenter la récupération depuis Firestore/Supabase
      // Exemple pour Supabase:
      if (authProvider.isSupabase) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', email)
            .single();
        return UserModel.fromSupabase(response);
      }

      // Exemple pour Firebase:
      // else {
      //   final doc = await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(authProvider.firebaseUser!.uid)
      //       .get();
      //   return UserModel.fromJson(doc.data()!);
      // }

      // Pour l'instant, retourner null pour forcer l'implémentation
      return null;
    } catch (e) {
      logError('Erreur récupération user data', e);
      return null;
    }
  }
}

class DeactivatedAccountScreen extends StatelessWidget {
  final VoidCallback onReactivate;
  final VoidCallback onLogout;

  const DeactivatedAccountScreen({
    super.key,
    required this.onReactivate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte Désactivé'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Compte Désactivé',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre compte a été temporairement désactivé. Vous pouvez le réactiver dans les 60 jours suivant la désactivation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onReactivate,
                icon: const Icon(Icons.refresh),
                label: const Text('Réactiver mon compte'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onLogout,
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// APPLICATION PRINCIPALE
// ============================================================================

class KidsAcademyApp extends StatelessWidget {
  const KidsAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return MaterialApp(
          // ============================================================
          // CONFIGURATION DE BASE
          // ============================================================
          title: 'Kids Sports Academy',
          //debugShowCheckedModeBanner: false,
          // ============================================================
          // LOCALISATION - ✅ FIX: Add localizationsDelegates
          // ============================================================

          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
            Locale('ar', 'DZ'),
          ],
          // ✅ ADD THIS - Critical for Material widgets localization
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // ============================================================
          // LOCALISATION
          // ============================================================
          locale: localeProvider.locale,

          // ============================================================
          // THEME - Material Design 3
          // ============================================================
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: ThemeMode.system,

          // ============================================================
          // NAVIGATION
          // ============================================================
          navigatorKey: GlobalKey<NavigatorState>(),

          // ============================================================
          // ÉCRAN PRINCIPAL
          // ============================================================
          home: const AuthWrapperRefactored(),

          // ============================================================
          // GESTION DES ROUTES
          // ============================================================
          onGenerateRoute: _generateRoute,

          // ============================================================
          // CONFIGURATION SCROLL
          // ============================================================
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
          ),
        );
      },
    );
  }

  /// Génère les routes de l'application
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // TODO: Implémenter le routing nommé
    return null;
  }

  /// Thème clair Material Design 3
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'oswald',

      // Palette de couleurs
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4), // Violet moderne
        brightness: Brightness.light,
      ),

      // Typographie
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      // Composants
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Thème sombre Material Design 3
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'oswald',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),

      // Reprendre la configuration du thème clair
      textTheme: _buildLightTheme().textTheme,
      appBarTheme: _buildLightTheme().appBarTheme,
      cardTheme: _buildLightTheme().cardTheme,
      chipTheme: _buildLightTheme().chipTheme,
      inputDecorationTheme: _buildLightTheme().inputDecorationTheme,
      elevatedButtonTheme: _buildLightTheme().elevatedButtonTheme,
      filledButtonTheme: _buildLightTheme().filledButtonTheme,
    );
  }
}

// ============================================================================
// ÉCRAN D'ERREUR D'INITIALISATION
// ============================================================================

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Redémarrer l'application
                    // ignore: invalid_use_of_protected_member
                    WidgetsBinding.instance.reassembleApplication();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
