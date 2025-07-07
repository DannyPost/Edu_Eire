import 'package:flutter/material.dart';

class GrantsTab extends StatelessWidget {
  final void Function(String) onTap;
  final String searchQuery;
  final Set<String> categories;

  const GrantsTab({
    required this.onTap,
    required this.searchQuery,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Sample data with a 'category' field
    final sample = <Map<String, String>>[
      {
        'title': 'DARE Scheme',
        'subtitle': 'Disability Access Route to Education',
        'url': 'https://accesscollege.ie/',
        'category': 'Disability',
      },
      {
        'title': '1916 Bursary Fund',
        'subtitle': 'Financial support for disadvantaged students',
        'url': 'https://susi.ie/',
        'category': 'Financial',
      },
      {
        'title': 'HEAR Scheme',
        'subtitle':
            'Reduced points for school leavers from socio-economically disadvantaged backgrounds',
        'url': 'https://hea.ie/funding-and-student-finance/',
        'category': 'Financial',
      },
      {
        'title': 'SUSI Grant',
        'subtitle': 'Ireland’s national awarding authority for further education',
        'url': 'https://susi.ie/',
        'category': 'Financial',
      },
    ];

    // 2) Filter by search & categories
    final filtered = sample.where((item) {
      final text = (item['title']! + ' ' + item['subtitle']!).toLowerCase();
      if (searchQuery.isNotEmpty &&
          !text.contains(searchQuery.toLowerCase())) {
        return false;
      }
      if (categories.isNotEmpty &&
          !categories.contains(item['category']!)) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No grants match your filters.'));
    }

    // 3) Build list
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: filtered.map((item) {
        return Card(
          child: ListTile(
            title: Text(item['title']!),
            subtitle: Text(item['subtitle']!),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => onTap(item['url']!),
          ),
        );
      }).toList(),
    );
  }
}
