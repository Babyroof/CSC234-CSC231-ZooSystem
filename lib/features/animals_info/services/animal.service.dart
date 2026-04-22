import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import '../models/zone_model.dart';

class AnimalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GET all zones
  Future<List<ZoneModel>> getZones() async {
    try {
      final snapshot = await _db.collection('zone').get();
      return snapshot.docs
          .map((doc) => ZoneModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting zones: $e');
      return [];
    }
  }

  // GET all animals
  Future<List<AnimalModel>> getAnimals() async {
    try {
      final snapshot = await _db.collection('animal').get();
      return snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting animals: $e');
      return [];
    }
  }

  // GET animals by zone
  Future<List<AnimalModel>> getAnimalsByZone(String zoneId) async {
    try {
      final snapshot = await _db
          .collection('animal')
          .where('zoneId', isEqualTo: '/zone/$zoneId')
          .get();
      return snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting animals by zone: $e');
      return [];
    }
  }
}