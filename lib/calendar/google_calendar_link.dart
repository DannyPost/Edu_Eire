import 'package:url_launcher/url_launcher.dart';

/// Helper to open Google Calendar "Create event" with fields prefilled.
/// Works on mobile and web. Falls back to the browser if the app isn’t installed.
class GoogleCalendarLink {
  /// Opens Google Calendar with a prefilled event template.
  ///
  /// [start] and [end] are in local time; we convert to UTC for Google format.
  /// For all-day events, pass [allDay]: true and only the date parts are used.
  static Future<void> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
    bool allDay = false,
  }) async {
    // Convert to UTC in the correct Google Calendar time format.
    String formatDate(DateTime dt) {
      final utc = dt.toUtc();
      return allDay
          ? utc.toIso8601String().split('T').first // just YYYY-MM-DD
          : utc.toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';
    }

    final startTime = formatDate(start);
    final endTime = formatDate(end);

    // Construct the Google Calendar event creation URL.
    final Uri googleUrl = Uri.parse(
      'https://www.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=$startTime/$endTime'
      '${description != null ? '&details=${Uri.encodeComponent(description)}' : ''}'
      '${location != null ? '&location=${Uri.encodeComponent(location)}' : ''}'
      '&sf=true&output=xml',
    );

    // Try launching the URL
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Calendar';
    }
  }
}
