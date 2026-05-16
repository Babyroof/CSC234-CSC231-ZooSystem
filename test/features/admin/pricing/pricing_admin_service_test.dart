import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/pricing/services/pricing_admin_service.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late PricingAdminService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = PricingAdminService(db: fakeDb);
  });

  // ── getPricing ────────────────────────────────────────────────────────────
  group('getPricing', () {
    test(
      'returns adultPrice, childPrice, elderPrice from config/pricing doc',
      () async {
        // Arrange
        await fakeDb.collection('config').doc('pricing').set({
          'adultPrice': 400,
          'childPrice': 200,
          'elderPrice': 60,
        });

        // Act
        final pricing = await service.getPricing();

        // Assert
        expect(pricing['adultPrice'], 400);
        expect(pricing['childPrice'], 200);
        expect(pricing['elderPrice'], 60);
      },
    );

    test(
      'returns BookingPricing fallback values when config/pricing doc does not exist',
      () async {
        // Arrange — empty Firestore; no config/pricing document

        // Act
        final pricing = await service.getPricing();

        // Assert
        expect(pricing['adultPrice'], BookingPricing.adultPrice);
        expect(pricing['childPrice'], BookingPricing.kidPrice);
        expect(pricing['elderPrice'], BookingPricing.elderPrice);
      },
    );

    test(
      'returns BookingPricing fallback for individual field if field is missing from doc',
      () async {
        // Arrange — doc exists but childPrice and elderPrice are absent
        await fakeDb.collection('config').doc('pricing').set({
          'adultPrice': 500,
          // childPrice intentionally omitted
          // elderPrice intentionally omitted
        });

        // Act
        final pricing = await service.getPricing();

        // Assert — present field uses doc value; missing fields fall back to constants
        expect(pricing['adultPrice'], 500);
        expect(pricing['childPrice'], BookingPricing.kidPrice);
        expect(pricing['elderPrice'], BookingPricing.elderPrice);
      },
    );
  });

  // ── updatePricing ─────────────────────────────────────────────────────────
  group('updatePricing', () {
    test(
      'writes adultPrice, childPrice, elderPrice to config/pricing',
      () async {
        // Arrange — fresh fakeDb (done in setUp)

        // Act
        await service.updatePricing(
          adultPrice: 350,
          childPrice: 180,
          elderPrice: 80,
        );

        // Assert
        final data = (await fakeDb.collection('config').doc('pricing').get())
            .data()!;
        expect(data['adultPrice'], 350);
        expect(data['childPrice'], 180);
        expect(data['elderPrice'], 80);
      },
    );

    test('values are readable back after write', () async {
      // Arrange — write some initial values first
      await service.updatePricing(
        adultPrice: 300,
        childPrice: 150,
        elderPrice: 40,
      );

      // Act — overwrite with new values
      await service.updatePricing(
        adultPrice: 600,
        childPrice: 300,
        elderPrice: 120,
      );

      // Assert — latest values are stored
      final pricing = await service.getPricing();
      expect(pricing['adultPrice'], 600);
      expect(pricing['childPrice'], 300);
      expect(pricing['elderPrice'], 120);
    });

    test(
      'updatePricing uses merge so a pre-existing unrelated field survives',
      () async {
        // Arrange — pre-seed config/pricing with an extra field
        await fakeDb.collection('config').doc('pricing').set({
          'someOtherField': 'keep me',
          'adultPrice': 100,
          'childPrice': 50,
          'elderPrice': 40,
        });

        // Act
        await service.updatePricing(
          adultPrice: 350,
          childPrice: 180,
          elderPrice: 80,
        );

        // Assert — pricing fields are updated
        final data = (await fakeDb.collection('config').doc('pricing').get())
            .data()!;
        expect(data['adultPrice'], 350);
        expect(data['childPrice'], 180);
        expect(data['elderPrice'], 80);

        // Assert — unrelated field is still present (merge, not overwrite)
        expect(data['someOtherField'], 'keep me');
      },
    );
  });
}
