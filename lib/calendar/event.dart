// lib/calendar/event.dart
//
// Unified event model for:
// - Public, timed events from Firestore: startsAt/endsAt, orgId/audience.colleges, location, description
// - Local/personal/all-day events: date-only + note
//
// Calendar UI groups by `date` (UTC midnight). For timed events we derive
// that from `startsAt`.

class Event {
  final String title;

  /// Date-only key used by the calendar grid (UTC midnight).
  final DateTime date;

  /// Optional start/end for timed events (from Firestore).
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Category (e.g., "Academic") or your legacy values.
  final String category;

  /// Note/description.
  final String? note;

  /// College/organisation. Mapped from orgId, audience.colleges[0], or college.
  final String? college;

  /// Optional location from Firestore (`location`).
  final String? location;

  const Event({
    required this.title,
    required this.date,
    required this.category,
    this.note,
    this.college,
    this.startsAt,
    this.endsAt,
    this.location,
  });

  // ---------------- Firestore mapping ----------------
  factory Event.fromFirestore(Map<String, dynamic> doc) {
    // Title
    final title = (doc['title'] ?? '') as String;

    // Category
    final category = (doc['category'] ?? 'other') as String;

    // Description / legacy note
    final note = (doc['description'] as String?) ?? (doc['note'] as String?);

    // College / Org: prefer orgId; else audience.colleges[0]; else 'college'
    String? college;
    if (doc['orgId'] is String && (doc['orgId'] as String).trim().isNotEmpty) {
      college = (doc['orgId'] as String).trim();
    } else if (doc['audience'] is Map<String, dynamic>) {
      final aud = doc['audience'] as Map<String, dynamic>;
      if (aud['colleges'] is List && (aud['colleges'] as List).isNotEmpty) {
        final first = (aud['colleges'] as List).first;
        if (first is String && first.trim().isNotEmpty) {
          college = first.trim();
        }
      }
    } else if (doc['college'] is String && (doc['college'] as String).trim().isNotEmpty) {
      college = (doc['college'] as String).trim();
    }

    // Location
    final location = (doc['location'] as String?);

    // Timed vs date-only
    DateTime? startsAt;
    DateTime? endsAt;
    if (doc['startsAt'] != null) {
      startsAt = (doc['startsAt'] as dynamic).toDate() as DateTime;
    }
    if (doc['endsAt'] != null) {
      endsAt = (doc['endsAt'] as dynamic).toDate() as DateTime;
    }

    // Legacy date (Timestamp) fallback
    DateTime? legacyDate;
    if (doc['date'] != null) {
      legacyDate = (doc['date'] as dynamic).toDate() as DateTime;
    }

    // Compute date key for calendar grouping
    final base = startsAt ?? legacyDate ?? DateTime.now().toUtc();
    final dateOnly = DateTime.utc(base.year, base.month, base.day);

    return Event(
      title: title,
      category: category,
      note: note,
      college: college,
      startsAt: startsAt,
      endsAt: endsAt,
      location: location,
      date: dateOnly,
    );
  }

  /// Writer used if you persist personal events to Firestore.
  Map<String, dynamic> toFirestore() {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return {
      'title': title,
      'date': normalized, // personal events as all-day
      'category': category,
      'note': note,
      'college': college,
      'location': location,
      'titleLower': title.toLowerCase(),
      'createdAt': DateTime.now().toUtc(),
    };
  }
}
