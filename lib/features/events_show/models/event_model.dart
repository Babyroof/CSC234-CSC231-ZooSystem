class EventModel {
  final String id;
  final String eventName;
  final String eventDetail;
  final String eventPicture;
  final double? locationX;
  final double? locationY;

  EventModel({
    required this.id,
    required this.eventName,
    required this.eventDetail,
    required this.eventPicture,
    this.locationX,
    this.locationY,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      eventName: map['eventName'] ?? '',
      eventDetail: map['eventDetail'] ?? '',
      eventPicture: map['eventPicture'] ?? '',
      locationX: map['location_x'] != null ? (map['location_x'] as num).toDouble() : null,
      locationY: map['location_y'] != null ? (map['location_y'] as num).toDouble() : null,
    );
  }
}
