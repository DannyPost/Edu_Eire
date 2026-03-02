import 'package:flutter/material.dart';

import 'event.dart';
import 'firestore_service.dart';
import 'ics_exporter.dart'; // your existing exporter

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = EventRepo();

  String _searchText = '';
  // Include your live categories. We add "Academic" to match your sample doc.
  String _selectedCategory = 'All';
  String _selectedCollege = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate =
        isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2028, 12, 31),
    );
    if (newDate != null) {
      setState(() => isStart ? _startDate = newDate : _endDate = newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collegeParam = _selectedCollege == 'All' ? null : _selectedCollege;
    final categoryParam = _selectedCategory == 'All' ? null : _selectedCategory;

    return Scaffold(
      appBar: AppBar(title: const Text('Search College Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Search Title'),
                onChanged: (value) => setState(() => _searchText = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Category: '),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: const [
                      'All',
                      'Academic', // matches your Firestore sample
                      'deadline',
                      'open_day',
                      'personal',
                      'imported',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(width: 12),
                  const Text('College: '),
                  DropdownButton<String>(
                    value: _selectedCollege,
                    items: const [
                      'All','NCI','UCD','TCD','DCU','UL','UCC','Other'
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCollege = v!),
                  ),
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
                    onPressed: () =>
                        setState(() {
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
            child: StreamBuilder<List<Event>>(
              stream: _repo.streamEvents(
                college: collegeParam,   // maps to orgId in Firestore
                category: categoryParam, // maps to category in Firestore
                startDate: _startDate,   // filters by startsAt
                endDate: _endDate,       // filters by startsAt
                searchText: _searchText,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snap.data ?? const <Event>[];
                if (events.isEmpty) return const Center(child: Text('No results found.'));
                return _SearchSelectableList(events: events);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSelectableList extends StatefulWidget {
  final List<Event> events;
  const _SearchSelectableList({required this.events});

  @override
  State<_SearchSelectableList> createState() => _SearchSelectableListState();
}

class _SearchSelectableListState extends State<_SearchSelectableList> {
  final _selected = <int>{};

  Future<void> _exportSelectedToICS() async {
    final picked = _selected.map((i) => widget.events[i]).toList();
    if (picked.isEmpty) return;

    // Your existing exporter builds all-day events from `event.date`.
    // That’s OK; if you later want true timed ICS, we can extend the exporter
    // to use startsAt/endsAt when present.
    await exportICS(picked, (msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.events.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text('${_selected.length} selected'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _exportSelectedToICS,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export selected (.ics)'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.events.length,
            itemBuilder: (context, i) {
              final e = widget.events[i];
              final selected = _selected.contains(i);
              final d = '${e.date.day}/${e.date.month}/${e.date.year}';
              final subtitleParts = <String>[d];
              if ((e.college ?? '').isNotEmpty) {
                subtitleParts.add('• ${e.college}');
              }
              if (e.category.isNotEmpty) {
                subtitleParts.add('• ${e.category}');
              }
              if ((e.location ?? '').isNotEmpty) {
                subtitleParts.add('• ${e.location}');
              }
              if ((e.note ?? '').isNotEmpty) {
                subtitleParts.add('\n${e.note!}');
              }

              return CheckboxListTile(
                value: selected,
                onChanged: (v) => setState(() {
                  v == true ? _selected.add(i) : _selected.remove(i);
                }),
                title: Text(e.title),
                subtitle: Text(subtitleParts.join(' ')),
              );
            },
          ),
        ),
      ],
    );
  }
}
