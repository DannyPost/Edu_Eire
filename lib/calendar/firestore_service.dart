import 'package:cloud_firestore/cloud_firestore.dart';
import 'event.dart';

class EventRepo {
  // Strongly typed collection using withConverter
  final CollectionReference<Event> _col =
      FirebaseFirestore.instance.collection('events').withConverter<Event>(
            fromFirestore: (snap, _) {
              final data = snap.data();
              if (data == null) {
                return Event(
                  title: '(untitled)',
                  category: 'other',
                  note: null,
                  college: null,
                  startsAt: null,
                  endsAt: null,
                  location: null,
                  date: DateTime.utc(1970, 1, 1),
                );
              }
              return Event.fromFirestore(data);
            },
            toFirestore: (event, _) => event.toFirestore(),
          );

  /// Streams events:
  /// - College filter matches ANY of:
  ///     orgId == <college>
  ///  OR audience.colleges array-contains <college>
  ///  OR college == <college>   (fallback if you add it later)
  /// - Category filter uses `category`
  /// - Date range (when provided) filters by `startsAt`
  ///
  /// We only order by `startsAt` when a date filter is present
  /// to avoid silently dropping docs that lack the field.
  Stream<List<Event>> streamEvents({
    String? college,      // 'NCI', 'UCD', etc.
    String? category,     // 'Academic', 'open_day', ...
    DateTime? startDate,  // inclusive; compared against startsAt
    DateTime? endDate,    // inclusive; compared against startsAt
    String? searchText,   // client-side contains on title
  }) {
    Query<Event> q = _col;

    // ----- College filter with OR on multiple field paths -----
    if (college != null && college.trim().isNotEmpty) {
      final c = college.trim();
      // Requires cloud_firestore that supports Filter.or (your 5.6.11 does).
      q = q.where(
        Filter.or(
          Filter('orgId', isEqualTo: c),
          Filter('audience.colleges', arrayContains: c),
          Filter('college', isEqualTo: c),
        ),
      );
    }

    // ----- Category filter (simple equality) -----
    if (category != null && category.isNotEmpty && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }

    // ----- Date filtering (on startsAt) -----
    final hasDateFilter = (startDate != null) || (endDate != null);
    if (hasDateFilter) {
      if (startDate != null) {
        final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
        q = q.where('startsAt', isGreaterThanOrEqualTo: start);
      }
      if (endDate != null) {
        final end = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        q = q.where('startsAt', isLessThanOrEqualTo: end);
      }
      q = q.orderBy('startsAt');
      // If Firestore prompts for an index, create:
      // - orgId + startsAt
      // - category + startsAt
      // - orgId + category + startsAt
      // OR versions with audience.colleges + startsAt if needed.
    }
    // else: no order so docs without startsAt still appear

    return q.snapshots().map((snapshot) {
      var list = snapshot.docs.map((d) => d.data()).toList();

      // Client-side text search (simple and robust)
      if (searchText != null && searchText.trim().isNotEmpty) {
        final txt = searchText.toLowerCase();
        list = list.where((e) => e.title.toLowerCase().contains(txt)).toList();
      }

      return list;
    });
  }

  Future<void> addEvent(Event e) async => _col.add(e);
}
