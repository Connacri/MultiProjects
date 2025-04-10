import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Oauth/Ogoogle/googleSignInProvider.dart';
import 'AuthProvider.dart';
import 'HomePage.dart';

class MyApp8888 extends StatelessWidget {
  const MyApp8888({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => googleSignInProvider(),
      child: MaterialApp(
        title: 'Google Auth Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomePage3(),
      ),
    );
  }
}
