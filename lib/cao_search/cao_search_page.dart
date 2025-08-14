// lib/pages/cao_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

/* ───────── assets ───────── */
const _csvAsset        = 'assets/cao_list_25.csv';
const _placeholderLogo = 'assets/atlantic_technological_university.jpeg';

/* optional: college → logo asset  (all caps key) */
const _logoMap = <String, String>{
  'ATLANTIC TECHNOLOGICAL UNIVERSITY': 'assets/atlantic_technological_university.jpeg',
  // add more when you have them
};

/* ───────── widget ───────── */
class CAOSearchPage extends StatefulWidget {
  const CAOSearchPage({super.key});
  @override
  State<CAOSearchPage> createState() => _CAOSearchPageState();
}

class _CAOSearchPageState extends State<CAOSearchPage> {
/* ───────── runtime data ───────── */
  List<Map<String, String>> _courses = [];

  final _universities = <String>['All'];
  final _locations    = <String>['All'];
  final _levels       = <String>['All'];
  final _jobFields    = <String>['All'];

/* ───────── UI state ───────── */
  String _query = '';
  String _uniF  = 'All';
  String _locF  = 'All';
  String _levF  = 'All';
  String _jobF  = 'All';
  int    _shown = 10;
  List<Map<String, String>> _sug = [];

/* ───────── helpers ───────── */
  /// trim + collapse whitespace/new-lines
  String _clean(String? v) =>
      v?.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';

  bool _match(String filter, String? rawCell) =>
      filter == 'All' || _clean(rawCell) == filter;

  List<Map<String, String>> get _currentCourses {
    final q = _query.toLowerCase();
    return _courses.where((c) {
      final sOK = q.isEmpty ||
          (c['Code']  ?? '').toLowerCase().contains(q) ||
          (c['Title'] ?? '').toLowerCase().contains(q);
      return sOK &&
          _match(_uniF,  c['University']) &&
          _match(_locF,  c['Location'])   &&
          _match(_levF,  c['Level'])      &&
          _match(_jobF,  c['Job Field']);
    }).take(_shown).toList();
  }

  void _updateSug(String q) {
    final L = q.toLowerCase();
    setState(() {
      _sug = q.isEmpty
          ? []
          : _courses.where((c) =>
              (c['Code']  ?? '').toLowerCase().contains(L) ||
              (c['Title'] ?? '').toLowerCase().contains(L))
              .take(5)
              .toList();
    });
  }

  Widget _logo(String? uni) {
    final path = _logoMap[(uni ?? '').trim().toUpperCase()] ?? _placeholderLogo;
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(_placeholderLogo, fit: BoxFit.cover),
        ),
      ),
    );
  }

  DropdownButtonFormField<String> _drop(
      String label, String val, List<String> items, ValueChanged<String> cb) {
    return DropdownButtonFormField<String>(
      value: val,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items
          .map((v) => DropdownMenuItem(
                value: v,
                child: Text(v, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => cb(v));
      },
    );
  }

/* ───────── init & CSV loader ───────── */
  @override
  void initState() {
    super.initState();
    unawaited(_loadCsv());
  }

  Future<void> _loadCsv() async {
    // 1. read CSV
    final raw = await rootBundle.loadString(_csvAsset);
    final table = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(raw);

    // 2. headers
    final headers = table.first.map((e) => e.toString().trim()).toList();
    const required = ['University', 'Location', 'Level', 'Job Field'];
    if (!required.every(headers.contains)) {
      throw StateError('CSV missing one of $required');
    }

    // 3. containers for unique values
    final uniSet = <String>{}, locSet = <String>{},
          levSet = <String>{}, jobSet = <String>{};

    final data = <Map<String, String>>[];

    // 4. iterate rows
    for (var r = 1; r < table.length; r++) {
      final rawRow = table[r];
      if (rawRow.every((e) => e.toString().trim().isEmpty)) continue;

      // normalise to correct length
      final row = rawRow.map((e) => e.toString()).toList();
      final fixed = row.length == headers.length
          ? row
          : row.length > headers.length
              ? [...row.take(headers.length - 1),
                 row.sublist(headers.length - 1).join(',')]
              : [...row, ...List.filled(headers.length - row.length, '')];

      final rec = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        rec[headers[i]] = _clean(fixed[i]);
      }
      data.add(rec);

      // collect sets
      if (rec['University']!.isNotEmpty) uniSet.add(rec['University']!);
      if (rec['Location']!.isNotEmpty)   locSet.add(rec['Location']!);
      if (rec['Level']!.isNotEmpty)      levSet.add(rec['Level']!);
      if (rec['Job Field']!.isNotEmpty)  jobSet.add(rec['Job Field']!);
    }

    // 5. sort lists
    final levList = levSet.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a), bi = int.tryParse(b);
        return (ai != null && bi != null) ? ai.compareTo(bi) : a.compareTo(b);
      });

    setState(() {
      _courses      = data;
      _universities
        ..clear() ..addAll(['All', ...uniSet.toList()..sort()]);
      _locations
        ..clear() ..addAll(['All', ...locSet.toList()..sort()]);
      _levels
        ..clear() ..addAll(['All', ...levList]);
      _jobFields
        ..clear() ..addAll(['All', ...jobSet.toList()..sort()]);
    });
  }

/* ───────── UI ───────── */
  @override
  Widget build(BuildContext ctx) {
    final res = _currentCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAO Search'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _courses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* search */
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by CAO code or course title',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) {
                      _query = v.trimLeft();
                      _updateSug(_query);
                    },
                  ),
                  if (_sug.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: _sug.length,
                        itemBuilder: (_, i) {
                          final s = _sug[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${s['Code']}  •  ${s['Title']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _query = s['Title'] ?? '';
                                _sug.clear();
                              });
                            },
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 12),

                  /* filters */
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 200,
                        child: _drop('University', _uniF, _universities,
                            (v) => _uniF = v),
                      ),
                      SizedBox(
                        width: 200,
                        child: _drop('Location', _locF, _locations,
                            (v) => _locF = v),
                      ),
                      SizedBox(
                        width: 120,
                        child:
                            _drop('Level', _levF, _levels, (v) => _levF = v),
                      ),
                      SizedBox(
                        width: 200,
                        child: _drop('Job Field', _jobF, _jobFields,
                            (v) => _jobF = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /* info + reset */
                  Row(
                    children: [
                      Text('Results: ${res.length}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _uniF = _locF = _levF = _jobF = 'All';
                            _shown = 10;
                            _sug.clear();
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /* list */
                  Expanded(
                    child: res.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses match the selected filters.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: res.length,
                            itemBuilder: (_, i) {
                              final c = res[i];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: _logo(c['University']),
                                  title: Text(c['Title'] ?? '—',
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    '${c['University']} • ${c['Location']} • '
                                    'Level ${c['Level']} • ${c['Job Field']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    c['Code'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  /* load-more / fewer */
                  if (res.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_shown < _courses.length)
                          ElevatedButton(
                            onPressed: () => setState(() => _shown += 10),
                            child: const Text('Load More'),
                          ),
                        if (_shown > 10) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => setState(() => _shown = 10),
                            child: const Text('Show Less'),
                          ),
                        ]
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
