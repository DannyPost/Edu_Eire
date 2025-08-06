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
        'title': 'Effective Study Techniques',
        'subtitle': 'Learn how to study smarter, not harder.',
        'url': 'https://www.usa.edu/blog/study-techniques/',
        'category': 'Study Skills',
      },
      {
        'title': 'Time Management for Students',
        'subtitle': 'Master your schedule with these strategies.',
        'url': 'https://summer.harvard.edu/blog/8-time-management-tips-for-students/#1-Create-a-Calendar',
        'category': 'Study Skills',
      },
      {
        'title': 'Exam Preparation Tips',
        'subtitle': 'Maximise focus and retention.',
        'url': 'https://summer.harvard.edu/blog/14-tips-for-test-taking-success/',
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
              Icons.menu_book_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => onTap(item['url']!),
          ),
        );
      },
    );
  }
}
