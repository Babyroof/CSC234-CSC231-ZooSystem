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
