import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/animal_model.dart';

class AnimalService {
  final FirebaseFirestore _db;

  static const String _collection = 'animal';

  AnimalService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<AnimalModel>> getAnimals() {
    try {
      return _db
          .collection(_collection)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => AnimalModel.fromFirestore(doc)).toList(),
          )
          .handleError((Object e) {
            debugPrint('[AnimalService] getAnimals stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[AnimalService] getAnimals error: $e');
      rethrow;
    }
  }

  Future<AnimalModel?> getAnimalById(String animalId) async {
    try {
      final doc = await _db.collection(_collection).doc(animalId).get();
      if (!doc.exists) return null;
      return AnimalModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[AnimalService] getAnimalById error: $e');
      rethrow;
    }
  }

  Future<void> createAnimal({
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required DocumentReference zoneId,
  }) async {
    try {
      await _db.collection(_collection).add({
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': zoneId,
      });
      debugPrint('[AnimalService] createAnimal: success');
    } catch (e) {
      debugPrint('[AnimalService] createAnimal error: $e');
      rethrow;
    }
  }

  Future<void> updateAnimal({
    required String animalId,
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required DocumentReference zoneId,
  }) async {
    try {
      await _db.collection(_collection).doc(animalId).update({
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': zoneId,
      });
      debugPrint('[AnimalService] updateAnimal: $animalId updated');
    } catch (e) {
      debugPrint('[AnimalService] updateAnimal error: $e');
      rethrow;
    }
  }

  Future<void> deleteAnimal(String animalId) async {
    try {
      await _db.collection(_collection).doc(animalId).delete();
      debugPrint('[AnimalService] deleteAnimal: $animalId deleted');
    } catch (e) {
      debugPrint('[AnimalService] deleteAnimal error: $e');
      rethrow;
    }
  }
}
