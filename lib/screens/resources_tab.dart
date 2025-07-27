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
        'url': 'https://www2.hse.ie/mental-health/services-support/supports-services/',
        'category': 'Wellness',
      },
      {
        'title': 'Writing Center',
        'subtitle': 'Help with essays and academic writing',
        'url': 'https://info.writetheworld.org/teaching-writing-resources?utm_term=&utm_campaign=AI+Writing&utm_source=adwords&utm_medium=ppc&hsa_acc=8591759309&hsa_cam=22436731428&hsa_grp=&hsa_ad=&hsa_src=x&hsa_tgt=&hsa_kw=&hsa_mt=&hsa_net=adwords&hsa_ver=3&gad_source=1&gad_campaignid=22436738868&gbraid=0AAAAAp_bUaRkAiHd8hoNarQNlg9RtQDnM&gclid=EAIaIQobChMIjcHRl87djgMVd4FQBh1IYCMXEAAYAiAAEgIDWPD_BwE',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
