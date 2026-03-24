import 'package:flutter/material.dart';
import 'package:rhos/login_screen.dart';
import 'package:rhos/palette.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RHOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Palette.backgroundColor3,
      ),
      home: LoginScreen(),
    );
  }
}