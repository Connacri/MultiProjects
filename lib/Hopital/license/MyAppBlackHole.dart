import 'dart:io';

import 'package:flutter/material.dart';

import 'Mobile/MobileEntryScreen.dart';

class MyAppBlackHole extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform = Platform.isAndroid || Platform.isIOS;

    if (isMobilePlatform) {
      return MobileEntryScreen();
    } else {
      return MobileEntryScreen(); //DesktopEntryScreen();
    }
  }
}
