import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String _gcDate(DateTime dt) {
  // Google expects UTC timestamps like 20251018T120000Z
  return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(dt.toUtc());
}

Uri buildGoogleCalendarUri({
  required String title,
  required DateTime start,
  required DateTime end,
  String? description,
  String? location,
}) {
  return Uri.https(
    'calendar.google.com',
    '/calendar/render',
    {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${_gcDate(start)}/${_gcDate(end)}',
      if (description != null && description.isNotEmpty) 'details': description,
      if (location != null && location.isNotEmpty) 'location': location,
    },
  );
}

Future<void> openInGoogleCalendar({
  required String title,
  required DateTime start,
  DateTime? end,
  String? description,
  String? location,
}) async {
  // Default to 1-hour duration if no end provided
  final finish = end ?? start.add(const Duration(hours: 1));
  final uri = buildGoogleCalendarUri(
    title: title,
    start: start,
    end: finish,
    description: description,
    location: location,
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
