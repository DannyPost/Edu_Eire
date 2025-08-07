import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_event_dialog.dart';
import 'search.dart';
import 'notification_service.dart';
import 'ics_importer.dart';

import '../events_page/event_details_page.dart';



class Event {
  final String title;
  final DateTime date;
  final String category;
  final String? note;

  Event({
    required this.title,
    required this.date,
    required this.category,
    this.note,
  });
}


class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

enum CalendarViewMode { month, week, agenda }

class _CalendarPageState extends State<CalendarPage> with SingleTickerProviderStateMixin {
  late final ValueNotifier<List<Event>> _selectedEvents;
  late final AnimationController _animationController;

  CalendarViewMode _viewMode = CalendarViewMode.month;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.utc(2025, 9, 1);
  DateTime? _selectedDay;

final List<Event> _allEvents = [
  Event(title: 'School Year Starts', date: DateTime.utc(2025, 8, 25), category: 'deadline'),
  Event(title: 'CAO Opens', date: DateTime.utc(2025, 11, 5), category: 'deadline'),
  Event(title: 'SUSI Grant Opens', date: DateTime.utc(2026, 4, 1), category: 'deadline'),
  Event(title: 'CAO Early Bird Deadline (€30)', date: DateTime.utc(2026, 1, 20), category: 'deadline'),
  Event(title: 'CAO Final Deadline (€45)', date: DateTime.utc(2026, 2, 1), category: 'deadline'),
  Event(title: 'HEAR/DARE Application Deadline', date: DateTime.utc(2026, 3, 1), category: 'deadline'),
  Event(title: 'HEAR/DARE Docs Submission Deadline', date: DateTime.utc(2026, 3, 15), category: 'deadline'),
  Event(title: 'Change of Mind Opens (CAO)', date: DateTime.utc(2026, 5, 5), category: 'deadline'),
  Event(title: 'Change of Mind Closes (CAO)', date: DateTime.utc(2026, 7, 1), category: 'deadline'),
  Event(title: 'Midterm Break Starts', date: DateTime.utc(2025, 10, 27), category: 'deadline'),
  Event(title: 'Midterm Break Ends', date: DateTime.utc(2025, 10, 31), category: 'deadline'),
  Event(title: 'Christmas Holidays Start', date: DateTime.utc(2025, 12, 22), category: 'deadline'),
  Event(title: 'Christmas Holidays End', date: DateTime.utc(2026, 1, 5), category: 'deadline'),
  Event(title: 'February Midterm', date: DateTime.utc(2026, 2, 17), category: 'deadline'),
  Event(title: 'Easter Holidays Start', date: DateTime.utc(2026, 4, 6), category: 'deadline'),
  Event(title: 'Easter Holidays End', date: DateTime.utc(2026, 4, 17), category: 'deadline'),
  Event(title: 'Leaving & Junior Cert Exams Begin', date: DateTime.utc(2026, 6, 3), category: 'deadline'),
  Event(title: 'College Open Day (UCD Sample)', date: DateTime.utc(2025, 10, 18), category: 'open_day'),
  Event(title: 'College Open Day (TCD Sample)', date: DateTime.utc(2025, 11, 15), category: 'open_day'),
];



