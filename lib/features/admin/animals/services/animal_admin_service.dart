import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal_admin_model.dart';

class AnimalAdminService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  AnimalAdminService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  /// Pre-generates a Firestore document ID without creating the document.
  String generateAnimalId() => _db.collection('animal').doc().id;

  Stream<List<AnimalAdminModel>> getAnimals() {
    return _db
        .collection('animal')
        .snapshots()
        .asyncMap((animalSnap) async {
          final zoneSnap = await _db.collection('zone').get();
          final zoneMap = {
            for (final doc in zoneSnap.docs)
              doc.id: (doc.data()['zoneName'] as String?) ?? '',
          };

          return animalSnap.docs.map((doc) {
            final data = doc.data();

            String zoneId = '';
            final rawZoneId = data['zoneId'];
            if (rawZoneId is DocumentReference) {
              zoneId = rawZoneId.id;
            } else if (rawZoneId is String) {
              zoneId = rawZoneId.split('/').last;
            }

            return AnimalAdminModel(
              id: doc.id,
              animalName: (data['animalName'] as String?) ?? '',
              animalDetail: (data['animalDetail'] as String?) ?? '',
              animalPicture: (data['animalPicture'] as String?) ?? '',
              zoneId: zoneId,
              zoneName: zoneMap[zoneId] ?? 'Unknown',
              locationX: (data['location_x'] as num?)?.toInt() ?? 0,
              locationY: (data['location_y'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        })
        .handleError((Object e) {
          debugPrint('[AnimalAdminService] getAnimals stream error: $e');
          throw e;
        });
  }

  Future<List<Map<String, String>>> getZones() async {
    try {
      final snap = await _db.collection('zone').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': (data['zoneName'] as String?) ?? ''};
      }).toList();
    } catch (e) {
      debugPrint('[AnimalAdminService] getZones error: $e');
      rethrow;
    }
  }

  Future<void> addAnimal({
    String? id,
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required String zoneId,
    int locationX = 0,
    int locationY = 0,
  }) async {
    try {
      final data = {
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': _db.doc('zone/$zoneId'),
        'location_x': locationX,
        'location_y': locationY,
      };
      if (id != null) {
        await _db.collection('animal').doc(id).set(data);
      } else {
        await _db.collection('animal').add(data);
      }
    } catch (e) {
      debugPrint('[AnimalAdminService] addAnimal error: $e');
      rethrow;
    }
  }

  Future<void> updateAnimal(
    String id, {
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required String zoneId,
    int? locationX,
    int? locationY,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': _db.doc('zone/$zoneId'),
      };
      if (locationX != null) updateData['location_x'] = locationX;
      if (locationY != null) updateData['location_y'] = locationY;
      await _db.collection('animal').doc(id).update(updateData);
    } catch (e) {
      debugPrint('[AnimalAdminService] updateAnimal error: $e');
      rethrow;
    }
  }

  Future<void> deleteAnimal(String id) async {
    try {
      await _db.collection('animal').doc(id).delete();
    } catch (e) {
      debugPrint('[AnimalAdminService] deleteAnimal error: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(List<int> bytes, String extension) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref('animals/$timestamp.$extension');
      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/$extension'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[AnimalAdminService] uploadImage error: $e');
      rethrow;
    }
  }
}

final animalAdminServiceProvider = Provider<AnimalAdminService>(
  (ref) => AnimalAdminService(),
);
