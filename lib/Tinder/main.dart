import 'package:flutter/material.dart';

import 'features/auth/auth_wrapper_tinder.dart';

class MyApp_TinderClone extends StatelessWidget {
  const MyApp_TinderClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AuthWrapperTinder(),
    );
  }
}
