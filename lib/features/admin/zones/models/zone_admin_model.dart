class ZoneAdminModel {
  const ZoneAdminModel({required this.id, required this.zoneName});

  final String id;
  final String zoneName;

  factory ZoneAdminModel.fromMap(String id, Map<String, dynamic> map) {
    return ZoneAdminModel(id: id, zoneName: map['zoneName'] ?? '');
  }
}
