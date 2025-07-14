
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const JustTravelApp());


class JustTravelApp extends StatelessWidget {
  const JustTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}