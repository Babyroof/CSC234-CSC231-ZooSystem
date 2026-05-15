import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';
import 'package:zoopernova_zoo_system/features/booking/services/pricing_service.dart';

void main() {
  group('PricingService', () {
    test('returns correct adultPrice, childPrice, elderPrice from config/pricing doc', () async {
      // Arrange
      final fakeDb = FakeFirebaseFirestore();
      await fakeDb.collection('config').doc('pricing').set({
        'adultPrice': 400,
        'childPrice': 200,
        'elderPrice': 60,
      });

      // Act
      final pricing = await PricingService(db: fakeDb).getPricing();

      // Assert
      expect(pricing['adultPrice'], 400);
      expect(pricing['childPrice'], 200);
      expect(pricing['elderPrice'], 60);
    });

    test('returns fallback BookingPricing constants when doc is missing', () async {
      // Arrange — empty Firestore, no config/pricing document
      final fakeDb = FakeFirebaseFirestore();

      // Act
      final pricing = await PricingService(db: fakeDb).getPricing();

      // Assert
      expect(pricing['adultPrice'], BookingPricing.adultPrice);
      expect(pricing['childPrice'], BookingPricing.kidPrice);
      expect(pricing['elderPrice'], BookingPricing.elderPrice);
    });

    test('falls back to BookingPricing constant for individual missing fields', () async {
      // Arrange — doc exists but only has adultPrice
      final fakeDb = FakeFirebaseFirestore();
      await fakeDb.collection('config').doc('pricing').set({
        'adultPrice': 500,
        // childPrice and elderPrice intentionally omitted
      });

      // Act
      final pricing = await PricingService(db: fakeDb).getPricing();

      // Assert
      expect(pricing['adultPrice'], 500);
      expect(pricing['childPrice'], BookingPricing.kidPrice);
      expect(pricing['elderPrice'], BookingPricing.elderPrice);
    });
  });
}
