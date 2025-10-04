import 'dart:io';

import 'package:flutter/material.dart';

import 'Desktop/DesktopEntryScreen.dart';
import 'Mobile/MobileEntryScreen.dart';

class MyAppBlackHole extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform = Platform.isAndroid || Platform.isIOS;

    if (isMobilePlatform) {
      return MaterialApp(
        title: 'Mon Application',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: MobileEntryScreen(),
        debugShowCheckedModeBanner: false,
      );
    } else {
      return MaterialApp(
        title: 'Mon Application',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: DesktopEntryScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
  }
}
