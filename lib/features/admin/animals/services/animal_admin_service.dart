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

  /// Returns a real-time stream of all animals, with zone names resolved.
  Stream<List<AnimalAdminModel>> getAnimals() {
    return _db.collection('zone').snapshots().asyncExpand((zoneSnap) {
      final zoneMap = {
        for (final doc in zoneSnap.docs)
          doc.id: (doc.data()['zoneName'] as String? ?? ''),
      };
      return _db
          .collection('animal')
          .snapshots()
          .map(
            (animalSnap) => animalSnap.docs
                .map((doc) => AnimalAdminModel.fromFirestore(doc, zoneMap))
                .toList(),
          )
          .handleError((Object e) {
            debugPrint('[AnimalAdminService] animal stream error: $e');
            throw e;
          });
    }).handleError((Object e) {
      debugPrint('[AnimalAdminService] zone stream error: $e');
      throw e;
    });
  }

  Future<List<Map<String, String>>> getZones() async {
    try {
      final snap = await _db.collection('zone').get();
      return snap.docs
          .map((doc) => {
                'id': doc.id,
                'name': (doc.data()['zoneName'] as String? ?? ''),
              })
          .toList();
    } catch (e) {
      debugPrint('[AnimalAdminService] getZones error: $e');
      rethrow;
    }
  }

  Future<void> addAnimal({
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required String zoneId,
    int locationX = 0,
    int locationY = 0,
  }) async {
    try {
      await _db.collection('animal').add({
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': _db.doc('/zone/$zoneId'),
      });
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
      await _db.collection('animal').doc(id).update({
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': _db.doc('/zone/$zoneId'),
      });
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
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = _storage.ref().child('animals/$fileName');
      final uploadTask = await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/$extension'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('[AnimalAdminService] uploadImage error: $e');
      rethrow;
    }
  }
}

final animalAdminServiceProvider = Provider<AnimalAdminService>(
  (ref) => AnimalAdminService(),
);
