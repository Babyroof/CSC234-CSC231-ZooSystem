import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String eventName;
  final String eventDetail;
  final String eventPicture;
  final int? locationX;
  final int? locationY;

  const EventModel({
    required this.id,
    required this.eventName,
    required this.eventDetail,
    required this.eventPicture,
    this.locationX,
    this.locationY,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      eventName: data['eventName'] as String? ?? '',
      eventDetail: data['eventDetail'] as String? ?? '',
      eventPicture: data['eventPicture'] as String? ?? '',
      locationX: (data['location_x'] as num?)?.toInt(),
      locationY: (data['location_y'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventName': eventName,
        'eventDetail': eventDetail,
        'eventPicture': eventPicture,
      };

  EventModel copyWith({
    String? id,
    String? eventName,
    String? eventDetail,
    String? eventPicture,
    int? locationX,
    int? locationY,
  }) =>
      EventModel(
        id: id ?? this.id,
        eventName: eventName ?? this.eventName,
        eventDetail: eventDetail ?? this.eventDetail,
        eventPicture: eventPicture ?? this.eventPicture,
        locationX: locationX ?? this.locationX,
        locationY: locationY ?? this.locationY,
      );
}
