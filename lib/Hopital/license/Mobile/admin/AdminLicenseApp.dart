import 'package:flutter/material.dart';

import 'AdminLoginScreen.dart';

class AdminLicenseApp extends StatelessWidget {
  const AdminLicenseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin License Generator',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: const AdminLoginScreen(),
    );
  }
}
