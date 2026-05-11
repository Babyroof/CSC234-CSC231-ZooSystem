import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/zones/models/zone_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  ZoneModel baseModel({
    String id = 'z1',
    String zoneName = 'Bird Zone',
  }) =>
      ZoneModel(id: id, zoneName: zoneName);

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('ZoneModel.fromFirestore', () {
    test('maps id and zoneName correctly', () async {
      // Arrange
      await fakeFirestore.collection('zone').doc('z1').set({
        'zoneName': 'Bird Zone',
      });
      final doc = await fakeFirestore.collection('zone').doc('z1').get();

      // Act
      final model = ZoneModel.fromFirestore(doc);

      // Assert
      expect(model.id, 'z1');
      expect(model.zoneName, 'Bird Zone');
    });

    test('defaults zoneName to empty string when field is absent', () async {
      // Arrange
      await fakeFirestore.collection('zone').doc('z2').set({});
      final doc = await fakeFirestore.collection('zone').doc('z2').get();

      // Act
      final model = ZoneModel.fromFirestore(doc);

      // Assert
      expect(model.zoneName, '');
    });
  });

  // ── toMap ────────────────────────────────────────────────────────────────
  group('ZoneModel.toMap', () {
    test('returns map with only zoneName key', () {
      // Arrange
      final model = baseModel();

      // Act
      final map = model.toMap();

      // Assert
      expect(map['zoneName'], 'Bird Zone');
      expect(map.length, 1);
    });

    test('does not include id in the map', () {
      final map = baseModel().toMap();
      expect(map.containsKey('id'), false);
    });

    test('value is a String', () {
      final map = baseModel(zoneName: 'Aquatic Zone').toMap();
      expect(map['zoneName'], isA<String>());
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('ZoneModel.copyWith', () {
    test('updates only zoneName, leaves id unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(zoneName: 'Aquatic Zone');

      // Assert — changed
      expect(updated.zoneName, 'Aquatic Zone');
      // Assert — unchanged
      expect(updated.id, original.id);
    });

    test('returns equivalent object when no fields are changed', () {
      final original = baseModel();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.zoneName, original.zoneName);
    });

    test('can update id independently', () {
      final updated = baseModel().copyWith(id: 'z99');
      expect(updated.id, 'z99');
      expect(updated.zoneName, 'Bird Zone');
    });
  });
}
