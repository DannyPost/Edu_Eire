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
        'url': 'https://www.amazon.ie/?ie=UTF8&tag=ietxtgostdde-21&hvadid=737904687346&hvpos=&hvexid=&hvnetw=g&hvrand=15114109918566190328&hvpone=&hvptwo=&hvqmt=b&hvdev=c&ref=pd_sl_6wv23rk26_e&tag=&ref=&adgrpid=176676570216&hvpone=&hvptwo=&hvadid=737904687346&hvpos=&hvnetw=g&hvrand=15114109918566190328&hvqmt=b&hvdev=c&hvdvcmdl=&hvlocint=&hvlocphy=1007850&hvtargid=kwd-10837581&hydadcr=&mcid=&gad_source=1&gad_campaignid=22324148786&gbraid=0AAAAA-dyU7qeZJN_UyXlPzMzlcckyvy3W&gclid=EAIaIQobChMIsfjHp9DdjgMV95NQBh0-rCevEAAYASAAEgJVV_D_BwE',
        'category': 'Deals',
      },
      {
        'title': 'Dominos',
        'subtitle': 'Student meal deals',
        'url': 'https://www.dominos.ie/',
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
              Icons.local_offer_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => onTap(item['url']!),
          ),
        );
      },
    );
  }
}
