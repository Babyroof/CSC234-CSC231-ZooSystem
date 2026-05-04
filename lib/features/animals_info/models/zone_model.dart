class ZoneModel {
  final String id;
  final String zoneName;

  ZoneModel({required this.id, required this.zoneName});

  factory ZoneModel.fromMap(String id, Map<String, dynamic> map) {
    return ZoneModel(id: id, zoneName: map['zoneName'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'zoneName': zoneName};
  }
}
