class AnimalWithZoneEntity {
  const AnimalWithZoneEntity({
    required this.id,
    required this.animalName,
    required this.animalDetail,
    required this.animalPicture,
    required this.zoneName,
    this.locationX,
    this.locationY,
  });

  final String id;
  final String animalName;
  final String animalDetail;
  final String animalPicture;
  final String zoneName;
  final num? locationX;
  final num? locationY;

  factory AnimalWithZoneEntity.fromMap(Map<String, dynamic> map) =>
      AnimalWithZoneEntity(
        id: map['id'] as String? ?? '',
        animalName: map['animalName'] as String? ?? '',
        animalDetail: map['animalDetail'] as String? ?? '',
        animalPicture: map['animalPicture'] as String? ?? '',
        zoneName: map['zoneName'] as String? ?? '',
        locationX: map['location_x'] as num?,
        locationY: map['location_y'] as num?,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'animalName': animalName,
    'animalDetail': animalDetail,
    'animalPicture': animalPicture,
    'zoneName': zoneName,
    'location_x': locationX,
    'location_y': locationY,
  };
}
