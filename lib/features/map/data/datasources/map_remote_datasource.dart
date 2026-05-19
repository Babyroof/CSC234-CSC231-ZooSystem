import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../../../events_show/domain/entities/event_entity.dart';
import '../../domain/entities/map_entity.dart';

abstract class MapRemoteDataSource {
  Stream<MapEntity?> watchMap();
  Stream<List<AnimalWithZoneEntity>> watchAnimalsWithZone();
  Stream<List<EventEntity>> watchEvents();
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final FirebaseFirestore _db;

  MapRemoteDataSourceImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  @override
  Stream<MapEntity?> watchMap() {
    try {
      return _db.collection('map').snapshots().map((snap) {
        if (snap.docs.isEmpty) return null;
        final url = snap.docs.first.data()['mapPicture'] as String?;
        if (url == null || url.isEmpty) return null;
        return MapEntity(mapPicture: url);
      });
    } catch (e) {
      debugPrint('[MapDataSource] watchMap failed: $e');
      return const Stream.empty();
    }
  }

  @override
  Stream<List<AnimalWithZoneEntity>> watchAnimalsWithZone() async* {
    try {
      final zoneSnap = await _db.collection('zone').get();
      final zoneMap = <String, String>{};
      for (final doc in zoneSnap.docs) {
        zoneMap[doc.reference.path] =
            doc.data()['zoneName']?.toString() ?? 'Unknown';
      }

      yield* _db.collection('animal').snapshots().map((snap) {
        return snap.docs.map((doc) {
          final data = doc.data();
          String zoneName = 'Unknown';
          final dynamic zoneRef = data['zoneId'];
          if (zoneRef != null) {
            final path = zoneRef is DocumentReference
                ? zoneRef.path
                : zoneRef.toString();
            zoneName = zoneMap[path] ?? zoneMap['/$path'] ?? 'Unknown';
          }
          return AnimalWithZoneEntity(
            id: doc.id,
            animalName: data['animalName']?.toString() ?? '',
            animalDetail: data['animalDetail']?.toString() ?? '',
            animalPicture: data['animalPicture']?.toString() ?? '',
            zoneName: zoneName,
            locationX: data['location_x'] as num?,
            locationY: data['location_y'] as num?,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('[MapDataSource] watchAnimalsWithZone failed: $e');
      yield [];
    }
  }

  @override
  Stream<List<EventEntity>> watchEvents() {
    try {
      return _db.collection('event').snapshots().map((snap) {
        return snap.docs.map((doc) {
          final data = doc.data();
          return EventEntity(
            id: doc.id,
            eventName: data['eventName']?.toString() ?? '',
            eventDetail: data['eventDetail']?.toString() ?? '',
            eventPicture: data['eventPicture']?.toString() ?? '',
            locationX: data['location_x'] != null
                ? (data['location_x'] as num).toDouble()
                : null,
            locationY: data['location_y'] != null
                ? (data['location_y'] as num).toDouble()
                : null,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('[MapDataSource] watchEvents failed: $e');
      return const Stream.empty();
    }
  }
}
