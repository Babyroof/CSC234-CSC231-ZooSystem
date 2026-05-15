import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/add_on_model.dart';

class AddOnService {
  final FirebaseFirestore _db;

  AddOnService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<AddOnModel>> getActiveAddOns() {
    return _db
        .collection('addOns')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AddOnModel.fromFirestore).toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        })
        .handleError((Object e) {
          debugPrint('[AddOnService] stream error: $e');
          throw e;
        });
  }
}
