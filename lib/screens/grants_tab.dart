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
    final sample = <Map<String, String>>[
      {
        'title': 'DARE Scheme',
        'subtitle': 'Disability Access Route to Education',
        'url': 'https://accesscollege.ie/dare/what-is-dare/',
        'category': 'Disability',
      },
      {
        'title': '1916 Bursary Fund',
        'subtitle': 'Financial support for disadvantaged students',
        'url': 'https://1916bursary.ie/',
        'category': 'Financial',
      },
      {
        'title': 'HEAR Scheme',
        'subtitle':
            'Reduced points for school leavers from socio-economically disadvantaged backgrounds',
        'url': 'https://accesscollege.ie/hear/',
        'category': 'Financial',
      },
      {
        'title': 'SUSI Grant',
        'subtitle': 'Ireland’s national awarding authority for further education',
        'url': 'https://susi.ie/',
        'category': 'Financial',
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
      return const Center(child: Text('No grants match your filters.'));
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
              Icons.open_in_new,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => onTap(item['url']!),
          ),
        );
      },
    );
  }
}
