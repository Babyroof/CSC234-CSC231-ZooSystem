import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/animal_dto.dart';
import '../models/zone_dto.dart';
import '../../domain/entities/animal_with_zone_entity.dart';

abstract class AnimalRemoteDataSource {
  Future<List<AnimalDto>> getAnimals();
  Future<List<AnimalDto>> getRandomAnimals(int count);
  Future<List<AnimalDto>> getAnimalsByZone(String zoneId);
  Future<List<ZoneDto>> getZones();
  Future<List<AnimalWithZoneEntity>> getAnimalsWithZone();
}

class AnimalRemoteDataSourceImpl implements AnimalRemoteDataSource {
  final FirebaseFirestore _db;

  AnimalRemoteDataSourceImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  @override
  Future<List<AnimalDto>> getAnimals() async {
    try {
      final snap = await _db.collection('animal').get();
      return snap.docs.map((d) => AnimalDto.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('[AnimalDataSource] getAnimals failed: $e');
      return [];
    }
  }

  @override
  Future<List<AnimalDto>> getRandomAnimals(int count) async {
    try {
      final snap = await _db.collection('animal').get();
      final list = snap.docs
          .map((d) => AnimalDto.fromMap(d.id, d.data()))
          .toList();
      list.shuffle();
      return list.take(count).toList();
    } catch (e) {
      debugPrint('[AnimalDataSource] getRandomAnimals failed: $e');
      return [];
    }
  }

  @override
  Future<List<AnimalDto>> getAnimalsByZone(String zoneId) async {
    try {
      final snap = await _db
          .collection('animal')
          .where('zoneId', isEqualTo: '/zone/$zoneId')
          .get();
      return snap.docs.map((d) => AnimalDto.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('[AnimalDataSource] getAnimalsByZone failed: $e');
      return [];
    }
  }

  @override
  Future<List<ZoneDto>> getZones() async {
    try {
      final snap = await _db.collection('zone').get();
      return snap.docs.map((d) => ZoneDto.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('[AnimalDataSource] getZones failed: $e');
      return [];
    }
  }

  @override
  Future<List<AnimalWithZoneEntity>> getAnimalsWithZone() async {
    final results = <AnimalWithZoneEntity>[];
    try {
      final zoneSnap = await _db.collection('zone').get();
      final zoneMap = <String, String>{};
      for (final doc in zoneSnap.docs) {
        final name = doc.data()['zoneName'];
        zoneMap[doc.reference.path] = name?.toString() ?? 'Unknown';
      }

      final animalSnap = await _db.collection('animal').get();
      for (final doc in animalSnap.docs) {
        try {
          final data = doc.data();
          String zoneName = 'Unknown';
          final dynamic zoneRef = data['zoneId'];
          if (zoneRef != null) {
            final path = zoneRef is DocumentReference
                ? zoneRef.path
                : zoneRef.toString();
            zoneName = zoneMap[path] ?? zoneMap['/$path'] ?? 'Unknown';
          }
          results.add(
            AnimalWithZoneEntity(
              id: doc.id,
              animalName: data['animalName']?.toString() ?? '',
              animalDetail: data['animalDetail']?.toString() ?? '',
              animalPicture: data['animalPicture']?.toString() ?? '',
              zoneName: zoneName,
              locationX: data['location_x'] as num?,
              locationY: data['location_y'] as num?,
            ),
          );
        } catch (e) {
          debugPrint('[AnimalDataSource] error at ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[AnimalDataSource] getAnimalsWithZone failed: $e');
    }
    return results;
  }
}
