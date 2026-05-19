import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/data/datasources/add_on_remote_datasource.dart';

void main() {
  group('AddOnRemoteDataSourceImpl', () {
    test('returns only addOns where isActive is true', () async {
      // Arrange
      final fakeDb = FakeFirebaseFirestore();
      await fakeDb.collection('addOns').add({
        'name': 'A',
        'price': 100,
        'isActive': true,
        'order': 1,
        'priceType': 'per_booking',
      });
      await fakeDb.collection('addOns').add({
        'name': 'B',
        'price': 200,
        'isActive': false,
        'order': 2,
        'priceType': 'per_booking',
      });

      // Act
      final results = await AddOnRemoteDataSourceImpl(
        db: fakeDb,
      ).getActiveAddOns().first;

      // Assert
      expect(results.length, 1);
      expect(results.first.name, 'A');
    });

    test('excludes addOns where isActive is false', () async {
      // Arrange
      final fakeDb = FakeFirebaseFirestore();
      await fakeDb.collection('addOns').add({
        'name': 'Inactive',
        'price': 150,
        'isActive': false,
        'order': 1,
        'priceType': 'per_booking',
      });

      // Act
      final results = await AddOnRemoteDataSourceImpl(
        db: fakeDb,
      ).getActiveAddOns().first;

      // Assert
      expect(results, isEmpty);
    });

    test('results are ordered by order field ascending', () async {
      // Arrange
      final fakeDb = FakeFirebaseFirestore();
      await fakeDb.collection('addOns').add({
        'name': 'Third',
        'price': 300,
        'isActive': true,
        'order': 3,
        'priceType': 'per_booking',
      });
      await fakeDb.collection('addOns').add({
        'name': 'First',
        'price': 100,
        'isActive': true,
        'order': 1,
        'priceType': 'per_booking',
      });
      await fakeDb.collection('addOns').add({
        'name': 'Second',
        'price': 200,
        'isActive': true,
        'order': 2,
        'priceType': 'per_booking',
      });

      // Act
      final results = await AddOnRemoteDataSourceImpl(
        db: fakeDb,
      ).getActiveAddOns().first;

      // Assert
      expect(results.length, 3);
      expect(results[0].name, 'First');
      expect(results[1].name, 'Second');
      expect(results[2].name, 'Third');
    });

    test('returns empty list when collection is empty', () async {
      // Arrange
      final fakeDb = FakeFirebaseFirestore();

      // Act
      final results = await AddOnRemoteDataSourceImpl(
        db: fakeDb,
      ).getActiveAddOns().first;

      // Assert
      expect(results, isEmpty);
    });

    test(
      'stream reflects a new active document added after stream starts',
      () async {
        // Arrange
        final fakeDb = FakeFirebaseFirestore();
        final service = AddOnRemoteDataSourceImpl(db: fakeDb);

        // Act — subscribe first, then add a document
        final streamFuture = service.getActiveAddOns().skip(1).first;
        await fakeDb.collection('addOns').add({
          'name': 'Late Arrival',
          'price': 250,
          'isActive': true,
          'order': 1,
          'priceType': 'per_person',
        });
        final results = await streamFuture;

        // Assert
        expect(results.length, 1);
        expect(results.first.name, 'Late Arrival');
        expect(results.first.priceType, 'per_person');
      },
    );
  });
}
