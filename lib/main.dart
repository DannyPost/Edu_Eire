import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Provider + StudyBot DI / Notifiers
import 'package:provider/provider.dart';
import 'studybot/di.dart';
import 'studybot/state/chat/chat_notifier.dart';
import 'studybot/state/grade/grade_notifier.dart';
import 'studybot/state/exemplar/exemplar_notifier.dart';

// Pages
import 'homepage.dart';
import '../auth/student_auth_page.dart';
import '../auth/business_pending_page.dart';

import 'calendar/notification_service.dart';

const kPrimaryColor = Color(0xFF3AB6FF);
const kSecondaryColor = Colors.white;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load dedicated env for homepage/news
  // Put HOMEPAGE_CACHE_URL in: app.env
  try {
    await dotenv.load(fileName: 'app.env');
  } catch (e) {
    debugPrint('[dotenv] Failed to load app.env: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final isDyslexicFont = prefs.getBool('isDyslexicFont') ?? false;

  runApp(MyApp(
    isDarkMode: isDarkMode,
    isDyslexicFont: isDyslexicFont,
  ));
}

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

  late final StudyBotDI _di;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _isDyslexicFont = widget.isDyslexicFont;
    _di = StudyBotDI.dev();
  }

  @override
  void dispose() {
    _di.dispose();
    super.dispose();
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatNotifier>.value(value: _di.chatNotifier),
        ChangeNotifierProvider<GradeNotifier>.value(value: _di.gradeNotifier),
        ChangeNotifierProvider<ExemplarNotifier>.value(value: _di.exemplarNotifier),
      ],
      child: MaterialApp(
        title: 'Edu Éire',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            brightness: Brightness.light,
          ).copyWith(secondary: kSecondaryColor),
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: kSecondaryColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryColor,
            foregroundColor: kSecondaryColor,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: kPrimaryColor,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: _isDyslexicFont ? 'OpenDyslexic' : null,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            brightness: Brightness.dark,
          ).copyWith(secondary: kSecondaryColor),
          primaryColor: kPrimaryColor,
          appBarTheme: const AppBarTheme(backgroundColor: kPrimaryColor),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: kPrimaryColor,
          ),
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: AuthGate(
          isDarkMode: _isDarkMode,
          isDyslexicFont: _isDyslexicFont,
          setDarkMode: _toggleTheme,
          setDyslexicFont: _toggleDyslexicFont,
        ),
      ),
    );
  }
}

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

  Future<_RoleState> _determineRole(User user) async {
    final stuDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
    if (stuDoc.exists) return _RoleState.student;

    final bizDoc = await FirebaseFirestore.instance.collection('businesses').doc(user.uid).get();
    if (bizDoc.exists) {
      final approved = bizDoc.data()?['approved'] == true;
      return approved ? _RoleState.business : _RoleState.businessPending;
    }

    return _RoleState.unknown;
  }
}

enum _RoleState { student, business, businessPending, unknown }