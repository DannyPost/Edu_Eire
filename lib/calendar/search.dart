import 'package:flutter/material.dart';
import '../calendar/calendar.dart'; // Ensure Event is imported

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
  String _searchText = '';
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showBookmarkedOnly = false;
  String _sortOption = 'date_asc';

  static const List<DropdownMenuItem<String>> _sortDropdownItems = [
    DropdownMenuItem(
      value: 'date_asc',
      child: Text('Date (Soonest First)'),
    ),
    DropdownMenuItem(
      value: 'date_desc',
      child: Text('Date (Latest First)'),
    ),
    DropdownMenuItem(
      value: 'title_az',
      child: Text('Title (A-Z)'),
    ),
  ];

  static const List<DropdownMenuItem<String>> _categoryDropdownItems = [
    DropdownMenuItem(value: 'All', child: Text('All')),
    DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
    DropdownMenuItem(value: 'open_day', child: Text('Open Day')),
    DropdownMenuItem(value: 'personal', child: Text('Personal')),
  ];

  static String _formatEventDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _categoryDisplayLabel(String category) {
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

  static Color _categoryChipColor(String category) {
    switch (category) {
      case 'deadline':
        return const Color(0xFFE57373);
      case 'open_day':
        return const Color(0xFF64B5F6);
      case 'personal':
        return const Color(0xFF81C784);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  List<Event> get _filteredEvents {
    return widget.allEvents.where((event) {
      final matchesText =
          event.title.toLowerCase().contains(_searchText.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || event.category == _selectedCategory;
      final matchesBookmark = !_showBookmarkedOnly ||
          widget.bookmarkedEventTitles
              .contains(bookmarkTitleKey(event.title));
      final matchesStartDate =
          _startDate == null || !event.date.isBefore(_startDate!);
      final matchesEndDate = _endDate == null || !event.date.isAfter(_endDate!);
      return matchesText &&
          matchesCategory &&
          matchesBookmark &&
          matchesStartDate &&
          matchesEndDate;
    }).toList();
  }

  List<Event> get _sortedFilteredEvents {
    final list = List<Event>.from(_filteredEvents);
    switch (_sortOption) {
      case 'date_desc':
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'title_az':
        list.sort(
          (a, b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'date_asc':
      default:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
    }
    return list;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2026, 12, 31),
    );
    if (newDate != null) {
      setState(() {
        if (isStart)
          _startDate = newDate;
        else
          _endDate = newDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _sortedFilteredEvents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('View and Search All Events'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Title or keywords',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Category'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items: _categoryDropdownItems,
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _showBookmarkedOnly,
                      onChanged: (val) =>
                          setState(() => _showBookmarkedOnly = val!),
                    ),
                    const Expanded(
                      child: Text('Bookmarked only'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(_startDate == null
                          ? 'Start date'
                          : 'From: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(_endDate == null
                          ? 'End date'
                          : 'To: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                      tooltip: 'Clear dates',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Sort'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _sortOption,
                        items: _sortDropdownItems,
                        onChanged: (value) =>
                            setState(() => _sortOption = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No events match your current filters.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Try adjusting your search, category, or date filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final isBookmarked = widget.bookmarkedEventTitles
                              .contains(bookmarkTitleKey(event.title));
                          final theme = Theme.of(context);
                          final dateStr = _formatEventDate(event.date);
                          final catLabel =
                              _categoryDisplayLabel(event.category);
                          final catColor =
                              _categoryChipColor(event.category);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  event.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 15,
                                            color: theme.hintColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateStr,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Chip(
                                        label: Text(
                                          catLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        side: BorderSide.none,
                                        backgroundColor:
                                            catColor.withValues(alpha: 0.2),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked ? Colors.blue : null,
                                  ),
                                  tooltip: isBookmarked
                                      ? 'Remove bookmark'
                                      : 'Save / bookmark',
                                  onPressed: () {
                                    widget.onToggleBookmark(event);
                                    setState(() {});
                                  },
                                ),
                                onTap: () {
                                  showEventDetails(
                                    context,
                                    event: event,
                                    isBookmarked: (e) => widget
                                        .bookmarkedEventTitles
                                        .contains(bookmarkTitleKey(e.title)),
                                    onToggleBookmark: (e) {
                                      widget.onToggleBookmark(e);
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
