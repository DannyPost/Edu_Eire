// lib/calendar/ics_exporter.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

import 'event.dart';

String _two(int n) => n.toString().padLeft(2, '0');

// All-day date (YYYYMMDD)
String _icsDate(DateTime d) {
  final local = DateTime(d.year, d.month, d.day);
  return '${local.year}${_two(local.month)}${_two(local.day)}';
}

// Escape ICS special chars
String _icsEscape(String s) => s
    .replaceAll(r'\', r'\\')
    .replaceAll('\n', r'\n')
    .replaceAll(',', r'\,')
    .replaceAll(';', r'\;');

String buildICS(List<Event> events) {
  final now = DateTime.now().toUtc();
  final dtstamp =
      '${now.year}${_two(now.month)}${_two(now.day)}T${_two(now.hour)}${_two(now.minute)}${_two(now.second)}Z';

  final buf = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//Edu Éire//Student Calendar//EN')
    ..writeln('CALSCALE:GREGORIAN')
    ..writeln('METHOD:PUBLISH');

  for (final e in events) {
    final start = _icsDate(e.date);
    // all-day events end next day per spec
    final end = _icsDate(e.date.add(const Duration(days: 1)));
    final uid = '${e.date.millisecondsSinceEpoch}-${e.title.hashCode}@edueire';

    buf
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:$uid')
      ..writeln('DTSTAMP:$dtstamp')
      ..writeln('DTSTART;VALUE=DATE:$start')
      ..writeln('DTEND;VALUE=DATE:$end')
      ..writeln('SUMMARY:${_icsEscape(e.title)}')
      ..writeln('CATEGORIES:${_icsEscape(e.category)}')
      ..writeln('DESCRIPTION:${_icsEscape(e.note ?? '')}')
      ..writeln('END:VEVENT');
  }

  buf.writeln('END:VCALENDAR');
  return buf.toString();
}

Future<void> exportICS(List<Event> events, void Function(String) showMessage) async {
  try {
    final ics = buildICS(events);
    final bytes = Uint8List.fromList(utf8.encode(ics));
    await FileSaver.instance.saveFile(
      name: 'EduEire_Events',
      bytes: bytes,
      fileExtension: 'ics',
      mimeType: MimeType.custom,
      customMimeType: 'text/calendar', // ✅ official .ics MIME
    );
    showMessage('Calendar exported as .ics');
  } catch (e) {
    showMessage('Export failed: $e');
  }
}