  void _handleICSImport() async {
  final importedEvents = await importICSFile();
  if (importedEvents.isNotEmpty) {
    setState(() {
      _allEvents.addAll(importedEvents);
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }
}


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
  final dateOnly = DateTime(day.year, day.month, day.day);
  return _allEvents.where((event) {
    final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
    return eventDate == dateOnly;
  }).toList();
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

void _goToEventsPage() {
  final bookmarkedEvents = _allEvents
      .where((event) => _bookmarkedEventTitles.contains(event.title))
      .toList();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EventsPage(
        allEvents: _allEvents,
        bookmarkedEvents: bookmarkedEvents,
        onBookmarkToggle: (event) {
          setState(() {
           if (_bookmarkedEventTitles.contains(event.title!)) {
  _bookmarkedEventTitles.remove(event.title!);
} else {
  _bookmarkedEventTitles.add(event.title!);
}

          });
        },
      ),
    ),
  );
}


void _addPersonalEvent() async {
  showAddOrEditEventDialog(
    context: context,
    selectedDate: _selectedDay,
    onSave: (newEvent) {
      setState(() {
        _allEvents.add(newEvent);
        _selectedDay = DateTime(
          newEvent.date.year,
          newEvent.date.month,
          newEvent.date.day,
        );
        _focusedDay = _selectedDay!;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });

      // Optional: Notification
      final reminderTime = newEvent.date.subtract(const Duration(days: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        NotificationService.scheduleNotification(
          id: newEvent.date.millisecondsSinceEpoch ~/ 1000,
          title: 'Upcoming Event: ${newEvent.title}',
          body: newEvent.note ?? 'You have an event tomorrow.',
          scheduledDate: reminderTime,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event "${newEvent.title}" added.')),
      );
    },
  );
}



void _addOrUpdateEvent(Event newEvent, {Event? oldEvent}) {
  setState(() {
    if (oldEvent != null) {
      _allEvents.remove(oldEvent);
    }
    _allEvents.add(newEvent);

    _selectedDay = DateTime(newEvent.date.year, newEvent.date.month, newEvent.date.day);
    _focusedDay = _selectedDay!;
    _selectedEvents.value = _getEventsForDay(_selectedDay!);
  });
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

Widget _buildAgendaView() {
  final sortedEvents = _allEvents
      .where((e) => e.date.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return ListView.builder(
    itemCount: sortedEvents.length,
    itemBuilder: (context, index) {
      final event = sortedEvents[index];
      return ListTile(
        title: Text(event.title),
        subtitle: Text(event.note ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showAddOrEditEventDialog(
                  context: context,
                  existingEvent: event,
                  onSave: (updatedEvent) {
                    _addOrUpdateEvent(updatedEvent, oldEvent: event);
                  },
                );
              },
              tooltip: 'Edit Event',
            ),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteEvent(event),
        tooltip: 'Delete Event',
      ),
    ],
  ),
  onTap: () {
    // Optional: show details or also call edit dialog
  },
);

    },
  );
}

Widget _buildSelectedDayView() {
  return ValueListenableBuilder<List<Event>>(
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
          onTap: () {
            showAddOrEditEventDialog(
              context: context,
              existingEvent: event,
              onSave: (updatedEvent) {
                _addOrUpdateEvent(updatedEvent, oldEvent: event);
              },
            );
          },
          leading: Icon(icon, color: Colors.blue),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _getEventColor(event.category),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Text(event.title)),
            ],
          ),
          subtitle: Text(
            dateFormatted +
                (event.note != null ? '\nNote: ${event.note}' : ''),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.blue : null,
                ),
                onPressed: () => _toggleBookmark(event),
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteEvent(event),
                tooltip: 'Delete Event',
              ),
            ],
          ),
        );

        },
      );
    },
  );
}


Color _getEventColor(String category) {
  switch (category) {
    case 'deadline':
      return Colors.red;
    case 'open_day':
      return Colors.blue;
    case 'personal':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

Widget _buildLegendDot(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );
}

void _deleteEvent(Event event) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Event'),
      content: Text('Are you sure you want to delete "${event.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() {
      _allEvents.remove(event);
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event "${event.title}" deleted.')),
    );
  }
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
        IconButton(
          icon: Icon(Icons.file_upload),
          tooltip: 'Import .ics File',
          onPressed: _handleICSImport,
        ),
        IconButton(
          icon: const Icon(Icons.event_note),
          tooltip: 'All Events',
          onPressed: _goToEventsPage,
        ),

        PopupMenuButton<CalendarViewMode>(
          icon: const Icon(Icons.view_agenda),
          tooltip: 'Change Calendar View',
          onSelected: (mode) {
            setState(() => _viewMode = mode);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: CalendarViewMode.month,
              child: Text('Month View'),
            ),
            PopupMenuItem(
              value: CalendarViewMode.week,
              child: Text('Week View'),
            ),
            PopupMenuItem(
              value: CalendarViewMode.agenda,
              child: Text('Agenda View'),
            ),
          ],
        ),
      ],

    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.red, 'Deadline'),
              const SizedBox(width: 10),
              _buildLegendDot(Colors.blue, 'Open Day'),
              const SizedBox(width: 10),
              _buildLegendDot(Colors.green, 'Personal'),
            ],
          ),
        ),
                if (_viewMode == CalendarViewMode.month || _viewMode == CalendarViewMode.week)
          TableCalendar<Event>(
            firstDay: DateTime.utc(2025, 9, 1),
            lastDay: DateTime.utc(2026, 8, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _viewMode == CalendarViewMode.month
                ? CalendarFormat.month
                : CalendarFormat.week,
            eventLoader: _getEventsForDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<Event>(
              markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;

              // Priority logic: show color based on most important event type
              Color color = Colors.green; // default: personal

              for (var event in events) {
                if (_bookmarkedEventTitles.contains(event.title)) {
                  color = Colors.green;
                  break;
                } else if (event.category == 'deadline') {
                  color = Colors.red;
                } else if (event.category == 'open_day') {
                  color = Colors.blue;
                }
              }

              return Container(
                margin: const EdgeInsets.only(top: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
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
          child: _viewMode == CalendarViewMode.agenda
            ? _buildAgendaView()
            : _buildSelectedDayView(),
        ),

      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        showAddOrEditEventDialog(
          context: context,
          selectedDate: _selectedDay,
          onSave: (newEvent) {
            _addOrUpdateEvent(newEvent);
          },
        );
      },
      child: const Icon(Icons.add),
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