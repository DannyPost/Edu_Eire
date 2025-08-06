import 'package:flutter/material.dart';

class ScholarshipsTab extends StatelessWidget {
  final void Function(String) onTap;
  final String searchQuery;
  final Set<String> categories;

  const ScholarshipsTab({
    required this.onTap,
    required this.searchQuery,
    required this.categories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sample = <Map<String, String>>[
      {
        'title': 'Trinity Entrance Scholarships',
        'subtitle': 'Scholarships for top Leaving Cert students.',
        'url': 'https://www.tcd.ie/study/undergraduate/scholarships/entrance/',
        'category': 'Scholarships',
      },
      {
        'title': 'NCI Scholarships',
        'subtitle': 'Merit-based and needs-based scholarships.',
        'url': 'https://www.ncirl.ie/Future-Students/Scholarships',
        'category': 'Scholarships',
      },
      {
        'title': 'UCD Global Scholarships',
        'subtitle': 'Funding for international students.',
        'url': 'https://www.ucd.ie/global/scholarships/',
        'category': 'Scholarships',
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
      return const Center(child: Text('No scholarships match your filters.'));
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
              Icons.school_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => onTap(item['url']!),
          ),
        );
      },
    );
  }
}
