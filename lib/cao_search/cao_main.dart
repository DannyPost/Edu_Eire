import 'package:flutter/material.dart';
import 'home_page.dart';
import 'cao_search_page.dart';

void main() {
  runApp(const CAOApp());
}

class CAOApp extends StatelessWidget {
  const CAOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAO App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/cao-search': (context) => const CAOSearchPage(),
      },
    );
  }
}
