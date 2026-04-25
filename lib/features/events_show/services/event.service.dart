import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GET all events
  Future<List<EventModel>> getEvents() async {
    try {
      final snapshot = await _db.collection('event').get();
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  //Random events
  Future<List<EventModel>> getRandomEvents(int count) async {
    try {
      final snap = await _db.collection('event').get();
      List<EventModel> list = snap.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .toList();
      list.shuffle(); 
      return list.take(count).toList();
    } catch (e) {
      return [];
    }
  }
}