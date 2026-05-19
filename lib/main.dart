import 'screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Your existing login screen

void main() {
  runApp(const RahisiAgroPayApp());
}

class RahisiAgroPayApp extends StatelessWidget {
  const RahisiAgroPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oletai Agri Finance',
      theme: ThemeData(
        // 1. Lock in the official Oletai Green globally
        primaryColor: const Color(0xFF144D2F), 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF144D2F),
          primary: const Color(0xFF144D2F),
          secondary: const Color(0xFF0A2E1A), // Darker accent shade
        ),
        fontFamily: 'Roboto', 
        
        // 2. Set a clean, unified background for all screens
        scaffoldBackgroundColor: Colors.white,

        // 3. Global Button Styling so you don't have to rewrite it on every page
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF144D2F),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // 4. Smooth Screen Transitions (iOS style slide for all platforms)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // --- THIS IS THE MAGIC SWITCH ---
      home: const OnboardingScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}