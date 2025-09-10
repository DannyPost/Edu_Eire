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

import 'calendar/notification_service.dart';

//import 'organizer/organizer_dashboard.dart'; 

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
        // 👇 send everything through the AuthGate first
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
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) return const StudentAuthPage();

        return FutureBuilder<_RoleState>(
          future: _determineRole(user),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            switch (roleSnap.data) {
              case _RoleState.organizer:
                return const OrganizerDashboard();

            case _RoleState.organizerPending:
              return const OrganizerPendingPage();

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
                FirebaseAuth.instance.signOut();
                return const StudentAuthPage();
            }
          },
        );
      },
    );
  }

  /* -----------------------------------------------------
     Query Firestore / claims to learn the user role
     ----------------------------------------------------- */
Future<_RoleState> _determineRole(User user) async {
  // 0) Claims-based organizer check (if you're using custom claims)
  await user.getIdToken(true);
  final claims = (await user.getIdTokenResult()).claims ?? {};
  final role = claims['role'];
  final orgId = claims['orgId'];
  if (role == 'organizer' && orgId is String && orgId.isNotEmpty) {
    return _RoleState.organizer;
  }

  // 1) Organizer by Firestore doc (APPROVED OR PENDING)
  final orgDoc = await FirebaseFirestore.instance
      .collection('organizers')        // <-- make sure this matches your collection name
      .doc(user.uid)
      .get();
  if (orgDoc.exists) {
    final approved = orgDoc.data()?['approved'] == true;
    return approved ? _RoleState.organizer : _RoleState.organizerPending;
  }

  // 2) Student?
  final stuDoc = await FirebaseFirestore.instance
      .collection('students').doc(user.uid).get();
  if (stuDoc.exists) return _RoleState.student;

  // 3) Business?
  final bizDoc = await FirebaseFirestore.instance
      .collection('businesses').doc(user.uid).get();
  if (bizDoc.exists) {
    final approved = bizDoc.data()?['approved'] == true;
    return approved ? _RoleState.business : _RoleState.businessPending;
  }

  // 4) Unknown
  return _RoleState.unknown;
}


}

// enum _RoleState { student, business, businessPending, unknown }
enum _RoleState { student, business, businessPending, organizer, organizerPending, unknown }

/* ──────────────────────────────────────────────────────────────
   Inlined Organizer Dashboard (moved here from separate file)
   ────────────────────────────────────────────────────────────── */
class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organizer Dashboard')),
      body: const Center(
        child: Text('Create, edit, and publish events for your organization.'),
      ),
    );
  }
}


class OrganizerPendingPage extends StatelessWidget {
  const OrganizerPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organizer sign-up')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 96),
              SizedBox(height: 16),
              Text(
                "We’re verifying your organizer account.\nYou’ll get an e-mail when approved.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
