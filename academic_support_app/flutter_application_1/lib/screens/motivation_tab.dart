import 'package:flutter/material.dart';

class MotivationTab extends StatelessWidget {
  final void Function(String) onTap;
  final String searchQuery;
  final Set<String> categories;

  const MotivationTab({
    required this.onTap,
    required this.searchQuery,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sample = <Map<String, String>>[
      {
        'title':
            '“Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing.”',
        'subtitle': '',
        'category': 'Wellness',
      },
      {
        'title': '“Believe you can and you’re halfway there.”',
        'subtitle': '',
        'category': 'Wellness',
      },
      {
        'title': 'Watch a motivational video',
        'subtitle': '',
        'url': 'https://www.youtube.com/watch?v=uKr_Cc_Ytfo',
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
      return const Center(child: Text('No motivational items found.'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: filtered.map((item) {
        final hasUrl = item.containsKey('url');
        return Card(
          child: ListTile(
            title: Text(item['title']!),
            trailing:
                hasUrl ? const Icon(Icons.open_in_new) : const SizedBox(),
            onTap: hasUrl ? () => onTap(item['url']!) : null,
          ),
        );
      }).toList(),
    );
  }
}
