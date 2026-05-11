import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db;

  static const String _collection = 'event';

  EventService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Stream<List<EventModel>> getEvents() {
    try {
      return _db
          .collection(_collection)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList(),
          )
          .handleError((Object e) {
            debugPrint('[EventService] getEvents stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[EventService] getEvents error: $e');
      rethrow;
    }
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _db.collection(_collection).doc(eventId).get();
      if (!doc.exists) return null;
      return EventModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[EventService] getEventById error: $e');
      rethrow;
    }
  }

  Future<void> createEvent({
    required String eventName,
    required String eventDetail,
    required String eventPicture,
  }) async {
    try {
      await _db.collection(_collection).add({
        'eventName': eventName,
        'eventDetail': eventDetail,
        'eventPicture': eventPicture,
      });
      debugPrint('[EventService] createEvent: success');
    } catch (e) {
      debugPrint('[EventService] createEvent error: $e');
      rethrow;
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required String eventName,
    required String eventDetail,
    required String eventPicture,
  }) async {
    try {
      await _db.collection(_collection).doc(eventId).update({
        'eventName': eventName,
        'eventDetail': eventDetail,
        'eventPicture': eventPicture,
      });
      debugPrint('[EventService] updateEvent: $eventId updated');
    } catch (e) {
      debugPrint('[EventService] updateEvent error: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _db.collection(_collection).doc(eventId).delete();
      debugPrint('[EventService] deleteEvent: $eventId deleted');
    } catch (e) {
      debugPrint('[EventService] deleteEvent error: $e');
      rethrow;
    }
  }
}
