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
        'title': 'All Ireland Scholarships',
        'subtitle': 'Comprehensive list of scholarships across Ireland',
        'url': 'https://www.allirelandscholarships.com/',
        'category': 'Scholarships',
      },
      {
        'title': 'Erasmus+',
        'subtitle': 'Study abroad opportunities in Europe',
        'url': 'https://erasmus-plus.ec.europa.eu/opportunities',
        'category': 'Scholarships',
      },
      {
        'title': 'HEAR Scheme',
        'subtitle': 'Access route for socio-economically disadvantaged students',
        'url': 'https://accesscollege.ie/hear/',
        'category': 'Scholarships',
      },
      {
        'title': 'Refugee Education',
        'subtitle': 'Support for refugees in higher education',
        'url':
            'https://www.irishrefugeecouncil.ie/listing/category/education',
        'category': 'Scholarships',
      },
      {
        'title': 'University Scholarships',
        'subtitle': 'Scholarships offered by individual universities',
        'url': 'https://careersportal.ie/scholarships',
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
