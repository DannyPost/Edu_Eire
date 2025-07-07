import 'package:flutter/material.dart';
import 'package:academic_support_app/screens/grants_tab.dart';
import 'package:academic_support_app/screens/motivation_tab.dart';
import 'package:academic_support_app/screens/resources_tab.dart';
import 'package:academic_support_app/screens/deals_tab.dart';
import 'package:academic_support_app/screens/scholarships_tab.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicSupportScreen extends StatefulWidget {
  const AcademicSupportScreen({super.key});

  @override
  State<AcademicSupportScreen> createState() => _AcademicSupportScreenState();
}

class _AcademicSupportScreenState extends State<AcademicSupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ─────── Search & Filter State ───────
  String _searchQuery = '';
  final Set<String> _activeCategories = {};
  final List<String> _allCategories = [
    'Disability',
    'Financial',
    'Wellness',
    'Study Skills',
    'Deals',
    'Scholarships',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ─────── A) Branded Header ───────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.jpeg', height: 48),
                  const SizedBox(width: 16),
                  const Text(
                    'EduEire Academic Support',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Grants'),
              Tab(text: 'Motivation'),
              Tab(text: 'Resources'),
              Tab(text: 'Deals'),
              Tab(text: 'Scholarships'),
            ],
          ),
        ),
      ),

      // ─────── B) Body ───────
      body: Column(
        children: [
          // 1) Global Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search grants, quotes, resources…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (text) => setState(() => _searchQuery = text),
            ),
          ),

          // 2) Category Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _allCategories.map((cat) {
                final selected = _activeCategories.contains(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (on) {
                      setState(() {
                        if (on) _activeCategories.add(cat);
                        else _activeCategories.remove(cat);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 3) Hero “Welcome” Card
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.jpeg', height: 64),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome to EduEire Academic Support!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your one-stop guide to grants, scholarships, resources & student deals.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // 4) Tab Views (now passing the new parameters!)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                GrantsTab(
                  onTap: (url) => launchUrl(Uri.parse(url)),
                  searchQuery: _searchQuery,
                  categories: _activeCategories,
                ),
                MotivationTab(
                  onTap: (url) => launchUrl(Uri.parse(url)),
                  searchQuery: _searchQuery,
                  categories: _activeCategories,
                ),
                ResourcesTab(
                  onTap: (url) => launchUrl(Uri.parse(url)),
                  searchQuery: _searchQuery,
                  categories: _activeCategories,
                ),
                DealsTab(
                  onTap: (url) => launchUrl(Uri.parse(url)),
                  searchQuery: _searchQuery,
                  categories: _activeCategories,
                ),
                ScholarshipsTab(
                  onTap: (url) => launchUrl(Uri.parse(url)),
                  searchQuery: _searchQuery,
                  categories: _activeCategories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
