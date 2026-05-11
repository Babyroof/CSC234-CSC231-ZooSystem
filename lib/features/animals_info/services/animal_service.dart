import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import '../models/zone_model.dart';

class AnimalService {
  final FirebaseFirestore _db;

  AnimalService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  //Random Animals
  Future<List<AnimalModel>> getRandomAnimals(int count) async {
    try {
      final snap = await _db.collection('animal').get();
      print('Firestore animal docs count: ${snap.docs.length}'); // เพิ่มตรงนี้

      List<AnimalModel> list = snap.docs.map((doc) {
        print('Doc ID: ${doc.id}, Data: ${doc.data()}'); // ดู raw data
        return AnimalModel.fromMap(doc.id, doc.data());
      }).toList();
      list.shuffle();
      return list.take(count).toList();
    } catch (e) {
      print('getRandomAnimals ERROR: $e'); // ดู error จริงๆ
      return [];
    }
  }

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

  // animal_service.dart

  Future<List<Map<String, dynamic>>> getAnimalsWithZone() async {
    List<Map<String, dynamic>> results = [];
    try {
      final zoneSnap = await _db.collection('zone').get();
      final Map<String, String> zoneMap = {};
      for (var doc in zoneSnap.docs) {
        final name = doc.data()['zoneName'];
        zoneMap[doc.reference.path] = name?.toString() ?? 'Unknown';
      }

      final animalSnap = await _db.collection('animal').get();

      for (var doc in animalSnap.docs) {
        try {
          final data = doc.data();
          print('Processing Animal ID: ${doc.id}');

          String zoneName = 'Unknown';
          final dynamic zoneRef = data['zoneId'];

          if (zoneRef != null) {
            String path = "";
            if (zoneRef is DocumentReference) {
              path = zoneRef.path;
            } else {
              path = zoneRef.toString();
            }
            zoneName = zoneMap[path] ?? zoneMap['/$path'] ?? 'Unknown';
          }

          results.add({
            'id': doc.id,
            'animalName': data['animalName']?.toString() ?? 'No Name',
            'animalDetail': data['animalDetail'] ?? '',
            'animalPicture': data['animalPicture'] ?? '',
            'zoneName': zoneName,
            'location_x': data['location_x'],
            'location_y': data['location_y'],
          });
        } catch (itemError) {
          print('Error at Animal ${doc.id}: ${itemError.toString()}');
          continue;
        }
      }
    } catch (e) {
      print('Critical Service Error: ${e.toString()}');
    }
    return results;
  }
}
