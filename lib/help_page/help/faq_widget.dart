import 'package:flutter/material.dart';

class FAQItem {
  final String question;
  final String answer;
  FAQItem({required this.question, required this.answer});
}

class FAQWidget extends StatelessWidget {
  final List<FAQItem> items;
  const FAQWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Colors.lightBlue.shade400,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              title: Text(
                item.question,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14, top: 0),
                  child: Text(
                    item.answer,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
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
