import '../../domain/entities/zone_entity.dart';

class ZoneDto {
  const ZoneDto({required this.id, required this.zoneName});

  final String id;
  final String zoneName;

  factory ZoneDto.fromMap(String id, Map<String, dynamic> map) =>
      ZoneDto(id: id, zoneName: map['zoneName'] ?? '');

  ZoneEntity toEntity() => ZoneEntity(id: id, zoneName: zoneName);
}
