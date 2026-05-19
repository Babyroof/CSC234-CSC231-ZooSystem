import '../entities/animal_entity.dart';
import '../entities/zone_entity.dart';
import '../entities/animal_with_zone_entity.dart';

abstract class AnimalRepository {
  Future<List<AnimalEntity>> getAnimals();
  Future<List<AnimalEntity>> getRandomAnimals(int count);
  Future<List<AnimalEntity>> getAnimalsByZone(String zoneId);
  Future<List<ZoneEntity>> getZones();
  Future<List<AnimalWithZoneEntity>> getAnimalsWithZone();
}
