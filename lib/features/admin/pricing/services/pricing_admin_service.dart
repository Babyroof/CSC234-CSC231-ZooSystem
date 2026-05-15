import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:zoopernova_zoo_system/features/booking/constants/booking_pricing.dart';

class PricingAdminService {
  final FirebaseFirestore _db;
  PricingAdminService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<Map<String, int>> getPricing() async {
    try {
      final doc = await _db.collection('config').doc('pricing').get();
      if (!doc.exists) {
        return {
          'adultPrice': BookingPricing.adultPrice,
          'childPrice': BookingPricing.kidPrice,
          'elderPrice': BookingPricing.elderPrice,
        };
      }
      final data = doc.data()!;
      return {
        'adultPrice': (data['adultPrice'] as num?)?.toInt() ?? BookingPricing.adultPrice,
        'childPrice': (data['childPrice'] as num?)?.toInt() ?? BookingPricing.kidPrice,
        'elderPrice': (data['elderPrice'] as num?)?.toInt() ?? BookingPricing.elderPrice,
      };
    } catch (e) {
      debugPrint('[PricingAdminService] getPricing error: $e');
      rethrow;
    }
  }

  Future<void> updatePricing({
    required int adultPrice,
    required int childPrice,
    required int elderPrice,
  }) async {
    try {
      await _db.collection('config').doc('pricing').set(
        {'adultPrice': adultPrice, 'childPrice': childPrice, 'elderPrice': elderPrice},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[PricingAdminService] updatePricing error: $e');
      rethrow;
    }
  }
}
