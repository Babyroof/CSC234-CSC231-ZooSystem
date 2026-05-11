import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String zoneName;

  const ZoneModel({required this.id, required this.zoneName});

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ZoneModel(id: doc.id, zoneName: data['zoneName'] as String? ?? '');
  }

  Map<String, dynamic> toMap() => {'zoneName': zoneName};

  ZoneModel copyWith({String? id, String? zoneName}) =>
      ZoneModel(id: id ?? this.id, zoneName: zoneName ?? this.zoneName);
}
