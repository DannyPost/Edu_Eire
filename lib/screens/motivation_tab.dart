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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final hasUrl = item.containsKey('url');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              item['title']!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: !hasUrl ? FontStyle.italic : FontStyle.normal,
                    fontWeight: hasUrl ? FontWeight.w600 : FontWeight.w400,
                    fontSize: hasUrl ? 15 : 14,
                  ),
            ),
            trailing: hasUrl
                ? Icon(Icons.ondemand_video,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: hasUrl ? () => onTap(item['url']!) : null,
          ),
        );
      },
    );
  }
}
