class AnimalModel {
  final String id;
  final String animalName;
  final String animalDetail;
  final String animalPicture;
  final String zoneId; // เป็น reference path เช่น /zone/UID

  AnimalModel({
    required this.id,
    required this.animalName,
    required this.animalDetail,
    required this.animalPicture,
    required this.zoneId,
  });

  factory AnimalModel.fromMap(String id, Map<String, dynamic> map) {
    return AnimalModel(
      id: id,
      animalName: map['animalName'] ?? '',
      animalDetail: map['animalDetail'] ?? '',
      animalPicture: map['animalPicture'] ?? '',
      zoneId: map['zoneId'] ?? '',
    );
  }
}