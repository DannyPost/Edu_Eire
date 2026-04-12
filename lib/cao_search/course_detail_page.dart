import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'course.dart';
import 'cao_search_provider.dart';
import 'university_logo.dart';

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CAOCourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(course.code),
        actions: [
          IconButton(
            icon: Icon(
              provider.isFavorite(course.code)
                  ? Icons.star
                  : Icons.star_border,
            ),
            onPressed: () => provider.toggleFavorite(course.code),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UniversityLogo(university: course.university),
            const SizedBox(height: 16),

            Text(
              course.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Text('University: ${course.university}'),
            Text('Location: ${course.location}'),
            Text('Level: ${course.level}'),
            Text('Job Field: ${course.jobField}'),
          ],
        ),
      ),
    );
  }
}
