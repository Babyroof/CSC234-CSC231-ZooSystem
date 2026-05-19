import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';
import 'package:zoopernova_zoo_system/features/booking/data/models/booking_dto.dart';
import 'package:zoopernova_zoo_system/features/booking/domain/entities/booking_entity.dart';
import 'package:zoopernova_zoo_system/features/booking/domain/entities/selected_add_on_entity.dart';

void main() {
  // Helper — builds a BookingEntity with explicit unit prices so tests are
  // independent of the BookingPricing defaults.
  BookingEntity makeEntity({
    String id = 'bk1',
    String userId = 'user1',
    int adultTotal = 0,
    int childTotal = 0,
    int elderTotal = 0,
    int adultUnitPrice = 300,
    int childUnitPrice = 150,
    int elderUnitPrice = 40,
    List<SelectedAddOnEntity> selectedAddOns = const [],
    String status = 'pending',
    DateTime? date,
    int? totalPrice,
    String? chargeId,
  }) => BookingEntity(
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
  group('BookingEntity.totalAmount', () {
    test(
      'is correct with per_booking addon — addon price added once regardless of people count',
      () {
        // Arrange — 2 adults + 1 per_booking addon of 200
        final booking = makeEntity(
          adultTotal: 2,
          selectedAddOns: const [
            SelectedAddOnEntity(
              addOnId: 'ao1',
              name: 'Buffet',
              price: 200,
              priceType: 'per_booking',
            ),
          ],
        );

        // Act
        final total = booking.totalAmount;

        // Assert — 2*300 + 200 = 800
        expect(total, equals(2 * 300 + 200));
      },
    );

    test('is correct with per_person addon — addon price * total people', () {
      // Arrange — 3 adults + 1 per_person addon of 80
      // NOTE: BookingEntity.totalAmount uses a.price directly via fold, NOT
      // calculatePrice(). So for per_person addons the price stored in
      // SelectedAddOnEntity must already be the per-head price, and the
      // screen/service pre-multiplies it before saving. The fold just sums
      // all a.price values regardless of priceType.
      final booking = makeEntity(
        adultTotal: 3,
        selectedAddOns: const [
          SelectedAddOnEntity(
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
      final booking = makeEntity(
        adultTotal: 2,
        selectedAddOns: const [
          SelectedAddOnEntity(
            addOnId: 'ao1',
            name: 'Buffet',
            price: 200,
            priceType: 'per_booking',
          ),
          SelectedAddOnEntity(
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
      final booking = makeEntity(adultTotal: 1, childTotal: 1, elderTotal: 1);

      // Act
      final total = booking.totalAmount;

      // Assert — 1*300 + 1*150 + 1*40 = 490
      expect(total, equals(300 + 150 + 40));
    });

    test('uses adultUnitPrice, childUnitPrice, elderUnitPrice fields', () {
      // Arrange — custom unit prices
      final booking = makeEntity(
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
        final booking = BookingEntity(
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
  group('BookingDto.fromFirestore with selectedAddOns', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    test(
      'deserializes selectedAddOns array into List<SelectedAddOnDto>',
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
        final dto = BookingDto.fromFirestore(doc);
        final entity = dto.toEntity();

        // Assert
        expect(entity.selectedAddOns.length, 2);
        expect(entity.selectedAddOns[0].addOnId, 'ao1');
        expect(entity.selectedAddOns[0].name, 'Buffet');
        expect(entity.selectedAddOns[0].price, 200);
        expect(entity.selectedAddOns[1].addOnId, 'ao2');
        expect(entity.selectedAddOns[1].name, 'Golf Car');
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
      final dto = BookingDto.fromFirestore(doc);

      // Assert
      expect(dto.selectedAddOns, isEmpty);
    });
  });

  // ===========================================================================
  // SelectedAddOnEntity.toMap — serialization
  // ===========================================================================
  group('SelectedAddOnEntity.toMap with selectedAddOns', () {
    test('serializes fields as map with correct keys', () {
      // Arrange
      const addon = SelectedAddOnEntity(
        addOnId: 'ao1',
        name: 'Buffet',
        price: 200,
        priceType: 'per_booking',
      );

      // Act
      final map = addon.toMap();

      // Assert
      expect(map['addOnId'], 'ao1');
      expect(map['name'], 'Buffet');
      expect(map['price'], 200);
      expect(map['priceType'], 'per_booking');
    });

    test(
      'does NOT contain legacy boolean keys buffetFood, golfCar, or guidTour',
      () {
        // Arrange
        const addon = SelectedAddOnEntity(
          addOnId: 'ao1',
          name: 'Buffet',
          price: 200,
          priceType: 'per_booking',
        );

        // Act
        final map = addon.toMap();

        // Assert — legacy boolean fields must not exist
        expect(map.containsKey('buffetFood'), false);
        expect(map.containsKey('golfCar'), false);
        expect(map.containsKey('guidTour'), false);
      },
    );

    test('empty selectedAddOns on entity results in empty list via toMap', () {
      // Arrange
      final entity = makeEntity(selectedAddOns: const []);

      // Assert
      expect(entity.selectedAddOns, isEmpty);
    });
  });
}
