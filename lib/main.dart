import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 👇 NEW  — core & the generated platform keys
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  // REQUIRED: initialise Firebase exactly once before any plugin usage
  // ------------------------------------------------------------------
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Local prefs -------------------------------------------------------
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode      = prefs.getBool('isDarkMode')     ?? false;
  final isDyslexicFont  = prefs.getBool('isDyslexicFont') ?? false;

  runApp(MyApp(
    isDarkMode:      isDarkMode,
    isDyslexicFont:  isDyslexicFont,
  ));
}

/* ──────────────────────────────────────────────────────────────
   everything below this line is unchanged — your original code
   ────────────────────────────────────────────────────────────── */

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final bool isDyslexicFont;

  const MyApp({
    super.key,
    required this.isDarkMode,
    required this.isDyslexicFont,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  late bool _isDyslexicFont;

  @override
  void initState() {
    super.initState();
    _isDarkMode     = widget.isDarkMode;
    _isDyslexicFont = widget.isDyslexicFont;
  }

  Future<void> _toggleTheme(bool v) async {
    setState(() => _isDarkMode = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', v);
  }

  Future<void> _toggleDyslexicFont(bool v) async {
    setState(() => _isDyslexicFont = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDyslexicFont', v);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edu Éire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        isDarkMode: _isDarkMode,
        isDyslexicFont: _isDyslexicFont,
        role: 'student', // or 'business' based on your login flow!
        setDarkMode: _toggleTheme,
        setDyslexicFont: _toggleDyslexicFont,
      ),
    );
  }
}
