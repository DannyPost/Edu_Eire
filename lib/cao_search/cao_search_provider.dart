import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'course.dart';

class CAOCourseProvider extends ChangeNotifier {
  final List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];

  final Set<String> _favorites = {}; // store course codes

  bool isLoading = true;

  String search = '';
  String university = 'All';
  String location = 'All';
  String level = 'All';
  String jobField = 'All';

  List<Course> get courses => _filteredCourses;
  Set<String> get favorites => _favorites;

  /* ───────────────── CSV LOADING ───────────────── */

  Future<void> loadCourses() async {
    if (_allCourses.isNotEmpty) return; // prevent reloading

    final raw = await rootBundle.loadString('assets/cao_list_25.csv');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(raw);

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue;

      final course = Course.fromCsv(row);

      // 🔐 Hard guard against empty / broken rows
      if (course.code.isEmpty || course.title.isEmpty) continue;

      _allCourses.add(course);
    }

    applyFilters();
    isLoading = false;
    notifyListeners();

    debugPrint('TOTAL COURSES LOADED: ${_allCourses.length}');
  }

  /* ───────────────── FILTERING ───────────────── */

  void applyFilters() {
    _filteredCourses = _allCourses.where((c) {
      final matchesSearch = search.isEmpty ||
          c.code.toLowerCase().contains(search) ||
          c.title.toLowerCase().contains(search);

      return matchesSearch &&
          (university == 'All' || c.university == university) &&
          (location == 'All' || c.location == location) &&
          (level == 'All' || c.level == level) &&
          (jobField == 'All' || c.jobField == jobField);
    }).toList();

    notifyListeners();
  }

  /* ───────────────── SEARCH SUGGESTIONS ───────────────── */

  List<Course> get suggestions {
    if (search.isEmpty) return [];
    return _allCourses
        .where((c) =>
            c.code.toLowerCase().contains(search) ||
            c.title.toLowerCase().contains(search))
        .take(5)
        .toList();
  }

  void setSearch(String value) {
    search = value.toLowerCase();
    applyFilters();
  }

  /* ───────────────── FILTER SETTERS ───────────────── */

  void setFilters({
    String? university,
    String? location,
    String? level,
    String? jobField,
  }) {
    this.university = university ?? this.university;
    this.location = location ?? this.location;
    this.level = level ?? this.level;
    this.jobField = jobField ?? this.jobField;
    applyFilters();
  }

  void resetFilters() {
    search = '';
    university = location = level = jobField = 'All';
    applyFilters();
  }

  /* ───────────────── DROPDOWN VALUES (FIXED) ───────────────── */

  List<String> get universities => _buildUniqueList((c) => c.university);
  List<String> get locations => _buildUniqueList((c) => c.location);
  List<String> get levels => _buildUniqueList((c) => c.level);
  List<String> get jobFields => _buildUniqueList((c) => c.jobField);

  List<String> _buildUniqueList(String Function(Course) selector) {
    final set = <String>{};

    for (final c in _allCourses) {
      final value = selector(c).trim();
      if (value.isNotEmpty) {
        set.add(value);
      }
    }

    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /* ───────────────── FAVORITES ───────────────── */

  bool isFavorite(String code) {
    return _favorites.contains(code);
  }

  void toggleFavorite(String code) {
    if (_favorites.contains(code)) {
      _favorites.remove(code);
    } else {
      _favorites.add(code);
    }
    notifyListeners();
  }
}
