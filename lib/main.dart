import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Your existing login screen

void main() async {
  // 1. Ensure Flutter is fully initialized before calling native code like Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Wake up Firebase using your specific auto-generated credentials
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        // 👇 THE REAL FIX: Removed 'const' entirely from this block
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
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