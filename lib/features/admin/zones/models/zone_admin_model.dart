// TODO: consolidate with ZoneModel
import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneAdminModel {
  const ZoneAdminModel({required this.id, required this.zoneName});

  final String id;
  final String zoneName;

  factory ZoneAdminModel.fromMap(String id, Map<String, dynamic> map) {
    return ZoneAdminModel(id: id, zoneName: map['zoneName'] ?? '');
  }

  factory ZoneAdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ZoneAdminModel(
      id: doc.id,
      zoneName: data['zoneName'] as String? ?? '',
    );
  }
}
