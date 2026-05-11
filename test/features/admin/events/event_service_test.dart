import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/events/models/event_admin_model.dart';
import 'package:zoopernova_zoo_system/features/admin/events/services/event_admin_service.dart';

/// A no-op stub of FirebaseStorage that satisfies the EventAdminService
/// constructor without requiring a real Firebase app to be initialised.
/// None of the unit tests exercise uploadImage(), so this stub is never called.
class _FakeFirebaseStorage extends Fake implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EventAdminService service;

  setUp(() {
    // Each test gets a fresh, isolated FakeFirebaseFirestore instance.
    // A _FakeFirebaseStorage stub is injected so that the EventAdminService
    // constructor never touches FirebaseStorage.instance (which would require
    // a running Firebase app).
    fakeFirestore = FakeFirebaseFirestore();
    service = EventAdminService(
      db: fakeFirestore,
      storage: _FakeFirebaseStorage(),
    );
  });

  // ── Shared seed helper ───────────────────────────────────────────────────
  Future<String> seedEvent({
    String? docId,
    String eventName = 'Seal Show',
    String eventDetail = 'Fun aquatic show',
    String eventPicture = 'https://example.com/seal.jpg',
    Map<String, dynamic> extra = const {},
  }) async {
    final ref = docId != null
        ? fakeFirestore.collection('event').doc(docId)
        : fakeFirestore.collection('event').doc();
    await ref.set({
      'eventName': eventName,
      'eventDetail': eventDetail,
      'eventPicture': eventPicture,
      ...extra,
    });
    return ref.id;
  }

  // ── getEvents() ───────────────────────────────────────────────────────────
  group('getEvents()', () {
    test('returns empty list when collection is empty', () async {
      // Arrange — fakeFirestore has no documents (fresh from setUp)

      // Act
      final result = await service.getEvents().first;

      // Assert
      expect(result, isEmpty);
    });

    test('streams all event documents', () async {
      // Arrange — seed two known events
      await seedEvent(docId: 'e1', eventName: 'Seal Show');
      await seedEvent(docId: 'e2', eventName: 'Elephant Bath');

      // Act — take the first emission from the stream
      final result = await service.getEvents().first;

      // Assert — both documents are returned with correct names
      expect(result.length, 2);
      expect(result, isA<List<EventAdminModel>>());
      final names = result.map((e) => e.eventName).toSet();
      expect(names, containsAll(['Seal Show', 'Elephant Bath']));
    });

    test('reflects new document added after stream starts', () async {
      // Arrange — start listening before any data exists
      final streamFuture = service
          .getEvents()
          .skip(1) // skip the initial empty emission
          .first;

      // Act — add a document after the stream has started
      await fakeFirestore.collection('event').add({
        'eventName': 'Parrot Talk',
        'eventDetail': 'Learn from parrots',
        'eventPicture': 'https://example.com/parrot.jpg',
      });

      // Assert — the second emission contains the newly added event
      final result = await streamFuture;
      expect(result.length, 1);
      expect(result.first.eventName, 'Parrot Talk');
    });
  });

  // ── getEventById() ────────────────────────────────────────────────────────
  group('getEventById()', () {
    test('returns EventAdminModel when document exists', () async {
      // Arrange — seed a doc with a known ID
      final docId = await seedEvent(
        docId: 'evt_known',
        eventName: 'Tiger Feeding',
        eventDetail: 'Watch the tigers eat',
        eventPicture: 'https://example.com/tiger.jpg',
      );

      // Act
      final result = await service.getEventById(docId);

      // Assert — non-null result with correct fields
      expect(result, isNotNull);
      expect(result, isA<EventAdminModel>());
      expect(result!.id, docId);
      expect(result.eventName, 'Tiger Feeding');
      expect(result.eventDetail, 'Watch the tigers eat');
      expect(result.eventPicture, 'https://example.com/tiger.jpg');
    });

    test('returns null when document not found', () async {
      // Arrange — empty Firestore; no document with this ID exists

      // Act
      final result = await service.getEventById('nonexistent_id');

      // Assert
      expect(result, isNull);
    });
  });

  // ── createEvent() ─────────────────────────────────────────────────────────
  group('createEvent()', () {
    test(
      'writes only eventName, eventDetail, eventPicture — not location fields',
      () async {
        // Arrange — fresh fakeFirestore (done in setUp)

        // Act
        await service.createEvent(
          eventName: 'Seal Show',
          eventDetail: 'Fun',
          eventPicture: 'url',
        );

        // Assert — read back the written document
        final snap = await fakeFirestore.collection('event').get();
        expect(snap.docs.length, 1);
        final data = snap.docs.first.data();

        expect(data['eventName'], 'Seal Show');
        expect(data['eventDetail'], 'Fun');
        expect(data['eventPicture'], 'url');

        // CRITICAL: location fields must NEVER be written by createEvent()
        expect(data.containsKey('location_x'), false);
        expect(data.containsKey('location_y'), false);
      },
    );

    test('creates multiple events independently', () async {
      // Arrange — fresh fakeFirestore (done in setUp)

      // Act — call createEvent twice with different names
      await service.createEvent(
        eventName: 'Seal Show',
        eventDetail: 'Aquatic fun',
        eventPicture: 'https://example.com/seal.jpg',
      );
      await service.createEvent(
        eventName: 'Elephant Bath',
        eventDetail: 'Watch elephants bathe',
        eventPicture: 'https://example.com/elephant.jpg',
      );

      // Assert — two separate documents exist
      final snap = await fakeFirestore.collection('event').get();
      expect(snap.docs.length, 2);
      final names = snap.docs
          .map((d) => d.data()['eventName'] as String)
          .toSet();
      expect(names, containsAll(['Seal Show', 'Elephant Bath']));
    });
  });

  // ── updateEvent() ─────────────────────────────────────────────────────────
  group('updateEvent()', () {
    test(
      'updates only eventName, eventDetail, eventPicture — does not overwrite location fields',
      () async {
        // Arrange — seed a doc that already has location fields set by admin map
        final docId = await seedEvent(
          docId: 'evt_update',
          eventName: 'Old',
          eventDetail: 'Old detail',
          eventPicture: 'old_url',
          extra: {'location_x': 100, 'location_y': 200},
        );

        // Act
        await service.updateEvent(
          eventId: docId,
          eventName: 'New',
          eventDetail: 'New detail',
          eventPicture: 'new_url',
        );

        // Assert — text fields updated correctly
        final data = (await fakeFirestore.collection('event').doc(docId).get())
            .data()!;
        expect(data['eventName'], 'New');
        expect(data['eventDetail'], 'New detail');
        expect(data['eventPicture'], 'new_url');

        // CRITICAL: location fields must be preserved because updateEvent uses
        // .update() (partial merge) NOT .set() (full overwrite)
        expect(data['location_x'], 100);
        expect(data['location_y'], 200);
      },
    );

    test('throws when updating a non-existent document', () async {
      // Arrange — empty Firestore; no document exists with this ID
      // NOTE: fake_cloud_firestore ^3.0.0 correctly mirrors production
      // Firestore behaviour: calling .update() on a missing document throws
      // a [FakeFirestore/not-found] exception. EventAdminService re-throws
      // the error after logging it, so callers can handle it appropriately.

      // Act + Assert — a FirebaseException is propagated
      await expectLater(
        service.updateEvent(
          eventId: 'nonexistent_id',
          eventName: 'Ghost Event',
          eventDetail: 'Does not exist',
          eventPicture: 'nowhere',
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── deleteEvent() ─────────────────────────────────────────────────────────
  group('deleteEvent()', () {
    test('removes document from Firestore', () async {
      // Arrange — seed a document and capture its ID
      final docId = await seedEvent(docId: 'todelete');

      // Act
      await service.deleteEvent(docId);

      // Assert — the document no longer exists
      final doc = await fakeFirestore.collection('event').doc(docId).get();
      expect(doc.exists, false);
    });

    test('does not affect other documents when deleting', () async {
      // Arrange — seed two documents
      await seedEvent(docId: 'keep', eventName: 'Seal Show');
      await seedEvent(docId: 'remove', eventName: 'Temp Event');

      // Act — delete only one
      await service.deleteEvent('remove');

      // Assert — collection still has exactly 1 document
      final remaining = await fakeFirestore.collection('event').get();
      expect(remaining.docs.length, 1);

      // Assert — the surviving document is the correct one
      expect(remaining.docs.first.id, 'keep');
      expect(remaining.docs.first.data()['eventName'], 'Seal Show');
    });
  });
}
