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

  String selectedJobField = 'All';
  String selectedUniversity = 'All';
  String selectedLocation = 'All';
  String selectedLevel = 'All';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadCSV();
  }

  Future<void> loadCSV() async {
    final rawData = await rootBundle.loadString('lib/assets/cao_list_25.csv');
    final List<List<dynamic>> csvTable = const CsvToListConverter().convert(rawData);

    allCourses = csvTable.skip(1).map((row) => Course(
      code: row[1].toString().trim(),
      title: row[2].toString().trim(),
      level: row[0].toString().trim().split('.').first,
      university: row[4].toString().trim(),
      location: row[3].toString().trim(),
      jobField: row[5].toString().trim(),
    )).toList();

    applyFilters();
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

  @override
  Widget build(BuildContext context) {
    final jobFields = getUnique(allCourses, (c) => c.jobField);
    final universities = getUnique(allCourses, (c) => c.university);
    final locations = getUnique(allCourses, (c) => c.location);
    final levels = ['All', '6', '7', '8'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('University Courses'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by title, code, or university',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
              },
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterDropdown("Job Field", selectedJobField, jobFields, (val) {
                    selectedJobField = val!;
                    applyFilters();
                  }),
                  _buildFilterDropdown("Location", selectedLocation, locations, (val) {
                    selectedLocation = val!;
                    applyFilters();
                  }),
                  _buildFilterDropdown("University", selectedUniversity, universities, (val) {
                    selectedUniversity = val!;
                    applyFilters();
                  }),
                  _buildFilterDropdown("Level", selectedLevel, levels, (val) {
                    selectedLevel = val!;
                    applyFilters();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredCourses.isEmpty
                  ? const Center(child: Text("No matching courses found."))
                  : ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
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
