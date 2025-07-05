// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Feature Imports
import 'homepage/widgets/education_news_feed.dart';
import 'settings/settings_page.dart';
import 'chatbot/screens/chat_screen.dart';
import 'susi_calculator/susi_calculator.dart';
import 'hear_calculator/hear_calculator.dart';
import 'dare_calculator/dare_calculator.dart';
import 'calendar/calendar.dart'; // ✅ School Calendar
import 'cao_search/cao_search.dart'; // This should contain your CoursePage


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'chatbot_api.env');
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
      const EducationNewsFeed(), // 0
      SettingsPage( // 1
        toggleTheme: _toggleTheme,
        isDarkMode: _isDarkMode,
        toggleDyslexicFont: _toggleDyslexicFont,
        isDyslexicFont: _isDyslexicFont,
      ),
      const ChatScreen(),        // 2
      const GrantCalculatorPage(),   // 3
      HearCalculatorPage(),     // 4
      DareCalculatorPage(),     // 5
      const CalendarPage(),     // 6 ✅ School Calendar
    ];

    return MaterialApp(
      title: 'Edu Eire App',
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
              // Use Builder for each ListTile that performs navigation/state change
              Builder(
                builder: (innerContext) { // Use innerContext for navigation
                  return ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Chatbot'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('SUSI Calculator'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('HEAR Calculator'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.accessibility_new),
                    title: const Text('DARE Calculator'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('School Calendar'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
                      });
                      Navigator.pop(innerContext);
                    },
                  );
                },
              ),
              // The CAO Search button (already correctly using Builder)
              Builder(
                builder: (innerContext) {
                  return ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('CAO Search'),
                    onTap: () {
                      Navigator.pop(innerContext); // close the drawer first
                      Navigator.push(
                        innerContext, // Use the innerContext here
                        MaterialPageRoute(
                          builder: (context) => const CoursePage(),
                        ),
                      );
                    },
                  );
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