import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/animal_with_zone_entity.dart';

class AnimalLocalDataSource {
  static const _boxName = 'animals_cache';
  static const _keyAnimalsWithZone = 'animals_with_zone';

  Future<Box<String>> _openBox() => Hive.openBox<String>(_boxName);

  Future<List<AnimalWithZoneEntity>?> getAnimalsWithZone() async {
    try {
      final box = await _openBox();
      final raw = box.get(_keyAnimalsWithZone);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AnimalWithZoneEntity.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AnimalCache] read failed: $e');
      return null;
    }
  }

  Future<void> saveAnimalsWithZone(List<AnimalWithZoneEntity> animals) async {
    try {
      final box = await _openBox();
      final encoded = jsonEncode(animals.map((a) => a.toMap()).toList());
      await box.put(_keyAnimalsWithZone, encoded);
    } catch (e) {
      debugPrint('[AnimalCache] write failed: $e');
    }
  }
}
