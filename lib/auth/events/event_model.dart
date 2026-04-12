// lib/auth/events/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalEvent {
  final String id;
  final String title;
  final String description;
  final String category;   // e.g., "Academic"
  final String location;
  final DateTime start;
  final DateTime end;

  /// Auth UID of the organiser who created this event.
  final String organiserId;

  /// Display name of organiser (optional).
  final String organiserName;

  /// College / organisation key like "NCI", "UCD", "TCD".
  final String orgId;

  /// Visible in public feeds?
  final bool isGlobal;

  /// Approved/published?
  final bool approved;

  GlobalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.start,
    required this.end,
    required this.organiserId,
    required this.organiserName,
    required this.orgId,
    required this.isGlobal,
    required this.approved,
  });

  // ------------------------ FROM FIRESTORE ------------------------

  factory GlobalEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    final startsAt = (d['startsAt'] as Timestamp?)?.toDate();
    final endsAt   = (d['endsAt'] as Timestamp?)?.toDate();

    return GlobalEvent(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'Academic',
      location: d['location'] ?? '',
      start: (startsAt ?? DateTime.now()).toLocal(),
      end: (endsAt ?? DateTime.now()).toLocal(),
      organiserId: d['createdBy'] ?? '',               // 👈 IMPORTANT
      organiserName: d['organiserName'] ?? '',
      orgId: d['orgId'] ?? '',
      isGlobal: d['published'] == true || d['isGlobal'] == true,
      approved: d['status'] == 'published' || d['approved'] == true,
    );
  }

  // ------------------------ TO FIRESTORE ------------------------

  /// Map used when creating a brand new event.
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      // store timestamps in UTC
      'startsAt': Timestamp.fromDate(start.toUtc()),
      'endsAt'  : Timestamp.fromDate(end.toUtc()),

      // organiser metadata
      'createdBy': organiserId,                 // 👈 organiser uid
      'organiserName': organiserName,

      // college/org for filters
      'orgId': orgId,

      // audience as in your sample document
      'allowedAudienceKeys': ['all-students'],
      'audience': {
        'colleges': orgId.isNotEmpty ? [orgId] : <String>[],
        'counties': <String>[''],
        'scope': 'all-students',
      },

      // publishing flags
      'published': isGlobal && approved,
      'status': approved ? 'published' : 'draft',

      // misc metadata
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Map used when updating an existing event.
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'startsAt': Timestamp.fromDate(start.toUtc()),
      'endsAt'  : Timestamp.fromDate(end.toUtc()),
      'orgId': orgId,
      'allowedAudienceKeys': ['all-students'],
      'audience': {
        'colleges': orgId.isNotEmpty ? [orgId] : <String>[],
        'counties': <String>[''],
        'scope': 'all-students',
      },
      'published': isGlobal && approved,
      'status': approved ? 'published' : 'draft',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
