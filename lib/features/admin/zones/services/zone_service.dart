import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/zone_model.dart';

class ZoneService {
  final FirebaseFirestore _db;

  static const String _collection = 'zone';

  ZoneService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<ZoneModel>> getZones() {
    try {
      return _db
          .collection(_collection)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList(),
          )
          .handleError((Object e) {
            debugPrint('[ZoneService] getZones stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[ZoneService] getZones error: $e');
      rethrow;
    }
  }

  Future<ZoneModel?> getZoneById(String zoneId) async {
    try {
      final doc = await _db.collection(_collection).doc(zoneId).get();
      if (!doc.exists) return null;
      return ZoneModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ZoneService] getZoneById error: $e');
      rethrow;
    }
  }

  Future<DocumentReference> createZone(String zoneName) async {
    try {
      final ref = await _db.collection(_collection).add({'zoneName': zoneName});
      debugPrint('[ZoneService] createZone: ${ref.id}');
      return ref;
    } catch (e) {
      debugPrint('[ZoneService] createZone error: $e');
      rethrow;
    }
  }

  Future<void> updateZone({
    required String zoneId,
    required String zoneName,
  }) async {
    try {
      await _db.collection(_collection).doc(zoneId).update({
        'zoneName': zoneName,
      });
      debugPrint('[ZoneService] updateZone: $zoneId updated');
    } catch (e) {
      debugPrint('[ZoneService] updateZone error: $e');
      rethrow;
    }
  }

  // WARNING: Deleting a zone does NOT cascade. Any animal document that holds a
  // DocumentReference pointing to this zone will retain a dangling reference.
  // Verify no animals reference this zone before calling deleteZone in production.
  Future<void> deleteZone(String zoneId) async {
    try {
      await _db.collection(_collection).doc(zoneId).delete();
      debugPrint('[ZoneService] deleteZone: $zoneId deleted');
    } catch (e) {
      debugPrint('[ZoneService] deleteZone error: $e');
      rethrow;
    }
  }
}
