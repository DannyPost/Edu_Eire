// lib/calendar/event.dart
class Event {
  final String title;
  final DateTime date;
  final String category;
  final String? note;

  const Event({
    required this.title,
    required this.date,
    required this.category,
    this.note,
  });
}
