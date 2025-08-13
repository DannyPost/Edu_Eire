import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'calendar.dart'; // for Event data model and bookmark toggling
=======
import '../calendar/calendar.dart'; // Ensure Event is imported
>>>>>>> ef348ae3adf21afb75625d5e812df23a645806e7

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
<<<<<<< HEAD
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
=======
  String _searchText = '';
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showBookmarkedOnly = false;

  List<Event> get _filteredEvents {
    return widget.allEvents.where((event) {
      final matchesText = event.title.toLowerCase().contains(_searchText.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || event.category == _selectedCategory;
      final matchesBookmark = !_showBookmarkedOnly || widget.bookmarkedEventTitles.contains(event.title);
      final matchesStartDate = _startDate == null || !event.date.isBefore(_startDate!);
      final matchesEndDate = _endDate == null || !event.date.isAfter(_endDate!);
      return matchesText && matchesCategory && matchesBookmark && matchesStartDate && matchesEndDate;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2026, 12, 31),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) _startDate = newDate;
        else _endDate = newDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;
    return Scaffold(
      appBar: AppBar(title: const Text('Search Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Search Title'),
                onChanged: (value) => setState(() => _searchText = value),
              ),
              Row(
                children: [
                  const Text('Category: '),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: ['All', 'deadline', 'open_day', 'personal']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const Spacer(),
                  Checkbox(
                    value: _showBookmarkedOnly,
                    onChanged: (val) => setState(() => _showBookmarkedOnly = val!),
                  ),
                  const Text('Bookmarked Only'),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(_startDate == null
                        ? 'Start Date'
                        : 'From: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(_endDate == null
                        ? 'End Date'
                        : 'To: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    tooltip: 'Clear Dates',
                  ),
                ],
              ),
            ]),
          ),
          Expanded(
            child: events.isEmpty
                ? const Center(child: Text('No results found.'))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isBookmarked = widget.bookmarkedEventTitles.contains(event.title);
                      return ListTile(
                        title: Text(event.title),
                        subtitle: Text('${event.date.day}/${event.date.month}/${event.date.year}'),
                        trailing: IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
>>>>>>> ef348ae3adf21afb75625d5e812df23a645806e7
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
