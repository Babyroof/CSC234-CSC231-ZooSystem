import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/models/booking_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  BookingModel baseModel({
    String id = 'bk1',
    bool buffetFood = true,
    bool golfCar = false,
    bool guidTour = true,
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 0,
    DateTime? date,
    String status = 'pending',
    String userId = 'user123',
  }) => BookingModel(
    id: id,
    buffetFood: buffetFood,
    golfCar: golfCar,
    guidTour: guidTour,
    adultTotal: adultTotal,
    childTotal: childTotal,
    elderTotal: elderTotal,
    date: date ?? DateTime(2026, 5, 10),
    status: status,
    userId: userId,
  );

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('BookingModel.fromFirestore', () {
    test(
      'maps all fields correctly when userId is a DocumentReference',
      () async {
        // Arrange
        final userRef = fakeFirestore.collection('user').doc('user123');
        await fakeFirestore.collection('booking').doc('bk1').set({
          'BuffetFood': true,
          'GolfCar': false,
          'GuideTour': true,
          'adultTotal': 2,
          'childTotal': 1,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
          'status': 'pending',
          'userId': userRef,
        });
        final doc = await fakeFirestore.collection('booking').doc('bk1').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.id, 'bk1');
        expect(model.buffetFood, true);
        expect(model.golfCar, false);
        expect(model.guidTour, true);
        expect(model.adultTotal, 2);
        expect(model.childTotal, 1);
        expect(model.elderTotal, 0);
        expect(model.date, DateTime(2026, 5, 10));
        expect(model.status, 'pending');
        expect(model.userId, 'user123');
      },
    );

    test('handles userId stored as plain String', () async {
      await fakeFirestore.collection('booking').doc('bk2').set({
        'BuffetFood': false,
        'GolfCar': false,
        'GuideTour': false,
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'Done',
        'userId': 'plainStringUid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk2').get();

      final model = BookingModel.fromFirestore(doc);

      expect(model.userId, 'plainStringUid');
      expect(model.status, 'Done');
    });

    test('falls back to epoch when date field is missing', () async {
      await fakeFirestore.collection('booking').doc('bk3').set({
        'BuffetFood': false,
        'GolfCar': false,
        'GuideTour': false,
        'adultTotal': 0,
        'childTotal': 0,
        'elderTotal': 0,
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk3').get();

      final model = BookingModel.fromFirestore(doc);

      expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('defaults numeric fields to 0 when missing', () async {
      await fakeFirestore.collection('booking').doc('bk4').set({
        'BuffetFood': false,
        'GolfCar': false,
        'GuideTour': false,
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk4').get();

      final model = BookingModel.fromFirestore(doc);

      expect(model.adultTotal, 0);
      expect(model.childTotal, 0);
      expect(model.elderTotal, 0);
    });

    test('boolean fields default to false when missing', () async {
      await fakeFirestore.collection('booking').doc('bk5').set({
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk5').get();

      final model = BookingModel.fromFirestore(doc);

      expect(model.buffetFood, false);
      expect(model.golfCar, false);
      expect(model.guidTour, false);
    });
  });

  // ── toMap ────────────────────────────────────────────────────────────────
  group('BookingModel.toMap', () {
    test('returns map with all expected keys and correct values', () {
      // Arrange
      final date = DateTime(2026, 5, 10);
      final model = baseModel(date: date);

      // Act
      final map = model.toMap();

      // Assert
      expect(map['BuffetFood'], true);
      expect(map['GolfCar'], false);
      expect(map['GuideTour'], true);
      expect(map['adultTotal'], 2);
      expect(map['childTotal'], 1);
      expect(map['elderTotal'], 0);
      expect(map['date'], Timestamp.fromDate(date));
      expect(map['status'], 'pending');
      expect(map['userId'], 'user123');
    });

    test('boolean fields are bool not String', () {
      final map = baseModel(
        buffetFood: true,
        golfCar: true,
        guidTour: false,
      ).toMap();

      expect(map['BuffetFood'], isA<bool>());
      expect(map['GolfCar'], isA<bool>());
      expect(map['GuideTour'], isA<bool>());
    });

    test('numeric fields are int not String', () {
      final map = baseModel(
        adultTotal: 3,
        childTotal: 2,
        elderTotal: 1,
      ).toMap();

      expect(map['adultTotal'], isA<int>());
      expect(map['childTotal'], isA<int>());
      expect(map['elderTotal'], isA<int>());
    });

    test('date field is Timestamp not String', () {
      final map = baseModel().toMap();

      expect(map['date'], isA<Timestamp>());
    });

    test(
      'userId in toMap is a plain String (service converts to DocumentReference)',
      () {
        final map = baseModel(userId: 'user123').toMap();

        expect(map['userId'], isA<String>());
        expect(map['userId'], 'user123');
      },
    );
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('BookingModel.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(adultTotal: 5, buffetFood: false);

      // Assert — changed
      expect(updated.adultTotal, 5);
      expect(updated.buffetFood, false);
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.childTotal, original.childTotal);
      expect(updated.elderTotal, original.elderTotal);
      expect(updated.golfCar, original.golfCar);
      expect(updated.guidTour, original.guidTour);
      expect(updated.date, original.date);
      expect(updated.status, original.status);
      expect(updated.userId, original.userId);
    });

    test('returns equivalent object when no fields are changed', () {
      final original = baseModel();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.buffetFood, original.buffetFood);
      expect(copy.golfCar, original.golfCar);
      expect(copy.guidTour, original.guidTour);
      expect(copy.adultTotal, original.adultTotal);
      expect(copy.childTotal, original.childTotal);
      expect(copy.elderTotal, original.elderTotal);
      expect(copy.date, original.date);
      expect(copy.status, original.status);
      expect(copy.userId, original.userId);
    });

    test('can update status to Done', () {
      final updated = baseModel().copyWith(status: 'Done');
      expect(updated.status, 'Done');
    });
  });
}
