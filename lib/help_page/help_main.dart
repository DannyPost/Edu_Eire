import 'package:flutter/material.dart';
import 'help/help_page.dart';
import 'firebase_options.dart';                // Make sure this is present!
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase initialization

void main() async {
  WidgetsFlutterBinding.ensureInitialized();      // Always required for async main
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
      title: 'Help Page Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: HelpPage(),
    );
  }
}
