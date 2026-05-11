class AnimalAdminModel {
  final String id;
  final String animalName;
  final String animalDetail;
  final String animalPicture;
  final String zoneId;
  final String zoneName;
  final int locationX;
  final int locationY;

  const AnimalAdminModel({
    required this.id,
    required this.animalName,
    required this.animalDetail,
    required this.animalPicture,
    required this.zoneId,
    required this.zoneName,
    this.locationX = 0,
    this.locationY = 0,
  });

  // TODO (backend): service layer must resolve DocumentReference → path string before calling fromMap
  factory AnimalAdminModel.fromMap(
    String id,
    Map<String, dynamic> map,
    Map<String, String> zoneMap,
  ) {
    final zoneId = (map['zoneId'] as String?) ?? '';
    return AnimalAdminModel(
      id: id,
      animalName: map['animalName'] ?? '',
      animalDetail: map['animalDetail'] ?? '',
      animalPicture: map['animalPicture'] ?? '',
      zoneId: zoneId,
      zoneName: zoneMap[zoneId] ?? 'Unknown',
      locationX: (map['location_x'] as num?)?.toInt() ?? 0,
      locationY: (map['location_y'] as num?)?.toInt() ?? 0,
    );
  }
}
