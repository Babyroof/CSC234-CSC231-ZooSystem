import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/tickets/models/ticket_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  TicketModel baseModel({
    String id = 'tk1',
    bool buffetFood = true,
    bool golfCar = false,
    bool guidTour = true,
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 0,
    DateTime? date,
    String status = 'pending',
    DocumentReference? userId,
  }) {
    final ref = fakeFirestore.collection('user').doc('user123');
    return TicketModel(
      id: id,
      buffetFood: buffetFood,
      golfCar: golfCar,
      guidTour: guidTour,
      adultTotal: adultTotal,
      childTotal: childTotal,
      elderTotal: elderTotal,
      date: date ?? DateTime(2026, 5, 10),
      status: status,
      userId: userId ?? ref,
    );
  }

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('TicketModel.fromFirestore', () {
    test('maps all fields correctly', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('user123');
      await fakeFirestore.collection('booking').doc('tk1').set({
        'BuffetFood': true,
        'GolfCar': false,
        'GuidTour': true,
        'adultTotal': 2,
        'childTotal': 1,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
        'status': 'pending',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk1').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.id, 'tk1');
      expect(model.buffetFood, true);
      expect(model.golfCar, false);
      expect(model.guidTour, true);
      expect(model.adultTotal, 2);
      expect(model.childTotal, 1);
      expect(model.elderTotal, 0);
      expect(model.date, DateTime(2026, 5, 10));
      expect(model.status, 'pending');
      expect(model.userId, isA<DocumentReference>());
      expect(model.userId.id, 'user123');
    });

    test('boolean fields default to false when absent', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('uid');
      await fakeFirestore.collection('booking').doc('tk2').set({
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'Done',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk2').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.buffetFood, false);
      expect(model.golfCar, false);
      expect(model.guidTour, false);
    });

    test('falls back to epoch when date field is missing', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('uid');
      await fakeFirestore.collection('booking').doc('tk3').set({
        'BuffetFood': false,
        'GolfCar': false,
        'GuidTour': false,
        'adultTotal': 0,
        'childTotal': 0,
        'elderTotal': 0,
        'status': 'pending',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk3').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('numeric fields default to 0 when absent', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('uid');
      await fakeFirestore.collection('booking').doc('tk4').set({
        'BuffetFood': false,
        'GolfCar': false,
        'GuidTour': false,
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk4').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.adultTotal, 0);
      expect(model.childTotal, 0);
      expect(model.elderTotal, 0);
    });
  });

  // ── toMap ────────────────────────────────────────────────────────────────
  group('TicketModel.toMap', () {
    test('returns map with all fields and correct values', () {
      // Arrange
      final date = DateTime(2026, 5, 10);
      final model = baseModel(date: date);

      // Act
      final map = model.toMap();

      // Assert
      expect(map['BuffetFood'], true);
      expect(map['GolfCar'], false);
      expect(map['GuidTour'], true);
      expect(map['adultTotal'], 2);
      expect(map['childTotal'], 1);
      expect(map['elderTotal'], 0);
      expect(map['date'], Timestamp.fromDate(date));
      expect(map['status'], 'pending');
      expect(map['userId'], isA<DocumentReference>());
    });

    test('boolean fields are bool not String', () {
      final map =
          baseModel(buffetFood: true, golfCar: true, guidTour: false).toMap();

      expect(map['BuffetFood'], isA<bool>());
      expect(map['GolfCar'], isA<bool>());
      expect(map['GuidTour'], isA<bool>());
    });

    test('numeric fields are int not String', () {
      final map =
          baseModel(adultTotal: 3, childTotal: 2, elderTotal: 1).toMap();

      expect(map['adultTotal'], isA<int>());
      expect(map['childTotal'], isA<int>());
      expect(map['elderTotal'], isA<int>());
    });

    test('date field is Timestamp not String', () {
      final map = baseModel().toMap();
      expect(map['date'], isA<Timestamp>());
    });

    test('userId field is DocumentReference', () {
      final map = baseModel().toMap();
      expect(map['userId'], isA<DocumentReference>());
      expect((map['userId'] as DocumentReference).id, 'user123');
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('TicketModel.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(status: 'Done', adultTotal: 5);

      // Assert — changed
      expect(updated.status, 'Done');
      expect(updated.adultTotal, 5);
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.buffetFood, original.buffetFood);
      expect(updated.golfCar, original.golfCar);
      expect(updated.guidTour, original.guidTour);
      expect(updated.childTotal, original.childTotal);
      expect(updated.elderTotal, original.elderTotal);
      expect(updated.date, original.date);
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

    test('can update userId to a different DocumentReference', () {
      // Arrange
      final original = baseModel();
      final newRef = fakeFirestore.collection('user').doc('user999');

      // Act
      final updated = original.copyWith(userId: newRef);

      // Assert
      expect(updated.userId.id, 'user999');
      expect(updated.id, original.id);
    });
  });
}
