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
        'title': 'Steve Jobs Quote',
        'subtitle': '“The only way to do great work is to love what you do.”',
        'url': 'https://www.youtube.com/watch?v=UF8uR6Z6KLc',
        'category': 'Wellness',
      },
      {
        'title': 'Atomic Habits Summary',
        'subtitle': 'Small changes lead to remarkable results.',
        'url': 'https://jamesclear.com/atomic-habits-summary',
        'category': 'Wellness',
      },
      {
        'title': 'Top Productivity Techniques',
        'subtitle': 'Pomodoro, Deep Work, and More',
        'url': 'https://todoist.com/productivity-methods',
        'category': 'Wellness',
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
      return const Center(child: Text('No motivation items match your filters.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              item['title']!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              item['subtitle']!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => onTap(item['url']!),
          ),
        );
      },
    );
  }
}
