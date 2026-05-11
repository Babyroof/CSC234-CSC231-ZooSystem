class EventAdminModel {
  final String id;
  final String eventName;
  final String eventDetail;
  final String eventPicture;
  final int locationX;
  final int locationY;

  const EventAdminModel({
    required this.id,
    required this.eventName,
    required this.eventDetail,
    required this.eventPicture,
    required this.locationX,
    required this.locationY,
  });

  factory EventAdminModel.fromMap(String id, Map<String, dynamic> map) {
    return EventAdminModel(
      id: id,
      eventName: map['eventName'] ?? '',
      eventDetail: map['eventDetail'] ?? '',
      eventPicture: map['eventPicture'] ?? '',
      locationX: (map['location_x'] as num?)?.toInt() ?? 0,
      locationY: (map['location_y'] as num?)?.toInt() ?? 0,
    );
  }
}
