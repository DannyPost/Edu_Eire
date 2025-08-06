import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:academic_support_app/firebase_options.dart';
import 'package:academic_support_app/homepage.dart'; // ← This is all you need

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduEire Academic Support',
      debugShowCheckedModeBanner: false,

      // ─────── Light Theme ───────
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'OpenDyslexic',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007BFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF007BFF),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF007BFF),
          ),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Color(0xFF007BFF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF007BFF),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
      ),

      // ─────── Dark Theme (fallback) ───────
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B4B8A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1C),
          foregroundColor: Colors.white,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Color(0xFFB89EFF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFFB89EFF),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          color: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFDDDDDD)),
        ),
      ),

      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
