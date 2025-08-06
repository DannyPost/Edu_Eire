import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicTab extends StatefulWidget {
  const AcademicTab({super.key});

  @override
  State<AcademicTab> createState() => _AcademicTabState();
}

class _AcademicTabState extends State<AcademicTab> {
  final List<Map<String, dynamic>> _supportItems = [
    {
      'title': 'Learning Support Service',
      'description':
          'Help with writing, reading, researching, note-taking, and more.\n📅 Tuesdays: 3–6pm\n📅 Wednesdays: 1–3pm\n📧 studentsupport@ncirl.ie',
      'icon': Icons.menu_book,
      'group': 'Study Supports',
    },
    {
      'title': 'Mathematics Support',
      'description':
          'Resources and help for numeracy modules across business, computing, and science courses.',
      'icon': Icons.calculate,
      'group': 'Study Supports',
    },
    {
      'title': 'Computing Support',
      'description':
          'Help via Moodle for programming, software dev, and core computing modules.',
      'icon': Icons.computer,
      'group': 'Study Supports',
    },
    {
      'title': 'Disability Supports – DARE',
      'description':
          'Support for students with disabilities including equipment and learning adjustments.',
      'icon': Icons.accessibility_new,
      'group': 'Inclusion & Accessibility',
    },
    {
      'title': 'HEAR Scheme',
      'description':
          'Support route for students from disadvantaged backgrounds with reduced points access.',
      'icon': Icons.groups_2,
      'group': 'Inclusion & Accessibility',
    },
    {
      'title': 'SUSI – Student Grants',
      'description':
          'Apply April–November for financial support with fees and expenses.',
      'icon': Icons.school,
      'group': 'Funding',
    },
    {
      'title': 'Scholarships & Bursaries',
      'description':
          'Explore scholarships for academic, sports, and subject-specific excellence.',
      'icon': Icons.volunteer_activism,
      'group': 'Funding',
    },
  ];

  final Set<int> _expandedIndices = {};

  void _openQuickAccessPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 16,
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.deepPurple),
                title: const Text('Email Student Support'),
                onTap: () {
                  launchUrl(Uri.parse('mailto:studentsupport@ncirl.ie'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.deepPurple),
                title: const Text('Apply for SUSI Grant'),
                onTap: () {
                  launchUrl(Uri.parse('https://susi.ie'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.calculate, color: Colors.deepPurple),
                title: const Text('Book Math Support'),
                onTap: () {
                  launchUrl(Uri.parse('https://studentsupport.ie/math-support'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.accessibility, color: Colors.deepPurple),
                title: const Text('Disability Supports'),
                onTap: () {
                  launchUrl(Uri.parse('https://accesscollege.ie/dare/'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<Map<String, dynamic>>>{};

    for (final item in _supportItems) {
      final group = item['group'] as String;
      groupedItems.putIfAbsent(group, () => []).add(item);
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: groupedItems.entries.expand((entry) {
          final groupName = entry.key;
          final items = entry.value;

          return [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            ...items.asMap().entries.map((entryMap) {
              final index = _supportItems.indexOf(entryMap.value);
              final item = entryMap.value;
              final isExpanded = _expandedIndices.contains(index);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(item['icon'], color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              item['description'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),
          ];
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickAccessPanel,
        label: const Text('Quick Access'),
        icon: const Icon(Icons.flash_on),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
