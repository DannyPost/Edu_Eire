import 'package:url_launcher/url_launcher.dart';

/// Helper to open Google Calendar "Create event" with fields prefilled.
/// Works on mobile and web. Falls back to the browser if the app isn't installed.
class GoogleCalendarLink {
  /// Opens Google Calendar with a prefilled event template.
  ///
  /// [start] and [end] are in local time; we convert to UTC for Google format.
  /// For all-day events, pass `allDay: true` and only the date parts are used.
  static Future<void> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
    bool allDay = false,
  }) async {
    final dates = _formatDates(start, end, allDay: allDay);
    final uri = Uri.https(
      'www.google.com',
      '/calendar/render',
      <String, String>{
        'action': 'TEMPLATE',
        'text': title,
        if (description != null && description.isNotEmpty) 'details': description,
        if (location != null && location.isNotEmpty) 'location': location,
        'dates': dates,
      },
    );

    // Prefer external app/browser.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback try: in-app webview
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  /// Google Calendar 'dates' parameter formatting:
  /// - Timed:  YYYYMMDDTHHMMSSZ/YYYYMMDDTHHMMSSZ  (UTC)
  /// - All-day: YYYYMMDD/YYYYMMDD  (end is exclusive)
  static String _formatDates(DateTime start, DateTime end, {bool allDay = false}) {
    if (allDay) {
      // For all-day, Google expects end as the *next day* (exclusive).
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
      String d(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      return '${d(s)}/${d(e)}';
    } else {
      // Convert to UTC and format
      String f(DateTime dt) {
        final u = dt.toUtc();
        String two(int v) => v.toString().padLeft(2, '0');
        return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
      }
      return '${f(start)}/${f(end)}';
    }
  }
}
