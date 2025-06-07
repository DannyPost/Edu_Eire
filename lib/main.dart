import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'homepage/widgets/education_news_feed.dart';
import 'settings/settings_page.dart';
import 'chatbot/screens/chat_screen.dart'; // ✅ Chatbot page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _isDyslexicFont = widget.isDyslexicFont;
  }

  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('isDarkMode', value);
  }

  void _toggleDyslexicFont(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDyslexicFont = value;
    });
    await prefs.setBool('isDyslexicFont', value);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const EducationNewsFeed(),
      SettingsPage(
        toggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
        toggleDyslexicFont: _toggleDyslexicFont,
        isDyslexicFont: _isDyslexicFont,
      ),
      const ChatScreen(), // ✅ Chatbot page
    ];

    return MaterialApp(
      title: 'Edu Eire App',
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Edu Eire App'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.lightBlue,
                ),
                child: Center(
                  child: Text(
                    'Edu Eire Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                  Navigator.pop(context); // Close drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                  Navigator.pop(context); // Close drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Chatbot'),
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                  Navigator.pop(context); // Close drawer
                },
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
    );
  }
}
