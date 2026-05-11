import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/animals/models/animal_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  AnimalModel baseModel({
    String id = 'a1',
    String animalName = 'Scarlet Macaw',
    String animalDetail = 'Native to South America',
    String animalPicture = 'https://example.com/macaw.jpg',
    DocumentReference? zoneId,
    int? locationX = 10,
    int? locationY = 20,
  }) {
    zoneId ??= fakeFirestore.collection('zone').doc('zone1');
    return AnimalModel(
      id: id,
      animalName: animalName,
      animalDetail: animalDetail,
      animalPicture: animalPicture,
      zoneId: zoneId,
      locationX: locationX,
      locationY: locationY,
    );
  }

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('AnimalModel.fromFirestore', () {
    test(
      'maps all fields correctly including locationX and locationY',
      () async {
        // Arrange
        final zoneRef = fakeFirestore.collection('zone').doc('zone1');
        await fakeFirestore.collection('animal').doc('a1').set({
          'animalName': 'Scarlet Macaw',
          'animalDetail': 'Native to South America',
          'animalPicture': 'https://example.com/macaw.jpg',
          'zoneId': zoneRef,
          'location_x': 10,
          'location_y': 20,
        });
        final doc = await fakeFirestore.collection('animal').doc('a1').get();

        // Act
        final model = AnimalModel.fromFirestore(doc);

        // Assert
        expect(model.id, 'a1');
        expect(model.animalName, 'Scarlet Macaw');
        expect(model.animalDetail, 'Native to South America');
        expect(model.animalPicture, 'https://example.com/macaw.jpg');
        expect(model.zoneId, isA<DocumentReference>());
        expect(model.zoneId.id, 'zone1');
        expect(model.locationX, 10);
        expect(model.locationY, 20);
      },
    );

    test(
      'returns null for locationX and locationY when fields are absent',
      () async {
        // Arrange
        final zoneRef = fakeFirestore.collection('zone').doc('zone1');
        await fakeFirestore.collection('animal').doc('a2').set({
          'animalName': 'Penguin',
          'animalDetail': 'Antarctic bird',
          'animalPicture': 'https://example.com/penguin.jpg',
          'zoneId': zoneRef,
        });
        final doc = await fakeFirestore.collection('animal').doc('a2').get();

        // Act
        final model = AnimalModel.fromFirestore(doc);

        // Assert
        expect(model.locationX, isNull);
        expect(model.locationY, isNull);
      },
    );

    test('defaults string fields to empty string when missing', () async {
      // Arrange
      final zoneRef = fakeFirestore.collection('zone').doc('zone1');
      await fakeFirestore.collection('animal').doc('a3').set({
        'zoneId': zoneRef,
        'location_x': 5,
        'location_y': 5,
      });
      final doc = await fakeFirestore.collection('animal').doc('a3').get();

      // Act
      final model = AnimalModel.fromFirestore(doc);

      // Assert
      expect(model.animalName, '');
      expect(model.animalDetail, '');
      expect(model.animalPicture, '');
    });
  });

  // ── toMap ────────────────────────────────────────────────────────────────
  group('AnimalModel.toMap', () {
    test('returns map with only the 4 admin-writable fields', () {
      // Arrange
      final model = baseModel();

      // Act
      final map = model.toMap();

      // Assert — present
      expect(map['animalName'], 'Scarlet Macaw');
      expect(map['animalDetail'], 'Native to South America');
      expect(map['animalPicture'], 'https://example.com/macaw.jpg');
      expect(map['zoneId'], isA<DocumentReference>());
      // Assert — absent
      expect(map.containsKey('location_x'), false);
      expect(map.containsKey('location_y'), false);
      expect(map.containsKey('locationX'), false);
      expect(map.containsKey('locationY'), false);
    });

    test('map contains exactly 4 keys', () {
      final map = baseModel().toMap();
      expect(map.length, 4);
    });

    test('zoneId field is a DocumentReference not a String', () {
      final map = baseModel().toMap();
      expect(map['zoneId'], isA<DocumentReference>());
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('AnimalModel.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(animalName: 'White Tiger');

      // Assert — changed
      expect(updated.animalName, 'White Tiger');
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.animalDetail, original.animalDetail);
      expect(updated.animalPicture, original.animalPicture);
      expect(updated.zoneId, original.zoneId);
      expect(updated.locationX, original.locationX);
      expect(updated.locationY, original.locationY);
    });

    test('returns equivalent object when no fields are changed', () {
      final original = baseModel();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.animalName, original.animalName);
      expect(copy.animalDetail, original.animalDetail);
      expect(copy.animalPicture, original.animalPicture);
      expect(copy.zoneId, original.zoneId);
      expect(copy.locationX, original.locationX);
      expect(copy.locationY, original.locationY);
    });

    test('can update zoneId to a different DocumentReference', () {
      final newZone = fakeFirestore.collection('zone').doc('zone2');
      final updated = baseModel().copyWith(zoneId: newZone);
      expect(updated.zoneId.id, 'zone2');
    });
  });
}
