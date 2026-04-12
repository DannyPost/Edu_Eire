import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_event_dialog.dart';
import 'search.dart';
import 'notification_service.dart';
import 'ics_importer.dart';

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

/// Single key for bookmark storage so titles match across Search and My Bookmarks.
String bookmarkTitleKey(String title) => title.trim();

String eventCategoryLabel(String category) {
  switch (category) {
    case 'deadline':
      return 'Deadline';
    case 'open_day':
      return 'Open Day';
    case 'personal':
      return 'Personal';
    default:
      return category;
  }
}

void showEventDetails(
  BuildContext context, {
  required Event event,
  required bool Function(Event) isBookmarked,
  required void Function(Event) onToggleBookmark,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final bookmarked = isBookmarked(event);
              final theme = Theme.of(context);
              final dateStr = DateFormat('EEEE, d MMMM y').format(event.date);
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: bookmarked
                              ? 'Remove bookmark'
                              : 'Add bookmark',
                          icon: Icon(
                            bookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: bookmarked ? Colors.blue : null,
                          ),
                          onPressed: () {
                            onToggleBookmark(event);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${eventCategoryLabel(event.category)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (event.note != null && event.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Note',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.note!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.utc(2025, 9, 1);
  DateTime? _selectedDay;

  final List<Event> _allEvents = [
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
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _allEvents.where((event) => event.date == dateOnly).toList();
  }

  /// Agenda includes today and future events (UTC calendar days), not `isAfter(now)` which drops "today".
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

      //Schedule notification 1 day before event (if in future)
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

  @override
  void dispose() {
    _selectedEvents.dispose();
    _animationController.dispose();
    super.dispose();
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
            tooltip: 'View and Search All Events',
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
                  if (events.isEmpty) return null;
                  Color color;
                  if (events.any((event) => _bookmarkedEventTitles
                      .contains(bookmarkTitleKey(event.title)))) {
                    color = Colors.green;
                  } else if (events
                      .any((event) => event.category == 'open_day')) {
                    color = Colors.blue;
                  } else if (events
                      .any((event) => event.category == 'deadline')) {
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
            )
          else if (_viewMode == CalendarViewMode.agenda)
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
                                trailing: _bookmarkedEventTitles.contains(
                                        bookmarkTitleKey(event.title))
                                    ? const Icon(Icons.bookmark,
                                        color: Colors.blue)
                                    : null,
                                onTap: () {
                                  showEventDetails(
                                    context,
                                    event: event,
                                    isBookmarked: (e) => _bookmarkedEventTitles
                                        .contains(bookmarkTitleKey(e.title)),
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
                    final isBookmarked = _bookmarkedEventTitles
                        .contains(bookmarkTitleKey(event.title));
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
                      subtitle: Text(dateFormatted +
                          (event.note != null ? '\nNote: ${event.note}' : '')),
                      trailing: ScaleTransition(
                        scale: _animationController,
                        child: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked ? Colors.blue : null,
                          ),
                          onPressed: () => _toggleBookmark(event),
                          tooltip:
                              isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                        ),
                      ),
                      onTap: () {
                        showEventDetails(
                          context,
                          event: event,
                          isBookmarked: (e) => _bookmarkedEventTitles
                              .contains(bookmarkTitleKey(e.title)),
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
        child: const Icon(Icons.add),
        tooltip: 'Add Personal Event',
      ),
    );
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
              child: Text('No events bookmarked yet.',
                  style: TextStyle(fontSize: 16)),
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
