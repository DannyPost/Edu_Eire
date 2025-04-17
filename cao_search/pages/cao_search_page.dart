import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

class CAOSearchPage extends StatefulWidget {
  const CAOSearchPage({super.key});

  @override
  State<CAOSearchPage> createState() => _CAOSearchPageState();
}

class _CAOSearchPageState extends State<CAOSearchPage> with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String? selectedField;
  String? selectedLocation;
  String? selectedCollege;
  String? selectedLevel;
  String? sortOption;
  RangeValues selectedPointsRange = const RangeValues(100, 600);

  final List<String> fieldsOfStudy = [
    'Business', 'Science', 'Engineering', 'Arts', 'Media', 'Healthcare', 'IT', 'Education', 'Law', 'Social Science'
  ];

  final List<String> countiesList = [
    'Carlow', 'Cavan', 'Clare', 'Cork', 'Donegal', 'Dublin', 'Galway', 'Kerry', 'Kildare', 'Kilkenny',
    'Laois', 'Leitrim', 'Limerick', 'Longford', 'Louth', 'Mayo', 'Meath', 'Monaghan', 'Offaly',
    'Roscommon', 'Sligo', 'Tipperary', 'Waterford', 'Westmeath', 'Wexford', 'Wicklow'
  ];

  final List<String> collegesList = [
  'American College Dublin',
  'National College of Art and Design',
  'Atlantic Technological University',
  'IBAT College Dublin',
  'University College Cork (NUI)',
  'Marino Institute of Education',
  'CCT College Dublin',
  'Dublin Business School',
  'Dublin City University',
  'Dundalk Institute of Technology',
  'Dun Laoghaire Institute of Art, Design and Technology',
  'University College Dublin (NUI)',
  'Dorset College',
  'Galway Business School',
  'Griffith College',
  'University of Galway',
  'ICD Business School',
  'University of Limerick',
  'Maynooth University',
  'Mary Immaculate College',
  'Munster Technological University',
  'Pontifical University, St Patrick\'s College',
  'National College of Ireland (NCI)',
  'Carlow College, St. Patrick\'s',
  'RCSI University of Medicine & Health Sciences',
  'Setanta College',
  'South East Technological University',
  'Trinity College Dublin',
  'Technological University Dublin',
  'Technological University of the Shannon',
];


  final List<String> levels = ['6', '7', '8'];
  final List<String> sortOptions = ['Alphabetical (A-Z)', 'Points (Low to High)', 'Points (High to Low)'];

  late final List<Map<String, dynamic>> dummyCourses;
  late AnimationController _controller;
  late Animation<double> _animation;

  int displayedCourses = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    dummyCourses = List.generate(20, (index) => {
      'title': 'Course ${index + 1}',
      'college': 'College ${index % 5 + 1}',
      'location': countiesList[index % countiesList.length],
      'code': 'AB${100 + index}',
      'level': (index % 3 + 6).toString(),
      'points': 300 + (index * 15) % 300,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> applySorting(List<Map<String, dynamic>> courses) {
    switch (sortOption) {
      case 'Alphabetical (A-Z)':
        courses.sort((a, b) => a['title'].compareTo(b['title']));
        break;
      case 'Points (Low to High)':
        courses.sort((a, b) => a['points'].compareTo(b['points']));
        break;
      case 'Points (High to Low)':
        courses.sort((a, b) => b['points'].compareTo(a['points']));
        break;
    }
    return courses;
  }

  Widget buildCourseCard(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(course['title']),
        subtitle: Text("${course['college']} • ${course['location']} • Level ${course['level']} • ${course['points']} pts"),
        trailing: Text(course['code']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredCourses = dummyCourses.where((course) {
      final matchesQuery = searchQuery.isEmpty || course['title'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesField = selectedField == null || course['title'].toLowerCase().contains(selectedField!.toLowerCase());
      final matchesLocation = selectedLocation == null || course['location'] == selectedLocation;
      final matchesCollege = selectedCollege == null || course['college'] == selectedCollege;
      final matchesLevel = selectedLevel == null || course['level'] == selectedLevel;
      final matchesPoints = course['points'] >= selectedPointsRange.start && course['points'] <= selectedPointsRange.end;
      return matchesQuery && matchesField && matchesLocation && matchesCollege && matchesLevel && matchesPoints;
    }).toList();

    filteredCourses = applySorting(filteredCourses).take(displayedCourses).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAO Search'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.lightBlue[50],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Courses',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: selectedField,
                      hint: const Text('Field of Study'),
                      items: fieldsOfStudy.map((field) => DropdownMenuItem(value: field, child: Text(field))).toList(),
                      onChanged: (value) => setState(() => selectedField = value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: selectedLocation,
                      hint: const Text('County'),
                      items: countiesList.map((county) => DropdownMenuItem(value: county, child: Text(county))).toList(),
                      onChanged: (value) => setState(() => selectedLocation = value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: selectedCollege,
                      hint: const Text('College'),
                      items: collegesList.map((college) => DropdownMenuItem(value: college, child: Text(college))).toList(),
                      onChanged: (value) => setState(() => selectedCollege = value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      value: selectedLevel,
                      hint: const Text('NFQ Level'),
                      items: levels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                      onChanged: (value) => setState(() => selectedLevel = value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: sortOption,
                      hint: const Text('Sort By'),
                      items: sortOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                      onChanged: (value) => setState(() => sortOption = value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Points Range"),
                      RangeSlider(
                        values: selectedPointsRange,
                        min: 0,
                        max: 600,
                        divisions: 12,
                        labels: RangeLabels(
                          selectedPointsRange.start.round().toString(),
                          selectedPointsRange.end.round().toString(),
                        ),
                        onChanged: (RangeValues values) {
                          setState(() => selectedPointsRange = values);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  return buildCourseCard(filteredCourses[index]);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (displayedCourses < dummyCourses.length)
                  ElevatedButton(
                    onPressed: () => setState(() => displayedCourses += 5),
                    child: const Text('Load More'),
                  ),
                const SizedBox(width: 10),
                if (displayedCourses > 5)
                  ElevatedButton(
                    onPressed: () => setState(() => displayedCourses = 5),
                    child: const Text('Show Less'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}