import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your actual pages
import 'homepage/widgets/education_news_feed.dart';
import 'settings/settings_page.dart';
import 'chatbot/screens/chat_screen.dart';
import 'studentdeals/studentdeals/student_deals_page.dart';
import 'studentdeals/admin/admin_dashboard_page.dart';
import 'susi_calculator/susi_calculator.dart';
import 'hear_calculator/hear_calculator.dart';
import 'dare_calculator/dare_calculator.dart';
import 'calendar/calendar.dart';
import 'cao_search/cao_search_page.dart';

const primaryColor = Color(0xFF0018EE);

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final bool isDyslexicFont;
  final String role; // 'student' | 'business'
  final void Function(bool) setDarkMode;
  final void Function(bool) setDyslexicFont;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.isDyslexicFont,
    required this.role,
    required this.setDarkMode,
    required this.setDyslexicFont,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dark = false;
  bool _dys = false;
  int _idx = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _dark = widget.isDarkMode;
    _dys = widget.isDyslexicFont;
  }

  // Callback relays for theme/font
  Future<void> _setDark(bool v) async {
    setState(() => _dark = v);
    widget.setDarkMode(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', v);
  }

  Future<void> _setFont(bool v) async {
    setState(() => _dys = v);
    widget.setDyslexicFont(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDyslexicFont', v);
  }

  // Pages for each role
  late final List<Widget> _bizPages = [
    SettingsPage(
      toggleTheme: _setDark,
      isDarkMode: _dark,
      toggleDyslexicFont: _setFont,
      isDyslexicFont: _dys,
    ),
    const ChatScreen(),
    const StudentDealsPage(),
    AdminDashboardPage(adminEmail: FirebaseAuth.instance.currentUser?.email ?? 'unknown'),
  ];

  late final List<String> _bizLabels = const [
    'Settings', 'Help', 'Deals', 'Dashboard'
  ];

  late final List<Widget> _stdPages = [
    const EducationNewsFeed(), // 0 Home
    SettingsPage(
      toggleTheme: _setDark,
      isDarkMode: _dark,
      toggleDyslexicFont: _setFont,
      isDyslexicFont: _dys,
    ),
    const ChatScreen(),
    const StudentDealsPage(),
    GrantCalculatorPage(),
    HearCalculatorPage(),
    DareCalculatorPage(),
    const CalendarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isBiz = widget.role == 'business';
    final pages = isBiz ? _bizPages : _stdPages;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text('Edu Éire'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: isBiz ? _bizDrawer(context) : _stdDrawer(context),
      body: IndexedStack(index: _idx, children: pages),
      // No bottomNavigationBar for either role
    );
  }

  // BUSINESS DRAWER
  Drawer _bizDrawer(BuildContext ctx) => Drawer(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28))),
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(FirebaseAuth.instance.currentUser?.email ?? 'Business',
                    style: const TextStyle(color: Colors.white, fontSize: 22)),
              ),
            ),
            for (int i = 0; i < _bizLabels.length; i++)
              ListTile(
                leading: _bizIcon(i),
                title: Text(_bizLabels[i], style: const TextStyle(fontWeight: FontWeight.w500)),
                selected: _idx == i,
                selectedTileColor: Colors.grey[200],
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _idx = i);
                },
              ),
          ],
        ),
      );

  Icon _bizIcon(int i) {
    switch (i) {
      case 0: return const Icon(Icons.settings, color: primaryColor);
      case 1: return const Icon(Icons.help, color: primaryColor);
      case 2: return const Icon(Icons.local_offer, color: primaryColor);
      case 3: return const Icon(Icons.dashboard, color: primaryColor);
      default: return const Icon(Icons.circle);
    }
  }

  // STUDENT DRAWER
  Drawer _stdDrawer(BuildContext ctx) => Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Edu Éire Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ),
            _drawerItem(Icons.home, 'Home', 0),
            _drawerItem(Icons.settings, 'Settings', 1),
            _drawerItem(Icons.chat, 'Chatbot', 2),
            _drawerItem(Icons.local_offer, 'Deals', 3),
            _drawerItem(Icons.calculate, 'SUSI Calculator', 4),
            _drawerItem(Icons.school, 'HEAR Calculator', 5),
            _drawerItem(Icons.accessibility_new, 'DARE Calculator', 6),
            _drawerItem(Icons.calendar_today, 'School Calendar', 7),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('CAO Search'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CAOSearchPage(),
                ));
              },
            ),
          ],
        ),
      );

  ListTile _drawerItem(IconData ico, String txt, int page) => ListTile(
        leading: Icon(ico),
        title: Text(txt),
        selected: _idx == page,
        selectedTileColor: Colors.grey[200],
        onTap: () {
          Navigator.pop(context);
          setState(() => _idx = page);
        },
      );
}
