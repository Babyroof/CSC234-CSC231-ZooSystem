import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:zoopernova_zoo_system/features/booking/models/add_on_model.dart';

class AddOnAdminService {
  final FirebaseFirestore _db;
  AddOnAdminService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<AddOnModel>> getAddOns() {
    return _db
        .collection('addOns')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AddOnModel.fromFirestore).toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        })
        .handleError((Object e) {
          debugPrint('[AddOnAdminService] stream error: $e');
          throw e;
        });
  }

  Future<void> createAddOn({
    required String name,
    required int price,
    required String priceType,
    required int order,
    bool isActive = true,
  }) async {
    try {
      await _db.collection('addOns').add({
        'name': name,
        'price': price,
        'priceType': priceType,
        'order': order,
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('[AddOnAdminService] createAddOn error: $e');
      rethrow;
    }
  }

  Future<void> updateAddOn({
    required String id,
    required String name,
    required int price,
    required String priceType,
    required int order,
    required bool isActive,
  }) async {
    try {
      await _db.collection('addOns').doc(id).update({
        'name': name,
        'price': price,
        'priceType': priceType,
        'order': order,
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('[AddOnAdminService] updateAddOn error: $e');
      rethrow;
    }
  }

  Future<void> deleteAddOn(String id) async {
    try {
      await _db.collection('addOns').doc(id).delete();
    } catch (e) {
      debugPrint('[AddOnAdminService] deleteAddOn error: $e');
      rethrow;
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _db.collection('addOns').doc(id).update({'isActive': isActive});
    } catch (e) {
      debugPrint('[AddOnAdminService] toggleActive error: $e');
      rethrow;
    }
  }
}
