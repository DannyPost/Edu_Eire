import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_event_dialog.dart';
import 'search.dart';
import 'notification_service.dart';
import 'ics_importer.dart';
import 'google_calendar_link.dart';
import 'event.dart';
import 'firestore_service.dart';
import 'event_details_sheet.dart';
import '../events_page/event_details_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

enum CalendarViewMode { month, week, agenda }

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<List<Event>> _selectedEvents;
  late final AnimationController _animationController;

  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _focusedDay = DateTime.utc(2025, 9, 1);
  DateTime? _selectedDay;

  final List<Event> _remoteEvents = [];
  final List<Event> _localEvents = [];
  List<Event> _allEvents = [];

  final Set<String> _bookmarkedEventTitles = {};

  final _repo = EventRepo();
  late final Stream<List<Event>> _eventsStream;
  late final StreamSubscription<List<Event>> _eventsSub;

  static List<Event> _defaultLocalEvents() => [
        Event(
            title: 'School Year Starts',
            date: DateTime.utc(2025, 8, 25),
            category: 'deadline'),
        Event(
            title: 'CAO Opens',
            date: DateTime.utc(2025, 11, 5),
            category: 'deadline'),
        Event(
            title: 'SUSI Grant Opens',
            date: DateTime.utc(2026, 4, 1),
            category: 'deadline'),
        Event(
            title: 'CAO Early Bird Deadline (€30)',
            date: DateTime.utc(2026, 1, 20),
            category: 'deadline'),
        Event(
            title: 'CAO Final Deadline (€45)',
            date: DateTime.utc(2026, 2, 1),
            category: 'deadline'),
        Event(
            title: 'HEAR/DARE Application Deadline',
            date: DateTime.utc(2026, 3, 1),
            category: 'deadline'),
        Event(
            title: 'HEAR/DARE Docs Submission Deadline',
            date: DateTime.utc(2026, 3, 15),
            category: 'deadline'),
        Event(
            title: 'Change of Mind Opens (CAO)',
            date: DateTime.utc(2026, 5, 5),
            category: 'deadline'),
        Event(
            title: 'Change of Mind Closes (CAO)',
            date: DateTime.utc(2026, 7, 1),
            category: 'deadline'),
        Event(
            title: 'Midterm Break Starts',
            date: DateTime.utc(2025, 10, 27),
            category: 'deadline'),
        Event(
            title: 'Midterm Break Ends',
            date: DateTime.utc(2025, 10, 31),
            category: 'deadline'),
        Event(
            title: 'Christmas Holidays Start',
            date: DateTime.utc(2025, 12, 22),
            category: 'deadline'),
        Event(
            title: 'Christmas Holidays End',
            date: DateTime.utc(2026, 1, 5),
            category: 'deadline'),
        Event(
            title: 'February Midterm',
            date: DateTime.utc(2026, 2, 17),
            category: 'deadline'),
        Event(
            title: 'Easter Holidays Start',
            date: DateTime.utc(2026, 4, 6),
            category: 'deadline'),
        Event(
            title: 'Easter Holidays End',
            date: DateTime.utc(2026, 4, 17),
            category: 'deadline'),
        Event(
            title: 'Leaving & Junior Cert Exams Begin',
            date: DateTime.utc(2026, 6, 3),
            category: 'deadline'),
        Event(
            title: 'College Open Day (UCD Sample)',
            date: DateTime.utc(2025, 10, 18),
            category: 'open_day'),
        Event(
            title: 'College Open Day (TCD Sample)',
            date: DateTime.utc(2025, 11, 15),
            category: 'open_day'),
      ];

  void _handleICSImport() async {
    final importedEvents = await importICSFile();
    if (importedEvents.isNotEmpty) {
      setState(() {
        final normalized = importedEvents.map((e) => Event(
              title: e.title,
              category: e.category,
              note: e.note,
              college: e.college,
              startsAt: e.startsAt,
              endsAt: e.endsAt,
              location: e.location,
              date: DateTime.utc(e.date.year, e.date.month, e.date.day),
            ));
        _localEvents.addAll(normalized);
        _rebuildAllEvents();
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _localEvents.addAll(_defaultLocalEvents());
    _rebuildAllEvents();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.0,
    );

    _eventsStream = _repo.streamEvents();
    _eventsSub = _eventsStream.listen((list) {
      setState(() {
        _remoteEvents
          ..clear()
          ..addAll(list.map((e) => Event(
                title: e.title,
                category: e.category,
                note: e.note,
                college: e.college,
                startsAt: e.startsAt,
                endsAt: e.endsAt,
                location: e.location,
                date: DateTime.utc(e.date.year, e.date.month, e.date.day),
              )));
        _rebuildAllEvents();
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    }, onError: (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $err')),
        );
      }
    });
  }

  void _rebuildAllEvents() {
    _allEvents = [..._remoteEvents, ..._localEvents];
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _allEvents.where((event) => event.date == dateOnly).toList();
  }

  bool _isEventOnOrAfterTodayUtc(Event e) {
    final eventDay = DateTime.utc(e.date.year, e.date.month, e.date.day);
    final n = DateTime.now().toUtc();
    final today = DateTime.utc(n.year, n.month, n.day);
    return !eventDay.isBefore(today);
  }

  String _agendaSectionHeading(DateTime dayKeyUtc) {
    final n = DateTime.now().toUtc();
    final today = DateTime.utc(n.year, n.month, n.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (dayKeyUtc == today) return 'Today';
    if (dayKeyUtc == tomorrow) return 'Tomorrow';
    return DateFormat('EEEE, d MMMM y').format(dayKeyUtc);
  }

  void _toggleBookmark(Event event) async {
    final key = bookmarkTitleKey(event.title);
    final hadBookmark = _bookmarkedEventTitles.contains(key);
    setState(() {
      if (hadBookmark) {
        _bookmarkedEventTitles.remove(key);
      } else {
        _bookmarkedEventTitles.add(key);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(hadBookmark ? 'Bookmark removed' : 'Bookmark added'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    await _animationController.forward();
    if (!mounted) return;
    await _animationController.reverse();
  }

  void _goToBookmarksPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookmarkedEventsPage(
          allEvents: _allEvents,
          bookmarkedTitles: _bookmarkedEventTitles,
          onRemoveBookmark: (event) {
            setState(() {
              _bookmarkedEventTitles.remove(bookmarkTitleKey(event.title));
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
          bookmarkedTitles: _bookmarkedEventTitles,
          onToggleBookmark: _toggleBookmark,
        ),
      ),
    );
  }

  void _goToEventsPage() {
    final bookmarkedEvents = _allEvents
        .where((e) =>
            _bookmarkedEventTitles.contains(bookmarkTitleKey(e.title)))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsPage(
          allEvents: List<Event>.from(_allEvents),
          bookmarkedEvents: bookmarkedEvents,
          onBookmarkToggle: (event) {
            setState(() {
              final key = bookmarkTitleKey(event.title);
              if (_bookmarkedEventTitles.contains(key)) {
                _bookmarkedEventTitles.remove(key);
              } else {
                _bookmarkedEventTitles.add(key);
              }
            });
          },
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
        final normalized = Event(
          title: newEvent.title,
          category: newEvent.category,
          note: newEvent.note,
          college: newEvent.college,
          startsAt: newEvent.startsAt,
          endsAt: newEvent.endsAt,
          location: newEvent.location,
          date: DateTime.utc(
              newEvent.date.year, newEvent.date.month, newEvent.date.day),
        );
        _localEvents.add(normalized);
        _rebuildAllEvents();
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });

      final reminderTime = newEvent.date.subtract(const Duration(days: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: newEvent.date.millisecondsSinceEpoch ~/ 1000,
          title: 'Upcoming Event: ${newEvent.title}',
          body: newEvent.note ?? 'You have an event tomorrow.',
          scheduledDate: reminderTime,
        );
      }
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  bool _isBookmarked(Event e) =>
      _bookmarkedEventTitles.contains(bookmarkTitleKey(e.title));

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
            icon: const Icon(Icons.file_upload),
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
          if (_viewMode == CalendarViewMode.month ||
              _viewMode == CalendarViewMode.week)
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
                  final evts = events.cast<Event>();
                  if (evts.isEmpty) return null;

                  Color color;
                  if (evts.any(_isBookmarked)) {
                    color = Colors.green;
                  } else if (evts.any((e) => e.category == 'open_day')) {
                    color = Colors.blue;
                  } else if (evts.any((e) => e.category == 'deadline')) {
                    color = Colors.red;
                  } else {
                    color = Colors.grey;
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    ],
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
            )
          else
            Expanded(
              child: Builder(
                builder: (context) {
                  final sortedEvents = _allEvents
                      .where(_isEventOnOrAfterTodayUtc)
                      .toList()
                    ..sort((a, b) => a.date.compareTo(b.date));

                  if (sortedEvents.isEmpty) {
                    return const Center(
                      child: Text('No upcoming events.'),
                    );
                  }

                  final groups = <DateTime, List<Event>>{};
                  for (final e in sortedEvents) {
                    final k =
                        DateTime.utc(e.date.year, e.date.month, e.date.day);
                    groups.putIfAbsent(k, () => []).add(e);
                  }
                  final dayKeys = groups.keys.toList()..sort();

                  final theme = Theme.of(context);
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      for (final day in dayKeys) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                          child: Text(
                            _agendaSectionHeading(day),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                        ...groups[day]!.map(
                          (event) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            child: Material(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                leading: Icon(_getEventIcon(event.category)),
                                title: Text(
                                  event.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Add to Google Calendar',
                                      icon: const Icon(Icons.event_available),
                                      onPressed: () async {
                                        final start = DateTime.utc(
                                          event.date.year,
                                          event.date.month,
                                          event.date.day,
                                        );
                                        final end = start
                                            .add(const Duration(days: 1));
                                        await openInGoogleCalendar(
                                          title: event.title,
                                          start: start,
                                          end: end,
                                          description: event.note,
                                          location: event.location,
                                        );
                                        if (!mounted) return;
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Opening Google Calendar…'),
                                          ),
                                        );
                                      },
                                    ),
                                    if (_isBookmarked(event))
                                      const Icon(Icons.bookmark,
                                          color: Colors.blue),
                                  ],
                                ),
                                onTap: () {
                                  showEventDetails(
                                    context,
                                    event: event,
                                    isBookmarked: _isBookmarked,
                                    onToggleBookmark: _toggleBookmark,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
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
                    final isBookmarked = _isBookmarked(event);
                    final dateFormatted =
                        '${event.date.day.toString().padLeft(2, '0')}/'
                        '${event.date.month.toString().padLeft(2, '0')}/'
                        '${event.date.year}';
                    final icon = _getEventIcon(event.category);

                    return ListTile(
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
                        [
                          dateFormatted,
                          if ((event.college ?? '').isNotEmpty)
                            ' • ${event.college}',
                          if ((event.location ?? '').isNotEmpty)
                            ' • ${event.location}',
                          if ((event.note ?? '').isNotEmpty)
                            '\nNote: ${event.note}',
                        ].join(''),
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            tooltip: 'Add to Google Calendar',
                            icon: const Icon(Icons.event_available),
                            onPressed: () async {
                              final start = DateTime.utc(
                                  event.date.year,
                                  event.date.month,
                                  event.date.day);
                              final end = start.add(const Duration(days: 1));
                              await openInGoogleCalendar(
                                title: event.title,
                                start: start,
                                end: end,
                                description: event.note,
                                location: event.location,
                              );
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Opening Google Calendar…'),
                                ),
                              );
                            },
                          ),
                          ScaleTransition(
                            scale: _animationController,
                            child: IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isBookmarked ? Colors.blue : null,
                              ),
                              onPressed: () => _toggleBookmark(event),
                              tooltip: isBookmarked
                                  ? 'Remove Bookmark'
                                  : 'Add Bookmark',
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        showEventDetails(
                          context,
                          event: event,
                          isBookmarked: _isBookmarked,
                          onToggleBookmark: _toggleBookmark,
                        );
                      },
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
        tooltip: 'Add Personal Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _eventsSub.cancel();
    _selectedEvents.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class BookmarkedEventsPage extends StatelessWidget {
  final List<Event> allEvents;
  final Set<String> bookmarkedTitles;
  final void Function(Event) onRemoveBookmark;

  const BookmarkedEventsPage({
    super.key,
    required this.allEvents,
    required this.bookmarkedTitles,
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
    final sortedEvents = allEvents
        .where((e) => bookmarkedTitles.contains(bookmarkTitleKey(e.title)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarked Events'),
        centerTitle: true,
      ),
      body: sortedEvents.isEmpty
          ? const Center(
              child: Text(
                'No events bookmarked yet.',
                style: TextStyle(fontSize: 16),
              ),
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
                  subtitle: Text('Date: $dateFormatted'
                      '${(event.college ?? '').isNotEmpty ? ' • ${event.college}' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Add to Google Calendar',
                        icon: const Icon(Icons.event_available),
                        onPressed: () async {
                          final start = DateTime.utc(
                              event.date.year, event.date.month, event.date.day);
                          final end = start.add(const Duration(days: 1));
                          await openInGoogleCalendar(
                            title: event.title,
                            start: start,
                            end: end,
                            description: event.note,
                            location: event.location,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Google Calendar…'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Remove from bookmarks',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Bookmark'),
                              content: Text(
                                'Are you sure you want to remove "${event.title}" from bookmarks?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            onRemoveBookmark(event);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bookmark removed'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
