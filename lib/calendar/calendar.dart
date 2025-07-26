import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_event_dialog.dart';
import 'search.dart';

class Event {
  final String title;
  final DateTime date;
  final String category;
  final String? note;

  Event(this.title, this.date, this.category, {this.note});
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with SingleTickerProviderStateMixin {
  late final ValueNotifier<List<Event>> _selectedEvents;
  late final AnimationController _animationController;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.utc(2025, 9, 1);
  DateTime? _selectedDay;

  final List<Event> _allEvents = [
    Event('CAO Opening Date', DateTime.utc(2025, 9, 15), 'deadline'),
    Event('SUSI Grant Opens', DateTime.utc(2025, 11, 1), 'deadline'),
    Event('CAO Final Deadline', DateTime.utc(2026, 2, 1), 'deadline'),
    Event('HEAR/DARE Application Closes', DateTime.utc(2026, 3, 15), 'deadline'),
    Event('College Open Day', DateTime.utc(2026, 4, 10), 'open_day'),
  ];

  final Set<String> _bookmarkedEventTitles = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.0,
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _allEvents.where((event) => event.date == dateOnly).toList();
  }

  void _toggleBookmark(Event event) async {
    await _animationController.forward();
    await _animationController.reverse();
    setState(() {
      if (_bookmarkedEventTitles.contains(event.title)) {
        _bookmarkedEventTitles.remove(event.title);
      } else {
        _bookmarkedEventTitles.add(event.title);
      }
    });
  }

  void _goToBookmarksPage() {
    final bookmarkedEvents = _allEvents
        .where((event) => _bookmarkedEventTitles.contains(event.title))
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookmarkedEventsPage(
          bookmarkedEvents: bookmarkedEvents,
          onRemoveBookmark: (event) {
            setState(() {
              _bookmarkedEventTitles.remove(event.title);
            });
          },
        ),
      ),
    );
  }

  void _goToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          allEvents: _allEvents,
          bookmarkedEventTitles: _bookmarkedEventTitles,
          onToggleBookmark: _toggleBookmark,
        ),
      ),
    );
  }

  void _addPersonalEvent() async {
    final newEvent = await showDialog<Event>(
      context: context,
      builder: (context) => const AddEventDialog(),
    );
    if (newEvent != null) {
      setState(() {
        _allEvents.add(newEvent);
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    }
  }

  IconData _getEventIcon(String category) {
    switch (category) {
      case 'deadline':
        return Icons.calendar_today;
      case 'open_day':
        return Icons.account_balance;
      case 'personal':
        return Icons.edit;
      default:
        return Icons.star;
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Year Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _goToSearchPage,
            tooltip: 'Search Events',
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: _goToBookmarksPage,
            tooltip: 'My Bookmarked Events',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2025, 9, 1),
            lastDay: DateTime.utc(2026, 8, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<Event>(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                Color color;
                if (events.any((event) => _bookmarkedEventTitles.contains(event.title))) {
                  color = Colors.green;
                } else if (events.any((event) => event.category == 'open_day')) {
                  color = Colors.blue;
                } else if (events.any((event) => event.category == 'deadline')) {
                  color = Colors.red;
                } else {
                  color = Colors.grey;
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents.value = _getEventsForDay(selectedDay);
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(child: Text('No events on this day.'));
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    final isBookmarked = _bookmarkedEventTitles.contains(event.title);
                    final dateFormatted =
                        '${event.date.day.toString().padLeft(2, '0')}/'
                        '${event.date.month.toString().padLeft(2, '0')}/'
                        '${event.date.year}';
                    final icon = _getEventIcon(event.category);
                    return ListTile(
                      leading: Icon(icon, color: Colors.blue),
                      title: Text(event.title),
                      subtitle: Text(dateFormatted +
                          (event.note != null ? '\nNote: ${event.note}' : '')),
                      trailing: ScaleTransition(
                        scale: _animationController,
                        child: IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isBookmarked ? Colors.blue : null,
                          ),
                          onPressed: () => _toggleBookmark(event),
                          tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPersonalEvent,
        child: const Icon(Icons.add),
        tooltip: 'Add Personal Event',
      ),
    );
  }
}

class BookmarkedEventsPage extends StatelessWidget {
  final List<Event> bookmarkedEvents;
  final void Function(Event) onRemoveBookmark;

  const BookmarkedEventsPage({
    super.key,
    required this.bookmarkedEvents,
    required this.onRemoveBookmark,
  });

  Color _getBookmarkColor(String category) {
    switch (category) {
      case 'deadline':
        return Colors.red;
      case 'open_day':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _getEventIcon(String category) {
    switch (category) {
      case 'deadline':
        return Icons.calendar_today;
      case 'open_day':
        return Icons.account_balance;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<Event>.from(bookmarkedEvents)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarked Events'),
        centerTitle: true,
      ),
      body: sortedEvents.isEmpty
          ? const Center(
              child: Text('No events bookmarked yet.', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final event = sortedEvents[index];
                final dateFormatted =
                    '${event.date.day.toString().padLeft(2, '0')}/'
                    '${event.date.month.toString().padLeft(2, '0')}/'
                    '${event.date.year}';
                final color = _getBookmarkColor(event.category);
                final icon = _getEventIcon(event.category);
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(event.title),
                  subtitle: Text('Date: $dateFormatted'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove Bookmark'),
                          content: Text(
                              'Are you sure you want to remove "${event.title}" from bookmarks?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        onRemoveBookmark(event);
                        Navigator.pop(context);
                      }
                    },
                    tooltip: 'Remove from bookmarks',
                  ),
                );
              },
            ),
    );
  }
}
