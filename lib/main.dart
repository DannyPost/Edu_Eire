import 'package:flutter/material.dart';
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

/* ──────────────────────────────────────────────────────────────
   Entry point
   ────────────────────────────────────────────────────────────── */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
          brightness: Brightness.light,
          fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue, brightness: Brightness.light),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue, brightness: Brightness.dark),
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
