import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cao_search_provider.dart';
import 'course.dart';
import 'course_detail_page.dart';

class CAOSearchPage extends StatelessWidget {
  const CAOSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CAOCourseProvider()..loadCourses(),
      child: const _CAOSearchView(),
    );
  }
}

/* ───────────────── INTERNAL VIEW ───────────────── */

class _CAOSearchView extends StatelessWidget {
  const _CAOSearchView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CAOCourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAO Course Search'),
        actions: [
          IconButton(
            tooltip: 'Reset Filters',
            icon: const Icon(Icons.refresh),
            onPressed: provider.resetFilters,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: const [
                _SearchBar(),
                _FilterSection(),
                Expanded(child: _CourseList()),
              ],
            ),
    );
  }
}

/* ───────────────── SEARCH BAR ───────────────── */

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CAOCourseProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔍 Search input
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: provider.setSearch,
            decoration: InputDecoration(
              hintText: 'Search by CAO code or course title',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // 🔽 Search suggestions (Step 7.2)
        if (provider.suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.suggestions.length,
              itemBuilder: (_, i) {
                final c = provider.suggestions[i];
                return ListTile(
                  dense: true,
                  title: Text('${c.code} – ${c.title}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<CAOCourseProvider>(),
                          child: CourseDetailPage(course: c),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

/* ───────────────── FILTER SECTION ───────────────── */

class _FilterSection extends StatelessWidget {
  const _FilterSection();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CAOCourseProvider>();

    Widget dropdown({
      required String label,
      required String value,
      required List<String> items,
      required void Function(String?) onChanged,
    }) {
      return Expanded(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              dropdown(
                label: 'University',
                value: p.university,
                items: p.universities,
                onChanged: (v) => p.setFilters(university: v),
              ),
              const SizedBox(width: 10),
              dropdown(
                label: 'Location',
                value: p.location,
                items: p.locations,
                onChanged: (v) => p.setFilters(location: v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              dropdown(
                label: 'Level',
                value: p.level,
                items: p.levels,
                onChanged: (v) => p.setFilters(level: v),
              ),
              const SizedBox(width: 10),
              dropdown(
                label: 'Job Field',
                value: p.jobField,
                items: p.jobFields,
                onChanged: (v) => p.setFilters(jobField: v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Results: ${p.courses.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────── COURSE LIST ───────────────── */

class _CourseList extends StatelessWidget {
  const _CourseList();

  @override
  Widget build(BuildContext context) {
    final List<Course> courses = context.watch<CAOCourseProvider>().courses;

    if (courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses match your search or filters.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Text(
              '${course.code} – ${course.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.university,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level ${course.level} • ${course.location}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                context.watch<CAOCourseProvider>().isFavorite(course.code)
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                context.read<CAOCourseProvider>().toggleFavorite(course.code);
              },
            ),
            onTap: () {
              debugPrint('Tapped ${course.code}');
            },
          ),
        );
      },
    );
  }
}
