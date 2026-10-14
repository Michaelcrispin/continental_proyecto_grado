import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Continental Trufi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Aplicando nuestro tema global
      home: const SplashScreen(),
    );
  }
}
