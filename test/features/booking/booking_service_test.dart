import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/models/booking_model.dart';
import 'package:zoopernova_zoo_system/features/booking/services/booking_service.dart';

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
  late BookingService service;

  // ── Shared test booking ─────────────────────────────────────────────────
  BookingModel testBooking({String id = '', String userId = 'user123'}) =>
      BookingModel(
        id: id,
        buffetFood: true,
        golfCar: false,
        guidTour: true,
        adultTotal: 2,
        childTotal: 1,
        elderTotal: 0,
        date: DateTime(2026, 5, 10),
        status: 'pending',
        userId: userId,
      );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = BookingService(db: fakeFirestore);
  });

  // ── createBooking ─────────────────────────────────────────────────────────
  group('createBooking', () {
    test('writes document to booking collection', () async {
      // Arrange
      final booking = testBooking();

      // Act
      await service.createBooking(booking);

      // Assert
      final snap = await fakeFirestore.collection('booking').get();
      expect(snap.docs.length, 1);
    });

    test('writes all fields with correct values', () async {
      await service.createBooking(testBooking());

      final data = (await fakeFirestore.collection('booking').get()).docs.first
          .data();

      expect(data['BuffetFood'], true);
      expect(data['GolfCar'], false);
      expect(data['GuideTour'], true);
      expect(data['adultTotal'], 2);
      expect(data['childTotal'], 1);
      expect(data['elderTotal'], 0);
      expect(data['status'], 'pending');
      expect(data['date'], isA<Timestamp>());
    });

    test(
      'writes userId as DocumentReference pointing to /user/{uid}',
      () async {
        await service.createBooking(testBooking(userId: 'user123'));

        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        final userIdField = data['userId'];

        expect(userIdField, isA<DocumentReference>());
        expect((userIdField as DocumentReference).id, 'user123');
      },
    );

    test('throws on Firestore error', () {
      final errorService = BookingService(db: _ErrorFirestore());

      expect(
        () => errorService.createBooking(testBooking()),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── getBookingById ────────────────────────────────────────────────────────
  group('getBookingById', () {
    Future<void> seedDoc(String docId) async {
      final userRef = fakeFirestore.collection('user').doc('user123');
      await fakeFirestore.collection('booking').doc(docId).set({
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
    }

    test('returns correct BookingModel for existing document', () async {
      // Arrange
      await seedDoc('bk1');

      // Act
      final result = await service.getBookingById('bk1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'bk1');
      expect(result.adultTotal, 2);
      expect(result.userId, 'user123');
      expect(result.buffetFood, true);
      expect(result.date, DateTime(2026, 5, 10));
    });

    test('returns null when document does not exist', () async {
      // Act
      final result = await service.getBookingById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('throws on Firestore error', () {
      final errorService = BookingService(db: _ErrorFirestore());

      expect(
        () => errorService.getBookingById('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── getBookingsByUser ─────────────────────────────────────────────────────
  group('getBookingsByUser', () {
    final baseDoc = {
      'BuffetFood': false,
      'GolfCar': false,
      'GuideTour': false,
      'adultTotal': 1,
      'childTotal': 0,
      'elderTotal': 0,
      'status': 'pending',
    };

    test('returns only bookings belonging to the specified user', () async {
      // Arrange
      final ref1 = fakeFirestore.collection('user').doc('user1');
      final ref2 = fakeFirestore.collection('user').doc('user2');

      await fakeFirestore.collection('booking').doc('b1').set({
        ...baseDoc,
        'date': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'userId': ref1,
      });
      await fakeFirestore.collection('booking').doc('b2').set({
        ...baseDoc,
        'date': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'userId': ref1,
      });
      await fakeFirestore.collection('booking').doc('b3').set({
        ...baseDoc,
        'date': Timestamp.fromDate(DateTime(2026, 5, 3)),
        'userId': ref2,
      });

      // Act
      final results = await service.getBookingsByUser('user1').first;

      // Assert
      expect(results.length, 2);
      expect(results.every((b) => b.userId == 'user1'), true);
    });

    test('returns empty list when user has no bookings', () async {
      final results = await service.getBookingsByUser('unknown').first;
      expect(results, isEmpty);
    });

    test('returns bookings ordered by date descending', () async {
      final userRef = fakeFirestore.collection('user').doc('user1');

      await fakeFirestore.collection('booking').doc('older').set({
        ...baseDoc,
        'date': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'userId': userRef,
      });
      await fakeFirestore.collection('booking').doc('newer').set({
        ...baseDoc,
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'userId': userRef,
      });

      final results = await service.getBookingsByUser('user1').first;

      expect(results.first.date, DateTime(2026, 6, 1));
      expect(results.last.date, DateTime(2026, 3, 1));
    });

    test('throws on Firestore error', () {
      final errorService = BookingService(db: _ErrorFirestore());

      expect(
        () => errorService.getBookingsByUser('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── deleteBooking ─────────────────────────────────────────────────────────
  group('deleteBooking', () {
    test('removes the document from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('todelete').set({
        'BuffetFood': false,
        'GolfCar': false,
        'GuideTour': false,
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'status': 'pending',
        'userId': fakeFirestore.collection('user').doc('uid'),
      });

      // Act
      await service.deleteBooking('todelete');

      // Assert
      final doc = await fakeFirestore
          .collection('booking')
          .doc('todelete')
          .get();
      expect(doc.exists, false);
    });

    test('does not affect other documents', () async {
      final userRef = fakeFirestore.collection('user').doc('uid');
      final docData = {
        'BuffetFood': false,
        'GolfCar': false,
        'GuideTour': false,
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'status': 'pending',
        'userId': userRef,
      };

      await fakeFirestore.collection('booking').doc('keep').set(docData);
      await fakeFirestore.collection('booking').doc('remove').set(docData);

      await service.deleteBooking('remove');

      final remaining = await fakeFirestore.collection('booking').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, 'keep');
    });

    test('throws on Firestore error', () {
      final errorService = BookingService(db: _ErrorFirestore());

      expect(
        () => errorService.deleteBooking('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
