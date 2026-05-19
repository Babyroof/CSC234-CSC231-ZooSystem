import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/animal_entity.dart';

class AnimalDto {
  const AnimalDto({
    required this.id,
    required this.animalName,
    required this.animalDetail,
    required this.animalPicture,
    required this.zoneId,
  });

  final String id;
  final String animalName;
  final String animalDetail;
  final String animalPicture;
  final String zoneId;

  factory AnimalDto.fromMap(String id, Map<String, dynamic> map) {
    String zoneId = '';
    final rawZone = map['zoneId'];
    if (rawZone is DocumentReference) {
      zoneId = rawZone.path;
    } else if (rawZone is String) {
      zoneId = rawZone;
    }
    return AnimalDto(
      id: id,
      animalName: map['animalName'] ?? '',
      animalDetail: map['animalDetail'] ?? '',
      animalPicture: map['animalPicture'] ?? '',
      zoneId: zoneId,
    );
  }

  AnimalEntity toEntity() => AnimalEntity(
    id: id,
    animalName: animalName,
    animalDetail: animalDetail,
    animalPicture: animalPicture,
    zoneId: zoneId,
  );
}
