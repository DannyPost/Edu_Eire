import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalEvent {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime start;
  final DateTime end;
  final String organiserId;
  final String organiserName;
  final bool isGlobal;
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
    required this.isGlobal,
    required this.approved,
  });

  factory GlobalEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return GlobalEvent(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'General',
      location: d['location'] ?? '',
      start: (d['start'] as Timestamp).toDate(),
      end: (d['end'] as Timestamp).toDate(),
      organiserId: d['organiserId'] ?? '',
      organiserName: d['organiserName'] ?? '',
      isGlobal: d['isGlobal'] ?? true,
      approved: d['approved'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'organiserId': organiserId,
      'organiserName': organiserName,
      'isGlobal': isGlobal,
      'approved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
