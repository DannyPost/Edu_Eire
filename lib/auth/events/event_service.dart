// lib/auth/events/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';

class EventService {
  final CollectionReference<GlobalEvent> _col =
      FirebaseFirestore.instance.collection('events').withConverter<GlobalEvent>(
            fromFirestore: (snap, _) => GlobalEvent.fromDoc(snap),
            toFirestore: (e, _) => e.toUpdateMap(),
          );

  /// Stream only events created by this organiser.
  Stream<List<GlobalEvent>> streamMine(String organiserUid) {
    return _col
        .where('createdBy', isEqualTo: organiserUid)   // 👈 field name matches model
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Create a new event with correct schema.
  Future<String> addEvent(GlobalEvent e) async {
    // Use raw collection here so we can pass the create-map
    final ref = FirebaseFirestore.instance.collection('events');
    final doc = await ref.add(e.toCreateMap());
    return doc.id;
  }

  /// Update an existing event.
  Future<void> updateEvent(GlobalEvent e) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(e.id)
        .update(e.toUpdateMap());
  }

  /// Delete event.
  Future<void> deleteEvent(String id) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(id)
        .delete();
  }
}
