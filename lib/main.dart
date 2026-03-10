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
        primaryColor: const Color(0xFF0C462B), 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C462B)),
        fontFamily: 'Roboto', 
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
      ),
      // --- THIS IS THE MAGIC SWITCH ---
      home: const OnboardingScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}