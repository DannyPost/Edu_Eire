import 'package:flutter/material.dart';

class ResourcesTab extends StatelessWidget {
  final void Function(String) onTap;
  final String searchQuery;
  final Set<String> categories;

  const ResourcesTab({
    required this.onTap,
    required this.searchQuery,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sample = <Map<String, String>>[
      {
        'title': 'Mental Health Support',
        'subtitle': 'Student wellness resources and counselling',
        'url': 'https://studentsupport.ie/mental-health',
        'category': 'Wellness',
      },
      {
        'title': 'Writing Center',
        'subtitle': 'Help with essays and academic writing',
        'url': 'https://writingcentre.university.ie/',
        'category': 'Study Skills',
      },
    ];

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
      return const Center(child: Text('No resources match your filters.'));
    }

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
