import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/animals_info/models/animal_model.dart';
import 'package:zoopernova_zoo_system/features/animals_info/services/animal_service.dart';

void main() {
  group('AnimalService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AnimalService service;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      service = AnimalService(db: fakeFirestore);

      await fakeFirestore.collection('animal').doc('animal1').set({
        'animalName': 'Scarlet Macaw',
        'animalDetail': 'Native to South America',
        'animalPicture': 'https://example.com/macaw.jpg',
        'zoneId': '/zone/zone1',
      });
      await fakeFirestore.collection('animal').doc('animal2').set({
        'animalName': 'Bengal Tiger',
        'animalDetail': 'Found in the forests of India',
        'animalPicture': 'https://example.com/tiger.jpg',
        'zoneId': '/zone/zone2',
      });
    });

    // ─── getAnimals ───────────────────────────────────────────────────────────

    group('getAnimals', () {
      test('returns a list of AnimalModel', () async {
        final result = await service.getAnimals();

        expect(result, isA<List<AnimalModel>>());
      });

      test('returns all seeded animals', () async {
        final result = await service.getAnimals();

        expect(result.length, 2);
      });

      test('each animal has all required fields populated', () async {
        final result = await service.getAnimals();

        for (final animal in result) {
          expect(
            animal.animalName,
            isNotEmpty,
            reason: 'animalName must not be empty',
          );
          expect(
            animal.animalDetail,
            isNotEmpty,
            reason: 'animalDetail must not be empty',
          );
          expect(
            animal.animalPicture,
            isNotEmpty,
            reason: 'animalPicture must not be empty',
          );
          expect(animal.zoneId, isNotEmpty, reason: 'zoneId must not be empty');
        }
      });

      test('returns correct data for a specific animal', () async {
        final result = await service.getAnimals();
        final macaw = result.firstWhere((a) => a.id == 'animal1');

        expect(macaw.animalName, 'Scarlet Macaw');
        expect(macaw.animalDetail, 'Native to South America');
        expect(macaw.animalPicture, 'https://example.com/macaw.jpg');
      });

      test('returns empty list when collection is empty', () async {
        final emptyService = AnimalService(db: FakeFirebaseFirestore());

        final result = await emptyService.getAnimals();

        expect(result, isEmpty);
      });
    });

    // ─── getAnimalsByZone ─────────────────────────────────────────────────────

    group('getAnimalsByZone', () {
      test('returns only animals belonging to the given zone', () async {
        await fakeFirestore.collection('animal').doc('animal3').set({
          'animalName': 'Flamingo',
          'animalDetail': 'Pink wading bird',
          'animalPicture': 'https://example.com/flamingo.jpg',
          'zoneId': '/zone/zone3',
        });

        final result = await service.getAnimalsByZone('zone3');

        expect(result, isA<List<AnimalModel>>());
        expect(result.length, 1);
        expect(result.first.animalName, 'Flamingo');
      });

      test('returns empty list when no animals match zone', () async {
        final result = await service.getAnimalsByZone('nonexistent-zone');

        expect(result, isEmpty);
      });
    });

    // ─── getZones ─────────────────────────────────────────────────────────────

    group('getZones', () {
      test('returns all seeded zones', () async {
        await fakeFirestore.collection('zone').doc('zone1').set({
          'zoneName': 'Bird Zone',
        });
        await fakeFirestore.collection('zone').doc('zone2').set({
          'zoneName': 'Savanna Zone',
        });

        final result = await service.getZones();

        expect(result.length, 2);
        expect(
          result.map((z) => z.zoneName),
          containsAll(['Bird Zone', 'Savanna Zone']),
        );
      });

      test('returns empty list when zone collection is empty', () async {
        final emptyService = AnimalService(db: FakeFirebaseFirestore());

        final result = await emptyService.getZones();

        expect(result, isEmpty);
      });
    });

    // ─── getRandomPopularAnimals ──────────────────────────────────────────────

    group('getRandomPopularAnimals', () {
      test('returns at most the requested count', () async {
        final result = await service.getRandomAnimals(1);

        expect(result.length, lessThanOrEqualTo(1));
      });

      test('returns all animals when count exceeds total', () async {
        final result = await service.getRandomAnimals(100);

        expect(result.length, 2);
      });

      test('returns empty list when collection is empty', () async {
        final emptyService = AnimalService(db: FakeFirebaseFirestore());

        final result = await emptyService.getRandomAnimals(3);

        expect(result, isEmpty);
      });
    });

    // ─── getAnimalsWithZone ───────────────────────────────────────────────────

    group('getAnimalsWithZone', () {
      test('returns combined animal+zone data as map list', () async {
        await fakeFirestore.collection('zone').doc('zone1').set({
          'zoneName': 'Bird Zone',
        });

        final result = await service.getAnimalsWithZone();

        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.isNotEmpty, true);

        final keys = result.first.keys;
        expect(
          keys,
          containsAll([
            'id',
            'animalName',
            'animalDetail',
            'animalPicture',
            'zoneName',
          ]),
        );
      });

      test('returns empty list when animal collection is empty', () async {
        final emptyService = AnimalService(db: FakeFirebaseFirestore());

        final result = await emptyService.getAnimalsWithZone();

        expect(result, isEmpty);
      });
    });
  });
}
