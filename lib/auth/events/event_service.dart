import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events');

  // Create
  Future<String> addEvent(GlobalEvent e) async {
    final doc = await _col.add({
      ...e.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Update
  Future<void> updateEvent(GlobalEvent e) async {
    await _col.doc(e.id).update(e.toMap());
  }

  // Delete
  Future<void> deleteEvent(String id) async {
    await _col.doc(id).delete();
  }

  // Stream approved global events in a date range
  Stream<List<GlobalEvent>> streamApprovedGlobal(
      DateTime from, DateTime to) {
    // Firestore supports range queries on the SAME field.
    // We'll range on 'start' and filter approved/isGlobal.
    return _col
        .where('isGlobal', isEqualTo: true)
        .where('approved', isEqualTo: true)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('start')
        .snapshots()
        .map((snap) => snap.docs.map((d) => GlobalEvent.fromDoc(d)).toList());
  }

  // Stream organiser’s own events (incl. pending)
  Stream<List<GlobalEvent>> streamMine(String organiserId) {
    return _col
        .where('organiserId', isEqualTo: organiserId)
        .orderBy('start', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => GlobalEvent.fromDoc(d)).toList());
  }
}
