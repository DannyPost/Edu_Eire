// lib/cao_search/cao_search_page.dart (formerly cao_search.dart)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:provider/provider.dart'; // Import provider

// Using the Course class from course.dart
import 'course.dart';

// ------------------- CourseProvider (moved here) -------------------
class CourseProvider with ChangeNotifier {
  List<Course> _allCourses = [];
  List<Course> _filtered = [];
  int _loadedCount = 20;
  String _search = '';
  String? _universityFilter, _locationFilter, _levelFilter, _jobFieldFilter; // Renamed to avoid confusion with Course properties

  // Initialize method to load CSV and apply initial filters
  Future<void> initLoadFromCsv(String csvPath) async {
    final rawData = await rootBundle.loadString(csvPath);
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(rawData);

    _allCourses = csvTable.skip(1).map((row) => Course(
      row[0].toString().trim().split('.').first, // level
      row[1].toString().trim(), // code
      row[2].toString().trim(), // title
      row[3].toString().trim(), // location
      row[4].toString().trim(), // university
      row[5].toString().trim(), // jobField
    )).toList();
    applyFilters();
    notifyListeners(); // Notify after initial load and filter
  }

  void applyFilters() {
    _filtered = _allCourses.where((course) {
      final matchesSearch = course.code.toLowerCase().contains(_search) ||
          course.title.toLowerCase().contains(_search) ||
          course.university.toLowerCase().contains(_search); // Added university to search

      final matchesUniversity = _universityFilter == null || _universityFilter == 'All' || course.university == _universityFilter;
      final matchesLocation = _locationFilter == null || _locationFilter == 'All' || course.location == _locationFilter;
      final matchesLevel = _levelFilter == null || _levelFilter == 'All' || course.level == _levelFilter;
      final matchesJobField = _jobFieldFilter == null || _jobFieldFilter == 'All' || course.jobField == _jobFieldFilter;

      return matchesSearch && matchesUniversity && matchesLocation && matchesLevel && matchesJobField;
    }).toList();
    _loadedCount = 20; // Reset loaded count on new filter
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
    if (university != null) _universityFilter = university;
    if (location != null) _locationFilter = location;
    if (level != null) _levelFilter = level;
    if (jobField != null) _jobFieldFilter = jobField;
    applyFilters();
  }

  List<String> getUnique(List<Course> courses, String Function(Course) selector) {
    return ['All', ...{...courses.map(selector)}.where((e) => e.isNotEmpty).toSet().toList()..sort()];
  }

  List<String> get universities => getUnique(_allCourses, (c) => c.university);
  List<String> get locations => getUnique(_allCourses, (c) => c.location);
  List<String> get levels => ['All', '6', '7', '8']; // Hardcoded as per your original logic
  List<String> get jobFields => getUnique(_allCourses, (c) => c.jobField);
}

// ------------------- CAOSearchPage (formerly CoursePage) -------------------
class CAOSearchPage extends StatefulWidget {
  const CAOSearchPage({super.key});

  @override
  State<CAOSearchPage> createState() => _CAOSearchPageState();
}

class _CAOSearchPageState extends State<CAOSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load courses when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).initLoadFromCsv('assets/cao_list_25.csv');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the CourseProvider
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAO Course Search'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by title, code, or university',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    courseProvider.setSearch('');
                  },
                ),
              ),
              onChanged: (value) {
                courseProvider.setSearch(value);
              },
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterDropdown(
                    "Job Field",
                    courseProvider._jobFieldFilter ?? 'All', // Use provider's filter state
                    courseProvider.jobFields,
                    (val) => courseProvider.setFilter(jobField: val),
                  ),
                  _buildFilterDropdown(
                    "Location",
                    courseProvider._locationFilter ?? 'All',
                    courseProvider.locations,
                    (val) => courseProvider.setFilter(location: val),
                  ),
                  _buildFilterDropdown(
                    "University",
                    courseProvider._universityFilter ?? 'All',
                    courseProvider.universities,
                    (val) => courseProvider.setFilter(university: val),
                  ),
                  _buildFilterDropdown(
                    "Level",
                    courseProvider._levelFilter ?? 'All',
                    courseProvider.levels,
                    (val) => courseProvider.setFilter(level: val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: courseProvider.visibleCourses.isEmpty
                  ? const Center(child: Text("No matching courses found."))
                  : ListView.builder(
                      itemCount: courseProvider.visibleCourses.length + (courseProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < courseProvider.visibleCourses.length) {
                          final course = courseProvider.visibleCourses[index];
                          return Card(
                            child: ListTile(
                              title: Text('${course.code} - ${course.title}'),
                              subtitle: Text('${course.university} • Level ${course.level} • ${course.location}'),
                              trailing: SizedBox(
                                width: 100,
                                child: Text(
                                  course.jobField,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: courseProvider.loadMore,
                                child: const Text('Load More'),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Filter by $label", style: const TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: options.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          ),
        ],
      ),
    );
  }
}