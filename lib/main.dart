import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import 'package:shared_preferences/shared_preferences.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Pages
import 'homepage.dart';
import '../auth/student_auth_page.dart';
import '../auth/business_pending_page.dart';

import 'calendar/notification_service.dart';


/* ──────────────────────────────────────────────────────────────
   Global brand colours
   ────────────────────────────────────────────────────────────── */
const kPrimaryColor   = Color(0xFF3AB6FF); // bright blue
const kSecondaryColor = Colors.white;      // accent / onPrimary

/* ──────────────────────────────────────────────────────────────
   Entry point
   ────────────────────────────────────────────────────────────── */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // 🆕 Initialize notification service
  await NotificationService.init();
  
  // Local prefs -------------------------------------------------------
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode     = prefs.getBool('isDarkMode')     ?? false;
  final isDyslexicFont = prefs.getBool('isDyslexicFont') ?? false;

  runApp(MyApp(
    isDarkMode:     isDarkMode,
    isDyslexicFont: isDyslexicFont,
  ));
}

/* ──────────────────────────────────────────────────────────────
   Root widget – holds user preferences (theme + font)
   ────────────────────────────────────────────────────────────── */
class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final bool isDyslexicFont;

  const MyApp({super.key, required this.isDarkMode, required this.isDyslexicFont});

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
  Widget build(BuildContext context) => MaterialApp(
        title: 'Edu Éire',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            brightness: Brightness.light,
          ).copyWith(
            secondary: kSecondaryColor,
          ),
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: kSecondaryColor,
          appBarTheme: const AppBarTheme(backgroundColor: kPrimaryColor, foregroundColor: kSecondaryColor),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: kPrimaryColor),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            brightness: Brightness.dark,
          ).copyWith(
            secondary: kSecondaryColor,
          ),
          primaryColor: kPrimaryColor,
          appBarTheme: const AppBarTheme(backgroundColor: kPrimaryColor),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: kPrimaryColor),
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        // 👇 NEW – send everything through the AuthGate first
        home: AuthGate(
          isDarkMode: _isDarkMode,
          isDyslexicFont: _isDyslexicFont,
          setDarkMode: _toggleTheme,
          setDyslexicFont: _toggleDyslexicFont,
        ),
      );
}

/* ──────────────────────────────────────────────────────────────
   AuthGate – decides what the first real page should be
   ────────────────────────────────────────────────────────────── */
class AuthGate extends StatelessWidget {
  final bool isDarkMode;
  final bool isDyslexicFont;
  final void Function(bool) setDarkMode;
  final void Function(bool) setDyslexicFont;

  const AuthGate({
    super.key,
    required this.isDarkMode,
    required this.isDyslexicFont,
    required this.setDarkMode,
    required this.setDyslexicFont,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // 1️⃣ Waiting for Firebase to emit the first auth state
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2️⃣ No user -> go straight to the login/ signup flow
        final user = snap.data;
        if (user == null) return const StudentAuthPage();

        // 3️⃣ We *do* have a user – figure out what type they are
        return FutureBuilder<_RoleState>(
          future: _determineRole(user),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            switch (roleSnap.data) {
              case _RoleState.student:
                return HomePage(
                  isDarkMode: isDarkMode,
                  isDyslexicFont: isDyslexicFont,
                  role: 'student',
                  setDarkMode: setDarkMode,
                  setDyslexicFont: setDyslexicFont,
                );
              case _RoleState.business:
                return HomePage(
                  isDarkMode: isDarkMode,
                  isDyslexicFont: isDyslexicFont,
                  role: 'business',
                  setDarkMode: setDarkMode,
                  setDyslexicFont: setDyslexicFont,
                );
              case _RoleState.businessPending:
                return const BusinessPendingPage();
              case _RoleState.unknown:
              default:
                // Fallback – sign the user out & go to login
                FirebaseAuth.instance.signOut();
                return const StudentAuthPage();
            }
          },
        );
      },
    );
  }

  /* -----------------------------------------------------
     Query Firestore to learn what *kind* of user we have
     ----------------------------------------------------- */
  Future<_RoleState> _determineRole(User user) async {
    // Students ------------------------------------------------------
    final stuDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
    if (stuDoc.exists) return _RoleState.student;

    // Businesses ----------------------------------------------------
    final bizDoc = await FirebaseFirestore.instance.collection('businesses').doc(user.uid).get();
    if (bizDoc.exists) {
      final approved = bizDoc.data()?['approved'] == true;
      return approved ? _RoleState.business : _RoleState.businessPending;
    }

    return _RoleState.unknown;
  }
}

enum _RoleState { student, business, businessPending, unknown }
>>>>>>> e0b4353cf7ba5b3fecaec3524f9d21f0f5e54769
