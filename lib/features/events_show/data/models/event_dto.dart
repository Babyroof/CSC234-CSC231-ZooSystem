import '../../domain/entities/event_entity.dart';

class EventDto {
  const EventDto({
    required this.id,
    required this.eventName,
    required this.eventDetail,
    required this.eventPicture,
    this.locationX,
    this.locationY,
  });

  final String id;
  final String eventName;
  final String eventDetail;
  final String eventPicture;
  final double? locationX;
  final double? locationY;

  factory EventDto.fromMap(String id, Map<String, dynamic> map) => EventDto(
    id: id,
    eventName: map['eventName'] ?? '',
    eventDetail: map['eventDetail'] ?? '',
    eventPicture: map['eventPicture'] ?? '',
    locationX: map['location_x'] != null
        ? (map['location_x'] as num).toDouble()
        : null,
    locationY: map['location_y'] != null
        ? (map['location_y'] as num).toDouble()
        : null,
  );

  EventEntity toEntity() => EventEntity(
    id: id,
    eventName: eventName,
    eventDetail: eventDetail,
    eventPicture: eventPicture,
    locationX: locationX,
    locationY: locationY,
  );
}
