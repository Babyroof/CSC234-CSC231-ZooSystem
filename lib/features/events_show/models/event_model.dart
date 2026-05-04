class EventModel {
  final String id;
  final String eventName;
  final String eventDetail;
  final String eventPicture;

  EventModel({
    required this.id,
    required this.eventName,
    required this.eventDetail,
    required this.eventPicture,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      eventName: map['eventName'] ?? '',
      eventDetail: map['eventDetail'] ?? '',
      eventPicture: map['eventPicture'] ?? '',
    );
  }
}
