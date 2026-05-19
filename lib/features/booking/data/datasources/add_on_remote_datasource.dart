import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/add_on_dto.dart';

abstract class AddOnRemoteDataSource {
  Stream<List<AddOnDto>> getActiveAddOns();
}

class AddOnRemoteDataSourceImpl implements AddOnRemoteDataSource {
  AddOnRemoteDataSourceImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<AddOnDto>> getActiveAddOns() {
    return _db
        .collection('addOns')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AddOnDto.fromFirestore).toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        })
        .handleError((Object e) {
          debugPrint('[AddOnDataSource] getActiveAddOns error: $e');
          throw e;
        });
  }
}
