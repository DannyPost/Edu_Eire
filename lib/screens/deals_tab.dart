import 'package:flutter/material.dart';

class DealsTab extends StatelessWidget {
  final void Function(String) onTap;
  final String searchQuery;
  final Set<String> categories;

  const DealsTab({
    required this.onTap,
    required this.searchQuery,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sample = <Map<String, String>>[
      {
        'title': 'Amazon',
        'subtitle': '10% off for NCI students',
        'url': 'https://amazon.com/student-deals',
        'category': 'Deals',
      },
      {
        'title': 'Dominos',
        'subtitle': 'Student meal deals',
        'url': 'https://dominos.ie/student',
        'category': 'Deals',
      },
      {
        'title': 'Spotify',
        'subtitle': '50% student discount on Premium',
        'url': 'https://spotify.com/student',
        'category': 'Deals',
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
      return const Center(child: Text('No deals match your filters.'));
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
