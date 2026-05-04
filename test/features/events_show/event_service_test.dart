import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/events_show/models/event_model.dart';
import 'package:zoopernova_zoo_system/features/events_show/services/event.service.dart';

void main() {
  group('EventService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late EventService service;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      service = EventService(db: fakeFirestore);

      await fakeFirestore.collection('event').doc('event1').set({
        'eventName': 'Smart Seal Show',
        'eventDetail': '2 shows per day, at 10 am and 3 pm',
        'eventPicture': 'https://example.com/seal_show.png',
      });
      await fakeFirestore.collection('event').doc('event2').set({
        'eventName': 'Bird Feeding Experience',
        'eventDetail': 'Hand-feed parrots and toucans in the aviary',
        'eventPicture': 'https://example.com/bird_feed.png',
      });
    });

    // ─── getEvents ────────────────────────────────────────────────────────────

    group('getEvents', () {
      test('returns a list of EventModel', () async {
        final result = await service.getEvents();

        expect(result, isA<List<EventModel>>());
      });

      test('returns all seeded events', () async {
        final result = await service.getEvents();

        expect(result.length, 2);
      });

      test('each event has all required fields populated', () async {
        final result = await service.getEvents();

        for (final event in result) {
          expect(
            event.eventName,
            isNotEmpty,
            reason: 'eventName must not be empty',
          );
          expect(
            event.eventDetail,
            isNotEmpty,
            reason: 'eventDetail must not be empty',
          );
          expect(
            event.eventPicture,
            isNotEmpty,
            reason: 'eventPicture must not be empty',
          );
        }
      });

      test('returns correct data for a specific event', () async {
        final result = await service.getEvents();
        final sealShow = result.firstWhere((e) => e.id == 'event1');

        expect(sealShow.eventName, 'Smart Seal Show');
        expect(sealShow.eventDetail, '2 shows per day, at 10 am and 3 pm');
        expect(sealShow.eventPicture, 'https://example.com/seal_show.png');
      });

      test('id field is populated from document ID', () async {
        final result = await service.getEvents();

        expect(result.map((e) => e.id), containsAll(['event1', 'event2']));
      });

      test('returns empty list when collection is empty', () async {
        final emptyService = EventService(db: FakeFirebaseFirestore());

        final result = await emptyService.getEvents();

        expect(result, isEmpty);
      });
    });

    // ─── getRandomEvents ──────────────────────────────────────────────────────

    group('getRandomEvents', () {
      test('returns at most the requested count', () async {
        final result = await service.getRandomEvents(1);

        expect(result.length, lessThanOrEqualTo(1));
      });

      test('returns all events when count exceeds total', () async {
        final result = await service.getRandomEvents(100);

        expect(result.length, 2);
      });

      test('returned events have required fields populated', () async {
        final result = await service.getRandomEvents(2);

        for (final event in result) {
          expect(event.eventName, isNotEmpty);
          expect(event.eventDetail, isNotEmpty);
          expect(event.eventPicture, isNotEmpty);
        }
      });

      test('returns empty list when collection is empty', () async {
        final emptyService = EventService(db: FakeFirebaseFirestore());

        final result = await emptyService.getRandomEvents(5);

        expect(result, isEmpty);
      });
    });
  });
}
