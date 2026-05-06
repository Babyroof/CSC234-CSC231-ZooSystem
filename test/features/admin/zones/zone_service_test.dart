import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/zones/services/zone_service.dart';

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
  late ZoneService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = ZoneService(db: fakeFirestore);
  });

  // ── Shared seed helper ───────────────────────────────────────────────────
  Future<void> seedZone({
    required String docId,
    String zoneName = 'Bird Zone',
  }) async {
    await fakeFirestore.collection('zone').doc(docId).set({
      'zoneName': zoneName,
    });
  }

  // ── getZones ──────────────────────────────────────────────────────────────
  group('getZones', () {
    test('returns stream containing all seeded zones', () async {
      // Arrange
      await seedZone(docId: 'z1', zoneName: 'Bird Zone');
      await seedZone(docId: 'z2', zoneName: 'Aquatic Zone');

      // Act
      final results = await service.getZones().first;

      // Assert
      expect(results.length, 2);
      final names = results.map((z) => z.zoneName).toSet();
      expect(names, containsAll(['Bird Zone', 'Aquatic Zone']));
    });

    test('returns empty list when collection has no documents', () async {
      final results = await service.getZones().first;
      expect(results, isEmpty);
    });

    test('throws on Firestore error', () {
      final errorService = ZoneService(db: _ErrorFirestore());
      expect(
        () => errorService.getZones(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── getZoneById ───────────────────────────────────────────────────────────
  group('getZoneById', () {
    test('returns correct ZoneModel for existing document', () async {
      // Arrange
      await seedZone(docId: 'z1', zoneName: 'Savanna Zone');

      // Act
      final result = await service.getZoneById('z1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'z1');
      expect(result.zoneName, 'Savanna Zone');
    });

    test('returns null when document does not exist', () async {
      // Act
      final result = await service.getZoneById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('throws on Firestore error', () {
      final errorService = ZoneService(db: _ErrorFirestore());
      expect(
        () => errorService.getZoneById('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── createZone ────────────────────────────────────────────────────────────
  group('createZone', () {
    test('writes a document with the correct zoneName', () async {
      // Act
      await service.createZone('Reptile Zone');

      // Assert
      final snap = await fakeFirestore.collection('zone').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['zoneName'], 'Reptile Zone');
    });

    test('returns a DocumentReference pointing to the new document', () async {
      // Act
      final ref = await service.createZone('Bird Zone');

      // Assert
      expect(ref, isA<DocumentReference>());
      final doc = await ref.get();
      expect(doc.exists, true);
      expect((doc.data() as Map<String, dynamic>)['zoneName'], 'Bird Zone');
    });

    test('each call creates a separate document', () async {
      // Act
      await service.createZone('Zone A');
      await service.createZone('Zone B');

      // Assert
      final snap = await fakeFirestore.collection('zone').get();
      expect(snap.docs.length, 2);
    });

    test('throws on Firestore error', () {
      final errorService = ZoneService(db: _ErrorFirestore());
      expect(
        () => errorService.createZone('Bird Zone'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── updateZone ────────────────────────────────────────────────────────────
  group('updateZone', () {
    test('updates zoneName correctly', () async {
      // Arrange
      await seedZone(docId: 'z1', zoneName: 'Bird Zone');

      // Act
      await service.updateZone(zoneId: 'z1', zoneName: 'Avian Zone');

      // Assert
      final data =
          (await fakeFirestore.collection('zone').doc('z1').get()).data()!;
      expect(data['zoneName'], 'Avian Zone');
    });

    test('does not affect other documents', () async {
      // Arrange
      await seedZone(docId: 'z1', zoneName: 'Bird Zone');
      await seedZone(docId: 'z2', zoneName: 'Aquatic Zone');

      // Act
      await service.updateZone(zoneId: 'z1', zoneName: 'Avian Zone');

      // Assert — z2 is untouched
      final data =
          (await fakeFirestore.collection('zone').doc('z2').get()).data()!;
      expect(data['zoneName'], 'Aquatic Zone');
    });

    test('throws on Firestore error', () {
      final errorService = ZoneService(db: _ErrorFirestore());
      expect(
        () => errorService.updateZone(zoneId: 'any', zoneName: 'Updated'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── deleteZone ────────────────────────────────────────────────────────────
  group('deleteZone', () {
    test('removes the document from Firestore', () async {
      // Arrange
      await seedZone(docId: 'todelete');

      // Act
      await service.deleteZone('todelete');

      // Assert
      final doc =
          await fakeFirestore.collection('zone').doc('todelete').get();
      expect(doc.exists, false);
    });

    test('does not affect other documents', () async {
      // Arrange
      await seedZone(docId: 'keep');
      await seedZone(docId: 'remove');

      // Act
      await service.deleteZone('remove');

      // Assert
      final remaining = await fakeFirestore.collection('zone').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, 'keep');
    });

    test('throws on Firestore error', () {
      final errorService = ZoneService(db: _ErrorFirestore());
      expect(
        () => errorService.deleteZone('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
