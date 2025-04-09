import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kenzy/checkit/login.dart';
import 'package:provider/provider.dart';
import 'CheckRole.dart';
import 'MainPage.dart';
import 'Ogoogle/googleSignInProvider.dart';
import 'VerifyEmailPage.dart';

Future initialization(BuildContext? context) async {
  Future.delayed(Duration(seconds: 5));
}

final navigatorKey = GlobalKey<NavigatorState>();

/// This is the main application widget.
class MyAppAuth extends StatelessWidget {
  MyAppAuth({Key? key}) : super(key: key);

  static const String _title = 'Oran ';
  final GoogleUser2 = FirebaseAuth.instance.currentUser;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseInAppMessaging fiam = FirebaseInAppMessaging.instance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider(
        create: (context) => googleSignInProvider(),
        //lazy: true,
        child: MaterialApp(
          locale: const Locale('fr', 'CA'),

          //scaffoldMessengerKey: Utils.messengerKey,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: _title,
          themeMode: ThemeMode.dark,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: "Oswald",
            colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.lightBlue, backgroundColor: Colors.white),
            appBarTheme: AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
              ),
            ),
          ),
          home: // upload_random(),
              //gantt_chart(),

              verifi_auth(),
        ));
  }
}

class verifi_auth extends StatefulWidget {
  const verifi_auth({Key? key}) : super(key: key);

  @override
  State<verifi_auth> createState() => _verifi_authState();
}

class _verifi_authState extends State<verifi_auth> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   return const CircularProgressIndicator();
            // } else
            if (snapshot.hasError) {
              return const Center(child: Text('Probleme de Connexion'));
            }
            if (snapshot.hasData) {
              final userD = snapshot.data!.uid;
              User? user = snapshot.data;
              if (user!.emailVerified) {
                // Email is verified, navigate to home page
                return CheckRole(userD); //MultiProviderWidget();
              } else {
                // Email is not verified, navigate to resend email page
                return VerifyEmailPage();
              }
            } else {
              return Center(child: MainPageAuth()); //unloggedPublicPage();
            }
          },
        ),
      );
}
