class Event {
  final String title;
  final DateTime date;
  final String category;
  final String? note;

  Event({
    required this.title,
    required this.date,
    required this.category,
    this.note,
  });
}
