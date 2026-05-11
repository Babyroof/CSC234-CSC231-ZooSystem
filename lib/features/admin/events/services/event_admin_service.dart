import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_admin_model.dart';

class EventAdminService {
  // TODO: Inject FirebaseFirestore — replace all methods with real Firestore calls
  final List<EventAdminModel> _events = [
    const EventAdminModel(
      id: 'mock_1',
      eventName: 'Smart Seal Show',
      eventDetail: '2 shows per day at 10:00 and 14:00.',
      eventPicture: '',
      locationX: 300,
      locationY: 400,
    ),
    const EventAdminModel(
      id: 'mock_2',
      eventName: 'Elephant Bathing',
      eventDetail: 'Watch elephants get their daily bath at 09:00.',
      eventPicture: '',
      locationX: 600,
      locationY: 250,
    ),
  ];

  int _nextId = 3;

  Future<List<EventAdminModel>> getEvents() async {
    // TODO: Query 'event' collection
    return List.from(_events);
  }

  Future<void> addEvent({
    required String eventName,
    required String eventDetail,
    required String eventPicture,
    required int locationX,
    required int locationY,
  }) async {
    // TODO: _db.collection('event').add({...})
    _events.add(
      EventAdminModel(
        id: 'mock_${_nextId++}',
        eventName: eventName,
        eventDetail: eventDetail,
        eventPicture: eventPicture,
        locationX: locationX,
        locationY: locationY,
      ),
    );
  }

  Future<void> updateEvent(
    String id, {
    required String eventName,
    required String eventDetail,
    required String eventPicture,
    required int locationX,
    required int locationY,
  }) async {
    // TODO: _db.collection('event').doc(id).update({...})
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _events[index] = EventAdminModel(
      id: id,
      eventName: eventName,
      eventDetail: eventDetail,
      eventPicture: eventPicture,
      locationX: locationX,
      locationY: locationY,
    );
  }

  Future<void> deleteEvent(String id) async {
    // TODO: _db.collection('event').doc(id).delete()
    _events.removeWhere((e) => e.id == id);
  }

  Future<String> uploadImage(List<int> bytes, String extension) async {
    // TODO: Upload to Firebase Storage at 'events/<timestamp>.<ext>', return download URL
    return '';
  }
}

final eventAdminServiceProvider = Provider<EventAdminService>(
  (ref) => EventAdminService(),
);
