import 'package:flutter/material.dart';

import 'event.dart';
import 'event_details_sheet.dart';
import 'firestore_service.dart';
import 'ics_exporter.dart';

class SearchPage extends StatefulWidget {
  final Set<String>? bookmarkedTitles;
  final void Function(Event)? onToggleBookmark;

  const SearchPage({
    super.key,
    this.bookmarkedTitles,
    this.onToggleBookmark,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = EventRepo();

  String _searchText = '';
  String _selectedCategory = 'All';
  String _selectedCollege = 'All';
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

  List<Event> _applyBookmarkAndSort(List<Event> events) {
    var list = List<Event>.from(events);
    final titles = widget.bookmarkedTitles;
    if (_showBookmarkedOnly && titles != null) {
      list = list
          .where((e) => titles.contains(bookmarkTitleKey(e.title)))
          .toList();
    }
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
    final hasBookmarkUi =
        widget.bookmarkedTitles != null && widget.onToggleBookmark != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search College Events'),
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Category'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items: const [
                          'All',
                          'Academic',
                          'deadline',
                          'open_day',
                          'personal',
                          'imported',
                        ]
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('College'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCollege,
                        items: const [
                          'All',
                          'NCI',
                          'UCD',
                          'TCD',
                          'DCU',
                          'UL',
                          'UCC',
                          'Other',
                        ]
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCollege = value!),
                      ),
                    ),
                  ],
                ),
                if (hasBookmarkUi) ...[
                  const SizedBox(height: 8),
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
                ],
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
                const SizedBox(height: 8),
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
            child: StreamBuilder<List<Event>>(
              stream: _repo.streamEvents(
                college: collegeParam,
                category: categoryParam,
                startDate: _startDate,
                endDate: _endDate,
                searchText: _searchText,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final raw = snap.data ?? const <Event>[];
                final events = _applyBookmarkAndSort(raw);

                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            raw.isEmpty
                                ? 'No results found.'
                                : 'No events match your current filters.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (raw.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Try adjusting your search, category, bookmarks, or date filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                if (!hasBookmarkUi) {
                  return _SearchSelectableList(events: events);
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final titles = widget.bookmarkedTitles!;
                        final onToggle = widget.onToggleBookmark!;
                        final isBookmarked = titles
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
                                  onToggle(event);
                                  setState(() {});
                                },
                              ),
                              onTap: () {
                                showEventDetails(
                                  context,
                                  event: event,
                                  isBookmarked: (e) => titles
                                      .contains(bookmarkTitleKey(e.title)),
                                  onToggleBookmark: (e) {
                                    onToggle(e);
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
                );
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
