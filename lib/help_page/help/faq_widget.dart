import 'package:flutter/material.dart';

class FAQItem {
  final String question;
  final String answer;
  const FAQItem({required this.question, required this.answer});
}

/// FAQWidget displays a card containing an ExpansionTile for each FAQ item.
/// It inherits the brand colour from the current Theme so it works in both
/// light and dark modes and stays consistent with the #3AB6FF seed colour.
class FAQWidget extends StatelessWidget {
  final List<FAQItem> items;
  const FAQWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: brand),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              title: Text(
                item.question,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                  child: Text(
                    item.answer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
