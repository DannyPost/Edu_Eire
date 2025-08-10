import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pages
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
import 'studybot/app/study_bot_screen.dart';

import '../help_page/help_main.dart';
import '../help_page/help/help_page.dart';

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
  bool _dys  = false;
  int  _idx  = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Color get _brand => Theme.of(context).primaryColor;

  @override
  void initState() {
    super.initState();
    _dark = widget.isDarkMode;
    _dys  = widget.isDyslexicFont;
  }

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

  /* --------------------- Page lists --------------------- */
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
    const EducationNewsFeed(),
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
    const StudyBotScreen(),

  ];

  /* ------------------------- UI ------------------------- */
  @override
  Widget build(BuildContext context) {
    final isBiz = widget.role == 'business';
    final pages = isBiz ? _bizPages : _stdPages;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _brand,
        centerTitle: true,
        title: const Text('Edu Éire'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: isBiz ? _bizDrawer(context) : _stdDrawer(context),
      body: IndexedStack(index: _idx, children: pages),
    );
  }

  /* ---------------- Business drawer ---------------- */
  Drawer _bizDrawer(BuildContext ctx) => Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: _brand),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'Business',
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
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
      case 0:
        return Icon(Icons.settings, color: _brand);
      case 1:
        return Icon(Icons.help, color: _brand);
      case 2:
        return Icon(Icons.local_offer, color: _brand);
      case 3:
        return Icon(Icons.dashboard, color: _brand);
      default:
        return const Icon(Icons.circle);
    }
  }

  /* ---------------- Student drawer ---------------- */
  Drawer _stdDrawer(BuildContext ctx) => Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: _brand),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text('Edu Éire Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ),
            _drawerItem(ctx, Icons.home, 'Home', 0),
            _drawerItem(ctx, Icons.settings, 'Settings', 1),
            _drawerItem(ctx, Icons.chat, 'Chatbot', 2),
            _drawerItem(ctx, Icons.local_offer, 'Deals', 3),
            _drawerItem(ctx, Icons.calculate, 'SUSI Calculator', 4),
            _drawerItem(ctx, Icons.school, 'HEAR Calculator', 5),
            _drawerItem(ctx, Icons.accessibility_new, 'DARE Calculator', 6),
            _drawerItem(ctx, Icons.calendar_today, 'School Calendar', 7),
            _drawerItem(ctx, Icons.school, 'Study-Bot', 8),     // add to drawer

            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('CAO Search'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => CAOSearchPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: _brand),
              title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(ctx, MaterialPageRoute(builder: (_) => HelpPage()));
              },
            ),
          ],
        ),
      );

  ListTile _drawerItem(BuildContext ctx, IconData icon, String title, int index) => ListTile(
        leading: Icon(icon, color: index == _idx ? _brand : null),
        title: Text(title),
        selected: _idx == index,
        selectedTileColor: Colors.grey[200],
        onTap: () {
          Navigator.pop(ctx);
          setState(() => _idx = index);
        },
      );
}
