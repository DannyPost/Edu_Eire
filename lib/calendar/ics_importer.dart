import 'package:file_picker/file_picker.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'dart:io';

// Make sure Event is defined here or imported correctly
// Your main calendar logic (if needed)
import 'event.dart';

Future<List<Event>> importICSFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['ics'],
  );

  if (result != null && result.files.single.path != null) {
    final file = File(result.files.single.path!);
    final content = await file.readAsString();

    final calendar = ICalendar.fromString(content); // ✅ Only call once
    final rawData = calendar.data as Map<String, dynamic>?;

    if (rawData == null) return [];

    final eventList = rawData['data'];
    List<Event> newEvents = [];

    if (eventList is List) {
      for (final item in eventList) {
        if (item is Map<String, dynamic>) {
          final summary = item['summary']?.toString();
          final start = DateTime.tryParse(item['dtstart']?.toString() ?? '');

          if (summary != null && start != null) {
            newEvents.add(
              Event(
                title: summary,
                date: start,
                category: 'imported',
              ),
            );
          }
        }
      }
    }

    return newEvents;
  }

  return [];
}
