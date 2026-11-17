import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../features/splash/splash_screen.dart';

class StitchStyleApp extends StatelessWidget {
  const StitchStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sivanya Tailoring',
      theme: AppTheme.lightTheme,

      home: const SplashScreen(),
    );
  }
}
