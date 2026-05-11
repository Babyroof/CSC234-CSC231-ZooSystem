import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/zone_admin_model.dart';

class ZoneAdminService {
  // TODO: Inject FirebaseFirestore — replace all methods with real Firestore calls
  final List<ZoneAdminModel> _zones = [
    const ZoneAdminModel(id: 'zone_1', zoneName: 'Bird Zone'),
    const ZoneAdminModel(id: 'zone_2', zoneName: 'Savanna Zone'),
    const ZoneAdminModel(id: 'zone_3', zoneName: 'Aquatic Zone'),
  ];

  int _nextId = 4;

  Future<List<ZoneAdminModel>> getZones() async {
    // TODO: Query 'zone' collection
    return List.from(_zones);
  }

  Future<void> addZone(String zoneName) async {
    // TODO: _db.collection('zone').add({'zoneName': zoneName})
    _zones.add(ZoneAdminModel(id: 'zone_${_nextId++}', zoneName: zoneName));
  }

  Future<void> updateZone(String id, String zoneName) async {
    // TODO: _db.collection('zone').doc(id).update({'zoneName': zoneName})
    final index = _zones.indexWhere((z) => z.id == id);
    if (index != -1) _zones[index] = ZoneAdminModel(id: id, zoneName: zoneName);
  }

  Future<void> deleteZone(String id) async {
    // TODO: _db.collection('zone').doc(id).delete()
    _zones.removeWhere((z) => z.id == id);
  }
}

final zoneAdminServiceProvider = Provider<ZoneAdminService>(
  (ref) => ZoneAdminService(),
);
