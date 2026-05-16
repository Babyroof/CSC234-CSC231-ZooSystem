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
    bool isActive = true,
  }) async {
    try {
      final snap = await _db
          .collection('addOns')
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      final maxOrder = snap.docs.isEmpty
          ? 0
          : (snap.docs.first.data()['order'] as num).toInt();
      await _db.collection('addOns').add({
        'name': name,
        'price': price,
        'priceType': priceType,
        'order': maxOrder + 1,
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('[AddOnAdminService] createAddOn error: $e');
      rethrow;
    }
  }

  Future<void> reorderAddOn(
    String id,
    int currentOrder, {
    required String direction,
  }) async {
    try {
      final snap =
          await _db.collection('addOns').orderBy('order').get();
      final docs = snap.docs;
      final index = docs.indexWhere((d) => d.id == id);
      if (index == -1) return;

      final adjacentIndex = direction == 'up' ? index - 1 : index + 1;
      if (adjacentIndex < 0 || adjacentIndex >= docs.length) return;

      final orderA = (docs[index].data()['order'] as num).toInt();
      final orderB = (docs[adjacentIndex].data()['order'] as num).toInt();

      final batch = _db.batch();
      batch.update(docs[index].reference, {'order': orderB});
      batch.update(docs[adjacentIndex].reference, {'order': orderA});
      await batch.commit();
    } catch (e) {
      debugPrint('[AddOnAdminService] reorderAddOn error: $e');
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
