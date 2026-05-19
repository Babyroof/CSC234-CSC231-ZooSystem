// test/features/booking/ticket/booking_data_layer_test.dart
//
// Unit tests for the booking/ticket data layer.
//
// BookingRemoteDataSourceImpl accepts an optional FirebaseFirestore via its constructor:
//
//   BookingRemoteDataSourceImpl({FirebaseFirestore? db})
//       : _db = db ?? FirebaseFirestore.instance;
//
// This makes full datasource-level testing possible without any refactoring by
// passing a FakeFirebaseFirestore instance.  All groups below use this pattern.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';
import 'package:zoopernova_zoo_system/features/booking/data/datasources/booking_remote_datasource.dart';
import 'package:zoopernova_zoo_system/features/booking/data/models/booking_dto.dart';
import 'package:zoopernova_zoo_system/features/booking/domain/entities/booking_entity.dart';
import 'package:zoopernova_zoo_system/features/booking/domain/entities/selected_add_on_entity.dart';

// ---------------------------------------------------------------------------
// _ErrorFirestore — simulates a Firestore that fails on every collection()
// call.  Used to verify that BookingRemoteDataSourceImpl re-throws exceptions.
// ---------------------------------------------------------------------------
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
  // ── Shared helpers ────────────────────────────────────────────────────────

  /// Returns a fully populated BookingEntity for use in entity-level tests.
  BookingEntity makeEntity({
    String id = 'bk_test',
    String userId = 'user_abc',
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 1,
    String status = 'pending',
    DateTime? date,
    int? totalPrice,
    String? chargeId,
    List<SelectedAddOnEntity> selectedAddOns = const [],
    int adultUnitPrice = BookingPricing.adultPrice,
    int childUnitPrice = BookingPricing.kidPrice,
    int elderUnitPrice = BookingPricing.elderPrice,
  }) => BookingEntity(
    id: id,
    userId: userId,
    adultTotal: adultTotal,
    childTotal: childTotal,
    elderTotal: elderTotal,
    date: date ?? DateTime(2026, 5, 10),
    status: status,
    totalPrice: totalPrice,
    chargeId: chargeId,
    selectedAddOns: selectedAddOns,
    adultUnitPrice: adultUnitPrice,
    childUnitPrice: childUnitPrice,
    elderUnitPrice: elderUnitPrice,
  );

  // =========================================================================
  // Group 1 — BookingEntity
  // =========================================================================
  group('BookingEntity', () {
    // ── totalAmount ──────────────────────────────────────────────────────────
    group('totalAmount', () {
      test('calculates ticket-only total with no add-ons', () {
        // Arrange
        final booking = makeEntity(
          adultTotal: 2,
          childTotal: 1,
          elderTotal: 1,
          selectedAddOns: const [],
        );

        // Act
        final total = booking.totalAmount;

        // Assert — 2*300 + 1*150 + 1*40 = 790
        const expected =
            2 * BookingPricing.adultPrice +
            1 * BookingPricing.kidPrice +
            1 * BookingPricing.elderPrice;
        expect(total, equals(expected)); // 790
      });

      test('calculates correctly with no add-ons and no people', () {
        // Arrange
        final booking = makeEntity(
          adultTotal: 0,
          childTotal: 0,
          elderTotal: 0,
          selectedAddOns: const [],
        );

        // Act & Assert
        expect(booking.totalAmount, equals(0));
      });

      test('uses BookingPricing constants for per-head prices', () {
        // Arrange — 3 adults, 2 children, 1 elder, no add-ons
        final booking = makeEntity(
          adultTotal: 3,
          childTotal: 2,
          elderTotal: 1,
          selectedAddOns: const [],
        );

        // Act
        final total = booking.totalAmount;

        // Assert
        expect(
          total,
          equals(
            3 * BookingPricing.adultPrice +
                2 * BookingPricing.kidPrice +
                1 * BookingPricing.elderPrice,
          ),
        );
      });

      test('adds selectedAddOns price to ticket total', () {
        // Arrange — 1 adult + 1 add-on of 200
        final booking = makeEntity(
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          selectedAddOns: const [
            SelectedAddOnEntity(
              addOnId: 'a1',
              name: 'Buffet',
              price: 200,
              priceType: 'per_booking',
            ),
          ],
        );

        // Act
        final total = booking.totalAmount;

        // Assert — totalAmount uses a.price directly (not calculatePrice)
        expect(total, equals(BookingPricing.adultPrice + 200));
      });
    });

    // ── totalPrice priority ──────────────────────────────────────────────────
    group('totalPrice field', () {
      test('totalPrice is null when not provided', () {
        // Arrange/Act
        final booking = makeEntity(totalPrice: null);

        // Assert
        expect(booking.totalPrice, isNull);
      });

      test('falls back to totalAmount when totalPrice is null', () {
        // Arrange — 1 adult, no add-ons → 300
        final booking = makeEntity(
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          selectedAddOns: const [],
          totalPrice: null,
        );

        // Act
        final effective = booking.totalPrice ?? booking.totalAmount;

        // Assert
        expect(effective, equals(BookingPricing.adultPrice));
      });
    });

    // ── BookingDto.fromFirestore ──────────────────────────────────────────────
    group('BookingDto.fromFirestore', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test(
        'maps all fields correctly when userId is a DocumentReference',
        () async {
          // Arrange
          final userRef = fakeFirestore.collection('user').doc('user_abc');
          await fakeFirestore.collection('booking').doc('bk1').set({
            'userId': userRef,
            'adultTotal': 2,
            'childTotal': 1,
            'elderTotal': 1,
            'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
            'status': 'Done',
            'totalPrice': 1540,
            'chargeId': 'ch_abc123',
            'selectedAddOns': [],
          });
          final doc = await fakeFirestore
              .collection('booking')
              .doc('bk1')
              .get();

          // Act
          final dto = BookingDto.fromFirestore(doc);

          // Assert
          expect(dto.id, 'bk1');
          expect(dto.userId, 'user_abc');
          expect(dto.adultTotal, 2);
          expect(dto.childTotal, 1);
          expect(dto.elderTotal, 1);
          expect(dto.date, DateTime(2026, 5, 10));
          expect(dto.status, 'Done');
          expect(dto.totalPrice, 1540);
          expect(dto.chargeId, 'ch_abc123');
        },
      );

      test('maps userId correctly when stored as plain String', () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk2').set({
          'userId': 'plainStringUid',
          'adultTotal': 1,
          'childTotal': 0,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
          'status': 'Pending',
          'selectedAddOns': [],
        });
        final doc = await fakeFirestore.collection('booking').doc('bk2').get();

        // Act
        final dto = BookingDto.fromFirestore(doc);

        // Assert
        expect(dto.userId, 'plainStringUid');
      });

      test('falls back to epoch when date field is absent', () async {
        // Arrange — no 'date' field
        await fakeFirestore.collection('booking').doc('bk3').set({
          'userId': 'uid',
          'adultTotal': 0,
          'childTotal': 0,
          'elderTotal': 0,
          'status': 'pending',
        });
        final doc = await fakeFirestore.collection('booking').doc('bk3').get();

        // Act
        final dto = BookingDto.fromFirestore(doc);

        // Assert
        expect(dto.date, DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('numeric fields default to 0 when absent', () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk4').set({
          'userId': 'uid',
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'status': 'pending',
          // adultTotal, childTotal, elderTotal intentionally omitted
        });
        final doc = await fakeFirestore.collection('booking').doc('bk4').get();

        // Act
        final dto = BookingDto.fromFirestore(doc);

        // Assert
        expect(dto.adultTotal, 0);
        expect(dto.childTotal, 0);
        expect(dto.elderTotal, 0);
      });

      test('chargeId and totalPrice are null when absent', () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk5').set({
          'userId': 'uid',
          'adultTotal': 1,
          'childTotal': 0,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'status': 'pending',
        });
        final doc = await fakeFirestore.collection('booking').doc('bk5').get();

        // Act
        final dto = BookingDto.fromFirestore(doc);

        // Assert
        expect(dto.chargeId, isNull);
        expect(dto.totalPrice, isNull);
      });
    });

    // ── entity fields ────────────────────────────────────────────────────────
    group('entity fields', () {
      test('all numeric fields are int', () {
        final entity = makeEntity(adultTotal: 3, childTotal: 2, elderTotal: 1);

        expect(entity.adultTotal, isA<int>());
        expect(entity.childTotal, isA<int>());
        expect(entity.elderTotal, isA<int>());
      });

      test('userId is a String', () {
        final entity = makeEntity(userId: 'user_xyz');

        expect(entity.userId, isA<String>());
        expect(entity.userId, 'user_xyz');
      });

      test('chargeId is null when not provided', () {
        final entity = makeEntity(chargeId: null);
        expect(entity.chargeId, isNull);
      });

      test('chargeId is set when provided', () {
        final entity = makeEntity(chargeId: 'ch_xyz');
        expect(entity.chargeId, 'ch_xyz');
      });

      test('totalPrice is null when not provided', () {
        final entity = makeEntity(totalPrice: null);
        expect(entity.totalPrice, isNull);
      });

      test('totalPrice is set when provided', () {
        final entity = makeEntity(totalPrice: 999);
        expect(entity.totalPrice, 999);
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────────────
    group('copyWith', () {
      test('updates only specified fields, leaves others unchanged', () {
        // Arrange
        final original = makeEntity();

        // Act
        final updated = original.copyWith(adultTotal: 5, status: 'Done');

        // Assert — changed
        expect(updated.adultTotal, 5);
        expect(updated.status, 'Done');
        // Assert — unchanged
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
        expect(updated.childTotal, original.childTotal);
        expect(updated.elderTotal, original.elderTotal);
        expect(updated.date, original.date);
      });

      test('returns equivalent entity when no fields are overridden', () {
        // Arrange
        final original = makeEntity();

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.adultTotal, original.adultTotal);
        expect(copy.childTotal, original.childTotal);
        expect(copy.elderTotal, original.elderTotal);
        expect(copy.date, original.date);
        expect(copy.status, original.status);
        expect(copy.chargeId, original.chargeId);
        expect(copy.totalPrice, original.totalPrice);
      });

      test('copyWith does not mutate the original entity', () {
        // Arrange
        final original = makeEntity(adultTotal: 2);

        // Act
        original.copyWith(adultTotal: 99);

        // Assert — original is unchanged
        expect(original.adultTotal, 2);
      });
    });
  });

  // =========================================================================
  // Group 2 — BookingRemoteDataSourceImpl
  // =========================================================================
  group('BookingRemoteDataSourceImpl', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingRemoteDataSourceImpl service;

    // Shared seed helper — writes a raw booking document into the fake store
    Future<void> seedRaw({
      required String docId,
      required String userId,
      String status = 'Done',
      int adultTotal = 1,
      int childTotal = 0,
      int elderTotal = 0,
      DateTime? date,
    }) async {
      final userRef = fakeFirestore.collection('user').doc(userId);
      await fakeFirestore.collection('booking').doc(docId).set({
        'userId': userRef,
        'status': status,
        'adultTotal': adultTotal,
        'childTotal': childTotal,
        'elderTotal': elderTotal,
        'date': Timestamp.fromDate(date ?? DateTime(2026, 5, 10)),
        'selectedAddOns': [],
      });
    }

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = BookingRemoteDataSourceImpl(db: fakeFirestore);
    });

    // ── createBooking ─────────────────────────────────────────────────────────
    group('createBooking', () {
      test('writes a new document to the booking collection', () async {
        // Arrange
        final booking = makeEntity(userId: 'user_abc');

        // Act
        await service.createBooking(booking);

        // Assert
        final snap = await fakeFirestore.collection('booking').get();
        expect(snap.docs.length, 1);
      });

      test('forces status to pending regardless of entity status', () async {
        // Arrange — entity has status 'Done'
        final booking = makeEntity(status: 'Done');

        // Act
        await service.createBooking(booking);

        // Assert — datasource always writes 'pending'
        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        expect(data['status'], 'pending');
      });

      test('stores totalPrice as the calculated totalAmount', () async {
        // Arrange — 2 adults, no add-ons → 2*300 = 600
        final booking = makeEntity(
          adultTotal: 2,
          childTotal: 0,
          elderTotal: 0,
          selectedAddOns: const [],
        );

        // Act
        await service.createBooking(booking);

        // Assert
        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        expect(data['totalPrice'], equals(2 * BookingPricing.adultPrice));
      });

      test(
        'stores userId as a DocumentReference pointing to /user/{uid}',
        () async {
          // Arrange
          final booking = makeEntity(userId: 'user_abc');

          // Act
          await service.createBooking(booking);

          // Assert
          final data = (await fakeFirestore.collection('booking').get())
              .docs
              .first
              .data();
          final userIdField = data['userId'];
          expect(userIdField, isA<DocumentReference>());
          expect((userIdField as DocumentReference).id, 'user_abc');
        },
      );

      test('date field is stored as Timestamp, not String', () async {
        // Arrange
        final booking = makeEntity(date: DateTime(2026, 5, 10));

        // Act
        await service.createBooking(booking);

        // Assert
        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        expect(data['date'], isA<Timestamp>());
      });

      test('returns the new document id', () async {
        // Arrange
        final booking = makeEntity();

        // Act
        final id = await service.createBooking(booking);

        // Assert
        expect(id, isA<String>());
        expect(id, isNotEmpty);
      });

      test('throws on Firestore error', () {
        // Arrange
        final errorService = BookingRemoteDataSourceImpl(db: _ErrorFirestore());

        // Assert
        expect(
          () => errorService.createBooking(makeEntity()),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    // ── getBookingById ────────────────────────────────────────────────────────
    group('getBookingById', () {
      test('returns correct BookingDto for an existing document', () async {
        // Arrange
        await seedRaw(
          docId: 'bk1',
          userId: 'user_abc',
          status: 'Done',
          adultTotal: 2,
          childTotal: 1,
          elderTotal: 0,
          date: DateTime(2026, 5, 10),
        );

        // Act
        final result = await service.getBookingById('bk1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'bk1');
        expect(result.userId, 'user_abc');
        expect(result.adultTotal, 2);
        expect(result.childTotal, 1);
        expect(result.elderTotal, 0);
        expect(result.status, 'Done');
        expect(result.date, DateTime(2026, 5, 10));
      });

      test('returns null when the document does not exist', () async {
        // Act
        final result = await service.getBookingById('nonexistent_id');

        // Assert
        expect(result, isNull);
      });

      test('throws on Firestore error', () {
        // Arrange
        final errorService = BookingRemoteDataSourceImpl(db: _ErrorFirestore());

        // Assert
        expect(
          () => errorService.getBookingById('any'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    // ── updateStatus ──────────────────────────────────────────────────────────
    group('updateStatus', () {
      test('updates only the status field', () async {
        // Arrange
        await seedRaw(docId: 'bk1', userId: 'uid', status: 'Pending');

        // Act
        await service.updateStatus(bookingId: 'bk1', status: 'Done');

        // Assert
        final data =
            (await fakeFirestore.collection('booking').doc('bk1').get())
                .data()!;
        expect(data['status'], 'Done');
        expect(data['adultTotal'], 1);
      });

      test('does not affect sibling documents', () async {
        // Arrange
        await seedRaw(docId: 'bk1', userId: 'uid', status: 'Pending');
        await seedRaw(docId: 'bk2', userId: 'uid', status: 'Pending');

        // Act — update only bk1
        await service.updateStatus(bookingId: 'bk1', status: 'Done');

        // Assert — bk2 is unchanged
        final data =
            (await fakeFirestore.collection('booking').doc('bk2').get())
                .data()!;
        expect(data['status'], 'Pending');
      });
    });

    // ── updateChargeId ────────────────────────────────────────────────────────
    group('updateChargeId', () {
      test('writes chargeId to the correct document', () async {
        // Arrange
        await seedRaw(docId: 'bk1', userId: 'uid');

        // Act
        await service.updateChargeId(bookingId: 'bk1', chargeId: 'ch_test_123');

        // Assert
        final data =
            (await fakeFirestore.collection('booking').doc('bk1').get())
                .data()!;
        expect(data['chargeId'], 'ch_test_123');
      });

      test('does not overwrite chargeId on sibling documents', () async {
        // Arrange
        await seedRaw(docId: 'bk1', userId: 'uid');
        await seedRaw(docId: 'bk2', userId: 'uid');

        // Act
        await service.updateChargeId(bookingId: 'bk1', chargeId: 'ch_only_bk1');

        // Assert
        final data2 =
            (await fakeFirestore.collection('booking').doc('bk2').get())
                .data()!;
        expect(data2.containsKey('chargeId'), false);
      });
    });

    // ── watchBooking ──────────────────────────────────────────────────────────
    group('watchBooking', () {
      test('emits the correct BookingDto when the document exists', () async {
        // Arrange
        await seedRaw(
          docId: 'bk1',
          userId: 'uid',
          status: 'Done',
          adultTotal: 3,
        );

        // Act
        final dto = await service.watchBooking('bk1').first;

        // Assert
        expect(dto, isNotNull);
        expect(dto!.id, 'bk1');
        expect(dto.adultTotal, 3);
        expect(dto.status, 'Done');
      });

      test('emits null when the document does not exist', () async {
        // Act
        final dto = await service.watchBooking('ghost').first;

        // Assert
        expect(dto, isNull);
      });

      test('emits updated dto after a status change', () async {
        // Arrange
        await seedRaw(docId: 'bk1', userId: 'uid', status: 'Pending');

        // Act — subscribe, skip initial emission, then update
        final stream = service.watchBooking('bk1');
        final futureDone = stream.skip(1).first;
        await service.updateStatus(bookingId: 'bk1', status: 'Done');
        final latest = await futureDone;

        // Assert
        expect(latest!.status, 'Done');
      });
    });

    // ── getPastBookings ───────────────────────────────────────────────────────
    // Replaces getBookingsByUser — filters Done status with date < today
    group('getPastBookings', () {
      test('returns Done bookings for user with past dates', () async {
        // Arrange — seed past dates (before today May 19 2026)
        await seedRaw(
          docId: 'done1',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 5, 10),
        );
        await seedRaw(
          docId: 'done2',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 5, 9),
        );

        // Act
        final bookings = await service.getPastBookings('user_1').first;

        // Assert — only Done bookings for user_1
        expect(bookings.length, 2);
        expect(bookings.every((b) => b.userId == 'user_1'), true);
      });

      test('filters out bookings belonging to other users', () async {
        // Arrange
        await seedRaw(
          docId: 'bk_user1',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 5, 10),
        );
        await seedRaw(
          docId: 'bk_user2',
          userId: 'user_2',
          status: 'Done',
          date: DateTime(2026, 5, 10),
        );

        // Act
        final bookings = await service.getPastBookings('user_1').first;

        // Assert
        expect(bookings.length, 1);
        expect(bookings.first.userId, 'user_1');
      });

      test('returns empty list when user has no bookings at all', () async {
        // Act
        final bookings = await service.getPastBookings('unknown_user').first;

        // Assert
        expect(bookings, isEmpty);
      });

      test('returns results ordered by date descending', () async {
        // Arrange — use past dates
        await seedRaw(
          docId: 'oldest',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 3, 1),
        );
        await seedRaw(
          docId: 'middle',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 5, 1),
        );

        // Act
        final bookings = await service.getPastBookings('user_1').first;

        // Assert — most recent first
        expect(bookings[0].date, DateTime(2026, 5, 1));
        expect(bookings[1].date, DateTime(2026, 3, 1));
      });

      test('throws on Firestore error', () {
        // Arrange
        final errorService = BookingRemoteDataSourceImpl(db: _ErrorFirestore());

        // Assert
        expect(
          () => errorService.getPastBookings('any'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    // ── deleteBooking ─────────────────────────────────────────────────────────
    group('deleteBooking', () {
      test('removes the target document from Firestore', () async {
        // Arrange
        await seedRaw(docId: 'to_delete', userId: 'uid');

        // Act
        await service.deleteBooking('to_delete');

        // Assert
        final doc = await fakeFirestore
            .collection('booking')
            .doc('to_delete')
            .get();
        expect(doc.exists, false);
      });

      test('does not remove sibling documents', () async {
        // Arrange
        await seedRaw(docId: 'keep', userId: 'uid');
        await seedRaw(docId: 'remove', userId: 'uid');

        // Act
        await service.deleteBooking('remove');

        // Assert
        final remaining = await fakeFirestore.collection('booking').get();
        expect(remaining.docs.length, 1);
        expect(remaining.docs.first.id, 'keep');
      });

      test('throws on Firestore error', () {
        // Arrange
        final errorService = BookingRemoteDataSourceImpl(db: _ErrorFirestore());

        // Assert
        expect(
          () => errorService.deleteBooking('any'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });
  });
}
