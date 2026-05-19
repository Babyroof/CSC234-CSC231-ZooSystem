class EventEntity {
  const EventEntity({
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
}
