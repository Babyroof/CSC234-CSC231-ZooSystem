import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:zoopernova_zoo_system/features/animals_info/models/animal_model.dart';
import 'package:zoopernova_zoo_system/features/animals_info/models/zone_model.dart';
import 'package:zoopernova_zoo_system/features/events_show/models/event_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Zone Tests', () {
    test('GET zones - should return list of zones', () async {
      // Arrange: ใส่ข้อมูลจำลอง
      await fakeFirestore.collection('zone').add({'zoneName': 'Birds'});
      await fakeFirestore.collection('zone').add({'zoneName': 'Mammals'});

      // Act: ดึงข้อมูล
      final snapshot = await fakeFirestore.collection('zone').get();
      final zones = snapshot.docs
          .map((doc) => ZoneModel.fromMap(doc.id, doc.data()))
          .toList();

      // Assert: ตรวจสอบผลลัพธ์
      expect(zones.length, 2);
      expect(zones[0].zoneName, 'Birds');
      expect(zones[1].zoneName, 'Mammals');
    });
  });

  group('Animal Tests', () {
    test('GET animals - should return list of animals', () async {
      // Arrange
      await fakeFirestore.collection('animal').add({
        'animalName': 'Punch Kung',
        'animalDetail': 'This is a monkey.',
        'animalPicture': 'URL',
        'zoneId': '/zone/UID123',
      });

      // Act
      final snapshot = await fakeFirestore.collection('animal').get();
      final animals = snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.id, doc.data()))
          .toList();

      // Assert
      expect(animals.length, 1);
      expect(animals[0].animalName, 'Punch Kung');
      expect(animals[0].zoneId, '/zone/UID123');
    });

    test('GET animals by zone - should filter correctly', () async {
      // Arrange
      await fakeFirestore.collection('animal').add({
        'animalName': 'Punch Kung',
        'animalDetail': 'This is a monkey.',
        'animalPicture': 'URL',
        'zoneId': '/zone/zone001',
      });
      await fakeFirestore.collection('animal').add({
        'animalName': 'Big Bird',
        'animalDetail': 'This is a bird.',
        'animalPicture': 'URL',
        'zoneId': '/zone/zone002',  // zone อื่น
      });

      // Act: filter เฉพาะ zone001
      final snapshot = await fakeFirestore
          .collection('animal')
          .where('zoneId', isEqualTo: '/zone/zone001')
          .get();
      final animals = snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.id, doc.data()))
          .toList();

      // Assert: ได้แค่ตัวเดียว
      expect(animals.length, 1);
      expect(animals[0].animalName, 'Punch Kung');
    });
  });

  group('Event Tests', () {
    test('GET events - should return list of events', () async {
      // Arrange
      await fakeFirestore.collection('event').add({
        'eventName': "Poom's Show",
        'eventDetail': 'Greatest elephant show',
        'eventPicture': 'URL',
      });

      // Act
      final snapshot = await fakeFirestore.collection('event').get();
      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data()))
          .toList();

      // Assert
      expect(events.length, 1);
      expect(events[0].eventName, "Poom's Show");
    });
  });
}