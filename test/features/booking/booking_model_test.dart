import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/models/booking_model.dart';
import 'package:zoopernova_zoo_system/features/booking/models/selected_add_on_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  BookingModel baseModel({
    String id = 'bk1',
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 0,
    DateTime? date,
    String status = 'pending',
    String userId = 'user123',
    List<SelectedAddOnModel> selectedAddOns = const [],
  }) => BookingModel(
    id: id,
    adultTotal: adultTotal,
    childTotal: childTotal,
    elderTotal: elderTotal,
    date: date ?? DateTime(2026, 5, 10),
    status: status,
    userId: userId,
    selectedAddOns: selectedAddOns,
  );

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('BookingModel.fromFirestore', () {
    test(
      'maps all fields correctly when userId is a DocumentReference',
      () async {
        // Arrange
        final userRef = fakeFirestore.collection('user').doc('user123');
        await fakeFirestore.collection('booking').doc('bk1').set({
          'adultTotal': 2,
          'childTotal': 1,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
          'status': 'pending',
          'userId': userRef,
          'selectedAddOns': [],
        });
        final doc = await fakeFirestore.collection('booking').doc('bk1').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.id, 'bk1');
        expect(model.adultTotal, 2);
        expect(model.childTotal, 1);
        expect(model.elderTotal, 0);
        expect(model.date, DateTime(2026, 5, 10));
        expect(model.status, 'pending');
        expect(model.userId, 'user123');
      },
    );

    test('handles userId stored as plain String', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk2').set({
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'Done',
        'userId': 'plainStringUid',
        'selectedAddOns': [],
      });
      final doc = await fakeFirestore.collection('booking').doc('bk2').get();

      // Act
      final model = BookingModel.fromFirestore(doc);

      // Assert
      expect(model.userId, 'plainStringUid');
      expect(model.status, 'Done');
    });

    test('falls back to epoch when date field is missing', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk3').set({
        'adultTotal': 0,
        'childTotal': 0,
        'elderTotal': 0,
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk3').get();

      // Act
      final model = BookingModel.fromFirestore(doc);

      // Assert
      expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('defaults numeric fields to 0 when missing', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk4').set({
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk4').get();

      // Act
      final model = BookingModel.fromFirestore(doc);

      // Assert
      expect(model.adultTotal, 0);
      expect(model.childTotal, 0);
      expect(model.elderTotal, 0);
    });

    test('selectedAddOns defaults to empty list when field is absent', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk5').set({
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk5').get();

      // Act
      final model = BookingModel.fromFirestore(doc);

      // Assert
      expect(model.selectedAddOns, isEmpty);
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
      expect(map['adultTotal'], 2);
      expect(map['childTotal'], 1);
      expect(map['elderTotal'], 0);
      expect(map['date'], Timestamp.fromDate(date));
      expect(map['status'], 'pending');
      expect(map['userId'], 'user123');
    });

    test('numeric fields are int not String', () {
      // Arrange/Act
      final map = baseModel(adultTotal: 3, childTotal: 2, elderTotal: 1).toMap();

      // Assert
      expect(map['adultTotal'], isA<int>());
      expect(map['childTotal'], isA<int>());
      expect(map['elderTotal'], isA<int>());
    });

    test('date field is Timestamp not String', () {
      // Arrange/Act
      final map = baseModel().toMap();

      // Assert
      expect(map['date'], isA<Timestamp>());
    });

    test(
      'userId in toMap is a plain String (service converts to DocumentReference)',
      () {
        // Arrange/Act
        final map = baseModel(userId: 'user123').toMap();

        // Assert
        expect(map['userId'], isA<String>());
        expect(map['userId'], 'user123');
      },
    );

    test('does not contain legacy boolean add-on keys', () {
      // Arrange/Act
      final map = baseModel().toMap();

      // Assert — old fields must not exist
      expect(map.containsKey('buffetFood'), false);
      expect(map.containsKey('golfCar'), false);
      expect(map.containsKey('guidTour'), false);
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('BookingModel.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(adultTotal: 5, status: 'Done');

      // Assert — changed
      expect(updated.adultTotal, 5);
      expect(updated.status, 'Done');
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.childTotal, original.childTotal);
      expect(updated.elderTotal, original.elderTotal);
      expect(updated.date, original.date);
      expect(updated.userId, original.userId);
    });

    test('returns equivalent object when no fields are changed', () {
      // Arrange
      final original = baseModel();

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.id, original.id);
      expect(copy.adultTotal, original.adultTotal);
      expect(copy.childTotal, original.childTotal);
      expect(copy.elderTotal, original.elderTotal);
      expect(copy.date, original.date);
      expect(copy.status, original.status);
      expect(copy.userId, original.userId);
    });

    test('can update status to Done', () {
      // Arrange/Act
      final updated = baseModel().copyWith(status: 'Done');

      // Assert
      expect(updated.status, 'Done');
    });
  });
}
