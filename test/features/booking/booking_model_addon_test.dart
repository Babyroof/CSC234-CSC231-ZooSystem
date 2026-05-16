import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';
import 'package:zoopernova_zoo_system/features/booking/models/booking_model.dart';
import 'package:zoopernova_zoo_system/features/booking/models/selected_add_on_model.dart';

void main() {
  // Helper — builds a BookingModel with explicit unit prices so tests are
  // independent of the BookingPricing defaults.
  BookingModel makeModel({
    String id = 'bk1',
    String userId = 'user1',
    int adultTotal = 0,
    int childTotal = 0,
    int elderTotal = 0,
    int adultUnitPrice = 300,
    int childUnitPrice = 150,
    int elderUnitPrice = 40,
    List<SelectedAddOnModel> selectedAddOns = const [],
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
    adultUnitPrice: adultUnitPrice,
    childUnitPrice: childUnitPrice,
    elderUnitPrice: elderUnitPrice,
    selectedAddOns: selectedAddOns,
    status: status,
    date: date ?? DateTime(2026, 5, 10),
    totalPrice: totalPrice,
    chargeId: chargeId,
  );

  // ===========================================================================
  // totalAmount
  // ===========================================================================
  group('BookingModel.totalAmount', () {
    test(
      'is correct with per_booking addon — addon price added once regardless of people count',
      () {
        // Arrange — 2 adults + 1 per_booking addon of 200
        final booking = makeModel(
          adultTotal: 2,
          selectedAddOns: const [
            SelectedAddOnModel(
              addOnId: 'ao1',
              name: 'Buffet',
              price: 200,
              priceType: 'per_booking',
            ),
          ],
        );

        // Act
        final total = booking.totalAmount;

        // Assert — totalAmount adds a.price directly (not calculatePrice)
        // 2*300 + 200 = 800
        expect(total, equals(2 * 300 + 200));
      },
    );

    test('is correct with per_person addon — addon price * total people', () {
      // Arrange — 3 adults + 1 per_person addon of 80
      // NOTE: BookingModel.totalAmount uses a.price directly via fold, NOT
      // calculatePrice(). So for per_person addons the price stored in
      // SelectedAddOnModel must already be the per-head price, and the
      // screen/service pre-multiplies it before saving. The fold just sums
      // all a.price values regardless of priceType.
      // This test verifies the actual getter behaviour.
      final booking = makeModel(
        adultTotal: 3,
        selectedAddOns: const [
          SelectedAddOnModel(
            addOnId: 'ao2',
            name: 'Snack',
            price: 240, // 80 * 3 already multiplied before saving
            priceType: 'per_person',
          ),
        ],
      );

      // Act
      final total = booking.totalAmount;

      // Assert — 3*300 + 240 = 1140
      expect(total, equals(3 * 300 + 240));
    });

    test('is correct with mixed addons — one per_booking and one per_person', () {
      // Arrange — 2 adults, addon1=200 (per_booking), addon2=160 (per_person, already multiplied)
      final booking = makeModel(
        adultTotal: 2,
        selectedAddOns: const [
          SelectedAddOnModel(
            addOnId: 'ao1',
            name: 'Buffet',
            price: 200,
            priceType: 'per_booking',
          ),
          SelectedAddOnModel(
            addOnId: 'ao2',
            name: 'Snack',
            price: 160, // 80 * 2
            priceType: 'per_person',
          ),
        ],
      );

      // Act
      final total = booking.totalAmount;

      // Assert — 2*300 + 200 + 160 = 960
      expect(total, equals(2 * 300 + 200 + 160));
    });

    test('ticket-only total with no selectedAddOns', () {
      // Arrange
      final booking = makeModel(adultTotal: 1, childTotal: 1, elderTotal: 1);

      // Act
      final total = booking.totalAmount;

      // Assert — 1*300 + 1*150 + 1*40 = 490
      expect(total, equals(300 + 150 + 40));
    });

    test('uses adultUnitPrice, childUnitPrice, elderUnitPrice fields', () {
      // Arrange — custom unit prices
      final booking = makeModel(
        adultTotal: 1,
        childTotal: 1,
        elderTotal: 1,
        adultUnitPrice: 500,
        childUnitPrice: 250,
        elderUnitPrice: 100,
      );

      // Act
      final total = booking.totalAmount;

      // Assert — 500 + 250 + 100 = 850
      expect(total, equals(850));
    });

    test(
      'defaults use BookingPricing constants when unit prices are omitted',
      () {
        // Arrange — no explicit unit prices → defaults
        final booking = BookingModel(
          id: 'bk1',
          userId: 'u1',
          adultTotal: 1,
          childTotal: 1,
          elderTotal: 1,
          date: DateTime(2026, 5, 10),
          status: 'pending',
        );

        // Act
        final total = booking.totalAmount;

        // Assert
        expect(
          total,
          equals(
            BookingPricing.adultPrice +
                BookingPricing.kidPrice +
                BookingPricing.elderPrice,
          ),
        );
      },
    );
  });

  // ===========================================================================
  // fromFirestore — selectedAddOns deserialization
  // ===========================================================================
  group('BookingModel.fromFirestore with selectedAddOns', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    test(
      'deserializes selectedAddOns array into List<SelectedAddOnModel>',
      () async {
        // Arrange
        final userRef = fakeDb.collection('user').doc('user1');
        await fakeDb.collection('booking').doc('bk1').set({
          'userId': userRef,
          'adultTotal': 2,
          'childTotal': 0,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
          'status': 'pending',
          'selectedAddOns': [
            {
              'addOnId': 'ao1',
              'name': 'Buffet',
              'price': 200,
              'priceType': 'per_booking',
            },
            {
              'addOnId': 'ao2',
              'name': 'Golf Car',
              'price': 500,
              'priceType': 'per_booking',
            },
          ],
        });
        final doc = await fakeDb.collection('booking').doc('bk1').get();

        // Act
        final model = BookingModel.fromFirestore(doc);

        // Assert
        expect(model.selectedAddOns.length, 2);
        expect(model.selectedAddOns[0].addOnId, 'ao1');
        expect(model.selectedAddOns[0].name, 'Buffet');
        expect(model.selectedAddOns[0].price, 200);
        expect(model.selectedAddOns[1].addOnId, 'ao2');
        expect(model.selectedAddOns[1].name, 'Golf Car');
      },
    );

    test('selectedAddOns is empty list when field is absent', () async {
      // Arrange
      await fakeDb.collection('booking').doc('bk2').set({
        'userId': 'uid',
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
        'status': 'pending',
        // selectedAddOns intentionally omitted
      });
      final doc = await fakeDb.collection('booking').doc('bk2').get();

      // Act
      final model = BookingModel.fromFirestore(doc);

      // Assert
      expect(model.selectedAddOns, isEmpty);
    });
  });

  // ===========================================================================
  // toMap — selectedAddOns serialization
  // ===========================================================================
  group('BookingModel.toMap with selectedAddOns', () {
    test('serializes selectedAddOns as list of maps', () {
      // Arrange
      final booking = makeModel(
        selectedAddOns: const [
          SelectedAddOnModel(
            addOnId: 'ao1',
            name: 'Buffet',
            price: 200,
            priceType: 'per_booking',
          ),
        ],
      );

      // Act
      final map = booking.toMap();

      // Assert
      final addOns = map['selectedAddOns'] as List;
      expect(addOns.length, 1);
      final addOnMap = addOns.first as Map<String, dynamic>;
      expect(addOnMap['addOnId'], 'ao1');
      expect(addOnMap['name'], 'Buffet');
      expect(addOnMap['price'], 200);
      expect(addOnMap['priceType'], 'per_booking');
    });

    test('does NOT contain keys buffetFood, golfCar, or guidTour', () {
      // Arrange
      final booking = makeModel();

      // Act
      final map = booking.toMap();

      // Assert — legacy boolean fields must not exist
      expect(map.containsKey('buffetFood'), false);
      expect(map.containsKey('golfCar'), false);
      expect(map.containsKey('guidTour'), false);
    });

    test('serializes empty selectedAddOns as empty list', () {
      // Arrange
      final booking = makeModel(selectedAddOns: const []);

      // Act
      final map = booking.toMap();

      // Assert
      final addOns = map['selectedAddOns'] as List;
      expect(addOns, isEmpty);
    });
  });
}
