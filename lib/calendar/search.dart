import 'package:flutter/material.dart';
import 'calendar.dart'; // for Event data model and bookmark toggling

class SearchPage extends StatefulWidget {
  final List<Event> allEvents;
  final Set<String> bookmarkedEventTitles;
  final void Function(Event) onToggleBookmark;

  const SearchPage({
    super.key,
    required this.allEvents,
    required this.bookmarkedEventTitles,
    required this.onToggleBookmark,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredEvents = widget.allEvents
        .where((event) =>
            event.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Events'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search events...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredEvents.isEmpty
                ? const Center(child: Text('No events found.'))
                : ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      final isBookmarked =
                          widget.bookmarkedEventTitles.contains(event.title);
                      final dateFormatted =
                          '${event.date.day.toString().padLeft(2, '0')}/'
                          '${event.date.month.toString().padLeft(2, '0')}/'
                          '${event.date.year}';
                      return ListTile(
                        leading: const Icon(Icons.event, color: Colors.blue),
                        title: Text(event.title),
                        subtitle: Text(dateFormatted +
                            (event.note != null ? '\nNote: ${event.note}' : '')),
                        trailing: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked ? Colors.blue : null,
                          ),
                          onPressed: () => widget.onToggleBookmark(event),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
