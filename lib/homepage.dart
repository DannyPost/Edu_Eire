import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'academic_support/academic_tab.dart';
import 'academic_support/motivation_tab.dart';
import 'academic_support/resources_tab.dart';
import 'academic_support/scholarships_tab.dart';
import 'screens/deals_tab.dart';
import 'screens/grants_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabController;

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
    _tabController = TabController(length: 6, vsync: this);
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EduEire Hub'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Academic'),
              Tab(text: 'Deals'),
              Tab(text: 'Grants'),
              Tab(text: 'Motivation'),
              Tab(text: 'Resources'),
              Tab(text: 'Scholarships'),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF007BFF)),
                child: Text(
                  'EduEire Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ...List.generate(6, (index) {
                final labels = [
                  'Academic Support',
                  'Student Deals',
                  'Grants',
                  'Motivation',
                  'Resources',
                  'Scholarships',
                ];
                final icons = [
                  Icons.school,
                  Icons.local_offer,
                  Icons.attach_money,
                  Icons.lightbulb,
                  Icons.menu_book,
                  Icons.star,
                ];
                return ListTile(
                  leading: Icon(icons[index]),
                  title: Text(labels[index]),
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(index);
                  },
                );
              }),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
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

            // Category filter chips
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
                          if (on) {
                            _activeCategories.add(cat);
                          } else {
                            _activeCategories.remove(cat);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const AcademicTab(),
                  DealsTab(
                    onTap: _launchURL,
                    searchQuery: _searchQuery,
                    categories: _activeCategories,
                  ),
                  GrantsTab(
                    onTap: _launchURL,
                    searchQuery: _searchQuery,
                    categories: _activeCategories,
                  ),
                  MotivationTab(
                    onTap: _launchURL,
                    searchQuery: _searchQuery,
                    categories: _activeCategories,
                  ),
                  ResourcesTab(
                    onTap: _launchURL,
                    searchQuery: _searchQuery,
                    categories: _activeCategories,
                  ),
                  ScholarshipsTab(
                    onTap: _launchURL,
                    searchQuery: _searchQuery,
                    categories: _activeCategories,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
