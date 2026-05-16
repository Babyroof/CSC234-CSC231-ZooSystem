import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/models/add_on_model.dart';
import 'package:zoopernova_zoo_system/features/booking/models/selected_add_on_model.dart';

void main() {
  // ===========================================================================
  // AddOnModel
  // ===========================================================================
  group('AddOnModel', () {
    group('fromFirestore', () {
      test(
        'maps all fields: id, name, price, isActive, order, priceType',
        () async {
          // Arrange
          final fakeDb = FakeFirebaseFirestore();
          final docRef = await fakeDb.collection('addOns').add({
            'name': 'Golf Car',
            'price': 500,
            'isActive': true,
            'order': 3,
            'priceType': 'per_booking',
          });
          final doc = await docRef.get();

          // Act
          final model = AddOnModel.fromFirestore(doc);

          // Assert
          expect(model.id, docRef.id);
          expect(model.name, 'Golf Car');
          expect(model.price, 500);
          expect(model.isActive, true);
          expect(model.order, 3);
          expect(model.priceType, 'per_booking');
        },
      );

      test('priceType defaults to per_booking when field is absent', () async {
        // Arrange
        final fakeDb = FakeFirebaseFirestore();
        final docRef = await fakeDb.collection('addOns').add({
          'name': 'Buffet',
          'price': 200,
          'isActive': true,
          'order': 1,
          // priceType intentionally omitted
        });
        final doc = await docRef.get();

        // Act
        final model = AddOnModel.fromFirestore(doc);

        // Assert
        expect(model.priceType, 'per_booking');
      });

      test('isActive defaults to false when field is absent', () async {
        // Arrange
        final fakeDb = FakeFirebaseFirestore();
        final docRef = await fakeDb.collection('addOns').add({
          'name': 'Guide Tour',
          'price': 350,
          'order': 2,
          // isActive intentionally omitted
        });
        final doc = await docRef.get();

        // Act
        final model = AddOnModel.fromFirestore(doc);

        // Assert
        expect(model.isActive, false);
      });

      test('order defaults to 0 when field is absent', () async {
        // Arrange
        final fakeDb = FakeFirebaseFirestore();
        final docRef = await fakeDb.collection('addOns').add({
          'name': 'Photo Package',
          'price': 100,
          'isActive': true,
          // order intentionally omitted
        });
        final doc = await docRef.get();

        // Act
        final model = AddOnModel.fromFirestore(doc);

        // Assert
        expect(model.order, 0);
      });
    });

    group('calculatePrice', () {
      test('returns price when priceType is per_booking', () {
        // Arrange
        const addon = AddOnModel(
          id: 'a1',
          name: 'Buffet',
          price: 200,
          isActive: true,
          order: 1,
          priceType: 'per_booking',
        );

        // Act
        final result = addon.calculatePrice(5);

        // Assert
        expect(result, 200);
      });

      test('returns price * totalPeople when priceType is per_person', () {
        // Arrange
        const addon = AddOnModel(
          id: 'a2',
          name: 'Snack Pack',
          price: 80,
          isActive: true,
          order: 2,
          priceType: 'per_person',
        );

        // Act
        final result = addon.calculatePrice(4);

        // Assert
        expect(result, 320); // 80 * 4
      });

      test('returns 0 when priceType is per_person and totalPeople is 0', () {
        // Arrange
        const addon = AddOnModel(
          id: 'a3',
          name: 'Snack Pack',
          price: 80,
          isActive: true,
          order: 2,
          priceType: 'per_person',
        );

        // Act
        final result = addon.calculatePrice(0);

        // Assert
        expect(result, 0);
      });
    });

    group('toMap', () {
      test('contains priceType key', () {
        // Arrange
        const addon = AddOnModel(
          id: 'a1',
          name: 'Buffet',
          price: 200,
          isActive: true,
          order: 1,
          priceType: 'per_person',
        );

        // Act
        final map = addon.toMap();

        // Assert
        expect(map.containsKey('priceType'), true);
        expect(map['priceType'], 'per_person');
      });
    });

    group('copyWith', () {
      test('updates only specified fields and leaves others unchanged', () {
        // Arrange
        const original = AddOnModel(
          id: 'a1',
          name: 'Buffet',
          price: 200,
          isActive: true,
          order: 1,
          priceType: 'per_booking',
        );

        // Act
        final updated = original.copyWith(price: 300, isActive: false);

        // Assert — changed
        expect(updated.price, 300);
        expect(updated.isActive, false);
        // Assert — unchanged
        expect(updated.id, original.id);
        expect(updated.name, original.name);
        expect(updated.order, original.order);
        expect(updated.priceType, original.priceType);
      });
    });
  });

  // ===========================================================================
  // SelectedAddOnModel
  // ===========================================================================
  group('SelectedAddOnModel', () {
    group('fromMap', () {
      test('maps addOnId, name, price, priceType correctly', () {
        // Arrange
        final map = {
          'addOnId': 'ao1',
          'name': 'Golf Car',
          'price': 500,
          'priceType': 'per_booking',
        };

        // Act
        final model = SelectedAddOnModel.fromMap(map);

        // Assert
        expect(model.addOnId, 'ao1');
        expect(model.name, 'Golf Car');
        expect(model.price, 500);
        expect(model.priceType, 'per_booking');
      });

      test('priceType defaults to per_booking when absent from map', () {
        // Arrange — no priceType key
        final map = {'addOnId': 'ao2', 'name': 'Snack', 'price': 80};

        // Act
        final model = SelectedAddOnModel.fromMap(map);

        // Assert
        expect(model.priceType, 'per_booking');
      });
    });

    group('toMap', () {
      test(
        'returns map with exactly 4 keys: addOnId, name, price, priceType',
        () {
          // Arrange
          const model = SelectedAddOnModel(
            addOnId: 'ao1',
            name: 'Buffet',
            price: 200,
            priceType: 'per_booking',
          );

          // Act
          final map = model.toMap();

          // Assert
          expect(
            map.keys.toSet(),
            equals({'addOnId', 'name', 'price', 'priceType'}),
          );
          expect(map.length, 4);
        },
      );
    });

    group('calculatePrice', () {
      test('returns price for per_booking regardless of totalPeople', () {
        // Arrange
        const model = SelectedAddOnModel(
          addOnId: 'ao1',
          name: 'Buffet',
          price: 200,
          priceType: 'per_booking',
        );

        // Act & Assert
        expect(model.calculatePrice(1), 200);
        expect(model.calculatePrice(10), 200);
        expect(model.calculatePrice(0), 200);
      });

      test('returns price * totalPeople for per_person', () {
        // Arrange
        const model = SelectedAddOnModel(
          addOnId: 'ao2',
          name: 'Snack',
          price: 80,
          priceType: 'per_person',
        );

        // Act & Assert
        expect(model.calculatePrice(3), 240); // 80 * 3
        expect(model.calculatePrice(0), 0);
      });
    });
  });
}
