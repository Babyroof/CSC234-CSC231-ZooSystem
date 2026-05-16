import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/booking_pricing.dart';

class PricingService {
  final FirebaseFirestore _db;

  PricingService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

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
        'adultPrice':
            (data['adultPrice'] as num?)?.toInt() ?? BookingPricing.adultPrice,
        'childPrice':
            (data['childPrice'] as num?)?.toInt() ?? BookingPricing.kidPrice,
        'elderPrice':
            (data['elderPrice'] as num?)?.toInt() ?? BookingPricing.elderPrice,
      };
    } catch (_) {
      return {
        'adultPrice': BookingPricing.adultPrice,
        'childPrice': BookingPricing.kidPrice,
        'elderPrice': BookingPricing.elderPrice,
      };
    }
  }
}
