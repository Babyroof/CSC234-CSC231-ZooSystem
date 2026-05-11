import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/events/services/event_service.dart';

// Fake Firestore that throws on every collection() call — used for error tests
class _ErrorFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'Simulated Firestore error',
    );
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EventService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = EventService(db: fakeFirestore);
  });

  // ── Shared seed helper ───────────────────────────────────────────────────
  Future<void> seedEvent({
    required String docId,
    String eventName = 'Smart Seal Show',
    String eventDetail = '2 shows per day',
    String eventPicture = 'https://example.com/seal_show.png',
    int? locationX,
    int? locationY,
  }) async {
    final data = <String, dynamic>{
      'eventName': eventName,
      'eventDetail': eventDetail,
      'eventPicture': eventPicture,
    };
    if (locationX != null) data['location_x'] = locationX;
    if (locationY != null) data['location_y'] = locationY;
    await fakeFirestore.collection('event').doc(docId).set(data);
  }

  // ── getEvents ─────────────────────────────────────────────────────────────
  group('getEvents', () {
    test('returns stream containing all seeded events', () async {
      // Arrange
      await seedEvent(docId: 'ev1', eventName: 'Smart Seal Show');
      await seedEvent(docId: 'ev2', eventName: 'Elephant Show');

      // Act
      final results = await service.getEvents().first;

      // Assert
      expect(results.length, 2);
      final names = results.map((e) => e.eventName).toSet();
      expect(names, containsAll(['Smart Seal Show', 'Elephant Show']));
    });

    test('returns empty list when collection has no documents', () async {
      final results = await service.getEvents().first;
      expect(results, isEmpty);
    });

    test('throws on Firestore error', () {
      final errorService = EventService(db: _ErrorFirestore());
      expect(
        () => errorService.getEvents(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── getEventById ──────────────────────────────────────────────────────────
  group('getEventById', () {
    test('returns correct EventModel for existing document', () async {
      // Arrange
      await seedEvent(
        docId: 'ev1',
        eventName: 'Smart Seal Show',
        eventDetail: '2 shows per day at the aquatic zone',
        eventPicture: 'https://example.com/seal_show.png',
        locationX: 10,
        locationY: 20,
      );

      // Act
      final result = await service.getEventById('ev1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'ev1');
      expect(result.eventName, 'Smart Seal Show');
      expect(result.eventDetail, '2 shows per day at the aquatic zone');
      expect(result.eventPicture, 'https://example.com/seal_show.png');
      expect(result.locationX, 10);
      expect(result.locationY, 20);
    });

    test('returns null when document does not exist', () async {
      // Act
      final result = await service.getEventById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('throws on Firestore error', () {
      final errorService = EventService(db: _ErrorFirestore());
      expect(
        () => errorService.getEventById('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── createEvent ───────────────────────────────────────────────────────────
  group('createEvent', () {
    test('writes a document to the event collection', () async {
      // Act
      await service.createEvent(
        eventName: 'Smart Seal Show',
        eventDetail: '2 shows per day',
        eventPicture: 'https://example.com/seal_show.png',
      );

      // Assert
      final snap = await fakeFirestore.collection('event').get();
      expect(snap.docs.length, 1);
    });

    test('writes only the 3 allowed fields — no location_x or location_y',
        () async {
      // Act
      await service.createEvent(
        eventName: 'Smart Seal Show',
        eventDetail: '2 shows per day',
        eventPicture: 'https://example.com/seal_show.png',
      );

      // Assert
      final data =
          (await fakeFirestore.collection('event').get()).docs.first.data();
      expect(data['eventName'], 'Smart Seal Show');
      expect(data['eventDetail'], '2 shows per day');
      expect(data['eventPicture'], 'https://example.com/seal_show.png');
      expect(data.containsKey('location_x'), false);
      expect(data.containsKey('location_y'), false);
    });

    test('throws on Firestore error', () {
      final errorService = EventService(db: _ErrorFirestore());
      expect(
        () => errorService.createEvent(
          eventName: 'Smart Seal Show',
          eventDetail: '2 shows per day',
          eventPicture: 'https://example.com/seal_show.png',
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── updateEvent ───────────────────────────────────────────────────────────
  group('updateEvent', () {
    test('updates the 3 writable fields correctly', () async {
      // Arrange
      await seedEvent(docId: 'ev1');

      // Act
      await service.updateEvent(
        eventId: 'ev1',
        eventName: 'Night Safari',
        eventDetail: 'After-dark guided tour',
        eventPicture: 'https://example.com/night_safari.png',
      );

      // Assert
      final data =
          (await fakeFirestore.collection('event').doc('ev1').get()).data()!;
      expect(data['eventName'], 'Night Safari');
      expect(data['eventDetail'], 'After-dark guided tour');
      expect(data['eventPicture'], 'https://example.com/night_safari.png');
    });

    test('does NOT overwrite location_x or location_y', () async {
      // Arrange — seed doc with existing coordinates
      await seedEvent(docId: 'ev1', locationX: 42, locationY: 99);

      // Act
      await service.updateEvent(
        eventId: 'ev1',
        eventName: 'Updated Show',
        eventDetail: 'Updated detail',
        eventPicture: 'https://example.com/updated.png',
      );

      // Assert — coordinates must be preserved unchanged
      final data =
          (await fakeFirestore.collection('event').doc('ev1').get()).data()!;
      expect(data['location_x'], 42);
      expect(data['location_y'], 99);
    });

    test('throws on Firestore error', () {
      final errorService = EventService(db: _ErrorFirestore());
      expect(
        () => errorService.updateEvent(
          eventId: 'any',
          eventName: 'Smart Seal Show',
          eventDetail: '2 shows per day',
          eventPicture: 'https://example.com/seal_show.png',
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── deleteEvent ───────────────────────────────────────────────────────────
  group('deleteEvent', () {
    test('removes the document from Firestore', () async {
      // Arrange
      await seedEvent(docId: 'todelete');

      // Act
      await service.deleteEvent('todelete');

      // Assert
      final doc =
          await fakeFirestore.collection('event').doc('todelete').get();
      expect(doc.exists, false);
    });

    test('does not affect other documents', () async {
      // Arrange
      await seedEvent(docId: 'keep');
      await seedEvent(docId: 'remove');

      // Act
      await service.deleteEvent('remove');

      // Assert
      final remaining = await fakeFirestore.collection('event').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, 'keep');
    });

    test('throws on Firestore error', () {
      final errorService = EventService(db: _ErrorFirestore());
      expect(
        () => errorService.deleteEvent('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
