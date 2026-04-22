import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalModel {
  final String id;
  final String animalName;
  final String animalDetail;
  final String animalPicture;
  final String zoneId;

  AnimalModel({
    required this.id,
    required this.animalName,
    required this.animalDetail,
    required this.animalPicture,
    required this.zoneId,
  });

  factory AnimalModel.fromMap(String id, Map<String, dynamic> map) {
  String zoneId = '';
  final rawZone = map['zoneId'];
  if (rawZone is DocumentReference) {
    zoneId = rawZone.path; // จะได้ "zone/MeyQ7x9lJoyBO7Yx1iSy"
  } else if (rawZone is String) {
    zoneId = rawZone;
  }

  return AnimalModel(
    id: id,
    animalName: map['animalName'] ?? '',
    animalDetail: map['animalDetail'] ?? '',
    animalPicture: map['animalPicture'] ?? '',
    zoneId: zoneId,
  );
}
}