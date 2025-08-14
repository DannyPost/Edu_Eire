import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class Course {
  final String code;
  final String title;
  final String level;
  final String university;
  final String location;
  final String jobField;

  Course({
    required this.code,
    required this.title,
    required this.level,
    required this.university,
    required this.location,
    required this.jobField,
  });
}

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  List<Course> allCourses = [];
  List<Course> filteredCourses = [];
  bool isLoading = true; // Added loading state

  // These will hold the CURRENTLY APPLIED filters from the main page state
  String selectedJobField = 'All';
  String selectedUniversity = 'All';
  String selectedLocation = 'All';
  String selectedLevel = 'All';
  String searchQuery = '';

  // Controller for the main search bar
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCSV(); // Renamed for clarity with async
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
        applyFilters();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCSV() async { // Renamed from loadCSV
    try {
      final rawData = await rootBundle.loadString('assets/cao_list_25.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(rawData);

      List<Course> courses = csvTable.skip(1).map((row) => Course(
        code: row[1].toString().trim(),
        title: row[2].toString().trim(),
        level: row[0].toString().trim().split('.').first,
        university: row[4].toString().trim(),
        location: row[3].toString().trim(),
        jobField: row[5].toString().trim(),
      )).toList();

      setState(() {
        allCourses = courses;
        isLoading = false; // Set loading to false once data is loaded
        applyFilters(); // Apply initial filters
      });
    } catch (e) {
      print("Error loading CSV: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredCourses = allCourses.where((course) {
        final matchJobField = selectedJobField == 'All' || course.jobField == selectedJobField;
        final matchUniversity = selectedUniversity == 'All' || course.university == selectedUniversity;
        final matchLocation = selectedLocation == 'All' || course.location == selectedLocation;
        final matchLevel = selectedLevel == 'All' || course.level == selectedLevel;
        final matchSearch = searchQuery.isEmpty ||
            course.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
            course.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            course.university.toLowerCase().contains(searchQuery.toLowerCase());

        return matchJobField && matchUniversity && matchLocation && matchLevel && matchSearch;
      }).toList();
    });
  }

  List<String> getUnique(List<Course> courses, String Function(Course) selector) {
    return ['All', ...{...courses.map(selector)}.where((e) => e.isNotEmpty).toList()..sort()];
  }

  // New method to show the filter bottom sheet
  void _showFilterSheet(BuildContext context) {
    // These will hold the filter selections *within* the bottom sheet
    // They are temporary until 'Apply' is pressed
    String tempSelectedJobField = selectedJobField;
    String tempSelectedUniversity = selectedUniversity;
    String tempSelectedLocation = selectedLocation;
    String tempSelectedLevel = selectedLevel;

    final jobFields = getUnique(allCourses, (c) => c.jobField);
    final universities = getUnique(allCourses, (c) => c.university);
    final locations = getUnique(allCourses, (c) => c.location);
    final levels = ['All', '6', '7', '8']; // As per original code

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      builder: (BuildContext bc) {
        return StatefulBuilder( // Use StatefulBuilder to manage state within the bottom sheet
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Courses',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Job Field Filter (Chips for better mobile selection)
                    Text('Job Field', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: jobFields.map((field) {
                        return ChoiceChip(
                          label: Text(field),
                          selected: tempSelectedJobField == field,
                          onSelected: (selected) {
                            setModalState(() {
                              tempSelectedJobField = selected ? field : 'All';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // University Filter (Dropdown)
                    Text('University', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: tempSelectedUniversity,
                      items: universities.map((uni) {
                        return DropdownMenuItem(value: uni, child: Text(uni));
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempSelectedUniversity = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Filter (Dropdown)
                    Text('Location', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: tempSelectedLocation,
                      items: locations.map((loc) {
                        return DropdownMenuItem(value: loc, child: Text(loc));
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempSelectedLocation = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Level Filter (Chips)
                    Text('Level', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: levels.map((lvl) {
                        return ChoiceChip(
                          label: Text(lvl),
                          selected: tempSelectedLevel == lvl,
                          onSelected: (selected) {
                            setModalState(() {
                              tempSelectedLevel = selected ? lvl : 'All';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons: Clear and Apply
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedJobField = 'All';
                                tempSelectedUniversity = 'All';
                                tempSelectedLocation = 'All';
                                tempSelectedLevel = 'All';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                            child: const Text('Clear Filters'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedJobField = tempSelectedJobField;
                                selectedUniversity = tempSelectedUniversity;
                                selectedLocation = tempSelectedLocation;
                                selectedLevel = tempSelectedLevel;
                              });
                              applyFilters(); // Apply filters to the main list
                              Navigator.pop(context); // Close the bottom sheet
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Padding for the bottom
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // New method to clear all filters (including search) from the main screen
  void _clearAllFilters() {
    setState(() {
      selectedJobField = 'All';
      selectedUniversity = 'All';
      selectedLocation = 'All';
      selectedLevel = 'All';
      searchQuery = '';
      _searchController.clear(); // Clear the search text field
      applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllFilters,
            tooltip: 'Clear All Filters',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Open Filters',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by title, code, or university',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Rounded corners
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    ),
                    // onChanged is now handled by the listener on _searchController
                  ),
                ),
                // Display active filters as chips (more user-friendly)
                if (selectedJobField != 'All' ||
                    selectedUniversity != 'All' ||
                    selectedLocation != 'All' ||
                    selectedLevel != 'All')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        if (selectedJobField != 'All')
                          Chip(
                            label: Text('Job Field: $selectedJobField'),
                            onDeleted: () {
                              setState(() {
                                selectedJobField = 'All';
                                applyFilters();
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Compact chip
                          ),
                        if (selectedUniversity != 'All')
                          Chip(
                            label: Text('University: $selectedUniversity'),
                            onDeleted: () {
                              setState(() {
                                selectedUniversity = 'All';
                                applyFilters();
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (selectedLocation != 'All')
                          Chip(
                            label: Text('Location: $selectedLocation'),
                            onDeleted: () {
                              setState(() {
                                selectedLocation = 'All';
                                applyFilters();
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (selectedLevel != 'All')
                          Chip(
                            label: Text('Level: $selectedLevel'),
                            onDeleted: () {
                              setState(() {
                                selectedLevel = 'All';
                                applyFilters();
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10), // Spacing between search/chips and list
                Expanded(
                  child: filteredCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sentiment_dissatisfied, size: 50, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              const Text(
                                'No matching courses found.',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              if (searchQuery.isNotEmpty || selectedJobField != 'All' || selectedUniversity != 'All' || selectedLocation != 'All' || selectedLevel != 'All')
                                const Text(
                                  'Try a different search term or clear filters.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              elevation: 2.0, // Subtle shadow
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12.0),
                                title: Text(
                                  '${course.code} - ${course.title}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.university,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                      ),
                                      Text(
                                        'Level ${course.level} • ${course.location}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 80, // Adjust width as needed
                                  child: Text(
                                    course.jobField,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                // Add a subtle visual tap effect
                                onTap: () {
                                  // Optional: Implement a dialog or new page for course details here
                                  // For now, it just gives a ripple effect.
                                  print('Tapped on ${course.title}');
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Removed _buildFilterDropdown as it's no longer used for the main filter UI
  // The filter UI is now handled within _showFilterSheet
}