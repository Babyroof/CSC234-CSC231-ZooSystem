// test/features/booking/ticket/booking_data_layer_test.dart
//
// Unit tests for the booking/ticket data layer.
//
// BookingService accepts an optional FirebaseFirestore via its constructor:
//
//   BookingService({FirebaseFirestore? db})
//       : _db = db ?? FirebaseFirestore.instance;
//
// This makes full service-level testing possible without any refactoring by
// passing a FakeFirebaseFirestore instance.  All groups below use this pattern.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';
import 'package:zoopernova_zoo_system/features/booking/models/booking_model.dart';
import 'package:zoopernova_zoo_system/features/booking/services/booking_service.dart';

// ---------------------------------------------------------------------------
// _ErrorFirestore — simulates a Firestore that fails on every collection()
// call.  Used to verify that BookingService re-throws Firestore exceptions.
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

  /// Returns a fully populated BookingModel for use in model-level tests.
  BookingModel makeModel({
    String id = 'bk_test',
    String userId = 'user_abc',
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 1,
    bool buffetFood = true,
    bool guidTour = true,
    bool golfCar = true,
    String status = 'pending',
    DateTime? date,
    int? totalPrice,
    String? chargeId,
  }) => BookingModel(
    id: id,
    userId: userId,
    adultTotal: adultTotal,
    childTotal: childTotal,
    elderTotal: elderTotal,
    date: date ?? DateTime(2026, 5, 10),
    buffetFood: buffetFood,
    guidTour: guidTour,
    golfCar: golfCar,
    status: status,
    totalPrice: totalPrice,
    chargeId: chargeId,
  );

  // =========================================================================
  // Group 1 — BookingModel
  // =========================================================================
  group('BookingModel', () {
    // ── totalAmount ──────────────────────────────────────────────────────────
    group('totalAmount', () {
      test('calculates correctly with all add-ons', () {
        // Arrange
        final booking = makeModel(
          adultTotal: 2,
          childTotal: 1,
          elderTotal: 1,
          buffetFood: true,
          guidTour: true,
          golfCar: true,
        );

        // Act
        final total = booking.totalAmount;

        // Assert
        // 2*300 + 1*150 + 1*40 + 200 + 350 + 500 = 1840
        const expected =
            2 * BookingPricing.adultPrice +
            1 * BookingPricing.kidPrice +
            1 * BookingPricing.elderPrice +
            BookingPricing.buffetFoodPrice +
            BookingPricing.guidTourPrice +
            BookingPricing.golfCarPrice;
        expect(total, equals(expected)); // 1840
      });

      test('calculates correctly with no add-ons', () {
        // Arrange
        final booking = makeModel(
          adultTotal: 2,
          childTotal: 1,
          elderTotal: 0,
          buffetFood: false,
          guidTour: false,
          golfCar: false,
        );

        // Act
        final total = booking.totalAmount;

        // Assert — 2*300 + 1*150 = 750
        const expected =
            2 * BookingPricing.adultPrice + 1 * BookingPricing.kidPrice;
        expect(total, equals(expected)); // 750
      });

      test('returns 0 when all counts are 0 and no add-ons', () {
        // Arrange
        final booking = makeModel(
          adultTotal: 0,
          childTotal: 0,
          elderTotal: 0,
          buffetFood: false,
          guidTour: false,
          golfCar: false,
        );

        // Act & Assert
        expect(booking.totalAmount, equals(0));
      });

      test('each add-on contributes its correct price independently', () {
        // Arrange — one adult, buffet only
        final withBuffet = makeModel(
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          buffetFood: true,
          guidTour: false,
          golfCar: false,
        );
        // Arrange — one adult, guide only
        final withGuide = makeModel(
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          buffetFood: false,
          guidTour: true,
          golfCar: false,
        );
        // Arrange — one adult, golf car only
        final withGolfCar = makeModel(
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          buffetFood: false,
          guidTour: false,
          golfCar: true,
        );

        // Act & Assert
        expect(
          withBuffet.totalAmount,
          equals(BookingPricing.adultPrice + BookingPricing.buffetFoodPrice),
        );
        expect(
          withGuide.totalAmount,
          equals(BookingPricing.adultPrice + BookingPricing.guidTourPrice),
        );
        expect(
          withGolfCar.totalAmount,
          equals(BookingPricing.adultPrice + BookingPricing.golfCarPrice),
        );
      });

      test('uses BookingPricing constants for per-head prices', () {
        // Arrange — 3 adults, 2 children, 1 elder, no add-ons
        final booking = makeModel(
          adultTotal: 3,
          childTotal: 2,
          elderTotal: 1,
          buffetFood: false,
          guidTour: false,
          golfCar: false,
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
    });

    // ── totalPrice priority ──────────────────────────────────────────────────
    group('totalPrice field', () {
      test('takes priority over calculated totalAmount when set', () {
        // Arrange — calculated totalAmount would be 1840, but totalPrice is 9999
        // 2*300 + 1*150 + 1*40 + 200 + 350 + 500 = 600+150+40+200+350+500 = 1840
        final booking = makeModel(
          adultTotal: 2,
          childTotal: 1,
          elderTotal: 1,
          buffetFood: true,
          guidTour: true,
          golfCar: true,
          totalPrice: 9999,
        );

        // Act — consumers should prefer totalPrice ?? totalAmount
        final effective = booking.totalPrice ?? booking.totalAmount;

        // Assert
        expect(effective, equals(9999));
        // The getter itself still returns the calculated value
        expect(booking.totalAmount, equals(1840));
      });

      test('totalPrice is null when not provided', () {
        final booking = makeModel(totalPrice: null);
        expect(booking.totalPrice, isNull);
      });

      test('falls back to totalAmount when totalPrice is null', () {
        // Arrange — 1 adult, no add-ons → 300
        final booking = makeModel(
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          buffetFood: false,
          guidTour: false,
          golfCar: false,
          totalPrice: null,
        );

        // Act
        final effective = booking.totalPrice ?? booking.totalAmount;

        // Assert
        expect(effective, equals(BookingPricing.adultPrice));
      });
    });

    // ── fromMap / fromFirestore ───────────────────────────────────────────────
    group('fromFirestore', () {
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
            'BuffetFood': true,
            'GuideTour': true,
            'GolfCar': true,
            'status': 'Done',
            'totalPrice': 1540,
            'chargeId': 'ch_abc123',
          });
          final doc = await fakeFirestore
              .collection('booking')
              .doc('bk1')
              .get();

          // Act
          final model = BookingModel.fromFirestore(doc);

          // Assert
          expect(model.id, 'bk1');
          expect(model.userId, 'user_abc');
          expect(model.adultTotal, 2);
          expect(model.childTotal, 1);
          expect(model.elderTotal, 1);
          expect(model.date, DateTime(2026, 5, 10));
          expect(model.buffetFood, true);
          expect(model.guidTour, true);
          expect(model.golfCar, true);
          expect(model.status, 'Done');
          expect(model.totalPrice, 1540);
          expect(model.chargeId, 'ch_abc123');
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
          'BuffetFood': false,
          'GuideTour': false,
          'GolfCar': false,
          'status': 'Pending',
        });
        final doc = await fakeFirestore.collection('booking').doc('bk2').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.userId, 'plainStringUid');
      });

      test('falls back to epoch when date field is absent', () async {
        // Arrange — no 'date' field
        await fakeFirestore.collection('booking').doc('bk3').set({
          'userId': 'uid',
          'adultTotal': 0,
          'childTotal': 0,
          'elderTotal': 0,
          'BuffetFood': false,
          'GuideTour': false,
          'GolfCar': false,
          'status': 'pending',
        });
        final doc = await fakeFirestore.collection('booking').doc('bk3').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('numeric fields default to 0 when absent', () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk4').set({
          'userId': 'uid',
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'BuffetFood': false,
          'GuideTour': false,
          'GolfCar': false,
          'status': 'pending',
          // adultTotal, childTotal, elderTotal intentionally omitted
        });
        final doc = await fakeFirestore.collection('booking').doc('bk4').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.adultTotal, 0);
        expect(model.childTotal, 0);
        expect(model.elderTotal, 0);
      });

      test('boolean fields default to false when absent', () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk5').set({
          'userId': 'uid',
          'adultTotal': 1,
          'childTotal': 0,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'status': 'pending',
          // BuffetFood, GuideTour, GolfCar intentionally omitted
        });
        final doc = await fakeFirestore.collection('booking').doc('bk5').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.buffetFood, false);
        expect(model.guidTour, false);
        expect(model.golfCar, false);
      });

      test('chargeId and totalPrice are null when absent', () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk6').set({
          'userId': 'uid',
          'adultTotal': 1,
          'childTotal': 0,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'BuffetFood': false,
          'GuideTour': false,
          'GolfCar': false,
          'status': 'pending',
        });
        final doc = await fakeFirestore.collection('booking').doc('bk6').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.chargeId, isNull);
        expect(model.totalPrice, isNull);
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────
    group('toMap', () {
      test('all boolean fields are bool, not String', () {
        // Arrange
        final model = makeModel(
          buffetFood: true,
          guidTour: false,
          golfCar: true,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['BuffetFood'], isA<bool>());
        expect(map['GuideTour'], isA<bool>());
        expect(map['GolfCar'], isA<bool>());
      });

      test('all numeric fields are int, not String', () {
        // Arrange
        final model = makeModel(adultTotal: 3, childTotal: 2, elderTotal: 1);

        // Act
        final map = model.toMap();

        // Assert
        expect(map['adultTotal'], isA<int>());
        expect(map['childTotal'], isA<int>());
        expect(map['elderTotal'], isA<int>());
      });

      test('date field is Timestamp, not String', () {
        // Arrange
        final model = makeModel(date: DateTime(2026, 5, 10));

        // Act
        final map = model.toMap();

        // Assert
        expect(map['date'], isA<Timestamp>());
        expect(map['date'], Timestamp.fromDate(DateTime(2026, 5, 10)));
      });

      test(
        'userId in toMap is a plain String (service converts to DocumentReference before write)',
        () {
          // Arrange
          final model = makeModel(userId: 'user_xyz');

          // Act
          final map = model.toMap();

          // Assert — model layer stays Firestore-agnostic
          expect(map['userId'], isA<String>());
          expect(map['userId'], 'user_xyz');
        },
      );

      test('boolean values match the model fields', () {
        // Arrange
        final model = makeModel(
          buffetFood: true,
          guidTour: false,
          golfCar: true,
        );

        // Act
        final map = model.toMap();

        // Assert
        expect(map['BuffetFood'], true);
        expect(map['GuideTour'], false);
        expect(map['GolfCar'], true);
      });

      test('chargeId is omitted from map when null', () {
        final map = makeModel(chargeId: null).toMap();
        expect(map.containsKey('chargeId'), false);
      });

      test('chargeId is included when not null', () {
        final map = makeModel(chargeId: 'ch_xyz').toMap();
        expect(map['chargeId'], 'ch_xyz');
      });

      test('totalPrice is omitted from map when null', () {
        final map = makeModel(totalPrice: null).toMap();
        expect(map.containsKey('totalPrice'), false);
      });

      test('totalPrice is included when set', () {
        final map = makeModel(totalPrice: 999).toMap();
        expect(map['totalPrice'], 999);
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────────────
    group('copyWith', () {
      test('updates only specified fields, leaves others unchanged', () {
        // Arrange
        final original = makeModel();

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
        expect(updated.buffetFood, original.buffetFood);
        expect(updated.guidTour, original.guidTour);
        expect(updated.golfCar, original.golfCar);
        expect(updated.date, original.date);
      });

      test('returns equivalent model when no fields are overridden', () {
        // Arrange
        final original = makeModel();

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.adultTotal, original.adultTotal);
        expect(copy.childTotal, original.childTotal);
        expect(copy.elderTotal, original.elderTotal);
        expect(copy.buffetFood, original.buffetFood);
        expect(copy.guidTour, original.guidTour);
        expect(copy.golfCar, original.golfCar);
        expect(copy.date, original.date);
        expect(copy.status, original.status);
        expect(copy.chargeId, original.chargeId);
        expect(copy.totalPrice, original.totalPrice);
      });

      test('copyWith does not mutate the original model', () {
        // Arrange
        final original = makeModel(adultTotal: 2);

        // Act
        original.copyWith(adultTotal: 99);

        // Assert — original is unchanged
        expect(original.adultTotal, 2);
      });
    });
  });

  // =========================================================================
  // Group 2 — BookingService
  //
  // BookingService accepts an optional FirebaseFirestore in its constructor:
  //
  //   BookingService({FirebaseFirestore? db})
  //       : _db = db ?? FirebaseFirestore.instance;
  //
  // FakeFirebaseFirestore is injected directly — no source changes needed.
  // =========================================================================
  group('BookingService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BookingService service;

    // Shared seed helper — writes a raw booking document into the fake store
    Future<void> seedRaw({
      required String docId,
      required String userId,
      String status = 'Done',
      bool buffetFood = false,
      bool guidTour = false,
      bool golfCar = false,
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
        'BuffetFood': buffetFood,
        'GuideTour': guidTour,
        'GolfCar': golfCar,
      });
    }

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = BookingService(db: fakeFirestore);
    });

    // ── createBooking ─────────────────────────────────────────────────────────
    group('createBooking', () {
      test('writes a new document to the booking collection', () async {
        // Arrange
        final booking = makeModel(userId: 'user_abc');

        // Act
        await service.createBooking(booking);

        // Assert
        final snap = await fakeFirestore.collection('booking').get();
        expect(snap.docs.length, 1);
      });

      test('forces status to pending regardless of model status', () async {
        // Arrange — model has status 'Done'
        final booking = makeModel(status: 'Done');

        // Act
        await service.createBooking(booking);

        // Assert — service always writes lowercase 'pending' (per schema)
        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        expect(data['status'], 'pending');
      });

      test('stores totalPrice as the calculated totalAmount', () async {
        // Arrange — 2 adults + buffet (300*2 + 200 = 800)
        final booking = makeModel(
          adultTotal: 2,
          childTotal: 0,
          elderTotal: 0,
          buffetFood: true,
          guidTour: false,
          golfCar: false,
        );

        // Act
        await service.createBooking(booking);

        // Assert
        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        expect(
          data['totalPrice'],
          equals(
            2 * BookingPricing.adultPrice + BookingPricing.buffetFoodPrice,
          ),
        );
      });

      test(
        'stores userId as a DocumentReference pointing to /user/{uid}',
        () async {
          // Arrange
          final booking = makeModel(userId: 'user_abc');

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

      test('boolean add-on fields are stored as bool, not String', () async {
        // Arrange
        final booking = makeModel(
          buffetFood: true,
          guidTour: false,
          golfCar: true,
        );

        // Act
        await service.createBooking(booking);

        // Assert
        final data = (await fakeFirestore.collection('booking').get())
            .docs
            .first
            .data();
        expect(data['BuffetFood'], isA<bool>());
        expect(data['GuideTour'], isA<bool>());
        expect(data['GolfCar'], isA<bool>());
      });

      test('date field is stored as Timestamp, not String', () async {
        // Arrange
        final booking = makeModel(date: DateTime(2026, 5, 10));

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
        final booking = makeModel();

        // Act
        final id = await service.createBooking(booking);

        // Assert
        expect(id, isA<String>());
        expect(id, isNotEmpty);
      });

      test('throws on Firestore error', () {
        final errorService = BookingService(db: _ErrorFirestore());
        expect(
          () => errorService.createBooking(makeModel()),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    // ── getBookingById ────────────────────────────────────────────────────────
    group('getBookingById', () {
      test('returns correct BookingModel for an existing document', () async {
        // Arrange
        await seedRaw(
          docId: 'bk1',
          userId: 'user_abc',
          status: 'Done',
          adultTotal: 2,
          childTotal: 1,
          elderTotal: 0,
          buffetFood: true,
          guidTour: true,
          golfCar: false,
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
        expect(result.buffetFood, true);
        expect(result.guidTour, true);
        expect(result.golfCar, false);
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
        final errorService = BookingService(db: _ErrorFirestore());
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
        // Other fields untouched
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
      test('emits the correct BookingModel when the document exists', () async {
        // Arrange
        await seedRaw(
          docId: 'bk1',
          userId: 'uid',
          status: 'Done',
          adultTotal: 3,
        );

        // Act
        final model = await service.watchBooking('bk1').first;

        // Assert
        expect(model, isNotNull);
        expect(model!.id, 'bk1');
        expect(model.adultTotal, 3);
        expect(model.status, 'Done');
      });

      test('emits null when the document does not exist', () async {
        // Act
        final model = await service.watchBooking('ghost').first;

        // Assert
        expect(model, isNull);
      });

      test('emits updated model after a status change', () async {
        // Arrange
        await seedRaw(docId: 'bk1', userId: 'uid', status: 'Pending');

        // Act — subscribe, skip the initial Pending emission, then update
        // skip(1) discards the first snapshot (Pending) so we receive the
        // next one emitted after the write (Done).
        final stream = service.watchBooking('bk1');
        final futureDone = stream.skip(1).first;
        await service.updateStatus(bookingId: 'bk1', status: 'Done');
        final latest = await futureDone;

        // Assert
        expect(latest!.status, 'Done');
      });
    });

    // ── getBookingsByUser ─────────────────────────────────────────────────────
    group('getBookingsByUser', () {
      test('returns all bookings for user regardless of status', () async {
        // Arrange — mix of Done and Pending bookings for user_1
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
        await seedRaw(
          docId: 'pending1',
          userId: 'user_1',
          status: 'Pending',
          date: DateTime(2026, 5, 8),
        );

        // Act
        final bookings = await service.getBookingsByUser('user_1').first;

        // Assert — all 3 bookings returned regardless of status
        expect(bookings.length, 3);
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
        final bookings = await service.getBookingsByUser('user_1').first;

        // Assert
        expect(bookings.length, 1);
        expect(bookings.first.userId, 'user_1');
      });

      test(
        'returns pending bookings for user (no status filter applied)',
        () async {
          // Arrange — seeded booking has Pending status
          await seedRaw(
            docId: 'pending1',
            userId: 'user_1',
            status: 'Pending',
            date: DateTime(2026, 5, 10),
          );

          // Act
          final bookings = await service.getBookingsByUser('user_1').first;

          // Assert — getBookingsByUser returns all bookings regardless of status
          expect(bookings.length, 1);
        },
      );

      test('returns empty list when user has no bookings at all', () async {
        // Act
        final bookings = await service.getBookingsByUser('unknown_user').first;

        // Assert
        expect(bookings, isEmpty);
      });

      test('returns results ordered by date descending', () async {
        // Arrange
        await seedRaw(
          docId: 'oldest',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 3, 1),
        );
        await seedRaw(
          docId: 'newest',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 7, 1),
        );
        await seedRaw(
          docId: 'middle',
          userId: 'user_1',
          status: 'Done',
          date: DateTime(2026, 5, 1),
        );

        // Act
        final bookings = await service.getBookingsByUser('user_1').first;

        // Assert — newest first
        expect(bookings[0].date, DateTime(2026, 7, 1));
        expect(bookings[1].date, DateTime(2026, 5, 1));
        expect(bookings[2].date, DateTime(2026, 3, 1));
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
        final errorService = BookingService(db: _ErrorFirestore());
        expect(
          () => errorService.deleteBooking('any'),
          throwsA(isA<FirebaseException>()),
        );
      });
    });
  });
}
