import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal_admin_model.dart';

class AnimalAdminService {
  // TODO: Inject FirebaseFirestore — replace all methods with real Firestore calls
  final List<AnimalAdminModel> _animals = [
    const AnimalAdminModel(
      id: 'mock_1',
      animalName: 'Scarlet Macaw',
      animalDetail: 'Native to South America with vibrant red plumage.',
      animalPicture: '',
      zoneId: 'zone_1',
      zoneName: 'Bird Zone',
      locationX: 200,
      locationY: 150,
    ),
    const AnimalAdminModel(
      id: 'mock_2',
      animalName: 'African Elephant',
      animalDetail: 'Largest land animal on Earth.',
      animalPicture: '',
      zoneId: 'zone_2',
      zoneName: 'Savanna Zone',
      locationX: 500,
      locationY: 300,
    ),
    const AnimalAdminModel(
      id: 'mock_3',
      animalName: 'Bottlenose Dolphin',
      animalDetail: 'Highly intelligent marine mammal.',
      animalPicture: '',
      zoneId: 'zone_3',
      zoneName: 'Aquatic Zone',
      locationX: 700,
      locationY: 600,
    ),
  ];

  int _nextId = 4;

  Future<List<AnimalAdminModel>> getAnimals() async {
    // TODO: Query 'animal' collection and join 'zone' collection for zoneName
    return List.from(_animals);
  }

  Future<List<Map<String, String>>> getZones() async {
    // TODO: Query 'zone' collection
    return [
      {'id': 'zone_1', 'name': 'Bird Zone'},
      {'id': 'zone_2', 'name': 'Savanna Zone'},
      {'id': 'zone_3', 'name': 'Aquatic Zone'},
    ];
  }

  Future<void> addAnimal({
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required String zoneId,
    required int locationX,
    required int locationY,
  }) async {
    // TODO: _db.collection('animal').add({...}), zoneId as DocumentReference: _db.doc('zone/$zoneId')
    _animals.add(
      AnimalAdminModel(
        id: 'mock_${_nextId++}',
        animalName: animalName,
        animalDetail: animalDetail,
        animalPicture: animalPicture,
        zoneId: zoneId,
        zoneName: zoneId,
        locationX: locationX,
        locationY: locationY,
      ),
    );
  }

  Future<void> updateAnimal(
    String id, {
    required String animalName,
    required String animalDetail,
    required String animalPicture,
    required String zoneId,
    int? locationX,
    int? locationY,
  }) async {
    // TODO: _db.collection('animal').doc(id).update({...})
    final index = _animals.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final old = _animals[index];
    _animals[index] = AnimalAdminModel(
      id: id,
      animalName: animalName,
      animalDetail: animalDetail,
      animalPicture: animalPicture,
      zoneId: zoneId,
      zoneName: zoneId,
      locationX: locationX ?? old.locationX,
      locationY: locationY ?? old.locationY,
    );
  }

  Future<void> deleteAnimal(String id) async {
    // TODO: _db.collection('animal').doc(id).delete()
    _animals.removeWhere((a) => a.id == id);
  }

  Future<String> uploadImage(List<int> bytes, String extension) async {
    // TODO: Upload to Firebase Storage at 'animals/<timestamp>.<ext>', return download URL
    return '';
  }
}

final animalAdminServiceProvider = Provider<AnimalAdminService>(
  (ref) => AnimalAdminService(),
);
