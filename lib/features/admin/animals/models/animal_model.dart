import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalModel {
  final String id;
  final String animalName;
  final String animalDetail;
  final String animalPicture;
  final DocumentReference zoneId;
  final int? locationX;
  final int? locationY;

  const AnimalModel({
    required this.id,
    required this.animalName,
    required this.animalDetail,
    required this.animalPicture,
    required this.zoneId,
    this.locationX,
    this.locationY,
  });

  factory AnimalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnimalModel(
      id: doc.id,
      animalName: data['animalName'] as String? ?? '',
      animalDetail: data['animalDetail'] as String? ?? '',
      animalPicture: data['animalPicture'] as String? ?? '',
      zoneId: data['zoneId'] as DocumentReference,
      locationX: (data['location_x'] as num?)?.toInt(),
      locationY: (data['location_y'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'animalName': animalName,
        'animalDetail': animalDetail,
        'animalPicture': animalPicture,
        'zoneId': zoneId,
      };

  AnimalModel copyWith({
    String? id,
    String? animalName,
    String? animalDetail,
    String? animalPicture,
    DocumentReference? zoneId,
    int? locationX,
    int? locationY,
  }) =>
      AnimalModel(
        id: id ?? this.id,
        animalName: animalName ?? this.animalName,
        animalDetail: animalDetail ?? this.animalDetail,
        animalPicture: animalPicture ?? this.animalPicture,
        zoneId: zoneId ?? this.zoneId,
        locationX: locationX ?? this.locationX,
        locationY: locationY ?? this.locationY,
      );
}
