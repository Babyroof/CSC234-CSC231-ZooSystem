import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/animals/services/animal_service.dart';

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
  late AnimalService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = AnimalService(db: fakeFirestore);
  });

  // ── Shared seed helper ───────────────────────────────────────────────────
  Future<void> seedAnimal({
    required String docId,
    String animalName = 'Tiger',
    String animalDetail = 'Big cat',
    String animalPicture = 'https://example.com/tiger.jpg',
    String zoneDocId = 'zone1',
    int? locationX,
    int? locationY,
  }) async {
    final zoneRef = fakeFirestore.collection('zone').doc(zoneDocId);
    final data = <String, dynamic>{
      'animalName': animalName,
      'animalDetail': animalDetail,
      'animalPicture': animalPicture,
      'zoneId': zoneRef,
    };
    if (locationX != null) data['location_x'] = locationX;
    if (locationY != null) data['location_y'] = locationY;
    await fakeFirestore.collection('animal').doc(docId).set(data);
  }

  // ── getAnimals ────────────────────────────────────────────────────────────
  group('getAnimals', () {
    test('returns stream containing all seeded animals', () async {
      // Arrange
      await seedAnimal(docId: 'a1', animalName: 'Tiger');
      await seedAnimal(docId: 'a2', animalName: 'Lion');

      // Act
      final results = await service.getAnimals().first;

      // Assert
      expect(results.length, 2);
      final names = results.map((a) => a.animalName).toSet();
      expect(names, containsAll(['Tiger', 'Lion']));
    });

    test('returns empty list when collection has no documents', () async {
      final results = await service.getAnimals().first;
      expect(results, isEmpty);
    });

    test('throws on Firestore error', () {
      final errorService = AnimalService(db: _ErrorFirestore());
      expect(
        () => errorService.getAnimals(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── getAnimalById ─────────────────────────────────────────────────────────
  group('getAnimalById', () {
    test('returns correct AnimalModel for existing document', () async {
      // Arrange
      await seedAnimal(
        docId: 'a1',
        animalName: 'Scarlet Macaw',
        animalDetail: 'Native to South America',
        animalPicture: 'https://example.com/macaw.jpg',
        zoneDocId: 'zone1',
        locationX: 10,
        locationY: 20,
      );

      // Act
      final result = await service.getAnimalById('a1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'a1');
      expect(result.animalName, 'Scarlet Macaw');
      expect(result.animalDetail, 'Native to South America');
      expect(result.animalPicture, 'https://example.com/macaw.jpg');
      expect(result.zoneId.id, 'zone1');
      expect(result.locationX, 10);
      expect(result.locationY, 20);
    });

    test('returns null when document does not exist', () async {
      // Act
      final result = await service.getAnimalById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('throws on Firestore error', () {
      final errorService = AnimalService(db: _ErrorFirestore());
      expect(
        () => errorService.getAnimalById('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── createAnimal ──────────────────────────────────────────────────────────
  group('createAnimal', () {
    test('writes a document to the animal collection', () async {
      // Arrange
      final zoneRef = fakeFirestore.collection('zone').doc('zone1');

      // Act
      await service.createAnimal(
        animalName: 'Tiger',
        animalDetail: 'Big cat',
        animalPicture: 'https://example.com/tiger.jpg',
        zoneId: zoneRef,
      );

      // Assert
      final snap = await fakeFirestore.collection('animal').get();
      expect(snap.docs.length, 1);
    });

    test(
      'writes only the 4 allowed fields — no location_x or location_y',
      () async {
        // Arrange
        final zoneRef = fakeFirestore.collection('zone').doc('zone1');

        // Act
        await service.createAnimal(
          animalName: 'Tiger',
          animalDetail: 'Big cat',
          animalPicture: 'https://example.com/tiger.jpg',
          zoneId: zoneRef,
        );

        // Assert
        final data = (await fakeFirestore.collection('animal').get()).docs.first
            .data();
        expect(data['animalName'], 'Tiger');
        expect(data['animalDetail'], 'Big cat');
        expect(data['animalPicture'], 'https://example.com/tiger.jpg');
        expect(data['zoneId'], isA<DocumentReference>());
        expect(data.containsKey('location_x'), false);
        expect(data.containsKey('location_y'), false);
      },
    );

    test('throws on Firestore error', () {
      final errorService = AnimalService(db: _ErrorFirestore());
      final zoneRef = fakeFirestore.collection('zone').doc('zone1');
      expect(
        () => errorService.createAnimal(
          animalName: 'Tiger',
          animalDetail: 'Big cat',
          animalPicture: 'https://example.com/tiger.jpg',
          zoneId: zoneRef,
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── updateAnimal ──────────────────────────────────────────────────────────
  group('updateAnimal', () {
    test('updates the 4 writable fields correctly', () async {
      // Arrange
      await seedAnimal(docId: 'a1');
      final newZoneRef = fakeFirestore.collection('zone').doc('zone2');

      // Act
      await service.updateAnimal(
        animalId: 'a1',
        animalName: 'White Tiger',
        animalDetail: 'Rare colour variant',
        animalPicture: 'https://example.com/white_tiger.jpg',
        zoneId: newZoneRef,
      );

      // Assert
      final data = (await fakeFirestore.collection('animal').doc('a1').get())
          .data()!;
      expect(data['animalName'], 'White Tiger');
      expect(data['animalDetail'], 'Rare colour variant');
      expect(data['animalPicture'], 'https://example.com/white_tiger.jpg');
      expect((data['zoneId'] as DocumentReference).id, 'zone2');
    });

    test('does NOT overwrite location_x or location_y', () async {
      // Arrange — seed doc with existing coordinates
      await seedAnimal(docId: 'a1', locationX: 42, locationY: 99);
      final zoneRef = fakeFirestore.collection('zone').doc('zone1');

      // Act
      await service.updateAnimal(
        animalId: 'a1',
        animalName: 'Tiger Updated',
        animalDetail: 'Updated detail',
        animalPicture: 'https://example.com/new.jpg',
        zoneId: zoneRef,
      );

      // Assert — coordinates must be preserved unchanged
      final data = (await fakeFirestore.collection('animal').doc('a1').get())
          .data()!;
      expect(data['location_x'], 42);
      expect(data['location_y'], 99);
    });

    test('throws on Firestore error', () {
      final errorService = AnimalService(db: _ErrorFirestore());
      final zoneRef = fakeFirestore.collection('zone').doc('zone1');
      expect(
        () => errorService.updateAnimal(
          animalId: 'any',
          animalName: 'Tiger',
          animalDetail: 'Big cat',
          animalPicture: 'https://example.com/tiger.jpg',
          zoneId: zoneRef,
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── deleteAnimal ──────────────────────────────────────────────────────────
  group('deleteAnimal', () {
    test('removes the document from Firestore', () async {
      // Arrange
      await seedAnimal(docId: 'todelete');

      // Act
      await service.deleteAnimal('todelete');

      // Assert
      final doc = await fakeFirestore
          .collection('animal')
          .doc('todelete')
          .get();
      expect(doc.exists, false);
    });

    test('does not affect other documents', () async {
      // Arrange
      await seedAnimal(docId: 'keep');
      await seedAnimal(docId: 'remove');

      // Act
      await service.deleteAnimal('remove');

      // Assert
      final remaining = await fakeFirestore.collection('animal').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, 'keep');
    });

    test('throws on Firestore error', () {
      final errorService = AnimalService(db: _ErrorFirestore());
      expect(
        () => errorService.deleteAnimal('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
