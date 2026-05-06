import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/events/models/event_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  EventModel baseModel({
    String id = 'ev1',
    String eventName = 'Smart Seal Show',
    String eventDetail = '2 shows per day at the aquatic zone',
    String eventPicture = 'https://example.com/seal_show.png',
    int? locationX = 10,
    int? locationY = 20,
  }) =>
      EventModel(
        id: id,
        eventName: eventName,
        eventDetail: eventDetail,
        eventPicture: eventPicture,
        locationX: locationX,
        locationY: locationY,
      );

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('EventModel.fromFirestore', () {
    test('maps all fields correctly including locationX and locationY',
        () async {
      // Arrange
      await fakeFirestore.collection('event').doc('ev1').set({
        'eventName': 'Smart Seal Show',
        'eventDetail': '2 shows per day at the aquatic zone',
        'eventPicture': 'https://example.com/seal_show.png',
        'location_x': 10,
        'location_y': 20,
      });
      final doc = await fakeFirestore.collection('event').doc('ev1').get();

      // Act
      final model = EventModel.fromFirestore(doc);

      // Assert
      expect(model.id, 'ev1');
      expect(model.eventName, 'Smart Seal Show');
      expect(model.eventDetail, '2 shows per day at the aquatic zone');
      expect(model.eventPicture, 'https://example.com/seal_show.png');
      expect(model.locationX, 10);
      expect(model.locationY, 20);
    });

    test('returns null for locationX and locationY when fields are absent',
        () async {
      // Arrange
      await fakeFirestore.collection('event').doc('ev2').set({
        'eventName': 'Elephant Show',
        'eventDetail': 'Daily elephant performance',
        'eventPicture': 'https://example.com/elephant.png',
      });
      final doc = await fakeFirestore.collection('event').doc('ev2').get();

      // Act
      final model = EventModel.fromFirestore(doc);

      // Assert
      expect(model.locationX, isNull);
      expect(model.locationY, isNull);
    });

    test('defaults string fields to empty string when missing', () async {
      // Arrange
      await fakeFirestore.collection('event').doc('ev3').set({
        'location_x': 5,
        'location_y': 5,
      });
      final doc = await fakeFirestore.collection('event').doc('ev3').get();

      // Act
      final model = EventModel.fromFirestore(doc);

      // Assert
      expect(model.eventName, '');
      expect(model.eventDetail, '');
      expect(model.eventPicture, '');
    });
  });

  // ── toMap ────────────────────────────────────────────────────────────────
  group('EventModel.toMap', () {
    test('returns map with only the 3 admin-writable fields', () {
      // Arrange
      final model = baseModel();

      // Act
      final map = model.toMap();

      // Assert — present
      expect(map['eventName'], 'Smart Seal Show');
      expect(map['eventDetail'], '2 shows per day at the aquatic zone');
      expect(map['eventPicture'], 'https://example.com/seal_show.png');
      // Assert — absent
      expect(map.containsKey('location_x'), false);
      expect(map.containsKey('location_y'), false);
      expect(map.containsKey('locationX'), false);
      expect(map.containsKey('locationY'), false);
    });

    test('map contains exactly 3 keys', () {
      final map = baseModel().toMap();
      expect(map.length, 3);
    });

    test('all values are String type', () {
      final map = baseModel().toMap();
      expect(map['eventName'], isA<String>());
      expect(map['eventDetail'], isA<String>());
      expect(map['eventPicture'], isA<String>());
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('EventModel.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(eventName: 'Penguin Show');

      // Assert — changed
      expect(updated.eventName, 'Penguin Show');
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.eventDetail, original.eventDetail);
      expect(updated.eventPicture, original.eventPicture);
      expect(updated.locationX, original.locationX);
      expect(updated.locationY, original.locationY);
    });

    test('returns equivalent object when no fields are changed', () {
      final original = baseModel();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.eventName, original.eventName);
      expect(copy.eventDetail, original.eventDetail);
      expect(copy.eventPicture, original.eventPicture);
      expect(copy.locationX, original.locationX);
      expect(copy.locationY, original.locationY);
    });

    test('can update multiple fields at once', () {
      final updated = baseModel().copyWith(
        eventName: 'Night Safari',
        eventPicture: 'https://example.com/night_safari.png',
      );
      expect(updated.eventName, 'Night Safari');
      expect(updated.eventPicture, 'https://example.com/night_safari.png');
    });
  });
}
