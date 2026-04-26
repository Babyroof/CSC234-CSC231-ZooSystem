import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../models/zone_model.dart';

class AnimalService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  //Random Animals
  Future<List<AnimalModel>> getRandomPopularAnimals(int count) async {
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
      print('getRandomPopularAnimals ERROR: $e'); // ดู error จริงๆ
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
      // 1. ดึง Zone มาก่อนแบบปลอดภัย
      final zoneSnap = await _db.collection('zone').get();
      final Map<String, String> zoneMap = {};
      for (var doc in zoneSnap.docs) {
        final name = doc.data()['zoneName'];
        zoneMap[doc.reference.path] = name?.toString() ?? 'Unknown';
      }

      // 2. ดึง Animals
      final animalSnap = await _db.collection('animal').get();

      for (var doc in animalSnap.docs) {
        try {
          final data = doc.data();
          // พิมพ์ดูเลยว่าตัวไหนกำลังถูกประมวลผล
          print('Processing Animal ID: ${doc.id}');

          String zoneName = 'Unknown';
          final dynamic zoneRef = data['zoneId'];

          if (zoneRef != null) {
            // ใช้การตรวจสอบแบบกว้างที่สุดเพื่อเลี่ยง TypeError
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
          });
        } catch (itemError) {
          // ถ้าพังแค่บางตัว ให้ข้ามตัวนั้นไปก่อน แอปจะได้ไม่ล่มทั้งหน้า
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
