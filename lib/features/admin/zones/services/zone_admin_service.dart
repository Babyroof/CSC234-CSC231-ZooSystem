import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zone_admin_model.dart';

class ZoneAdminService {
  final FirebaseFirestore _db;

  ZoneAdminService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  /// Returns a real-time stream of all zones from Firestore.
  Stream<List<ZoneAdminModel>> getZones() {
    return _db
        .collection('zone')
        .snapshots()
        .map((snap) => snap.docs.map(ZoneAdminModel.fromFirestore).toList())
        .handleError((Object e) {
          debugPrint('[ZoneAdminService] getZones stream error: $e');
          throw e;
        });
  }

  Future<void> addZone(String zoneName) async {
    try {
      await _db.collection('zone').add({'zoneName': zoneName});
      debugPrint('[ZoneAdminService] addZone: $zoneName added');
    } catch (e) {
      debugPrint('[ZoneAdminService] addZone error: $e');
      rethrow;
    }
  }

  Future<void> updateZone(String id, String zoneName) async {
    try {
      await _db.collection('zone').doc(id).set({'zoneName': zoneName}, SetOptions(merge: true));
      debugPrint('[ZoneAdminService] updateZone: $id updated');
    } catch (e) {
      debugPrint('[ZoneAdminService] updateZone error: $e');
      rethrow;
    }
  }

  // WARNING: Deleting a zone does not remove animals referencing this zone.
  // Any animal document with a zoneId pointing here will retain a dangling reference.
  Future<void> deleteZone(String id) async {
    try {
      await _db.collection('zone').doc(id).delete();
      debugPrint('[ZoneAdminService] deleteZone: $id deleted');
    } catch (e) {
      debugPrint('[ZoneAdminService] deleteZone error: $e');
      rethrow;
    }
  }
}

final zoneAdminServiceProvider = Provider<ZoneAdminService>(
  (ref) => ZoneAdminService(),
);
