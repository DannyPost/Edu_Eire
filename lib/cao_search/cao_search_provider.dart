// lib/cao_search/cao_course_provider.dart
import 'package:flutter/material.dart'; // Keep this for ChangeNotifier
import 'package:csv/csv.dart';
import 'course.dart'; // Assuming course.dart is in the same directory

class CAOCourseProvider with ChangeNotifier { // Renamed from CAOSearchPage
  List<Course> _allCourses = [];
  List<Course> _filtered = [];
  int _loadedCount = 20;
  String _search = '';
  String? _university, _location, _level, _jobField;

  // Constructor is not needed if you only use loadFromCsv
  // CAOCourseProvider(); // No const constructor here as it manages mutable state

  void loadFromCsv(String csvString) {
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');
    // Ensure that Course.fromList expects 6 values, based on your Course model
    _allCourses = rows.skip(1).map((e) => Course.fromList(e.map((e) => '$e').toList())).toList();
    applyFilters();
  }

  void applyFilters() {
    _filtered = _allCourses.where((course) {
      final matchesSearch = course.code.toLowerCase().contains(_search) ||
          course.title.toLowerCase().contains(_search);
      final matchesUniversity = _university == null || course.university == _university;
      final matchesLocation = _location == null || course.location == _location;
      final matchesLevel = _level == null || course.level == _level;
      final matchesJobField = _jobField == null || course.jobField == _jobField;
      return matchesSearch && matchesUniversity && matchesLocation && matchesLevel && matchesJobField;
    }).toList();
    _loadedCount = 20; // Reset loaded count on filter change
    notifyListeners();
  }

  List<Course> get visibleCourses => _filtered.take(_loadedCount).toList();
  bool get hasMore => _loadedCount < _filtered.length;

  void loadMore() {
    _loadedCount += 20;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value.toLowerCase();
    applyFilters();
  }

  void setFilter({String? university, String? location, String? level, String? jobField}) {
    _university = university;
    _location = location;
    _level = level;
    _jobField = jobField;
    applyFilters();
  }

  // Ensure these getters correctly extract unique values from _allCourses
  List<String> get universities => _allCourses.map((c) => c.university).toSet().toList()..sort();
  List<String> get locations => _allCourses.map((c) => c.location).toSet().toList()..sort();
  List<String> get levels => _allCourses.map((c) => c.level).toSet().toList()..sort();
  List<String> get jobFields => _allCourses.map((c) => c.jobField).toSet().toList()..sort();
}