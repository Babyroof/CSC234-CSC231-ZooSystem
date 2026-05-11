import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_admin_model.dart';

class EventAdminService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  EventAdminService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  /// Returns a real-time stream of all events from Firestore.
  Stream<List<EventAdminModel>> getEvents() {
    return _db
        .collection('event')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map<EventAdminModel>(EventAdminModel.fromFirestore)
              .toList(),
        )
        .handleError((Object e) {
          debugPrint('[EventAdminService] getEvents stream error: $e');
          throw e;
        });
  }

  Future<EventAdminModel?> getEventById(String eventId) async {
    try {
      final doc = await _db.collection('event').doc(eventId).get();
      if (!doc.exists) return null;
      return EventAdminModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[EventAdminService] getEventById error: $e');
      rethrow;
    }
  }

  /// Create: ONLY eventName, eventDetail, eventPicture — NO location fields.
  Future<void> createEvent({
    required String eventName,
    required String eventDetail,
    required String eventPicture,
  }) async {
    try {
      await _db.collection('event').add({
        'eventName': eventName,
        'eventDetail': eventDetail,
        'eventPicture': eventPicture,
      });
      debugPrint('[EventAdminService] createEvent: success');
    } catch (e) {
      debugPrint('[EventAdminService] createEvent error: $e');
      rethrow;
    }
  }

  /// Update: uses .update() NOT .set() — NEVER writes location_x or location_y.
  Future<void> updateEvent({
    required String eventId,
    required String eventName,
    required String eventDetail,
    required String eventPicture,
  }) async {
    try {
      await _db.collection('event').doc(eventId).update({
        'eventName': eventName,
        'eventDetail': eventDetail,
        'eventPicture': eventPicture,
      });
      debugPrint('[EventAdminService] updateEvent: $eventId updated');
    } catch (e) {
      debugPrint('[EventAdminService] updateEvent error: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _db.collection('event').doc(eventId).delete();
      debugPrint('[EventAdminService] deleteEvent: $eventId deleted');
    } catch (e) {
      debugPrint('[EventAdminService] deleteEvent error: $e');
      rethrow;
    }
  }

  /// Uploads image bytes to Firebase Storage under 'events/' and returns the
  /// public download URL. The screens keep this flow unchanged.
  Future<String> uploadImage(List<int> bytes, String extension) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref('events/$timestamp.$extension');
      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/$extension'),
      );
      final url = await ref.getDownloadURL();
      debugPrint('[EventAdminService] uploadImage: $url');
      return url;
    } catch (e) {
      debugPrint('[EventAdminService] uploadImage error: $e');
      rethrow;
    }
  }
}

final eventAdminServiceProvider = Provider<EventAdminService>(
  (ref) => EventAdminService(),
);
