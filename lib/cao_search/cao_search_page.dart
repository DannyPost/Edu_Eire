// lib/cao_search/cao_search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';

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

  // New method to clear all filters
  void clearAllFilters() {
    _universityFilter = 'All';
    _locationFilter = 'All';
    _levelFilter = 'All';
    _jobFieldFilter = 'All';
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

  // Getters for current filter values (useful for displaying selected filters)
  String? get currentUniversityFilter => _universityFilter;
  String? get currentLocationFilter => _locationFilter;
  String? get currentLevelFilter => _levelFilter;
  String? get currentJobFieldFilter => _jobFieldFilter;
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        final courseProvider = Provider.of<CourseProvider>(context); // Listen to provider for real-time updates

        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Start at 70% height
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false, // Don't expand to full screen by default
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle for dragging the sheet
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Options',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          courseProvider.clearAllFilters(); // Clear all filters
                          Navigator.pop(context); // Close the bottom sheet
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildFilterDropdown(
                          "Job Field",
                          courseProvider.currentJobFieldFilter ?? 'All',
                          courseProvider.jobFields,
                          (val) => courseProvider.setFilter(jobField: val),
                          context // Pass context to access theme within _buildFilterDropdown
                        ),
                        _buildFilterDropdown(
                          "Location",
                          courseProvider.currentLocationFilter ?? 'All',
                          courseProvider.locations,
                          (val) => courseProvider.setFilter(location: val),
                          context
                        ),
                        _buildFilterDropdown(
                          "University",
                          courseProvider.currentUniversityFilter ?? 'All',
                          courseProvider.universities,
                          (val) => courseProvider.setFilter(university: val),
                          context
                        ),
                        _buildFilterDropdown(
                          "Level",
                          courseProvider.currentLevelFilter ?? 'All',
                          courseProvider.levels,
                          (val) => courseProvider.setFilter(level: val),
                          context
                        ),
                        const SizedBox(height: 20),
                        // Add an apply button if filtering doesn't happen onChange
                        // For this setup, filtering happens on change, so an explicit apply might not be needed.
                        // However, a "Done" or "Apply" button can provide closure.
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the bottom sheet
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('Apply Filters', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by title, code, or university',
                hintText: 'e.g., Computer Science, UCD, DN201',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    courseProvider.setSearch('');
                  },
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                courseProvider.setSearch(value);
              },
            ),
            const SizedBox(height: 16),

            // --- Filter Button ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 2,
                  ),
                ),
                // Optional: Display currently active filters as chips (more advanced, but good for UX)
                // For brevity, we are not implementing detailed active filter chips here,
                // but you could add a Row of FilterChip widgets.
              ],
            ),
            const SizedBox(height: 16), // Spacing after filter button

            Expanded(
              child: courseProvider.visibleCourses.isEmpty
                  ? const Center(child: Text("No matching courses found."))
                  : ListView.builder(
                      itemCount: courseProvider.visibleCourses.length + (courseProvider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < courseProvider.visibleCourses.length) {
                          final course = courseProvider.visibleCourses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${course.code} - ${course.title}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${course.university} • Level ${course.level}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${course.location} • ${course.jobField}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: courseProvider.loadMore,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text('Load More', style: TextStyle(fontSize: 16)),
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

  // Modified _buildFilterDropdown to be suitable for vertical layout in a bottom sheet
  Widget _buildFilterDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // More vertical spacing between filter sections
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Spacing between label and dropdown
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: double.infinity, // Make the dropdown take full width
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10.0), // Slightly more rounded for the full-width
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                onChanged: onChanged,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                style: TextStyle(color: Colors.blue.shade700, fontSize: 16),
                items: options.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                isExpanded: true, // Make dropdown take full available width
              ),
            ),
          ),
        ],
      ),
    );
  }
}